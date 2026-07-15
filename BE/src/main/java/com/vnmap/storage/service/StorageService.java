package com.vnmap.storage.service;

import com.vnmap.common.util.SigV4Presigner;
import com.vnmap.storage.dto.UploadUrlResponse;
import com.vnmap.common.security.CurrentUser;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpDelete;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.entity.ByteArrayEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Map;

/**
 * Service for generating pre-signed URLs and uploading generated objects to MinIO.
 *
 * The FE uploads directly to MinIO using a pre-signed URL -- the file never
 * passes through the backend, avoiding memory/bandwidth bottlenecks.
 *
 * Server-side uploads (e.g. generated PDFs) use raw HTTP via presigned URLs
 * produced by {@link SigV4Presigner} and Apache HttpClient because the
 * AWS SDK v2 client/presigner chain fails against non-AWS HTTP endpoints
 * like MinIO (URISyntaxException).
 */
@Service
public class StorageService {

    private static final Logger log = LoggerFactory.getLogger(StorageService.class);
    private static final long URL_EXPIRY_SECONDS = 15L * 60; // 15 minutes
    private static final String OBJECT_KEY_SEPARATOR = "/";
    private final CloseableHttpClient httpClient;
    private final String publicEndpoint;
    private final String internalEndpoint;
    private final String bucket;
    private final String reportsBucket;
    private final SigV4Presigner.Credentials credentials;

    public StorageService(
            CloseableHttpClient minioHttpClient,
            @Value("${minio.public-endpoint:http://localhost:9002}") String publicEndpoint,
            @Value("${minio.endpoint:http://localhost:9002}") String internalEndpoint,
            @Value("${minio.access-key:minioadmin}") String accessKey,
            @Value("${minio.secret-key:minioadmin}") String secretKey,
            @Value("${minio.region:us-east-1}") String region,
            @Value("${minio.bucket:vnmap-campaign}") String bucket,
            @Value("${minio.reports-bucket:vnmap-campaign-reports}") String reportsBucket
    ) {
        this.httpClient = minioHttpClient;
        this.publicEndpoint = stripTrailingSlash(publicEndpoint);
        this.internalEndpoint = stripTrailingSlash(internalEndpoint);
        this.bucket = bucket;
        this.reportsBucket = reportsBucket;
        this.credentials = new SigV4Presigner.Credentials(accessKey, secretKey, region);
    }

    public String getBucket() {
        return bucket;
    }

    /**
     * Generates a pre-signed URL for uploading a file to MinIO. URL is signed
     * against the public endpoint so the browser can use it directly.
     */
    public UploadUrlResponse generateUploadUrl(
            String folder, String fileName, String contentType, CurrentUser user
    ) {
        if (user == null) {
            throw new IllegalArgumentException("Authenticated user is required");
        }
        if (!"avatars".equals(folder)) {
            throw new IllegalArgumentException("Unsupported upload folder");
        }
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("Only image uploads are allowed");
        }
        String sanitizedFileName = sanitizeFileName(fileName);
        String path = String.join(OBJECT_KEY_SEPARATOR, "avatars", String.valueOf(user.id()), sanitizedFileName);

        String uploadUrl = SigV4Presigner.presign(
                publicEndpoint, bucket, path, "PUT", credentials, (int) URL_EXPIRY_SECONDS);
        String publicUrl = String.join("/", publicEndpoint, bucket, path);
        long expiresAtSeconds = (System.currentTimeMillis() / 1000) + URL_EXPIRY_SECONDS;
        log.info("Generated upload URL for path={}, userId={}", path, user.id());
        return new UploadUrlResponse(uploadUrl, publicUrl, path, expiresAtSeconds);
    }

    /**
     * Uploads generated content (e.g. a rendered PDF) directly to MinIO using
     * a presigned PUT URL + raw Apache HttpClient. The signed URL is built
     * against the internal endpoint so the BE reaches MinIO over the Docker
     * network without requiring a host rewrite.
     */
    public void uploadGeneratedObject(String path, byte[] bytes, String contentType) {
        if (path == null || path.isBlank()) return;
        UploadTarget target = resolveTarget(path);
        try {
            String signedUrl = SigV4Presigner.presignPut(
                    internalEndpoint, target.bucket, target.key, credentials, (int) URL_EXPIRY_SECONDS);
            log.info("uploadGeneratedObject url={}", signedUrl);
            HttpPut httpPut = new HttpPut(signedUrl);
            String ct = contentType == null ? "application/octet-stream" : contentType;
            httpPut.setHeader("Content-Type", ct);
            httpPut.setEntity(new ByteArrayEntity(bytes));
            executeAndCheck(httpPut, "PUT " + target.bucket + "/" + target.key);
            log.info("Uploaded generated object bucket={} key={} bytes={}",
                    target.bucket, target.key, bytes.length);
        } catch (Exception e) {
            log.error("Failed to upload generated object path={}: {}", path, e.getMessage());
            throw new RuntimeException("Failed to upload object to storage", e);
        }
    }

    /**
     * Generates a time-limited signed URL for downloading an object from MinIO.
     */
    public String generateDownloadUrl(String path, Duration ttl) {
        if (path == null || path.isBlank()) return null;
        UploadTarget target = resolveTarget(path);
        return SigV4Presigner.presignGet(
                publicEndpoint, target.bucket, target.key, credentials, (int) ttl.getSeconds());
    }

    /**
     * Deletes an object from MinIO by its path. Best-effort: tolerates 404.
     */
    public void deleteObject(String path) {
        if (path == null || path.isBlank()) return;
        UploadTarget target = resolveTarget(path);
        try {
            // Delete via an unsigned DELETE against the internal endpoint
            // (the init script leaves the buckets writable from the BE network).
            String url = String.join("/", internalEndpoint, target.bucket, target.key);
            HttpDelete httpDelete = new HttpDelete(url);
            HttpResponse response = httpClient.execute(httpDelete);
            int status = response.getStatusLine().getStatusCode();
            if (status != 204 && status != 404) {
                log.warn("Unexpected DELETE status {} for {}/{}", status, target.bucket, target.key);
            } else {
                log.info("Deleted object bucket={} key={} status={}", target.bucket, target.key, status);
            }
        } catch (Exception e) {
            log.warn("Failed to delete object path={}: {}", path, e.getMessage());
        }
    }

    private void executeAndCheck(HttpUriRequest request, String description) throws IOException {
        HttpResponse response = httpClient.execute(request);
        int status = response.getStatusLine().getStatusCode();
        if (status < 200 || status >= 300) {
            String body = "";
            try (java.io.InputStream is = response.getEntity().getContent();
                 java.io.ByteArrayOutputStream bos = new java.io.ByteArrayOutputStream()) {
                is.transferTo(bos);
                body = bos.toString(StandardCharsets.UTF_8);
            } catch (Exception ignored) {
                log.debug("Unable to read failed MinIO response body", ignored);
            }
            throw new IOException("MinIO request " + description
                    + " failed with status " + status + " body=" + body);
        }
    }

    /** Resolves the {@code path} argument into a (bucket, key) pair. */
    private UploadTarget resolveTarget(String path) {
        String normalized = path.startsWith("/") ? path.substring(1) : path;
        String targetBucket = normalized.startsWith("reports/") ? reportsBucket : bucket;
        return new UploadTarget(targetBucket, normalized);
    }

    /** Removes path traversal characters and reserved characters from the filename. */
    private String sanitizeFileName(String fileName) {
        String name = fileName.replaceAll("[/\\\\]", "_")
                               .replaceAll("[^a-zA-Z0-9._-]", "_");
        return System.currentTimeMillis() + "_" + name;
    }

    private String stripTrailingSlash(String s) {
        return s.endsWith("/") ? s.substring(0, s.length() - 1) : s;
    }

    private record UploadTarget(String bucket, String key) {}
}