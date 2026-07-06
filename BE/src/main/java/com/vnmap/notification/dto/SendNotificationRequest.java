package com.vnmap.notification.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Request to send a push notification via Firebase Cloud Messaging.
 * Admin-only — only STAFF, MANAGER, or ADMIN can send notifications.
 */
public record SendNotificationRequest(
        Long targetUserId,
        @NotBlank String title,
        @NotBlank String body,
        /** Arbitrary key-value data payload (e.g. { "type": "event_reminder", "eventId": 5 }) */
        java.util.Map<String, String> data
) {}
