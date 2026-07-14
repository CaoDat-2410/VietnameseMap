package com.vnmap.auth.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vnmap.common.security.CurrentUser;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class JwtService {

    private static final Base64.Encoder URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder URL_DECODER = Base64.getUrlDecoder();

    private final ObjectMapper objectMapper;
    private final String secret;
    private final Duration accessTtl;

    public JwtService(
            ObjectMapper objectMapper,
            @Value("${security.jwt.secret:${JWT_SECRET:dev-secret-change-me-for-production}}") String secret,
            @Value("${security.jwt.access-token-ttl:${JWT_ACCESS_TOKEN_TTL:PT1H}}") Duration accessTtl
    ) {
        this.objectMapper = objectMapper;
        this.secret = secret;
        this.accessTtl = accessTtl;
    }

    public String createAccessToken(CurrentUser user) {
        try {
            Map<String, Object> header = Map.of("alg", "HS256", "typ", "JWT");
            Map<String, Object> claims = new LinkedHashMap<>();
            Instant now = Instant.now();
            claims.put("sub", user.id());
            claims.put("email", user.email());
            claims.put("role", user.role());
            claims.put("status", user.status());
            claims.put("employeeId", user.employeeId());
            claims.put("studentId", user.studentId());
            claims.put("iat", now.getEpochSecond());
            claims.put("exp", now.plus(accessTtl).getEpochSecond());

            String headerPart = encode(objectMapper.writeValueAsBytes(header));
            String claimsPart = encode(objectMapper.writeValueAsBytes(claims));
            String unsigned = headerPart + "." + claimsPart;
            return unsigned + "." + sign(unsigned);
        } catch (GeneralSecurityException | IOException ex) {
            throw new IllegalStateException("Unable to create access token", ex);
        }
    }

    public CurrentUser parseAccessToken(String token) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                throw new IllegalArgumentException("Invalid token");
            }
            String unsigned = parts[0] + "." + parts[1];
            if (!constantTimeEquals(sign(unsigned), parts[2])) {
                throw new IllegalArgumentException("Invalid token signature");
            }
            Map<String, Object> claims = objectMapper.readValue(
                    URL_DECODER.decode(parts[1]),
                    new TypeReference<>() {
                    }
            );
            long exp = ((Number) claims.get("exp")).longValue();
            if (Instant.now().getEpochSecond() >= exp) {
                throw new IllegalArgumentException("Token expired");
            }
            return new CurrentUser(
                    ((Number) claims.get("sub")).longValue(),
                    (String) claims.get("email"),
                    (String) claims.get("role"),
                    (String) claims.get("status"),
                    numberOrNull(claims.get("employeeId")),
                    numberOrNull(claims.get("studentId"))
            );
        } catch (GeneralSecurityException | IOException | IllegalArgumentException ex) {
            throw new IllegalArgumentException("Invalid token", ex);
        }
    }

    public long accessTokenExpiresInSeconds() {
        return accessTtl.toSeconds();
    }

    private String encode(byte[] data) {
        return URL_ENCODER.encodeToString(data);
    }

    private String sign(String value) throws GeneralSecurityException {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        return encode(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
    }

    private boolean constantTimeEquals(String a, String b) {
        return java.security.MessageDigest.isEqual(
                a.getBytes(StandardCharsets.UTF_8),
                b.getBytes(StandardCharsets.UTF_8)
        );
    }

    private Long numberOrNull(Object value) {
        return value instanceof Number number ? number.longValue() : null;
    }
}
