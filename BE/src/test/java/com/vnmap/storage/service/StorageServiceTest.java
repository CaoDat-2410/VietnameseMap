package com.vnmap.storage.service;

import com.vnmap.common.security.CurrentUser;
import com.vnmap.storage.dto.UploadUrlResponse;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.StatusLine;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.impl.client.CloseableHttpClient;
import org.junit.jupiter.api.Test;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class StorageServiceTest {
    private final CloseableHttpClient http = mock(CloseableHttpClient.class);
    private final StorageService service = new StorageService(http, "http://localhost:9002/", "http://minio:9000/", "key", "secret", "us-east-1", "assets", "reports");
    private final CurrentUser user = new CurrentUser(7L, "student@example.test", "STUDENT", "ACTIVE", null, 3L);

    @Test
    void generatesAvatarUploadUrlWithSafePath() {
        UploadUrlResponse result = service.generateUploadUrl("avatars", "../a profile.png", "image/png", user);
        assertThat(result.storagePath()).startsWith("avatars/7/").contains("_.._a_profile.png");
        assertThat(result.publicUrl()).startsWith("http://localhost:9002/assets/avatars/7/");
        assertThat(result.uploadUrl()).contains("X-Amz-Signature=");
        assertThat(result.expiresAtSeconds()).isGreaterThan(System.currentTimeMillis() / 1000);
    }

    @Test
    void rejectsInvalidUploadInputs() {
        assertThatIllegalArgumentException().isThrownBy(() -> service.generateUploadUrl("avatars", "x.png", "image/png", null));
        assertThatIllegalArgumentException().isThrownBy(() -> service.generateUploadUrl("reports", "x.png", "image/png", user));
        assertThatIllegalArgumentException().isThrownBy(() -> service.generateUploadUrl("avatars", "x.pdf", "application/pdf", user));
    }

    @Test
    void generatesDownloadUrlAndHandlesBlankPath() {
        assertThat(service.generateDownloadUrl("reports/a.pdf", Duration.ofSeconds(30)))
                .startsWith("http://localhost:9002/reports/reports/a.pdf?");
        assertThat(service.generateDownloadUrl("", Duration.ofSeconds(30))).isNull();
    }

    @Test
    void uploadsGeneratedObjectAndFailsForNonSuccessResponse() throws Exception {
        CloseableHttpResponse response = mock(CloseableHttpResponse.class);
        StatusLine status = mock(StatusLine.class);
        when(response.getStatusLine()).thenReturn(status);
        when(status.getStatusCode()).thenReturn(200);
        when(http.execute(any(HttpUriRequest.class))).thenReturn(response);
        service.uploadGeneratedObject("reports/a.pdf", new byte[]{1, 2}, "application/pdf");
        verify(http).execute(argThat(request -> request.getURI().toString().contains("http://minio:9000/reports/reports/a.pdf")));

        when(status.getStatusCode()).thenReturn(500);
        assertThatThrownBy(() -> service.uploadGeneratedObject("reports/a.pdf", new byte[]{1}, null))
                .isInstanceOf(RuntimeException.class).hasMessageContaining("Failed to upload object");
    }

    @Test
    void deleteIsBestEffortAndUsesReportsBucket() throws Exception {
        CloseableHttpResponse response = mock(CloseableHttpResponse.class);
        StatusLine status = mock(StatusLine.class);
        when(response.getStatusLine()).thenReturn(status);
        when(status.getStatusCode()).thenReturn(204);
        when(http.execute(any(HttpUriRequest.class))).thenReturn(response);
        service.deleteObject("reports/old.pdf");
        service.deleteObject(" ");
        verify(http, times(1)).execute(argThat(request -> request.getURI().toString().equals("http://minio:9000/reports/reports/old.pdf")));
    }
}