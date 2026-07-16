package com.vnmap.report.service;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class PdfReportRendererTest {
    private final PdfReportRenderer renderer = new PdfReportRenderer();

    @Test
    void rendersKpisRowsAndAnInvalidChartWithoutFailingTheExport() {
        Map<String, List<Map<String, Object>>> sections = new LinkedHashMap<>();
        sections.put("Summary", List.of(
                Map.of("School", "THPT A", "Count", 2),
                Map.of("School", "THPT B", "Count", 0)
        ));
        sections.put("Empty", List.of());

        byte[] pdf = renderer.render(
                "Campaign report", "For verification",
                List.of(Map.of("label", "Events", "value", 3), Map.of("label", "Missing")),
                sections,
                List.of(),
                "CHARTS_AND_TABLES"
        );

        assertThat(pdf).startsWith("%PDF".getBytes()).hasSizeGreaterThan(500);
    }

    @Test
    void rendersTheConvenienceOverloadWithNoSections() {
        byte[] pdf = renderer.render("Empty report", Map.of());

        assertThat(pdf).startsWith("%PDF".getBytes()).hasSizeGreaterThan(100);
    }
    @Test
    void rendersDataDerivedDonutBarLineAndEmptyChartStates() {
        List<ReportChart> charts = List.of(
                new ReportChart("status", "Status", "By status", "DONUT", "count", "2026", "campaigns", "ACTIVE leads", List.of(new ReportChart.Datum("ACTIVE", 4), new ReportChart.Datum("DRAFT", 2))),
                new ReportChart("events", "Events", "By campaign", "BAR", "count", "2026", "events", "Campaign A leads", List.of(new ReportChart.Datum("Campaign A", 3), new ReportChart.Datum("Campaign B", 1))),
                new ReportChart("trend", "Trend", "Daily", "LINE", "count", "2026", "interactions", "Day one leads", List.of(new ReportChart.Datum("2026-01-01", 1), new ReportChart.Datum("2026-01-02", 2))),
                new ReportChart("empty", "Empty", "No records", "BAR", "count", "2026", "events", "No records", List.of())
        );
        byte[] pdf = renderer.render("Verified report", "summary", List.of(), Map.of(), charts, "CHARTS_AND_TABLES");
        assertThat(pdf).startsWith("%PDF".getBytes()).hasSizeGreaterThan(10_000);
    }
}
