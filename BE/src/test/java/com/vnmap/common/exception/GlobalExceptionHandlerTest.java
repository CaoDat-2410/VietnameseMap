package com.vnmap.common.exception;

import com.vnmap.common.model.ApiError;
import com.vnmap.common.model.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.ConstraintViolation;

import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@DisplayName("GlobalExceptionHandler Tests")
class GlobalExceptionHandlerTest {

    private GlobalExceptionHandler handler;
    private HttpServletRequest request;

    @BeforeEach
    void setUp() {
        handler = new GlobalExceptionHandler();
        request = mock(HttpServletRequest.class);
        when(request.getRequestURI()).thenReturn("/api/test");
    }

    private ResponseEntity<ApiResponse<ApiError>> assertResponse(ResponseEntity<ApiResponse<ApiError>> response, int status, String error) {
        assertThat(response.getStatusCode().value()).isEqualTo(status);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isFalse();
        assertThat(response.getBody().getTraceId()).isEqualTo(response.getBody().getData().traceId());
        assertThat(response.getBody().getData().status()).isEqualTo(status);
        assertThat(response.getBody().getData().code()).isEqualTo(error);
        assertThat(response.getBody().getData().path()).isEqualTo("/api/test");
        return response;
    }

    @Nested
    @DisplayName("ResourceNotFoundException")
    class HandleResourceNotFound {

        @Test
        @DisplayName("should return 404")
        void shouldReturn404() {
            ResourceNotFoundException ex = new ResourceNotFoundException("User", "id", "123");
            ResponseEntity<ApiResponse<ApiError>> response = handler.handleResourceNotFoundException(ex, request);

            assertResponse(response, 404, "NOT_FOUND");
            assertThat(response.getBody().getMessage()).isEqualTo("User not found with id: '123'");
        }
    }

    @Nested
    @DisplayName("ExternalApiException")
    class HandleExternalApi {

        @Test
        @DisplayName("should return 502")
        void shouldReturn502() {
            ExternalApiException ex = new ExternalApiException("Weather", "API timeout");
            ResponseEntity<ApiResponse<ApiError>> response = handler.handleExternalApiException(ex, request);

            assertResponse(response, 502, "EXTERNAL_SERVICE_ERROR");
            assertThat(response.getBody().getMessage()).contains("Unable to retrieve");
        }

        @Test
        @DisplayName("should include status code in message")
        void shouldIncludeStatusCode() {
            ExternalApiException ex = new ExternalApiException("Weather", 500, "Server error");
            ResponseEntity<ApiResponse<ApiError>> response = handler.handleExternalApiException(ex, request);

            assertResponse(response, 502, "EXTERNAL_SERVICE_ERROR");
            assertThat(response.getBody().getMessage()).contains("Server error");
        }
    }

    @Nested
    @DisplayName("MethodArgumentNotValidException")
    class HandleValidation {

        @Test
        @DisplayName("should return 400 with field errors")
        void shouldReturn400WithFieldErrors() {
            MethodArgumentNotValidException ex = mock(MethodArgumentNotValidException.class);
            var bindingResult = mock(org.springframework.validation.BindingResult.class);
            var fieldError = new org.springframework.validation.FieldError("user", "email", null, false, null, null, "must not be blank");

            when(ex.getBindingResult()).thenReturn(bindingResult);
            when(bindingResult.getFieldErrors()).thenReturn(List.of(fieldError));

            ResponseEntity<ApiResponse<ApiError>> response = handler.handleValidationException(ex, request);

            assertResponse(response, 400, "VALIDATION_FAILED");
            assertThat(response.getBody().getData().fieldErrors()).containsKey("email");
        }
    }

    @Nested
    @DisplayName("HttpMessageNotReadableException")
    class HandleUnreadableMessage {

        @Test
        @DisplayName("should return 400 for malformed or unsupported JSON")
        void shouldReturn400() {
            HttpMessageNotReadableException ex = new HttpMessageNotReadableException("Unknown field");

            ResponseEntity<ApiResponse<ApiError>> response = handler.handleUnreadableMessage(ex, request);

            assertResponse(response, 400, "MALFORMED_REQUEST");
        }
    }

    @Nested
    @DisplayName("MissingServletRequestParameterException")
    class HandleMissingParam {

        @Test
        @DisplayName("should return 400")
        void shouldReturn400() {
            MissingServletRequestParameterException ex =
                    new MissingServletRequestParameterException("lat", "Double");
            ResponseEntity<ApiResponse<ApiError>> response = handler.handleMissingParameterException(ex, request);

            assertResponse(response, 400, "MISSING_PARAMETER");
            assertThat(response.getBody().getMessage()).contains("'lat'");
        }
    }

    @Nested
    @DisplayName("MethodArgumentTypeMismatchException")
    class HandleTypeMismatch {

        @Test
        @DisplayName("should return 400")
        void shouldReturn400() {
            MethodArgumentTypeMismatchException ex =
                    new MethodArgumentTypeMismatchException("abc", String.class, "name", null, null);
            ResponseEntity<ApiResponse<ApiError>> response = handler.handleTypeMismatchException(ex, request);

            assertResponse(response, 400, "TYPE_MISMATCH");
            assertThat(response.getBody().getMessage()).contains("'name'").contains("String");
        }
    }

    @Nested
    @DisplayName("IllegalArgumentException")
    class HandleIllegalArgument {

        @Test
        @DisplayName("should return 400")
        void shouldReturn400() {
            IllegalArgumentException ex = new IllegalArgumentException("Invalid province code");
            ResponseEntity<ApiResponse<ApiError>> response = handler.handleIllegalArgumentException(ex, request);

            assertResponse(response, 400, "BAD_REQUEST");
            assertThat(response.getBody().getMessage()).isEqualTo("Invalid province code");
        }
    }

    @Nested
    @DisplayName("ConstraintViolationException")
    class HandleConstraintViolation {

        @Test
        @DisplayName("should return 400")
        void shouldReturn400() {
            ConstraintViolationException ex = mock(ConstraintViolationException.class);
            ConstraintViolation<?> violation = mock(ConstraintViolation.class);
            when(violation.getMessage()).thenReturn("must not be blank");
            when(violation.getPropertyPath()).thenReturn(mock(jakarta.validation.Path.class));
            when(ex.getConstraintViolations()).thenReturn(Set.of(violation));

            ResponseEntity<ApiResponse<ApiError>> response = handler.handleConstraintViolationException(ex, request);

            assertResponse(response, 400, "VALIDATION_FAILED");
        }
    }

    @Nested
    @DisplayName("Generic Exception")
    class HandleGeneric {

        @Test
        @DisplayName("should return 500")
        void shouldReturn500() {
            Exception ex = new RuntimeException("Something went wrong");
            ResponseEntity<ApiResponse<ApiError>> response = handler.handleGenericException(ex, request);

            assertResponse(response, 500, "INTERNAL_ERROR");
            assertThat(response.getBody().getMessage()).contains("unexpected error");
        }
    }

    @Nested
    @DisplayName("generateTraceId")
    class GenerateTraceId {

        @Test
        @DisplayName("should return 8-character UUID")
        void shouldReturn8Chars() throws Exception {
            var method = GlobalExceptionHandler.class.getDeclaredMethod("generateTraceId");
            method.setAccessible(true);

            String traceId = (String) method.invoke(handler);

            assertThat(traceId).hasSize(8);
        }

        @Test
        @DisplayName("should return unique IDs")
        void shouldReturnUniqueIds() throws Exception {
            var method = GlobalExceptionHandler.class.getDeclaredMethod("generateTraceId");
            method.setAccessible(true);

            String id1 = (String) method.invoke(handler);
            String id2 = (String) method.invoke(handler);

            assertThat(id1).isNotEqualTo(id2);
        }
    }
}
