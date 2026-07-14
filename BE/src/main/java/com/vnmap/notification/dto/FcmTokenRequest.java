package com.vnmap.notification.dto;

/**
 * Request to register or update a user's FCM push notification token.
 */
public record FcmTokenRequest(
        String token,
        /** 'WEB', 'ANDROID', or 'IOS' */
        String platform
) {}
