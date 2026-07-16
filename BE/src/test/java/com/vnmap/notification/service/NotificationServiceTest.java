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
import static org.assertj.core.api.Assertions.assertThatThrownBy;
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

        when(jdbc.queryForList("SELECT token FROM fcm_tokens", String.class)).thenReturn(List.of());
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

    @Test
    void preservesAuditWhenPayloadCannotBeSerializedAndHandlesReadBranches() throws Exception {
        ObjectMapper failingMapper = mock(ObjectMapper.class);
        NotificationService failingService = new NotificationService(jdbc, fcm, failingMapper);
        when(jdbc.queryForList(contains("WHERE user_id"), eq(String.class), eq(7L))).thenReturn(List.of());
        when(failingMapper.writeValueAsString(any())).thenThrow(new IllegalStateException("bad json"));
        when(jdbc.update(contains("UPDATE notification_audit"), eq(3L), eq(7L))).thenReturn(0);

        assertThat(failingService.sendToUser(7L, "T", "B", Map.of("k", "v"), "EVENT")).isNull();
        assertThat(failingService.markRead(7L, 3L)).isFalse();
        verify(jdbc).update(contains("notification_audit"), eq(7L), eq("EVENT"), eq("T"), eq("B"), isNull(), isNull(), eq("NO_TOKEN"));
    }

    @Test
    void capsNotificationListAtBothBoundsAndSurfacesFcmFailure() throws Exception {
        when(jdbc.query(anyString(), any(RowMapper.class), eq(5L), eq(1))).thenReturn(List.of());
        assertThat(service.listForUser(5L, 0)).isEmpty();

        when(jdbc.queryForList(contains("WHERE user_id"), eq(String.class), eq(8L))).thenReturn(List.of("token"));
        when(fcm.send(any())).thenThrow(new IllegalStateException("FCM offline"));
        assertThatThrownBy(() -> service.sendToUser(8L, "T", "B", Map.of(), "EVENT"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("FCM send failed");
    }
    @Test
    void mapsAuditRowsForValidBlankAndMalformedJson() throws Exception {
        @SuppressWarnings("unchecked")
        RowMapper<com.vnmap.notification.dto.NotificationAuditDto> mapper =
                (RowMapper<com.vnmap.notification.dto.NotificationAuditDto>)
                        org.springframework.test.util.ReflectionTestUtils.getField(NotificationService.class, "AUDIT_ROW_MAPPER");
        java.sql.ResultSet rs = mock(java.sql.ResultSet.class);
        java.sql.Timestamp readAt = java.sql.Timestamp.valueOf(java.time.LocalDateTime.of(2026, java.time.Month.JANUARY, 2, 3, 4));
        java.sql.Timestamp createdAt = java.sql.Timestamp.valueOf(java.time.LocalDateTime.of(2026, java.time.Month.JANUARY, 1, 3, 4));
        when(rs.getTimestamp("read_at")).thenReturn(readAt);
        when(rs.getTimestamp("created_at")).thenReturn(createdAt);
        when(rs.getString("data_json")).thenReturn("{\"type\":\"event\"}");
        when(rs.getLong("id")).thenReturn(4L);
        when(rs.getObject("target_user_id")).thenReturn(9L);
        when(rs.getString("trigger_type")).thenReturn("EVENT");
        when(rs.getString("title")).thenReturn("Title");
        when(rs.getString("body")).thenReturn("Body");
        when(rs.getString("status")).thenReturn("READ");
        var mapped = mapper.mapRow(rs, 0);
        assertThat(mapped.data()).containsEntry("type", "event");
        assertThat(mapped.readAt()).isEqualTo(readAt.toLocalDateTime());
        assertThat(mapped.createdAt()).isEqualTo(createdAt.toLocalDateTime());

        when(rs.getTimestamp("read_at")).thenReturn(null);
        when(rs.getTimestamp("created_at")).thenReturn(null);
        when(rs.getString("data_json")).thenReturn(" ", "malformed");
        assertThat(mapper.mapRow(rs, 1).data()).isEmpty();
        assertThat(mapper.mapRow(rs, 2).data()).isEmpty();
    }

    @Test
    void broadcastsMulticastThroughRequestOverloadAndCountsUnread() throws Exception {
        com.google.firebase.messaging.BatchResponse batch = mock(com.google.firebase.messaging.BatchResponse.class);
        when(batch.getSuccessCount()).thenReturn(2);
        when(batch.getFailureCount()).thenReturn(0);
        when(fcm.sendEachForMulticast(any())).thenReturn(batch);
        when(jdbc.queryForList("SELECT token FROM fcm_tokens", String.class))
                .thenReturn(List.of("token-1", "token-2"));
        when(jdbc.queryForList(contains("FROM app_users"), eq(Long.class))).thenReturn(List.of(1L));
        SendNotificationRequest request = new SendNotificationRequest(null, "Title", "Body", null);
        assertThat(service.sendBroadcast(request)).isEqualTo("multicast:2/2");
        verify(fcm).sendEachForMulticast(any());

        when(jdbc.queryForObject(anyString(), eq(Long.class), eq(10L))).thenReturn(5L);
        assertThat(service.unreadCount(10L)).isEqualTo(5L);
    }
}