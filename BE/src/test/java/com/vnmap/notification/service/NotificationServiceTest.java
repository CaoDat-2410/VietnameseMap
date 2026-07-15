package com.vnmap.notification.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.firebase.messaging.FirebaseMessaging;
import com.vnmap.notification.dto.SendNotificationRequest;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class NotificationServiceTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final FirebaseMessaging fcm = mock(FirebaseMessaging.class);
    private final NotificationService service = new NotificationService(jdbc, fcm, new ObjectMapper());

    @Test
    void savesDeletesAndCountsTokensAndNotifications() {
        service.saveToken(3L, "token", "android");
        service.deleteToken(3L, "token");
        when(jdbc.queryForObject(anyString(), eq(Long.class), eq(3L))).thenReturn(null);
        when(jdbc.update(anyString(), eq(12L), eq(3L))).thenReturn(1);
        when(jdbc.update(anyString(), eq(3L))).thenReturn(4);
        assertThat(service.unreadCount(3L)).isZero();
        assertThat(service.markRead(3L, 12L)).isTrue();
        assertThat(service.markAllRead(3L)).isEqualTo(4);
        verify(jdbc, times(4)).update(anyString(), any(Object[].class));
    }

    @Test
    void sendsSingleTokenAndRecordsAudit() throws Exception {
        when(jdbc.queryForList(contains("WHERE user_id"), eq(String.class), eq(9L))).thenReturn(List.of("token-1"));
        when(fcm.send(any())).thenReturn("message-1");
        String response = service.sendToUser(9L, "Title", "Body", Map.of("type", "event"), "EVENT");
        assertThat(response).isEqualTo("message-1");
        verify(fcm).send(any());
        verify(jdbc).update(contains("notification_audit"), eq(9L), eq("EVENT"), eq("Title"), eq("Body"), contains("event"), eq("message-1"), eq("SENT"));
    }

    @Test
    void sendsNoTokenAndBroadcastAuditsEveryActiveUser() {
        when(jdbc.queryForList(contains("WHERE user_id"), eq(String.class), eq(9L))).thenReturn(List.of());
        assertThat(service.sendToUser(9L, new SendNotificationRequest(9L, "T", "B", Map.of()))).isNull();

        when(jdbc.queryForList(eq("SELECT token FROM fcm_tokens"), eq(String.class))).thenReturn(List.of());
        when(jdbc.queryForList(contains("FROM app_users"), eq(Long.class))).thenReturn(List.of(1L, 2L));
        assertThat(service.sendBroadcast("T", "B", Map.of(), "BROADCAST")).isNull();
        verify(jdbc, times(3)).update(contains("notification_audit"), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void delegatesToAllUsersAndCapsLimits() {
        service.sendToUsers(List.of(1L, 2L), "T", "B", Map.of(), "TYPE");
        verify(jdbc, times(2)).queryForList(contains("WHERE user_id"), eq(String.class), anyLong());
        verify(jdbc, times(2)).update(contains("notification_audit"), any(), any(), any(), any(), any(), any(), any());
        service.listForUser(1L, 999);
        verify(jdbc).query(contains("notification_audit"), any(RowMapper.class), eq(1L), eq(200));
    }
}