package com.vnmap.common.exception;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ErrorResponse {

    private LocalDateTime timestamp;
    private int status;
    private String error;
    private String message;
    private String path;
    private String traceId;
    private Map<String, List<String>> validationErrors;

    public static ErrorResponse of(int status, String error, String message, String path) {
        return ErrorResponse.builder()
                .timestamp(LocalDateTime.now(ZoneOffset.UTC))
                .status(status)
                .error(error)
                .message(message)
                .path(path)
                .build();
    }

    public static ErrorResponse withValidation(int status, String error, String message, String path,
                                               Map<String, List<String>> validationErrors) {
        return ErrorResponse.builder()
                .timestamp(LocalDateTime.now(ZoneOffset.UTC))
                .status(status)
                .error(error)
                .message(message)
                .path(path)
                .validationErrors(validationErrors)
                .build();
    }
}
