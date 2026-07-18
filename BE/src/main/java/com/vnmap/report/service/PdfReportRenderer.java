package com.vnmap.report.service;

import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.Image;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.ColumnText;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfPageEventHelper;
import com.lowagie.text.pdf.PdfWriter;
import org.springframework.stereotype.Component;

import javax.imageio.ImageIO;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/** Renders concise, print-friendly, data-derived executive reports. */
@Component
public class PdfReportRenderer {
    private static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final String CHARTS_AND_TABLES = "CHARTS_AND_TABLES";
    private static final String CHARTS_ONLY = "CHARTS_ONLY";
    private static final String TABLES_ONLY = "TABLES_ONLY";
    private static final int MAX_APPENDIX_ROWS = 20;
    private static final int MAX_APPENDIX_COLUMNS = 6;
    private static final Color INK = new Color(30, 41, 59);
    private static final Color MUTED = new Color(71, 85, 105);
    private static final Color ACCENT = new Color(37, 99, 235);
    private static final Color ACCENT_SOFT = new Color(239, 246, 255);
    private static final Color BORDER = new Color(203, 213, 225);
    private static final Color ROW_ALT = new Color(248, 250, 252);
    private static final Color[] PALETTE = {
            new Color(37, 99, 235),
            new Color(5, 150, 105),
            new Color(217, 119, 6),
            new Color(124, 58, 237),
            new Color(220, 38, 38),
            new Color(8, 145, 178)
    };

    private final BaseFont regularBaseFont = loadBaseFont(false);
    private final BaseFont boldBaseFont = loadBaseFont(true);
    private final Font titleFont = font(true, 22, INK);
    private final Font subtitleFont = font(false, 9, MUTED);
    private final Font sectionFont = font(true, 13, INK);
    private final Font chartTitleFont = font(true, 11, INK);
    private final Font bodyFont = font(false, 8.5f, INK);
    private final Font mutedFont = font(false, 8, MUTED);
    private final Font headFont = font(true, 8, Color.WHITE);
    private final Font appendixHeadFont = font(true, 7.5f, Color.WHITE);
    private final Font appendixBodyFont = font(false, 7.2f, INK);
    private final Font kpiLabelFont = font(false, 7.5f, MUTED);
    private final Font kpiValueFont = font(true, 15, INK);
    private final Font accentFont = font(true, 8, ACCENT);

    public byte[] render(
            String title,
            String subtitle,
            List<Map<String, Object>> kpis,
            Map<String, List<Map<String, Object>>> sections,
            List<ReportChart> charts,
            String displayMode
    ) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Document document = new Document(PageSize.A4, 36, 36, 42, 42);
        String safeMode = normalizeMode(displayMode);
        Map<String, List<Map<String, Object>>> safeSections = sections == null ? Map.of() : sections;
        List<ReportChart> safeCharts = charts == null ? List.of() : charts;
        try {
            PdfWriter writer = PdfWriter.getInstance(document, out);
            writer.setPageEvent(new PageNumberEvent());
            document.open();
            addTitlePage(document, title, subtitle, kpis, safeSections, safeCharts, safeMode);
            if (!TABLES_ONLY.equals(safeMode)) {
                addChartPages(document, safeCharts);
            }
            if (!CHARTS_ONLY.equals(safeMode)) {
                addDataOverview(document, safeSections, safeMode);
            }
            if (TABLES_ONLY.equals(safeMode)) {
                addAppendix(document, safeSections);
            }
            document.close();
            return out.toByteArray();
        } catch (DocumentException exception) {
            throw new IllegalStateException("Unable to render PDF report", exception);
        } finally {
            if (document.isOpen()) {
                document.close();
            }
        }
    }

    public byte[] render(String title, Map<String, List<Map<String, Object>>> sections) {
        return render(
                title,
                "Generated at: " + LocalDateTime.now(VIETNAM_ZONE),
                List.of(),
                sections,
                List.of(),
                CHARTS_AND_TABLES
        );
    }

    private void addTitlePage(
            Document document,
            String title,
            String subtitle,
            List<Map<String, Object>> kpis,
            Map<String, List<Map<String, Object>>> sections,
            List<ReportChart> charts,
            String displayMode
    ) throws DocumentException {
        Paragraph reportTitle = new Paragraph(safe(title), titleFont);
        reportTitle.setSpacingAfter(4);
        document.add(reportTitle);

        Paragraph reportSubtitle = new Paragraph(safe(subtitle), subtitleFont);
        reportSubtitle.setSpacingAfter(18);
        document.add(reportSubtitle);

        Paragraph heading = new Paragraph("Executive summary", sectionFont);
        heading.setSpacingAfter(8);
        document.add(heading);
        if (kpis != null && !kpis.isEmpty()) {
            addKpiGrid(document, kpis);
        }

        long matchedRecords = sections.values().stream()
                .filter(java.util.Objects::nonNull)
                .mapToLong(List::size)
                .sum();
        String scope = switch (displayMode) {
            case TABLES_ONLY -> "Compact data appendix: up to " + MAX_APPENDIX_ROWS
                    + " rows and " + MAX_APPENDIX_COLUMNS + " decision-relevant columns per section.";
            case CHARTS_ONLY -> "Visual brief: aggregated charts and findings only; raw records are not embedded.";
            default -> "Executive brief: aggregated charts, key findings, and dataset coverage. Raw records stay in VNMap.";
        };
        addCallout(document, scope + " The selected filters matched " + matchedRecords + " records across "
                + sections.size() + " data sections.", ACCENT_SOFT, bodyFont);

        Paragraph findingsHeading = new Paragraph("Key findings", sectionFont);
        findingsHeading.setSpacingBefore(14);
        findingsHeading.setSpacingAfter(6);
        document.add(findingsHeading);
        if (charts.isEmpty()) {
            document.add(new Paragraph("No chart findings were selected for this export.", mutedFont));
        } else {
            int findingCount = Math.min(charts.size(), 4);
            for (int index = 0; index < findingCount; index++) {
                ReportChart chart = charts.get(index);
                Paragraph finding = new Paragraph(
                        (index + 1) + ". " + chart.title() + ": " + safe(chart.insight()),
                        bodyFont
                );
                finding.setSpacingAfter(5);
                document.add(finding);
            }
        }

        Paragraph readingNote = new Paragraph("Report design", sectionFont);
        readingNote.setSpacingBefore(14);
        readingNote.setSpacingAfter(6);
        document.add(readingNote);
        document.add(new Paragraph(
                "The main PDF is intentionally concise for review and decision-making. Use VNMap filters or a dedicated data export when row-level investigation is required.",
                mutedFont
        ));
    }

    private void addKpiGrid(Document document, List<Map<String, Object>> kpis) throws DocumentException {
        int columns = Math.max(1, Math.min(kpis.size(), 4));
        PdfPTable table = new PdfPTable(columns);
        table.setWidthPercentage(100);
        table.setSpacingAfter(6);
        for (Map<String, Object> kpi : kpis) {
            PdfPCell cell = new PdfPCell();
            cell.setPadding(9);
            cell.setBackgroundColor(ROW_ALT);
            cell.setBorderColor(BORDER);
            cell.addElement(new Paragraph(safe(kpi.get("label")), kpiLabelFont));
            cell.addElement(new Paragraph(safe(kpi.get("value")), kpiValueFont));
            table.addCell(cell);
        }
        document.add(table);
    }

    private void addChartPages(Document document, List<ReportChart> charts) throws DocumentException {
        for (int index = 0; index < charts.size(); index++) {
            if (index % 2 == 0) {
                document.newPage();
                Paragraph heading = new Paragraph("Performance overview", sectionFont);
                heading.setSpacingAfter(8);
                document.add(heading);
            }
            addChartBlock(document, charts.get(index), index + 1);
        }
    }

    private void addChartBlock(Document document, ReportChart chart, int figureNumber) throws DocumentException {
        Paragraph label = new Paragraph("FIGURE " + figureNumber, accentFont);
        label.setSpacingBefore(2);
        label.setSpacingAfter(1);
        document.add(label);

        Paragraph title = new Paragraph(chart.title(), chartTitleFont);
        title.setSpacingAfter(2);
        document.add(title);
        document.add(new Paragraph(chart.description(), mutedFont));
        document.add(new Paragraph(
                "Unit: " + safe(chart.unit()) + "  |  Period: " + safe(chart.period())
                        + "  |  Source: " + safe(chart.dataSource()),
                mutedFont
        ));
        addCallout(document, "Insight: " + safe(chart.insight()), ACCENT_SOFT, bodyFont);

        if (!chart.hasData()) {
            Paragraph empty = new Paragraph("No matching data is available for this chart.", mutedFont);
            empty.setSpacingBefore(10);
            empty.setSpacingAfter(14);
            document.add(empty);
            return;
        }
        try {
            Image image = Image.getInstance(drawChart(chart));
            float maxWidth = document.getPageSize().getWidth() - document.leftMargin() - document.rightMargin();
            image.scaleToFit(maxWidth, 190);
            image.setAlignment(Element.ALIGN_CENTER);
            document.add(image);
        } catch (IOException | DocumentException exception) {
            throw new IllegalStateException("Unable to draw chart " + chart.id(), exception);
        }
        Paragraph spacer = new Paragraph(" ");
        spacer.setSpacingAfter(5);
        document.add(spacer);
    }

    private void addDataOverview(
            Document document,
            Map<String, List<Map<String, Object>>> sections,
            String displayMode
    ) throws DocumentException {
        document.newPage();
        Paragraph heading = new Paragraph("Data coverage", sectionFont);
        heading.setSpacingAfter(4);
        document.add(heading);
        document.add(new Paragraph(
                TABLES_ONLY.equals(displayMode)
                        ? "The appendix is bounded to keep the PDF readable. Counts below reflect all matching records; appendix rows are samples."
                        : "Counts reflect all records matching the selected filters. The executive PDF keeps detail data in the system to avoid duplicating long operational tables.",
                mutedFont
        ));

        PdfPTable table = new PdfPTable(3);
        table.setWidthPercentage(100);
        table.setSpacingBefore(12);
        table.setWidths(new float[]{2.2f, 1.1f, 3.7f});
        addHeaderCell(table, "Data section");
        addHeaderCell(table, "Matched");
        addHeaderCell(table, "PDF treatment");

        int rowIndex = 0;
        for (Map.Entry<String, List<Map<String, Object>>> entry : sections.entrySet()) {
            List<Map<String, Object>> rows = entry.getValue() == null ? List.of() : entry.getValue();
            Color background = rowIndex++ % 2 == 1 ? ROW_ALT : Color.WHITE;
            addBodyCell(table, humanize(entry.getKey()), bodyFont, background);
            addBodyCell(table, String.valueOf(rows.size()), bodyFont, background);
            String treatment = TABLES_ONLY.equals(displayMode)
                    ? "Up to " + Math.min(rows.size(), MAX_APPENDIX_ROWS) + " representative rows"
                    : "Aggregated into KPIs, findings, or charts";
            addBodyCell(table, treatment, bodyFont, background);
        }
        document.add(table);
        addCallout(
                document,
                "Need every row? Apply narrower filters in VNMap or use a dedicated CSV/data export. A decision report should not duplicate the operational database.",
                ROW_ALT,
                bodyFont
        );
    }

    private void addAppendix(Document document, Map<String, List<Map<String, Object>>> sections)
            throws DocumentException {
        for (Map.Entry<String, List<Map<String, Object>>> entry : sections.entrySet()) {
            List<Map<String, Object>> rows = entry.getValue();
            if (rows == null || rows.isEmpty()) {
                continue;
            }
            document.newPage();
            addAppendixSection(document, entry.getKey(), rows);
        }
    }

    private void addAppendixSection(Document document, String name, List<Map<String, Object>> rows)
            throws DocumentException {
        Paragraph heading = new Paragraph("Appendix: " + humanize(name), sectionFont);
        heading.setSpacingAfter(4);
        document.add(heading);
        int shownRows = Math.min(rows.size(), MAX_APPENDIX_ROWS);
        document.add(new Paragraph(
                "Showing " + shownRows + " of " + rows.size() + " matching records and at most "
                        + MAX_APPENDIX_COLUMNS + " decision-relevant columns.",
                mutedFont
        ));

        List<String> columns = selectColumns(rows.get(0));
        PdfPTable table = new PdfPTable(columns.size());
        table.setWidthPercentage(100);
        table.setSpacingBefore(10);
        table.setHeaderRows(1);
        table.setSplitLate(false);
        table.setSplitRows(true);
        for (String column : columns) {
            PdfPCell header = new PdfPCell(new Phrase(humanize(column), appendixHeadFont));
            header.setPadding(4);
            header.setBackgroundColor(INK);
            header.setBorderColor(BORDER);
            table.addCell(header);
        }
        for (int rowIndex = 0; rowIndex < shownRows; rowIndex++) {
            Map<String, Object> row = rows.get(rowIndex);
            Color background = rowIndex % 2 == 1 ? ROW_ALT : Color.WHITE;
            for (String column : columns) {
                addBodyCell(table, compactValue(row.get(column)), appendixBodyFont, background);
            }
        }
        document.add(table);
        if (rows.size() > shownRows) {
            addCallout(
                    document,
                    (rows.size() - shownRows) + " additional records were intentionally omitted from this PDF.",
                    ACCENT_SOFT,
                    bodyFont
            );
        }
    }

    private List<String> selectColumns(Map<String, Object> firstRow) {
        Map<String, Integer> priority = new LinkedHashMap<>();
        List<String> preferred = List.of(
                "name", "title", "status", "province_name", "school_name", "event_type",
                "starts_at", "date", "outcome", "channel", "registrations", "interactions", "id"
        );
        for (int index = 0; index < preferred.size(); index++) {
            priority.put(preferred.get(index), index);
        }
        return firstRow.keySet().stream()
                .sorted(Comparator.comparingInt(column -> priority.getOrDefault(column.toLowerCase(Locale.ROOT), 100)))
                .limit(MAX_APPENDIX_COLUMNS)
                .toList();
    }

    private void addCallout(Document document, String text, Color background, Font font)
            throws DocumentException {
        PdfPTable callout = new PdfPTable(1);
        callout.setWidthPercentage(100);
        callout.setSpacingBefore(6);
        callout.setSpacingAfter(6);
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setPadding(7);
        cell.setBackgroundColor(background);
        cell.setBorderColor(BORDER);
        callout.addCell(cell);
        document.add(callout);
    }

    private void addHeaderCell(PdfPTable table, String text) {
        PdfPCell cell = new PdfPCell(new Phrase(text, headFont));
        cell.setPadding(6);
        cell.setBackgroundColor(INK);
        cell.setBorderColor(BORDER);
        table.addCell(cell);
    }

    private void addBodyCell(PdfPTable table, String text, Font font, Color background) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setPadding(5);
        cell.setBackgroundColor(background);
        cell.setBorderColor(BORDER);
        table.addCell(cell);
    }

    private byte[] drawChart(ReportChart chart) throws IOException {
        BufferedImage image = new BufferedImage(1100, 440, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = image.createGraphics();
        graphics.setColor(Color.WHITE);
        graphics.fillRect(0, 0, image.getWidth(), image.getHeight());
        graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        List<ReportChart.Datum> visibleData = chart.data().stream()
                .filter(datum -> datum.value() > 0)
                .toList();
        if (visibleData.isEmpty()) {
            visibleData = chart.data();
        }
        if ("DONUT".equals(chart.chartType())) {
            drawDonut(graphics, visibleData);
        } else if ("LINE".equals(chart.chartType()) && visibleData.size() == 1) {
            drawSinglePoint(graphics, visibleData.get(0));
        } else if ("LINE".equals(chart.chartType())) {
            drawLine(graphics, visibleData);
        } else {
            drawBars(graphics, visibleData);
        }
        graphics.dispose();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "png", out);
        return out.toByteArray();
    }

    private void drawBars(Graphics2D graphics, List<ReportChart.Datum> data) {
        if (data.size() >= 7) {
            drawHorizontalBars(graphics, data);
            return;
        }
        int left = 90;
        int top = 28;
        int width = 930;
        int height = 315;
        long max = Math.max(1, data.stream().mapToLong(ReportChart.Datum::value).max().orElse(1));
        graphics.setColor(new Color(148, 163, 184));
        graphics.drawLine(left, top + height, left + width, top + height);
        for (int index = 0; index < data.size(); index++) {
            int slotWidth = width / data.size();
            int barWidth = Math.max(24, width / Math.max(data.size() * 2, 1));
            int x = left + (index * slotWidth) + Math.max(8, (slotWidth - barWidth) / 2);
            int barHeight = (int) (data.get(index).value() * (height - 30) / max);
            graphics.setColor(PALETTE[index % PALETTE.length]);
            graphics.fillRoundRect(x, top + height - barHeight, barWidth, barHeight, 8, 8);
            graphics.setColor(INK);
            graphics.drawString(String.valueOf(data.get(index).value()), x, top + height - barHeight - 8);
            graphics.drawString(shortLabel(data.get(index).label()), x, top + height + 24);
        }
    }

    private void drawHorizontalBars(Graphics2D graphics, List<ReportChart.Datum> data) {
        int left = 285;
        int top = 18;
        int width = 715;
        int height = 365;
        int rowHeight = Math.max(30, height / data.size());
        int barHeight = Math.min(24, rowHeight - 7);
        long max = Math.max(1, data.stream().mapToLong(ReportChart.Datum::value).max().orElse(1));
        graphics.setFont(graphics.getFont().deriveFont(java.awt.Font.PLAIN, 15f));
        for (int index = 0; index < data.size(); index++) {
            ReportChart.Datum datum = data.get(index);
            int y = top + index * rowHeight + Math.max(2, (rowHeight - barHeight) / 2);
            String label = horizontalLabel(datum.label());
            graphics.setColor(INK);
            graphics.drawString(label, 22, y + barHeight - 5);
            int barWidth = Math.max(3, (int) (datum.value() * width / max));
            graphics.setColor(PALETTE[index % PALETTE.length]);
            graphics.fillRoundRect(left, y, barWidth, barHeight, 8, 8);
            graphics.setColor(INK);
            graphics.drawString(String.valueOf(datum.value()), Math.min(left + barWidth + 10, 1045), y + barHeight - 5);
        }
    }
    private void drawLine(Graphics2D graphics, List<ReportChart.Datum> data) {
        int left = 90;
        int top = 28;
        int width = 930;
        int height = 315;
        long max = Math.max(1, data.stream().mapToLong(ReportChart.Datum::value).max().orElse(1));
        graphics.setColor(new Color(148, 163, 184));
        graphics.drawLine(left, top + height, left + width, top + height);
        graphics.setColor(PALETTE[0]);
        graphics.setStroke(new BasicStroke(3));
        for (int index = 0; index < data.size(); index++) {
            int x = data.size() == 1 ? left + width / 2 : left + index * width / (data.size() - 1);
            int y = top + height - (int) (data.get(index).value() * (height - 30) / max);
            if (index > 0) {
                int previousX = left + (index - 1) * width / (data.size() - 1);
                int previousY = top + height
                        - (int) (data.get(index - 1).value() * (height - 30) / max);
                graphics.drawLine(previousX, previousY, x, y);
            }
            graphics.fillOval(x - 5, y - 5, 10, 10);
            graphics.setColor(INK);
            graphics.drawString(shortLabel(data.get(index).label()), x - 18, top + height + 24);
            graphics.setColor(PALETTE[0]);
        }
    }

    private void drawSinglePoint(Graphics2D graphics, ReportChart.Datum datum) {
        int cardX = 320;
        int cardY = 55;
        int cardWidth = 460;
        int cardHeight = 265;
        graphics.setColor(ACCENT_SOFT);
        graphics.fillRoundRect(cardX, cardY, cardWidth, cardHeight, 28, 28);

        String value = String.valueOf(datum.value());
        graphics.setColor(ACCENT);
        graphics.setFont(graphics.getFont().deriveFont(java.awt.Font.BOLD, 68f));
        int valueX = cardX + (cardWidth - graphics.getFontMetrics().stringWidth(value)) / 2;
        graphics.drawString(value, valueX, cardY + 125);

        String label = shortLabel(datum.label());
        graphics.setColor(INK);
        graphics.setFont(graphics.getFont().deriveFont(java.awt.Font.BOLD, 22f));
        int labelX = cardX + (cardWidth - graphics.getFontMetrics().stringWidth(label)) / 2;
        graphics.drawString(label, labelX, cardY + 178);

        String note = "Single data point in selected period";
        graphics.setColor(new Color(71, 85, 105));
        graphics.setFont(graphics.getFont().deriveFont(java.awt.Font.PLAIN, 17f));
        int noteX = cardX + (cardWidth - graphics.getFontMetrics().stringWidth(note)) / 2;
        graphics.drawString(note, noteX, cardY + 220);
    }
    private void drawDonut(Graphics2D graphics, List<ReportChart.Datum> data) {
        long total = Math.max(1, data.stream().mapToLong(ReportChart.Datum::value).sum());
        int start = 0;
        for (int index = 0; index < data.size(); index++) {
            int arc = (int) Math.round(data.get(index).value() * 360d / total);
            graphics.setColor(PALETTE[index % PALETTE.length]);
            graphics.fillArc(110, 28, 330, 330, start, arc);
            start += arc;
            graphics.fillRect(545, 55 + index * 45, 20, 20);
            graphics.setColor(INK);
            graphics.drawString(
                    shortLabel(data.get(index).label()) + " - " + data.get(index).value(),
                    580,
                    71 + index * 45
            );
        }
        graphics.setColor(Color.WHITE);
        graphics.fillOval(203, 121, 144, 144);
        graphics.setColor(INK);
        graphics.drawString("Total", 250, 181);
        graphics.drawString(String.valueOf(total), 250, 207);
    }

    private BaseFont loadBaseFont(boolean bold) {
        String[] candidates = {
                environmentFont(bold),
                bold ? "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf" : "/usr/share/fonts/dejavu/DejaVuSans.ttf",
                bold ? "C:/Windows/Fonts/arialbd.ttf" : "C:/Windows/Fonts/arial.ttf"
        };
        for (String candidate : candidates) {
            if (candidate == null || candidate.isBlank() || !Files.isRegularFile(Path.of(candidate))) {
                continue;
            }
            try {
                return BaseFont.createFont(candidate, BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
            } catch (DocumentException | IOException ignored) {
                // Try the next deterministic platform font.
            }
        }
        try {
            return BaseFont.createFont(
                    bold ? BaseFont.HELVETICA_BOLD : BaseFont.HELVETICA,
                    BaseFont.CP1252,
                    BaseFont.NOT_EMBEDDED
            );
        } catch (DocumentException | IOException exception) {
            throw new IllegalStateException("Unable to initialize PDF font", exception);
        }
    }

    private String environmentFont(boolean bold) {
        return System.getenv(bold ? "REPORT_BOLD_FONT_PATH" : "REPORT_FONT_PATH");
    }

    private Font font(boolean bold, float size, Color color) {
        return new Font(bold ? boldBaseFont : regularBaseFont, size, Font.NORMAL, color);
    }

    private String normalizeMode(String displayMode) {
        if (displayMode == null) {
            return CHARTS_AND_TABLES;
        }
        return switch (displayMode.toUpperCase(Locale.ROOT)) {
            case CHARTS_ONLY, TABLES_ONLY, CHARTS_AND_TABLES -> displayMode.toUpperCase(Locale.ROOT);
            default -> CHARTS_AND_TABLES;
        };
    }

    private String humanize(String value) {
        if (value == null || value.isBlank()) {
            return "Data";
        }
        String normalized = value.replace('_', ' ').trim();
        return normalized.substring(0, 1).toUpperCase(Locale.ROOT) + normalized.substring(1);
    }

    private String compactValue(Object value) {
        String text = safe(value).replace('\n', ' ').replace('\r', ' ').trim();
        return text.length() <= 48 ? text : text.substring(0, 45) + "...";
    }

    private String horizontalLabel(String value) {
        if (value == null) {
            return "";
        }
        return value.length() <= 28 ? value : value.substring(0, 25) + "...";
    }
    private String shortLabel(String value) {
        if (value == null) {
            return "";
        }
        return value.length() <= 16 ? value : value.substring(0, 13) + "...";
    }

    private String safe(Object value) {
        return value == null ? "" : String.valueOf(value);
    }

    private final class PageNumberEvent extends PdfPageEventHelper {
        @Override
        public void onEndPage(PdfWriter writer, Document document) {
            ColumnText.showTextAligned(
                    writer.getDirectContent(),
                    Element.ALIGN_CENTER,
                    new Phrase("VNMap  |  Page " + writer.getPageNumber(), mutedFont),
                    (document.right() + document.left()) / 2,
                    20,
                    0
            );
        }
    }
}