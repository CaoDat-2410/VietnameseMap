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
                Map.of("Summary", "not-a-base64-image")
        );

        assertThat(pdf).startsWith("%PDF".getBytes()).hasSizeGreaterThan(500);
    }

    @Test
    void rendersTheConvenienceOverloadWithNoSections() {
        byte[] pdf = renderer.render("Empty report", Map.of());

        assertThat(pdf).startsWith("%PDF".getBytes()).hasSizeGreaterThan(100);
    }
}
