package com.vnmap.common.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.ConstraintViolation;

import java.util.List;
import java.util.Map;
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

    private ResponseEntity<ErrorResponse> assertResponse(ResponseEntity<ErrorResponse> response, int status, String error) {
        assertThat(response.getStatusCode().value()).isEqualTo(status);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getStatus()).isEqualTo(status);
        assertThat(response.getBody().getError()).isEqualTo(error);
        assertThat(response.getBody().getPath()).isEqualTo("/api/test");
        return response;
    }

    @Nested
    @DisplayName("ResourceNotFoundException")
    class HandleResourceNotFound {

        @Test
        @DisplayName("should return 404")
        void shouldReturn404() {
            ResourceNotFoundException ex = new ResourceNotFoundException("User", "id", "123");
            ResponseEntity<ErrorResponse> response = handler.handleResourceNotFoundException(ex, request);

            assertResponse(response, 404, "Not Found");
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
            ResponseEntity<ErrorResponse> response = handler.handleExternalApiException(ex, request);

            assertResponse(response, 502, "External Service Error");
            assertThat(response.getBody().getMessage()).contains("Unable to retrieve");
        }

        @Test
        @DisplayName("should include status code in message")
        void shouldIncludeStatusCode() {
            ExternalApiException ex = new ExternalApiException("Weather", 500, "Server error");
            ResponseEntity<ErrorResponse> response = handler.handleExternalApiException(ex, request);

            assertResponse(response, 502, "External Service Error");
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

            ResponseEntity<ErrorResponse> response = handler.handleValidationException(ex, request);

            assertResponse(response, 400, "Validation Failed");
            assertThat(response.getBody().getValidationErrors()).containsKey("email");
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
            ResponseEntity<ErrorResponse> response = handler.handleMissingParameterException(ex, request);

            assertResponse(response, 400, "Missing Parameter");
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
            ResponseEntity<ErrorResponse> response = handler.handleTypeMismatchException(ex, request);

            assertResponse(response, 400, "Type Mismatch");
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
            ResponseEntity<ErrorResponse> response = handler.handleIllegalArgumentException(ex, request);

            assertResponse(response, 400, "Bad Request");
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

            ResponseEntity<ErrorResponse> response = handler.handleConstraintViolationException(ex, request);

            assertResponse(response, 400, "Validation Failed");
        }
    }

    @Nested
    @DisplayName("Generic Exception")
    class HandleGeneric {

        @Test
        @DisplayName("should return 500")
        void shouldReturn500() {
            Exception ex = new RuntimeException("Something went wrong");
            ResponseEntity<ErrorResponse> response = handler.handleGenericException(ex, request);

            assertResponse(response, 500, "Internal Server Error");
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
