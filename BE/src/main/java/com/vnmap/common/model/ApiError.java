package com.vnmap.common.model;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;
import java.util.Map;

/**
 * Machine-readable details attached to every failed API response.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiError(
        int status,
        String code,
        String path,
        String traceId,
        Map<String, List<String>> fieldErrors
) {
}