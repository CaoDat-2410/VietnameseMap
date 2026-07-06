package com.vnmap.notification.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Service
public class NotificationTriggerService {

    private final JdbcTemplate jdbc;
    private final NotificationService notificationService;

    public NotificationTriggerService(JdbcTemplate jdbc, NotificationService notificationService) {
        this.jdbc = jdbc;
        this.notificationService = notificationService;
    }

    public void campaignCreated(long campaignId, String campaignName) {
        List<Long> users = usersByRoles("MANAGER", "ADMIN");
        notificationService.sendToUsers(
                users,
                "Campaign created",
                "New campaign: " + campaignName,
                Map.of("type", "campaign_created", "campaignId", String.valueOf(campaignId)),
                "CAMPAIGN_CREATED"
        );
    }

    public void eventCreated(long eventId, String eventName) {
        List<Long> users = usersByRoles("MANAGER", "ADMIN");
        users.addAll(assignedUsersForEvent(eventId));
        notificationService.sendToUsers(
                users.stream().distinct().toList(),
                "Event created",
                "New event: " + eventName,
                Map.of("type", "event_created", "eventId", String.valueOf(eventId)),
                "EVENT_CREATED"
        );
    }

    public void staffAssigned(long eventId, long employeeId) {
        List<Long> users = jdbc.queryForList(
                "SELECT id FROM app_users WHERE employee_id = ? AND status = 'ACTIVE'",
                Long.class,
                employeeId
        );
        notificationService.sendToUsers(
                users,
                "Event assignment",
                "You have been assigned to an event",
                Map.of("type", "event_assigned", "eventId", String.valueOf(eventId)),
                "EVENT_ASSIGNED"
        );
    }

    public void accountDeactivated(long userId) {
        List<Long> admins = usersByRoles("ADMIN");
        notificationService.sendToUser(
                userId,
                "Account deactivated",
                "Your account has been deactivated.",
                Map.of("type", "account_deactivated"),
                "ACCOUNT_DEACTIVATED"
        );
        notificationService.sendToUsers(
                admins,
                "Account deactivated",
                "User account deactivated: " + userId,
                Map.of("type", "account_deactivated", "userId", String.valueOf(userId)),
                "ACCOUNT_DEACTIVATED_ADMIN"
        );
    }

    @Scheduled(cron = "${notifications.daily-reminder-cron:0 0 7 * * *}", zone = "Asia/Saigon")
    public void dailyEventReminders() {
        LocalDate today = LocalDate.now();
        List<Map<String, Object>> events = jdbc.queryForList(
                """
                SELECT id, name FROM campaign_events
                WHERE DATE(starts_at) = ? AND status <> 'ARCHIVED'
                """,
                today
        );
        for (Map<String, Object> event : events) {
            Long eventId = ((Number) event.get("id")).longValue();
            String eventName = (String) event.get("name");
            notificationService.sendToUsers(
                    assignedUsersForEvent(eventId),
                    "Today's event",
                    "You have an event today: " + eventName,
                    Map.of("type", "today_event_reminder", "eventId", String.valueOf(eventId)),
                    "TODAY_EVENT_REMINDER"
            );
            notificationService.sendToUsers(
                    studentUsersForEvent(eventId),
                    "Campaign event today",
                    "A campaign event linked to your registration is scheduled today: " + eventName,
                    Map.of("type", "today_event_reminder", "eventId", String.valueOf(eventId)),
                    "TODAY_EVENT_REMINDER_STUDENT"
            );
        }
    }

    private List<Long> usersByRoles(String... roles) {
        String placeholders = String.join(",", java.util.Arrays.stream(roles).map(role -> "?").toList());
        return new java.util.ArrayList<>(jdbc.queryForList(
                "SELECT id FROM app_users WHERE role IN (" + placeholders + ") AND status = 'ACTIVE'",
                Long.class,
                (Object[]) roles
        ));
    }

    private List<Long> assignedUsersForEvent(long eventId) {
        return new java.util.ArrayList<>(jdbc.queryForList(
                """
                SELECT u.id
                FROM event_assignments ea
                JOIN app_users u ON u.employee_id = ea.employee_id
                WHERE ea.event_id = ? AND u.status = 'ACTIVE'
                """,
                Long.class,
                eventId
        ));
    }

    private List<Long> studentUsersForEvent(long eventId) {
        return jdbc.queryForList(
                """
                SELECT DISTINCT u.id
                FROM campaign_events e
                JOIN campaign_student_registrations r ON r.campaign_id = e.campaign_id
                JOIN app_users u ON u.student_id = r.student_id
                WHERE e.id = ? AND u.status = 'ACTIVE'
                """,
                Long.class,
                eventId
        );
    }
}
