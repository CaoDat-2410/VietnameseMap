package com.vnmap.notification.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.vnmap.notification.dto.NotificationAuditDto;
import com.vnmap.notification.dto.SendNotificationRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
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
 *
 * Audit:
 *  - Every notification (single user OR broadcast) is mirrored into
 *    notification_audit so the in-app bell can list, count unread,
 *    and mark-read via REST.
 */
@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final JdbcTemplate jdbc;
    private final FirebaseMessaging fcm;
    private final ObjectMapper objectMapper;

    public NotificationService(JdbcTemplate jdbc, FirebaseMessaging fcm, ObjectMapper objectMapper) {
        this.jdbc = jdbc;
        this.fcm = fcm;
        this.objectMapper = objectMapper;
    }

    private static final RowMapper<NotificationAuditDto> AUDIT_ROW_MAPPER = (rs, rowNum) -> {
        Timestamp readAt = rs.getTimestamp("read_at");
        Timestamp createdAt = rs.getTimestamp("created_at");
        Map<String, String> data = Map.of();
        String raw = rs.getString("data_json");
        if (raw != null && !raw.isBlank()) {
            try {
                data = new ObjectMapper().readValue(raw, new TypeReference<Map<String, String>>() {});
            } catch (Exception ignored) {
                // ignore malformed data_json, fall back to empty map
            }
        }
        return new NotificationAuditDto(
                rs.getLong("id"),
                (Long) rs.getObject("target_user_id"),
                rs.getString("trigger_type"),
                rs.getString("title"),
                rs.getString("body"),
                data,
                rs.getString("status"),
                readAt == null ? null : readAt.toLocalDateTime(),
                createdAt == null ? null : createdAt.toLocalDateTime()
        );
    };

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
     * Records an audit row regardless of FCM token availability.
     * Returns the FCM message ID, or null if the user has no registered token.
     */
    public String sendToUser(Long userId, SendNotificationRequest request) {
        return sendToUser(userId, request.title(), request.body(), request.data(), null);
    }

    /**
     * Sends a push notification to a single user with explicit trigger type.
     */
    public String sendToUser(Long userId, String title, String body, Map<String, String> data, String triggerType) {
        List<String> tokens = jdbc.queryForList(
                "SELECT token FROM fcm_tokens WHERE user_id = ?",
                String.class, userId);

        String fcmResult;
        if (tokens.isEmpty()) {
            log.warn("No FCM token found for userId={}", userId);
            fcmResult = null;
        } else {
            fcmResult = sendToTokens(tokens, title, body, data);
        }

        recordAudit(userId, triggerType, title, body, data, fcmResult);
        return fcmResult;
    }

    /**
     * Sends a push notification to a list of users.
     */
    public void sendToUsers(List<Long> userIds, String title, String body, Map<String, String> data, String triggerType) {
        for (Long userId : userIds) {
            sendToUser(userId, title, body, data, triggerType);
        }
    }

    /**
     * Sends a push notification to all users with registered tokens.
     * Also mirrors an audit row per user (so each user sees it in their bell).
     */
    public String sendBroadcast(SendNotificationRequest request) {
        return sendBroadcast(request.title(), request.body(), request.data(), null);
    }

    public String sendBroadcast(String title, String body, Map<String, String> data, String triggerType) {
        List<String> tokens = jdbc.queryForList(
                "SELECT token FROM fcm_tokens",
                String.class);

        String fcmResult;
        if (tokens.isEmpty()) {
            log.warn("No FCM tokens registered for broadcast");
            fcmResult = null;
        } else {
            fcmResult = sendToTokens(tokens, title, body, data);
        }

        // Mirror audit for every active user so each user has a personal record.
        List<Long> userIds = jdbc.queryForList(
                "SELECT id FROM app_users WHERE status = 'ACTIVE'",
                Long.class);
        for (Long userId : userIds) {
            recordAudit(userId, triggerType, title, body, data, fcmResult);
        }
        return fcmResult;
    }

    private void recordAudit(Long userId, String triggerType, String title, String body,
                              Map<String, String> data, String fcmResult) {
        String dataJson = null;
        if (data != null && !data.isEmpty()) {
            try {
                dataJson = objectMapper.writeValueAsString(data);
            } catch (Exception e) {
                log.warn("Failed to serialize data_json: {}", e.getMessage());
            }
        }
        String status = fcmResult == null ? "NO_TOKEN" : "SENT";
        jdbc.update("""
            INSERT INTO notification_audit
                (target_user_id, trigger_type, title, body, data_json, fcm_result, status, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            """,
                userId, triggerType, title, body, dataJson, fcmResult, status);
    }

    /**
     * Lists notifications for a user, newest first.
     */
    public List<NotificationAuditDto> listForUser(Long userId, int limit) {
        int cappedLimit = Math.max(1, Math.min(limit, 200));
        return jdbc.query("""
            SELECT id, target_user_id, trigger_type, title, body, data_json,
                   status, read_at, created_at
            FROM notification_audit
            WHERE target_user_id = ?
            ORDER BY created_at DESC
            LIMIT ?
            """, AUDIT_ROW_MAPPER, userId, cappedLimit);
    }

    /**
     * Counts unread notifications for a user.
     */
    public long unreadCount(Long userId) {
        Long count = jdbc.queryForObject("""
            SELECT COUNT(*) FROM notification_audit
            WHERE target_user_id = ? AND read_at IS NULL
            """, Long.class, userId);
        return count == null ? 0L : count;
    }

    /**
     * Marks a single notification as read (must belong to the user).
     * Returns true if the row was updated.
     */
    public boolean markRead(Long userId, Long notificationId) {
        int updated = jdbc.update("""
            UPDATE notification_audit
            SET read_at = CURRENT_TIMESTAMP,
                status = CASE WHEN status = 'NO_TOKEN' THEN 'READ_NO_TOKEN' ELSE 'READ' END
            WHERE id = ? AND target_user_id = ? AND read_at IS NULL
            """, notificationId, userId);
        return updated > 0;
    }

    /**
     * Marks all unread notifications as read for a user.
     */
    public int markAllRead(Long userId) {
        return jdbc.update("""
            UPDATE notification_audit
            SET read_at = CURRENT_TIMESTAMP,
                status = CASE WHEN status = 'NO_TOKEN' THEN 'READ_NO_TOKEN' ELSE 'READ' END
            WHERE target_user_id = ? AND read_at IS NULL
            """, userId);
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
