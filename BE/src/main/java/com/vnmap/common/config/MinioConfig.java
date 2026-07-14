package com.vnmap.common.config;

import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MinioConfig {

    /**
     * Shared HTTP client used for backend PUT/DELETE requests to MinIO via
     * presigned URLs. See {@link com.vnmap.common.util.SigV4Presigner} for
     * the URL signing implementation.
     */
    @Bean(destroyMethod = "close")
    public CloseableHttpClient minioHttpClient() {
        return HttpClients.createDefault();
    }
}