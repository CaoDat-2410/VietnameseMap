package com.vnmap.common.exception;

import com.vnmap.common.model.ApiError;
import com.vnmap.common.model.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<ApiError>> handleResourceNotFoundException(
            ResourceNotFoundException ex, HttpServletRequest request) {
        return error(HttpStatus.NOT_FOUND, "NOT_FOUND", ex.getMessage(), request, null);
    }

    @ExceptionHandler(ExternalApiException.class)
    public ResponseEntity<ApiResponse<ApiError>> handleExternalApiException(
            ExternalApiException ex, HttpServletRequest request) {
        return error(HttpStatus.BAD_GATEWAY, "EXTERNAL_SERVICE_ERROR",
                "Unable to retrieve data from external service: " + ex.getMessage(), request, ex);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<ApiError>> handleValidationException(
            MethodArgumentNotValidException ex, HttpServletRequest request) {
        Map<String, List<String>> fieldErrors = ex.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.groupingBy(
                        org.springframework.validation.FieldError::getField,
                        Collectors.mapping(
                                error -> error.getDefaultMessage() != null ? error.getDefaultMessage() : "Invalid value",
                                Collectors.toList())));
        return error(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED",
                "Request validation failed. Please check the provided data.", request, fieldErrors, null);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResponse<ApiError>> handleUnreadableMessage(
            HttpMessageNotReadableException ex, HttpServletRequest request) {
        return error(HttpStatus.BAD_REQUEST, "MALFORMED_REQUEST",
                "Request body is malformed or contains unsupported fields.", request, null);
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiResponse<ApiError>> handleMissingParameterException(
            MissingServletRequestParameterException ex, HttpServletRequest request) {
        return error(HttpStatus.BAD_REQUEST, "MISSING_PARAMETER",
                "Required parameter '" + ex.getParameterName() + "' is missing", request, null);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiResponse<ApiError>> handleTypeMismatchException(
            MethodArgumentTypeMismatchException ex, HttpServletRequest request) {
        Class<?> requiredType = ex.getRequiredType();
        String typeName = requiredType == null ? "unknown" : requiredType.getSimpleName();
        String message = String.format("Parameter '%s' should be of type '%s'", ex.getName(), typeName);
        return error(HttpStatus.BAD_REQUEST, "TYPE_MISMATCH", message, request, null);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<ApiError>> handleIllegalArgumentException(
            IllegalArgumentException ex, HttpServletRequest request) {
        return error(HttpStatus.BAD_REQUEST, "BAD_REQUEST", ex.getMessage(), request, null);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResponse<ApiError>> handleConstraintViolationException(
            ConstraintViolationException ex, HttpServletRequest request) {
        return error(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", ex.getMessage(), request, null);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<ApiError>> handleDataIntegrityViolation(
            DataIntegrityViolationException ex, HttpServletRequest request) {
        return error(HttpStatus.CONFLICT, "DATA_CONFLICT",
                "The attendance operation conflicts with the current data state. Refresh and try again.",
                request, ex);
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ApiResponse<ApiError>> handleResponseStatusException(
            ResponseStatusException ex, HttpServletRequest request) {
        HttpStatus status = HttpStatus.valueOf(ex.getStatusCode().value());
        return error(status, status.name(), ex.getReason() == null ? status.getReasonPhrase() : ex.getReason(), request, null);
    }

    @ExceptionHandler(org.springframework.web.servlet.resource.NoResourceFoundException.class)
    public ResponseEntity<ApiResponse<ApiError>> handleNoResourceFound(
            org.springframework.web.servlet.resource.NoResourceFoundException ex, HttpServletRequest request) {
        return error(HttpStatus.NOT_FOUND, "NOT_FOUND", "No resource found at " + request.getRequestURI(), request, null);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<ApiError>> handleGenericException(Exception ex, HttpServletRequest request) {
        return error(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                "An unexpected error occurred. Please try again later.", request, ex);
    }

    private ResponseEntity<ApiResponse<ApiError>> error(
            HttpStatus status, String code, String message, HttpServletRequest request, Throwable cause) {
        return error(status, code, message, request, null, cause);
    }

    private ResponseEntity<ApiResponse<ApiError>> error(
            HttpStatus status, String code, String message, HttpServletRequest request,
            Map<String, List<String>> fieldErrors, Throwable cause) {
        String traceId = generateTraceId();
        if (status.is5xxServerError() || cause instanceof ExternalApiException) {
            log.error("API error [traceId={}, code={}]: {}", traceId, code, message, cause);
        } else {
            log.warn("API error [traceId={}, code={}]: {}", traceId, code, message);
        }
        ApiError details = new ApiError(status.value(), code, request.getRequestURI(), traceId, fieldErrors);
        return ResponseEntity.status(status).body(ApiResponse.error(message, details, traceId));
    }

    private String generateTraceId() {
        return UUID.randomUUID().toString().substring(0, 8);
    }
}