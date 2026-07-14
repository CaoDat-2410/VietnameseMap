package com.vnmap.notification.dto;

import java.time.LocalDateTime;
import java.util.Map;

public record NotificationAuditDto(
        Long id,
        Long targetUserId,
        String triggerType,
        String title,
        String body,
        Map<String, String> data,
        String status,
        LocalDateTime readAt,
        LocalDateTime createdAt
) {}
