package com.vnmap.campaign.service;

import com.vnmap.campaign.dto.AggregateDashboardDto;
import com.vnmap.campaign.dto.ChannelBreakdownDto;
import com.vnmap.campaign.dto.EmployeeRankingDto;
import com.vnmap.campaign.dto.TrendPointDto;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.Month;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AnalyticsServiceTest {

    private static final Clock FIXED_CLOCK = Clock.fixed(
            Instant.parse("2026-07-01T00:00:00Z"),
            ZoneOffset.UTC
    );

    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final AnalyticsService service = new AnalyticsService(jdbc, FIXED_CLOCK);

    @Test
    void aggregateDashboardMapsTotalsAndBreakdownsWithFilters() {
        when(jdbc.queryForObject(anyString(), eq(Long.class))).thenReturn(7L);
        when(jdbc.queryForObject(anyString(), eq(Long.class), any(Object[].class)))
                .thenReturn(3L, 2L, 5L, 9L);
        when(jdbc.queryForList(anyString(), any(Object[].class)))
                .thenReturn(
                        List.of(Map.of("outcome", "INTERESTED", "total", 4L)),
                        List.of(Map.of("province_code", "79", "province_name", "Ho Chi Minh", "total", 4L)),
                        List.of(Map.of("school_uid", "79-001", "school_name", "Coverage School", "total", 4L))
                );

        AggregateDashboardDto result = service.getAggregateDashboard(10L, "79-001");

        assertThat(result.totalCampaigns()).isEqualTo(1L);
        assertThat(result.totalEvents()).isEqualTo(3L);
        assertThat(result.totalSchools()).isEqualTo(2L);
        assertThat(result.totalEmployees()).isEqualTo(5L);
        assertThat(result.totalInteractions()).isEqualTo(9L);
        assertThat(result.interactionsByOutcome())
                .containsEntry("SUCCESSFUL", 0L)
                .containsEntry("INTERESTED", 4L);
        assertThat(result.interactionsByProvince()).singleElement()
                .satisfies(row -> {
                    assertThat(row.provinceCode()).isEqualTo("79");
                    assertThat(row.totalInteractions()).isEqualTo(4L);
                });
        assertThat(result.topSchools()).singleElement()
                .satisfies(row -> {
                    assertThat(row.schoolUid()).isEqualTo("79-001");
                    assertThat(row.totalInteractions()).isEqualTo(4L);
                });
    }

    @Test
    void aggregateDashboardHandlesNullCountsAndUnfilteredQueries() {
        when(jdbc.queryForObject(anyString(), eq(Long.class))).thenReturn(null);
        when(jdbc.queryForList(anyString()))
                .thenReturn(List.of(), List.of(), List.of());

        AggregateDashboardDto result = service.getAggregateDashboard(null, "");

        assertThat(result.totalCampaigns()).isZero();
        assertThat(result.totalEvents()).isZero();
        assertThat(result.totalSchools()).isZero();
        assertThat(result.totalEmployees()).isZero();
        assertThat(result.totalInteractions()).isZero();
        assertThat(result.interactionsByOutcome().values()).containsOnly(0L);
        assertThat(result.interactionsByProvince()).isEmpty();
        assertThat(result.topSchools()).isEmpty();
    }

    @Test
    void trendBackfillsMissingDays() {
        LocalDate today = LocalDate.of(2026, Month.JULY, 1);
        when(jdbc.query(anyString(), any(RowMapper.class), any(Object[].class))).thenReturn(List.of(
                new TrendPointDto(today.minusDays(2), 6L),
                new TrendPointDto(today, 3L)
        ));

        List<TrendPointDto> result = service.getInteractionsTrend(3, 10L, "79-001");

        assertThat(result).hasSize(3);
        assertThat(result).extracting(TrendPointDto::date)
                .containsExactly(today.minusDays(2), today.minusDays(1), today);
        assertThat(result).extracting(TrendPointDto::total)
                .containsExactly(6L, 0L, 3L);
    }

    @Test
    void channelsAndEmployeesMapRows() {
        when(jdbc.queryForList(anyString(), any(Object[].class)))
                .thenReturn(
                        List.of(Map.of("channel", "EMAIL", "total", 8L)),
                        List.of(Map.of("id", 42L, "full_name", "Coverage Staff", "total", 5L))
                );

        List<ChannelBreakdownDto> channels = service.getChannelBreakdown(10L, "79-001");
        List<EmployeeRankingDto> employees = service.getTopEmployees(5, 10L, "79-001");

        assertThat(channels).singleElement()
                .satisfies(row -> {
                    assertThat(row.channel()).isEqualTo("EMAIL");
                    assertThat(row.total()).isEqualTo(8L);
                });
        assertThat(employees).singleElement()
                .satisfies(row -> {
                    assertThat(row.employeeId()).isEqualTo(42L);
                    assertThat(row.employeeName()).isEqualTo("Coverage Staff");
                    assertThat(row.totalInteractions()).isEqualTo(5L);
                });
    }
}