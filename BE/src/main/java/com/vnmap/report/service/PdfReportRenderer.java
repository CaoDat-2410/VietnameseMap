package com.vnmap.report.service;

import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Image;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
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
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Renders print-friendly, data-derived charts and their audit metadata. */
@Component
public class PdfReportRenderer {
    private static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final String CHARTS_AND_TABLES = "CHARTS_AND_TABLES";
    private static final Color[] PALETTE = { new Color(37, 99, 235), new Color(5, 150, 105), new Color(217, 119, 6), new Color(124, 58, 237), new Color(220, 38, 38), new Color(8, 145, 178) };
    private final Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
    private final Font subtitleFont = FontFactory.getFont(FontFactory.HELVETICA, 10);
    private final Font sectionFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12);
    private final Font bodyFont = FontFactory.getFont(FontFactory.HELVETICA, 9);
    private final Font headFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9);
    private final Font kpiLabelFont = FontFactory.getFont(FontFactory.HELVETICA, 8);
    private final Font kpiValueFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 14);

    public byte[] render(String title, String subtitle, List<Map<String, Object>> kpis, Map<String, List<Map<String, Object>>> sections, List<ReportChart> charts, String displayMode) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Document document = new Document(PageSize.A4, 36, 36, 48, 48);
        try {
            PdfWriter.getInstance(document, out);
            document.open();
            addTitlePage(document, title, subtitle, kpis, charts);
            if (!"TABLES_ONLY".equals(displayMode)) for (ReportChart chart : charts) { document.newPage(); addChartPage(document, chart); }
            if (!"CHARTS_ONLY".equals(displayMode)) for (Map.Entry<String, List<Map<String, Object>>> entry : sections.entrySet()) { document.newPage(); addSection(document, entry.getKey(), entry.getValue()); }
            document.close();
            return out.toByteArray();
        } catch (DocumentException e) {
            throw new IllegalStateException("Unable to render PDF report", e);
        } finally { if (document.isOpen()) document.close(); }
    }


    public byte[] render(String title, Map<String, List<Map<String, Object>>> sections) {
        return render(title, "Generated at: " + LocalDateTime.now(VIETNAM_ZONE), List.of(), sections, List.of(), CHARTS_AND_TABLES);
    }

    private void addTitlePage(Document document, String title, String subtitle, List<Map<String, Object>> kpis, List<ReportChart> charts) throws DocumentException {
        document.add(new Paragraph(title, titleFont));
        document.add(new Paragraph(subtitle == null ? "" : subtitle, subtitleFont));
        document.add(new Paragraph("Executive summary", sectionFont));
        if (kpis != null && !kpis.isEmpty()) addKpiGrid(document, kpis);
        document.add(new Paragraph("This report contains " + charts.size() + " selected, data-derived charts. Each chart lists its source, period, unit, insight, and data table.", bodyFont));
    }
    private void addKpiGrid(Document document, List<Map<String, Object>> kpis) throws DocumentException {
        PdfPTable table = new PdfPTable(Math.clamp(kpis.size(), 1, 4));
        table.setWidthPercentage(100);
        for (Map<String, Object> kpi : kpis) {
            PdfPCell cell = new PdfPCell();
            cell.setPadding(8);
            cell.addElement(new Paragraph(safe(kpi.get("label")), kpiLabelFont));
            cell.addElement(new Paragraph(safe(kpi.get("value")), kpiValueFont));
            table.addCell(cell);
        }
        document.add(table);
        document.add(new Paragraph(" "));
    }
    private void addChartPage(Document document, ReportChart chart) throws DocumentException {
        document.add(new Paragraph(chart.title(), sectionFont));
        document.add(new Paragraph(chart.description(), bodyFont));
        document.add(new Paragraph("Unit: " + chart.unit() + " | Period: " + chart.period(), bodyFont));
        document.add(new Paragraph("Data source: " + chart.dataSource(), bodyFont));
        document.add(new Paragraph("Insight: " + chart.insight(), bodyFont)); document.add(new Paragraph(" "));
        if (!chart.hasData()) { document.add(new Paragraph("Khong co du du lieu de tao bieu do trong khoang thoi gian da chon.", bodyFont)); return; }
        try {
            Image image = Image.getInstance(drawChart(chart));
            float maxWidth = document.getPageSize().getWidth() - document.leftMargin() - document.rightMargin();
            image.scaleToFit(maxWidth, 285);
            image.setAlignment(Element.ALIGN_CENTER);
            document.add(image);
        } catch (IOException | DocumentException exception) {
            throw new IllegalStateException("Unable to draw chart " + chart.id(), exception);
        }
        document.add(new Paragraph(" "));
        PdfPTable dataTable = new PdfPTable(2); dataTable.setWidthPercentage(100);
        dataTable.addCell(new PdfPCell(new Phrase("Label", headFont))); dataTable.addCell(new PdfPCell(new Phrase(chart.unit(), headFont)));
        for (ReportChart.Datum datum : chart.data()) { dataTable.addCell(new Phrase(datum.label(), bodyFont)); dataTable.addCell(new Phrase(String.valueOf(datum.value()), bodyFont)); }
        document.add(dataTable);
    }
    private void addSection(Document document, String name, List<Map<String, Object>> rows) throws DocumentException {
        document.add(new Paragraph(name.toUpperCase(), sectionFont));
        if (rows == null || rows.isEmpty()) { document.add(new Paragraph("No data for the selected filters.", bodyFont)); return; }
        List<String> columns = new ArrayList<>(rows.get(0).keySet());
        PdfPTable table = new PdfPTable(columns.size());
        table.setWidthPercentage(100);
        for (String column : columns) table.addCell(new PdfPCell(new Phrase(column, headFont)));
        for (Map<String, Object> row : rows) for (String column : columns) table.addCell(new Phrase(safe(row.get(column)), bodyFont));
        document.add(table);
    }
    private byte[] drawChart(ReportChart chart) throws IOException {
        BufferedImage image = new BufferedImage(1100, 520, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = image.createGraphics();
        graphics.setColor(Color.WHITE);
        graphics.fillRect(0, 0, image.getWidth(), image.getHeight());
        graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        if ("DONUT".equals(chart.chartType())) {
            drawDonut(graphics, chart.data());
        } else if ("LINE".equals(chart.chartType())) {
            drawLine(graphics, chart.data());
        } else {
            drawBars(graphics, chart.data());
        }
        graphics.dispose();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "png", out);
        return out.toByteArray();
    }
    private void drawBars(Graphics2D g, List<ReportChart.Datum> data) {
        int left = 90;
        int top = 40;
        int width = 930;
        int height = 370;
        long max = Math.max(1, data.stream().mapToLong(ReportChart.Datum::value).max().orElse(1));
        g.setColor(new Color(148, 163, 184));
        g.drawLine(left, top + height, left + width, top + height);
        for (int i = 0; i < data.size(); i++) {
            int slotWidth = width / data.size();
            int barWidth = Math.max(24, width / Math.max(data.size() * 2, 1));
            int x = left + (i * slotWidth) + Math.max(8, (slotWidth - barWidth) / 2);
            int barHeight = (int) (data.get(i).value() * (height - 30) / max);
            g.setColor(PALETTE[i % PALETTE.length]);
            g.fillRoundRect(x, top + height - barHeight, barWidth, barHeight, 8, 8);
            g.setColor(new Color(30, 41, 59));
            g.drawString(String.valueOf(data.get(i).value()), x, top + height - barHeight - 8);
            g.drawString(shortLabel(data.get(i).label()), x, top + height + 24);
        }
    }    private void drawLine(Graphics2D g, List<ReportChart.Datum> data) {
        int left = 90;
        int top = 40;
        int width = 930;
        int height = 370;
        long max = Math.max(1, data.stream().mapToLong(ReportChart.Datum::value).max().orElse(1));
        g.setColor(new Color(148, 163, 184));
        g.drawLine(left, top + height, left + width, top + height);
        g.setColor(PALETTE[0]);
        g.setStroke(new BasicStroke(3));
        for (int i = 0; i < data.size(); i++) {
            int x = data.size() == 1 ? left + width / 2 : left + i * width / (data.size() - 1);
            int y = top + height - (int) (data.get(i).value() * (height - 30) / max);
            if (i > 0) {
                int previousX = left + (i - 1) * width / (data.size() - 1);
                int previousY = top + height - (int) (data.get(i - 1).value() * (height - 30) / max);
                g.drawLine(previousX, previousY, x, y);
            }
            g.fillOval(x - 5, y - 5, 10, 10);
            g.setColor(new Color(30, 41, 59));
            g.drawString(shortLabel(data.get(i).label()), x - 18, top + height + 24);
            g.setColor(PALETTE[0]);
        }
    }    private void drawDonut(Graphics2D g, List<ReportChart.Datum> data) {
        long total = Math.max(1, data.stream().mapToLong(ReportChart.Datum::value).sum());
        int start = 0;
        for (int i = 0; i < data.size(); i++) {
            int arc = (int) Math.round(data.get(i).value() * 360d / total);
            g.setColor(PALETTE[i % PALETTE.length]);
            g.fillArc(110, 55, 370, 370, start, arc);
            start += arc;
            g.fillRect(570, 80 + i * 52, 22, 22);
            g.setColor(new Color(30, 41, 59));
            g.drawString(shortLabel(data.get(i).label()) + " - " + data.get(i).value(), 605, 98 + i * 52);
        }
        g.setColor(Color.WHITE);
        g.fillOval(215, 160, 160, 160);
        g.setColor(new Color(30, 41, 59));
        g.drawString("Total", 265, 226);
        g.drawString(String.valueOf(total), 265, 252);
    }    private String shortLabel(String value) {
        if (value == null) return "";
        return value.length() <= 16 ? value : value.substring(0, 13) + "...";
    }
    private String safe(Object value) { return value == null ? "" : String.valueOf(value); }
}