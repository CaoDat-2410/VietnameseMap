package com.vnmap.notification.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.vnmap.notification.dto.SendNotificationRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

/**
 * Service for Firebase Cloud Messaging (FCM) push notifications.
 *
 * Token management:
 *  - Tokens are stored in fcm_tokens(user_id, token, platform)
 *  - When a token is re-registered, old entries for that token are replaced
 *
 * Sending:
 *  - Single user: look up token by user_id
 *  - Broadcast: look up all ACTIVE tokens
 */
@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final JdbcTemplate jdbc;
    private final FirebaseMessaging fcm;

    public NotificationService(JdbcTemplate jdbc, FirebaseMessaging fcm) {
        this.jdbc = jdbc;
        this.fcm = fcm;
    }

    /**
     * Saves or updates an FCM token for a user.
     * Replaces any existing entry with the same token (token rotation).
     */
    public void saveToken(Long userId, String token, String platform) {
        jdbc.update("""
            INSERT INTO fcm_tokens (user_id, token, platform, updated_at)
            VALUES (?, ?, ?, NOW())
            ON CONFLICT (token)
            DO UPDATE SET user_id = EXCLUDED.user_id,
                          platform = EXCLUDED.platform,
                          updated_at = NOW()
            """, userId, token, platform);
        log.info("Saved FCM token for userId={}, platform={}", userId, platform);
    }

    /**
     * Removes a token (e.g. when user logs out).
     */
    public void deleteToken(String token) {
        jdbc.update("DELETE FROM fcm_tokens WHERE token = ?", token);
        log.info("Deleted FCM token");
    }

    /**
     * Sends a push notification to a single user.
     * Returns the FCM message ID, or null if the user has no registered token.
     */
    public String sendToUser(Long userId, SendNotificationRequest request) {
        List<String> tokens = jdbc.queryForList(
                "SELECT token FROM fcm_tokens WHERE user_id = ?",
                String.class, userId);

        if (tokens.isEmpty()) {
            log.warn("No FCM token found for userId={}", userId);
            return null;
        }

        return sendToTokens(tokens, request.title(), request.body(), request.data());
    }

    /**
     * Sends a push notification to all users with registered tokens.
     */
    public String sendBroadcast(SendNotificationRequest request) {
        List<String> tokens = jdbc.queryForList(
                "SELECT token FROM fcm_tokens",
                String.class);

        if (tokens.isEmpty()) {
            log.warn("No FCM tokens registered for broadcast");
            return null;
        }

        return sendToTokens(tokens, request.title(), request.body(), request.data());
    }

    private String sendToTokens(List<String> tokens, String title, String body, Map<String, String> data) {
        try {
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            Message.Builder messageBuilder = Message.builder()
                    .setNotification(notification);

            if (data != null && !data.isEmpty()) {
                messageBuilder.putAllData(data);
            }

            if (tokens.size() == 1) {
                messageBuilder.setToken(tokens.get(0));
                String response = fcm.send(messageBuilder.build());
                log.info("FCM send success to 1 token: {}", response);
                return response;
            } else {
                // Batch send
                com.google.firebase.messaging.MulticastMessage multicast = com.google.firebase.messaging.MulticastMessage.builder()
                        .addAllTokens(tokens)
                        .setNotification(notification)
                        .putAllData(data != null ? data : Map.of())
                        .build();
                var response = fcm.sendEachForMulticast(multicast);
                log.info("FCM multicast sent: successCount={}, failureCount={}",
                        response.getSuccessCount(), response.getFailureCount());
                return "multicast:" + response.getSuccessCount() + "/" + tokens.size();
            }
        } catch (Exception e) {
            log.error("FCM send failed: {}", e.getMessage());
            throw new RuntimeException("FCM send failed", e);
        }
    }
}
