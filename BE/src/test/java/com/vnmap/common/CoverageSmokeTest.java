package com.vnmap.common;

import com.vnmap.auth.controller.GoogleAuthController;
import com.vnmap.auth.dto.GoogleAuthRequest;
import com.vnmap.auth.service.GoogleAuthService;
import com.vnmap.campaign.controller.AnalyticsController;
import com.vnmap.campaign.service.AnalyticsService;
import com.vnmap.common.exception.ErrorResponse;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CoverageSmokeTest {

    @Test
    void delegatesEveryAnalyticsControllerEndpoint() {
        AnalyticsService service = mock(AnalyticsService.class);
        when(service.getInteractionsTrend(14, 2L, "school")).thenReturn(List.of());
        when(service.getChannelBreakdown(2L, "school")).thenReturn(List.of());
        when(service.getTopEmployees(5, 2L, "school")).thenReturn(List.of());
        AnalyticsController controller = new AnalyticsController(service);

        assertThat(controller.getAggregateDashboard(2L, "school").getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(controller.getTrend(14, 2L, "school").getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(controller.getChannels(2L, "school").getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(controller.getTopEmployees(5, 2L, "school").getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(service).getAggregateDashboard(2L, "school");
        verify(service).getInteractionsTrend(14, 2L, "school");
        verify(service).getChannelBreakdown(2L, "school");
        verify(service).getTopEmployees(5, 2L, "school");
    }

    @Test
    void delegatesGoogleControllerAndBuildsBothErrorResponses() {
        GoogleAuthService service = mock(GoogleAuthService.class);
        GoogleAuthController controller = new GoogleAuthController(service);
        GoogleAuthRequest request = new GoogleAuthRequest("token");
        assertThat(controller.googleAuth(request).getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(service).authenticateWithGoogle("token");

        ErrorResponse simple = ErrorResponse.of(400, "Bad Request", "invalid", "/api/test");
        assertThat(simple.getStatus()).isEqualTo(400);
        assertThat(simple.getTimestamp()).isNotNull();
        assertThat(simple.getValidationErrors()).isNull();

        Map<String, List<String>> validation = Map.of("name", List.of("required"));
        ErrorResponse detailed = ErrorResponse.withValidation(422, "Validation", "invalid", "/api/test", validation);
        assertThat(detailed.getValidationErrors()).containsEntry("name", List.of("required"));
        assertThat(detailed.getTimestamp()).isNotNull();
    }
}