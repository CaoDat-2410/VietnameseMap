package com.vnmap.common.exception;

public class ExternalApiException extends RuntimeException {

    private final String apiName;
    private final int statusCode;

    public ExternalApiException(String message) {
        super(message);
        this.apiName = "Unknown";
        this.statusCode = 0;
    }

    public ExternalApiException(String apiName, String message) {
        super(message);
        this.apiName = apiName;
        this.statusCode = 0;
    }

    public ExternalApiException(String apiName, int statusCode, String message) {
        super(message);
        this.apiName = apiName;
        this.statusCode = statusCode;
    }

    public ExternalApiException(String apiName, String message, Throwable cause) {
        super(message, cause);
        this.apiName = apiName;
        this.statusCode = 0;
    }

    public String getApiName() {
        return apiName;
    }

    public int getStatusCode() {
        return statusCode;
    }
}
