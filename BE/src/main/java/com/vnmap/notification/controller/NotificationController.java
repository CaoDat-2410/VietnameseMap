package com.vnmap.notification.controller;

import com.vnmap.common.model.ApiResponse;
import com.vnmap.common.security.CurrentUser;
import com.vnmap.notification.dto.FcmTokenRequest;
import com.vnmap.notification.dto.SendNotificationRequest;
import com.vnmap.notification.service.NotificationService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

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
        notificationService.deleteToken(token);
        return ResponseEntity.ok(ApiResponse.success(null, "Token deleted"));
    }

    /**
     * Sends a push notification to a single user or broadcasts to all users.
     * Requires STAFF, MANAGER, or ADMIN role (enforced by SecurityConfig).
     */
    @PostMapping("/send")
    public ResponseEntity<ApiResponse<String>> sendNotification(
            @AuthenticationPrincipal CurrentUser sender,
            @Valid @RequestBody SendNotificationRequest request
    ) {
        log.info("Notification sent by userId={}: title='{}'", sender.id(), request.title());

        String result;
        if (request.targetUserId() != null) {
            result = notificationService.sendToUser(request.targetUserId(), request);
        } else {
            result = notificationService.sendBroadcast(request);
        }

        return ResponseEntity.ok(ApiResponse.success(result));
    }
}
