package com.vnmap.notification.controller;

import com.vnmap.common.model.ApiResponse;
import com.vnmap.common.security.CurrentUser;
import com.vnmap.notification.dto.FcmTokenRequest;
import com.vnmap.notification.dto.NotificationAuditDto;
import com.vnmap.notification.dto.SendNotificationRequest;
import com.vnmap.notification.service.NotificationService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private static final Logger log = LoggerFactory.getLogger(NotificationController.class);

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    /**
     * Registers or updates the FCM push token for the authenticated user.
     */
    @PostMapping("/token")
    public ResponseEntity<ApiResponse<Void>> registerToken(
            @AuthenticationPrincipal CurrentUser user,
            @Valid @RequestBody FcmTokenRequest request
    ) {
        notificationService.saveToken(user.id(), request.token(), request.platform());
        return ResponseEntity.ok(ApiResponse.success(null, "Token registered"));
    }

    /**
     * Removes the FCM token for the authenticated user (e.g. on logout).
     */
    @DeleteMapping("/token")
    public ResponseEntity<ApiResponse<Void>> deleteToken(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam String token
    ) {
        notificationService.deleteToken(user.id(), token);
        return ResponseEntity.ok(ApiResponse.success(null, "Token deleted"));
    }

    /**
     * Sends a push notification to a single user or broadcasts to all users.
     * Requires the ADMIN role (enforced by SecurityConfig).
     */
    @PostMapping("/send")
    public ResponseEntity<ApiResponse<String>> sendNotification(
            @AuthenticationPrincipal CurrentUser sender,
            @Valid @RequestBody SendNotificationRequest request
    ) {
        log.info("Notification sent by userId={}: title='{}'", sender.id(), request.title());

        String result;
        if (request.targetUserId() != null) {
            result = notificationService.sendToUser(
                    request.targetUserId(),
                    request.title(),
                    request.body(),
                    request.data(),
                    "ADMIN_MANUAL"
            );
        } else {
            result = notificationService.sendBroadcast(
                    request.title(),
                    request.body(),
                    request.data(),
                    "ADMIN_MANUAL"
            );
        }

        return ResponseEntity.ok(ApiResponse.success(result));
    }

    /**
     * Lists the authenticated user's notifications, newest first.
     * Limit defaults to 50, capped at 200.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<NotificationAuditDto>>> listMyNotifications(
            @AuthenticationPrincipal CurrentUser user,
            @RequestParam(defaultValue = "50") int limit
    ) {
        List<NotificationAuditDto> items = notificationService.listForUser(user.id(), limit);
        return ResponseEntity.ok(ApiResponse.success(items));
    }

    /**
     * Returns the count of unread notifications for the authenticated user.
     */
    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<Map<String, Long>>> unreadCount(
            @AuthenticationPrincipal CurrentUser user
    ) {
        long count = notificationService.unreadCount(user.id());
        return ResponseEntity.ok(ApiResponse.success(Map.of("count", count)));
    }

    /**
     * Marks a single notification as read (must belong to the caller).
     */
    @PutMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Map<String, Object>>> markRead(
            @AuthenticationPrincipal CurrentUser user,
            @PathVariable Long id
    ) {
        boolean updated = notificationService.markRead(user.id(), id);
        return ResponseEntity.ok(ApiResponse.success(
                Map.of("updated", updated, "id", id)
        ));
    }

    /**
     * Marks every unread notification as read for the caller.
     */
    @PostMapping("/read-all")
    public ResponseEntity<ApiResponse<Map<String, Object>>> markAllRead(
            @AuthenticationPrincipal CurrentUser user
    ) {
        int updated = notificationService.markAllRead(user.id());
        return ResponseEntity.ok(ApiResponse.success(Map.of("updated", updated)));
    }
}
