package com.vnmap.common.util;

import org.junit.jupiter.api.Test;



import static org.assertj.core.api.Assertions.assertThat;

class SigV4PresignerTest {
    @Test
    void presignIncludesEncodedCredentialsAndEndpointPort() {
        String url = SigV4Presigner.presignPut("http://localhost:9002/", "bucket", "folder/a file.pdf", new SigV4Presigner.Credentials("access key", "secret", "us-east-1"), 60);
        assertThat(url).startsWith("http://localhost:9002/bucket/folder/a file.pdf?");
        assertThat(url).contains("X-Amz-Algorithm=AWS4-HMAC-SHA256", "X-Amz-Credential=access%20key%2F", "X-Amz-Signature=");
    }

    @Test
    void presignGetUsesGetAndHandlesEndpointsWithoutExplicitPort() {
        String get = SigV4Presigner.presignGet("https://storage.example.test", "photos", "avatar.png", new SigV4Presigner.Credentials("key", "secret", "ap-southeast-1"), 120);
        String put = SigV4Presigner.presign("https://storage.example.test", "photos", "avatar.png", "PUT", new SigV4Presigner.Credentials("key", "secret", "ap-southeast-1"), 120);
        assertThat(get).startsWith("https://storage.example.test/photos/avatar.png?");
        assertThat(get).contains("X-Amz-Expires=120", "X-Amz-SignedHeaders=host");
        assertThat(get).isNotEqualTo(put);
    }
}