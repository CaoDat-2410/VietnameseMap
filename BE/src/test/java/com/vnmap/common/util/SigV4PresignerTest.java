package com.vnmap.common.util;

import org.junit.jupiter.api.Test;



import static org.assertj.core.api.Assertions.assertThat;

class SigV4PresignerTest {
    @Test
    void presignIncludesEncodedCredentialsAndEndpointPort() {
        String url = SigV4Presigner.presignPut("http://localhost:9002/", "bucket", "folder/a file.pdf", new SigV4Presigner.Credentials("access key", "secret", "us-east-1"), 60);
        assertThat(url)
                .startsWith("http://localhost:9002/bucket/folder/a file.pdf?")
                .contains("X-Amz-Algorithm=AWS4-HMAC-SHA256", "X-Amz-Credential=access%20key%2F", "X-Amz-Signature=");
    }

    @Test
    void presignGetUsesGetAndHandlesEndpointsWithoutExplicitPort() {
        String get = SigV4Presigner.presignGet("https://storage.example.test", "photos", "avatar.png", new SigV4Presigner.Credentials("key", "secret", "ap-southeast-1"), 120);
        String put = SigV4Presigner.presign("https://storage.example.test", "photos", "avatar.png", "PUT", new SigV4Presigner.Credentials("key", "secret", "ap-southeast-1"), 120);
        assertThat(get)
                .startsWith("https://storage.example.test/photos/avatar.png?")
                .contains("X-Amz-Expires=120", "X-Amz-SignedHeaders=host")
                .isNotEqualTo(put);
    }

    @Test
    void coversFallbackEndpointParsingAndEncodingBranches() throws Exception {
        String fallback = SigV4Presigner.presignGet(
                "storage.example.test/path", "bucket", "a*b~c",
                new SigV4Presigner.Credentials("key", "secret", "us-east-1"), 30
        );
        assertThat(fallback)
                .startsWith("http://storage.example.test/bucket/a*b~c?")
                .contains("X-Amz-Signature=");

        java.lang.reflect.Method parseHost = SigV4Presigner.class.getDeclaredMethod("parseHost", String.class);
        parseHost.setAccessible(true);
        assertThat(parseHost.invoke(null, "https://host.test:9000/path")).isEqualTo("host.test");
        assertThat(parseHost.invoke(null, "http://host.test/path")).isEqualTo("host.test");

        java.lang.reflect.Method parsePort = SigV4Presigner.class.getDeclaredMethod("parsePort", String.class);
        parsePort.setAccessible(true);
        assertThat(parsePort.invoke(null, "http://host.test:9000/path")).isEqualTo(9000);
        assertThat(parsePort.invoke(null, "http://host.test/path")).isEqualTo(-1);
        assertThat(parsePort.invoke(null, "http://host.test:/path")).isEqualTo(-1);
        assertThat(parsePort.invoke(null, "http://host.test:bad/path")).isEqualTo(-1);
    }
}