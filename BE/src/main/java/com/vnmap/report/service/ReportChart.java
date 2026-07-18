package com.vnmap.report.service;

import java.util.List;

/** A chart derived from the selected report data, never from synthetic values. */
public record ReportChart(
        String id,
        String title,
        String description,
        String chartType,
        String unit,
        String period,
        String dataSource,
        String insight,
        List<Datum> data
) {
    public record Datum(String label, long value) { }

    public boolean hasData() {
        return data != null && !data.isEmpty() && data.stream().anyMatch(item -> item.value() > 0);
    }
}
