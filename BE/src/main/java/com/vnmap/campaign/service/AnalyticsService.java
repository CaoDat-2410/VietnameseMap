package com.vnmap.campaign.service;

import com.vnmap.campaign.dto.AggregateDashboardDto;
import com.vnmap.campaign.dto.ChannelBreakdownDto;
import com.vnmap.campaign.dto.EmployeeRankingDto;
import com.vnmap.campaign.dto.ProvinceInteractionDto;
import com.vnmap.campaign.dto.TopSchoolDto;
import com.vnmap.campaign.dto.TrendPointDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Service that returns aggregate analytics across (optionally filtered) campaigns.
 * Used by the Analytics tab in the FE.
 *
 * <p>Filters are applied via the {@code campaignId} and {@code schoolUid} request
 * parameters on {@code GET /api/analytics/aggregate}. When a filter is set the
 * totals and breakdowns are scoped to the matching subset of {@code interactions}
 * rows. Without a filter the response is a global roll-up.</p>
 */
@Service
public class AnalyticsService {

    private static final String BASE_WHERE = " WHERE 1=1";
    private static final String CAMPAIGN_FILTER = " AND i.campaign_id = ?";
    private static final String SCHOOL_FILTER = " AND i.school_uid = ?";
    private static final String TOTAL_COLUMN = "total";

    private final JdbcTemplate jdbc;
    private final Clock clock;

    @Autowired
    public AnalyticsService(JdbcTemplate jdbc) {
        this(jdbc, Clock.systemDefaultZone());
    }

    AnalyticsService(JdbcTemplate jdbc, Clock clock) {
        this.jdbc = jdbc;
        this.clock = clock;
    }

    public AggregateDashboardDto getAggregateDashboard(Long campaignId, String schoolUid) {
        StringBuilder interactionWhere = new StringBuilder(BASE_WHERE);
        List<Object> interactionParams = new ArrayList<>();
        appendScopeFilters(interactionWhere, interactionParams, campaignId, schoolUid);

        long totalCampaigns;
        if (campaignId != null) {
            // When scoped to a single campaign we report "1" so the UI has a
            // sensible value; alternatively we could return the real campaign
            // row but the FE expects a count.
            totalCampaigns = 1L;
        } else {
            totalCampaigns = count("SELECT COUNT(*) FROM campaigns");
        }

        long totalEvents;
        if (campaignId != null) {
            totalEvents = count(
                    "SELECT COUNT(*) FROM campaign_events WHERE campaign_id = ?",
                    List.of(campaignId)
            );
        } else {
            totalEvents = count("SELECT COUNT(*) FROM campaign_events");
        }

        // Distinct school/employee/interaction counts all scoped through the
        // interactions table so the filter applies consistently.
        long totalSchools = count(
                "SELECT COUNT(DISTINCT i.school_uid) FROM interactions i" + interactionWhere,
                interactionParams
        );
        long totalEmployees = count(
                "SELECT COUNT(DISTINCT i.employee_id) FROM interactions i" + interactionWhere,
                interactionParams
        );
        long totalInteractions = count(
                "SELECT COUNT(*) FROM interactions i" + interactionWhere,
                interactionParams
        );

        Map<String, Long> byOutcome = new LinkedHashMap<>();
        byOutcome.put("SUCCESSFUL", 0L);
        byOutcome.put("FOLLOW_UP", 0L);
        byOutcome.put("NO_RESPONSE", 0L);
        byOutcome.put("INTERESTED", 0L);
        byOutcome.put("NOT_INTERESTED", 0L);
        String outcomeSql = "SELECT outcome, COUNT(*) AS total FROM interactions i" +
                interactionWhere + " GROUP BY outcome";
        queryForListWithParams(outcomeSql, interactionParams).forEach(row -> byOutcome.put(
                (String) row.get("outcome"),
                ((Number) row.get(TOTAL_COLUMN)).longValue()
        ));

        String provinceSql = "SELECT s.province_code, s.province_name, COUNT(i.id) AS total " +
                "FROM interactions i " +
                "JOIN schools s ON s.school_uid = i.school_uid " +
                interactionWhere + " " +
                "GROUP BY s.province_code, s.province_name " +
                "ORDER BY total DESC, s.province_name " +
                "LIMIT 20";
        List<ProvinceInteractionDto> byProvince = new ArrayList<>();
        for (Map<String, Object> row : queryForListWithParams(provinceSql, interactionParams)) {
            byProvince.add(new ProvinceInteractionDto(
                    (String) row.get("province_code"),
                    (String) row.get("province_name"),
                    ((Number) row.get(TOTAL_COLUMN)).longValue()
            ));
        }

        String topSql = "SELECT s.school_uid, s.school_name, COUNT(i.id) AS total " +
                "FROM interactions i " +
                "JOIN schools s ON s.school_uid = i.school_uid " +
                interactionWhere + " " +
                "GROUP BY s.school_uid, s.school_name " +
                "ORDER BY total DESC, s.school_name " +
                "LIMIT 10";
        List<TopSchoolDto> topSchools = new ArrayList<>();
        for (Map<String, Object> row : queryForListWithParams(topSql, interactionParams)) {
            topSchools.add(new TopSchoolDto(
                    (String) row.get("school_uid"),
                    (String) row.get("school_name"),
                    ((Number) row.get(TOTAL_COLUMN)).longValue()
            ));
        }

        return new AggregateDashboardDto(
                totalCampaigns, totalEvents, totalSchools, totalEmployees,
                totalInteractions, byOutcome, byProvince, topSchools
        );
    }

    /**
     * Returns interactions per day for the last {@code days} days, scoped by the
     * optional filter. Days with zero interactions are filled in so the FE can
     * plot a continuous line without gaps.
     */
    public List<TrendPointDto> getInteractionsTrend(int days, Long campaignId, String schoolUid) {
        // Build a parameterised WHERE clause that conditionally adds the
        // optional campaign / school filters. Using positional `?` inside
        // expressions like `(? IS NULL OR col = ?)` triggers PostgreSQL's
        // "could not determine data type of parameter" error, so we append
        // each filter explicitly only when a value is provided.
        StringBuilder where = new StringBuilder(" WHERE i.created_at >= CURRENT_DATE - ?");
        List<Object> params = new ArrayList<>();
        params.add(days);
        appendScopeFilters(where, params, campaignId, schoolUid);

        String sql = "SELECT DATE(i.created_at) AS d, COUNT(*) AS total " +
                "FROM interactions i" + where + " " +
                "GROUP BY DATE(i.created_at) " +
                "ORDER BY d";

        Map<LocalDate, Long> byDate = new LinkedHashMap<>();
        jdbc.query(sql, (rs, rowNum) -> new TrendPointDto(
                rs.getObject("d", LocalDate.class),
                rs.getLong(TOTAL_COLUMN)
        ), params.toArray()).forEach(row -> byDate.put(row.date(), row.total()));

        LocalDate today = LocalDate.now(clock);
        List<TrendPointDto> out = new ArrayList<>(days);
        for (int i = days - 1; i >= 0; i--) {
            LocalDate day = today.minusDays(i);
            out.add(new TrendPointDto(day, byDate.getOrDefault(day, 0L)));
        }
        return out;
    }

    /**
     * Interactions grouped by communication channel (PHONE / EMAIL / ZALO /
     * VISIT / EVENT / etc.), ordered by volume.
     */
    public List<ChannelBreakdownDto> getChannelBreakdown(Long campaignId, String schoolUid) {
        StringBuilder where = new StringBuilder(BASE_WHERE);
        List<Object> params = new ArrayList<>();
        appendScopeFilters(where, params, campaignId, schoolUid);

        String sql = "SELECT i.channel, COUNT(*) AS total " +
                "FROM interactions i" + where + " " +
                "GROUP BY i.channel " +
                "ORDER BY total DESC";
        List<ChannelBreakdownDto> out = new ArrayList<>();
        for (Map<String, Object> row : queryForListWithParams(sql, params)) {
            out.add(new ChannelBreakdownDto(
                    (String) row.get("channel"),
                    ((Number) row.get(TOTAL_COLUMN)).longValue()
            ));
        }
        return out;
    }

    /**
     * Top {@code limit} employees ranked by number of interactions in scope.
     */
    public List<EmployeeRankingDto> getTopEmployees(int limit, Long campaignId, String schoolUid) {
        StringBuilder where = new StringBuilder(BASE_WHERE);
        List<Object> params = new ArrayList<>();
        appendScopeFilters(where, params, campaignId, schoolUid);
        params.add(limit);

        String sql = "SELECT e.id, e.full_name, COUNT(i.id) AS total " +
                "FROM interactions i " +
                "JOIN employees e ON e.id = i.employee_id" + where + " " +
                "GROUP BY e.id, e.full_name " +
                "ORDER BY total DESC, e.full_name " +
                "LIMIT ?";
        List<EmployeeRankingDto> out = new ArrayList<>();
        for (Map<String, Object> row : queryForListWithParams(sql, params)) {
            out.add(new EmployeeRankingDto(
                    ((Number) row.get("id")).longValue(),
                    (String) row.get("full_name"),
                    ((Number) row.get(TOTAL_COLUMN)).longValue()
            ));
        }
        return out;
    }

    private void appendScopeFilters(
            StringBuilder where,
            List<Object> params,
            Long campaignId,
            String schoolUid
    ) {
        if (campaignId != null) {
            where.append(CAMPAIGN_FILTER);
            params.add(campaignId);
        }
        if (schoolUid != null && !schoolUid.isEmpty()) {
            where.append(SCHOOL_FILTER);
            params.add(schoolUid);
        }
    }

    private long count(String sql) {
        return count(sql, null);
    }

    private long count(String sql, List<Object> params) {
        Long result;
        if (params == null || params.isEmpty()) {
            result = jdbc.queryForObject(sql, Long.class);
        } else {
            result = jdbc.queryForObject(sql, Long.class, params.toArray());
        }
        return result == null ? 0L : result;
    }

    private List<Map<String, Object>> queryForListWithParams(String sql, List<Object> params) {
        if (params == null || params.isEmpty()) {
            return jdbc.queryForList(sql);
        }
        return jdbc.queryForList(sql, params.toArray());
    }
}