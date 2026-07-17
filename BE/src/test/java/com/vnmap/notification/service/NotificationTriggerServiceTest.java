package com.vnmap.notification.service;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class NotificationTriggerServiceTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final NotificationService notifications = mock(NotificationService.class);
    private final NotificationTriggerService service = new NotificationTriggerService(jdbc, notifications);

    @Test
    void sendsCampaignEventAssignmentAndDeactivationNotifications() {
        when(jdbc.queryForList(contains("role IN"), eq(Long.class), any(Object[].class)))
                .thenReturn(List.of(1L, 2L));
        when(jdbc.queryForList(contains("employee_id = ?"), eq(Long.class), eq(7L)))
                .thenReturn(List.of(3L));

        service.campaignCreated(4L, "Summer campaign");
        service.eventCreated(5L, "School visit");
        service.staffAssigned(5L, 7L);
        service.accountDeactivated(8L);

        verify(notifications).sendToUsers(eq(List.of(1L, 2L)), eq("Campaign created"), anyString(), anyMap(), eq("CAMPAIGN_CREATED"));
        verify(notifications).sendToUsers(eq(List.of(1L, 2L)), eq("Event created"), anyString(), anyMap(), eq("EVENT_CREATED"));
        verify(notifications).sendToUser(eq(8L), eq("Account deactivated"), anyString(), anyMap(), eq("ACCOUNT_DEACTIVATED"));
        verify(notifications).sendToUsers(eq(List.of(1L, 2L)), eq("Account deactivated"), anyString(), anyMap(), eq("ACCOUNT_DEACTIVATED_ADMIN"));
    }

    @Test
    void sendsBothReminderAudiencesForEventsScheduledToday() {
        when(jdbc.queryForList(contains("WHERE DATE(starts_at)"), any(Object[].class)))
                .thenReturn(List.of(Map.of("id", 9L, "name", "Open day")));
        when(jdbc.queryForList(contains("FROM event_assignments"), eq(Long.class), eq(9L)))
                .thenReturn(List.of(10L));
        when(jdbc.queryForList(contains("FROM campaign_events e"), eq(Long.class), eq(9L)))
                .thenReturn(List.of(11L));

        service.dailyEventReminders();

        verify(notifications).sendToUsers(eq(List.of(10L)), eq("Today's event"), anyString(), anyMap(), eq("TODAY_EVENT_REMINDER"));
        verify(notifications).sendToUsers(eq(List.of(11L)), eq("Campaign event today"), anyString(), anyMap(), eq("TODAY_EVENT_REMINDER_STUDENT"));
    }
}
