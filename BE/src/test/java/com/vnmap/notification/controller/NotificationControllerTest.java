package com.vnmap.notification.controller;

import com.vnmap.common.security.CurrentUser;
import com.vnmap.notification.dto.FcmTokenRequest;
import com.vnmap.notification.dto.SendNotificationRequest;
import com.vnmap.notification.service.NotificationService;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class NotificationControllerTest {
    private final NotificationService service = mock(NotificationService.class);
    private final NotificationController controller = new NotificationController(service);
    private final CurrentUser user = new CurrentUser(7L, "staff@test", "STAFF", "ACTIVE", 3L, null);

    @Test
    void delegatesAllAuthenticatedNotificationActions() {
        when(service.sendToUser(eq(2L), eq("Title"), eq("Body"), anyMap(), eq("ADMIN_MANUAL")))
                .thenReturn("single");
        when(service.sendBroadcast(eq("Title"), eq("Body"), anyMap(), eq("ADMIN_MANUAL")))
                .thenReturn("broadcast");
        when(service.unreadCount(7L)).thenReturn(4L);
        when(service.markRead(7L, 8L)).thenReturn(true);
        when(service.markAllRead(7L)).thenReturn(3);

        assertThat(controller.registerToken(user, new FcmTokenRequest("t", "WEB")).getBody().getMessage()).isEqualTo("Token registered");
        assertThat(controller.deleteToken(user, "t").getBody().getMessage()).isEqualTo("Token deleted");
        assertThat(controller.sendNotification(user, new SendNotificationRequest(2L, "Title", "Body", Map.of())).getBody().getData()).isEqualTo("single");
        assertThat(controller.sendNotification(user, new SendNotificationRequest(null, "Title", "Body", Map.of())).getBody().getData()).isEqualTo("broadcast");
        assertThat(controller.listMyNotifications(user, 10).getBody().getData()).isEqualTo(List.of());
        assertThat(controller.unreadCount(user).getBody().getData()).containsEntry("count", 4L);
        assertThat(controller.markRead(user, 8L).getBody().getData()).containsEntry("updated", true);
        assertThat(controller.markAllRead(user).getBody().getData()).containsEntry("updated", 3);

        verify(service).saveToken(7L, "t", "WEB");
        verify(service).deleteToken(7L, "t");
        verify(service).listForUser(7L, 10);
    }
}
