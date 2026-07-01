package com.vnmap.storage.service;

import com.google.cloud.storage.BlobId;
import com.google.cloud.storage.BlobInfo;
import com.google.cloud.storage.HttpMethod;
import com.google.cloud.storage.Storage;
import com.vnmap.storage.dto.UploadUrlResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URL;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Service for generating Firebase Storage pre-signed upload URLs.
 *
 * The FE uploads directly to GCS using a pre-signed URL — the file never
 * passes through the backend, avoiding memory/bandwidth bottlenecks.
 *
 * Security: URLs expire after 15 minutes. Users must complete the upload
 * within that window. Access is scoped to the specific file path.
 */
@Service
public class StorageService {

    private static final Logger log = LoggerFactory.getLogger(StorageService.class);
    private static final long URL_EXPIRY_SECONDS = 15 * 60; // 15 minutes

    private final Storage storage;
    private final String bucket;

    public StorageService(
            Storage storage,
            @Value("${firebase.storage-bucket:vnmap-campaign.appspot.com}") String bucket
    ) {
        this.storage = storage;
        this.bucket = bucket;
    }

    /**
     * Generates a pre-signed URL for uploading a file to Firebase Storage.
     *
     * @param folder   one of: 'campaigns', 'schools', 'events'
     * @param fileName the original file name (e.g. 'banner.jpg')
     * @param contentType the MIME type (e.g. 'image/jpeg')
     * @param userId   the ID of the uploading user (logged for audit)
     * @return UploadUrlResponse with uploadUrl (POST) and publicUrl (GET)
     */
    public UploadUrlResponse generateUploadUrl(
            String folder,
            String fileName,
            String contentType,
            Long userId
    ) {
        String sanitizedFileName = sanitizeFileName(fileName);
        String path = folder + "/" + sanitizedFileName;

        BlobId blobId = BlobId.of(bucket, path);
        BlobInfo blobInfo = BlobInfo.newBuilder(blobId)
                .setContentType(contentType)
                .setMetadata(Map.of("uploadedBy", String.valueOf(userId)))
                .build();

        try {
            URL uploadUrl = storage.signUrl(
                    blobInfo,
                    URL_EXPIRY_SECONDS,
                    TimeUnit.SECONDS,
                    Storage.SignUrlOption.httpMethod(HttpMethod.POST),
                    Storage.SignUrlOption.withContentType()
            );

            String publicUrl = String.format(
                    "https://firebasestorage.googleapis.com/v0/b/%s/o/%s?alt=media",
                    bucket,
                    path.replace("/", "%2F")
            );

            long expiresAtSeconds = (System.currentTimeMillis() / 1000) + URL_EXPIRY_SECONDS;

            log.info("Generated upload URL for path={}, userId={}", path, userId);

            return new UploadUrlResponse(
                    uploadUrl.toString(),
                    publicUrl,
                    path,
                    expiresAtSeconds
            );
        } catch (Exception e) {
            log.error("Failed to generate signed upload URL for path={}: {}", path, e.getMessage());
            throw new RuntimeException("Failed to generate upload URL", e);
        }
    }

    /** Removes path traversal characters and reserved characters from the filename. */
    private String sanitizeFileName(String fileName) {
        String name = fileName.replaceAll("[/\\\\..]", "_")
                               .replaceAll("[^a-zA-Z0-9._-]", "_");
        // Ensure unique with timestamp prefix
        return System.currentTimeMillis() + "_" + name;
    }
}
