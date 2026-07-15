package com.vnmap.common.util;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.HexFormat;
import java.util.Map;
import java.util.TreeMap;

public final class SigV4Presigner {

    private static final String ALGORITHM = "AWS4-HMAC-SHA256";
    private static final String SERVICE = "s3";
    private static final DateTimeFormatter DATE_STAMP =
            DateTimeFormatter.ofPattern("yyyyMMdd").withZone(ZoneOffset.UTC);
    private static final DateTimeFormatter TIME_STAMP =
            DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'").withZone(ZoneOffset.UTC);

    private SigV4Presigner() {}

    public record Credentials(String accessKey, String secretKey, String region) {}


    public static String presignPut(String endpoint, String bucket, String key,
                                    Credentials credentials, int expirySeconds) {
        return presign(endpoint, bucket, key, "PUT", credentials, expirySeconds);
    }

    public static String presignGet(String endpoint, String bucket, String key,
                                    Credentials credentials, int expirySeconds) {
        return presign(endpoint, bucket, key, "GET", credentials, expirySeconds);
    }

    public static String presign(String endpoint, String bucket, String key, String method,
                                 Credentials credentials, int expirySeconds) {
        URI uri = URI.create(endpoint);
        String host = uri.getHost();
        if (host == null || host.isBlank()) {
            host = parseHost(endpoint);
        }
        int port = uri.getPort();
        if (port <= 0) {
            port = parsePort(endpoint);
        }
        String scheme = uri.getScheme();
        if (scheme == null) scheme = "http";

        Instant now = Instant.now();
        String dateStamp = DATE_STAMP.format(now);
        String timeStamp = TIME_STAMP.format(now);
        String credentialScope = dateStamp + "/" + credentials.region() + "/" + SERVICE + "/aws4_request";

        Map<String, String> params = new TreeMap<>();
        params.put("X-Amz-Algorithm", ALGORITHM);
        params.put("X-Amz-Credential", credentials.accessKey() + "/" + credentialScope);
        params.put("X-Amz-Date", timeStamp);
        params.put("X-Amz-Expires", String.valueOf(expirySeconds));
        params.put("X-Amz-SignedHeaders", "host");

        String canonicalUri = "/" + bucket + "/" + key;
        String canonicalQuery = buildCanonicalQuery(params);
        String hostHeader = port > 0 ? host + ":" + port : host;
        String canonicalHeaders = "host:" + hostHeader + "\n";
        String signedHeaders = "host";
        String payloadHash = "UNSIGNED-PAYLOAD";

        String canonicalRequest = method + "\n"
                + canonicalUri + "\n"
                + canonicalQuery + "\n"
                + canonicalHeaders + "\n"
                + signedHeaders + "\n"
                + payloadHash;

        String stringToSign = ALGORITHM + "\n"
                + timeStamp + "\n"
                + credentialScope + "\n"
                + sha256Hex(canonicalRequest);

        byte[] kDate = hmacSha256(("AWS4" + credentials.secretKey()).getBytes(StandardCharsets.UTF_8), dateStamp);
        byte[] kRegion = hmacSha256(kDate, credentials.region());
        byte[] kService = hmacSha256(kRegion, SERVICE);
        byte[] kSigning = hmacSha256(kService, "aws4_request");

        String signature = hexEncode(hmacSha256(kSigning, stringToSign));

        StringBuilder url = new StringBuilder();
        url.append(scheme).append("://").append(host);
        if (port > 0) {
            url.append(":").append(port);
        }
        url.append(canonicalUri).append("?").append(canonicalQuery)
                .append("&X-Amz-Signature=").append(signature);
        return url.toString();
    }

    private static String buildCanonicalQuery(Map<String, String> params) {
        StringBuilder sb = new StringBuilder();
        boolean first = true;
        for (Map.Entry<String, String> e : params.entrySet()) {
            if (!first) sb.append("&");
            sb.append(urlEncode(e.getKey())).append("=").append(urlEncode(e.getValue()));
            first = false;
        }
        return sb.toString();
    }

    private static String urlEncode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8)
                .replace("+", "%20")
                .replace("*", "%2A")
                .replace("%7E", "~");
    }

    private static byte[] hmacSha256(byte[] key, String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(key, "HmacSHA256"));
            return mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new RuntimeException("HMAC-SHA256 failed", e);
        }
    }

    private static String sha256Hex(String data) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(data.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (Exception e) {
            throw new RuntimeException("SHA-256 failed", e);
        }
    }

    private static String hexEncode(byte[] bytes) {
        return HexFormat.of().formatHex(bytes);
    }

    private static String parseHost(String url) {
        String stripped = url.replaceFirst("^https?://", "");
        int slash = stripped.indexOf('/');
        if (slash >= 0) stripped = stripped.substring(0, slash);
        int colon = stripped.lastIndexOf(':');
        if (colon < 0) return stripped;
        return stripped.substring(0, colon);
    }

    private static int parsePort(String url) {
        String stripped = url.replaceFirst("^https?://", "");
        int slash = stripped.indexOf('/');
        if (slash >= 0) stripped = stripped.substring(0, slash);
        int colon = stripped.lastIndexOf(':');
        if (colon < 0 || colon + 1 >= stripped.length()) return -1;
        try {
            return Integer.parseInt(stripped.substring(colon + 1));
        } catch (NumberFormatException e) {
            return -1;
        }
    }
}