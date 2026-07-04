package com.vnmap.report.dto;

import java.time.LocalDateTime;

public record ReportExportResponse(
        Long reportId,
        String reportType,
        String status,
        String fileName,
        String storagePath,
        String downloadUrl,
        String errorMessage,
        LocalDateTime createdAt,
        LocalDateTime completedAt
) {
}
