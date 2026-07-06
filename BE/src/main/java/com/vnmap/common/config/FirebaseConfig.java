package com.vnmap.common.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.storage.Storage;
import com.google.cloud.storage.StorageOptions;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.messaging.FirebaseMessaging;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.util.StringUtils;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

@Configuration
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @Value("${firebase.service-account-json:}")
    private String serviceAccountJson;

    @Value("${firebase.service-account-file:}")
    private String serviceAccountFile;

    @Value("${firebase.storage-bucket:vnmap-campaign.appspot.com}")
    private String storageBucket;

    @Bean
    public GoogleCredentials firebaseCredentials() throws IOException {
        try (InputStream serviceAccount = resolveServiceAccount()) {
            return GoogleCredentials.fromStream(serviceAccount);
        }
    }

    @Bean
    public FirebaseApp firebaseApp(GoogleCredentials firebaseCredentials) {
        if (FirebaseApp.getApps().isEmpty()) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(firebaseCredentials)
                    .setStorageBucket(storageBucket)
                    .build();
            FirebaseApp app = FirebaseApp.initializeApp(options);
            log.info("Firebase initialized with storage bucket: {}", storageBucket);
            return app;
        }
        return FirebaseApp.getInstance();
    }

    @Bean
    public FirebaseMessaging firebaseMessaging(FirebaseApp firebaseApp) {
        return FirebaseMessaging.getInstance(firebaseApp);
    }

    @Bean
    public FirebaseAuth firebaseAuth(FirebaseApp firebaseApp) {
        return FirebaseAuth.getInstance(firebaseApp);
    }

    @Bean
    public Storage firebaseStorage(FirebaseApp firebaseApp, GoogleCredentials firebaseCredentials) {
        return StorageOptions.newBuilder()
                .setCredentials(firebaseCredentials)
                .setProjectId(firebaseApp.getOptions().getProjectId())
                .build()
                .getService();
    }

    private InputStream resolveServiceAccount() throws IOException {
        if (StringUtils.hasText(serviceAccountJson)) {
            log.info("Loading Firebase service account from FIREBASE_SERVICE_ACCOUNT_JSON env var");
            return new ByteArrayInputStream(serviceAccountJson.getBytes(StandardCharsets.UTF_8));
        }
        if (StringUtils.hasText(serviceAccountFile)) {
            log.info("Loading Firebase service account from file: {}", serviceAccountFile);
            // Absolute filesystem paths (e.g. /run/secrets/*.json in Docker) take precedence
            // over classpath resources — spring's ClassPathResource tries to resolve relative
            // to the classpath, which fails for absolute paths.
            if (serviceAccountFile.startsWith("/") || serviceAccountFile.contains(":")) {
                java.io.File f = new java.io.File(serviceAccountFile);
                if (!f.isFile()) {
                    throw new java.io.FileNotFoundException("Firebase service account file not found at " + serviceAccountFile);
                }
                return new java.io.FileInputStream(f);
            }
            return new ClassPathResource(serviceAccountFile).getInputStream();
        }
        log.warn("Firebase service account not configured. "
            + "Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_FILE env var.");
        throw new IOException(
            "Firebase service account not configured. "
            + "Set FIREBASE_SERVICE_ACCOUNT_JSON env var with the full JSON string, "
            + "or FIREBASE_SERVICE_ACCOUNT_FILE env var with the file path.");
    }
}
