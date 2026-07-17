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

import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Base64;
import java.util.List;
import java.util.Map;

@Component
public class PdfReportRenderer {

    private static final ZoneId VIETNAM_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");

    private final Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
    private final Font subtitleFont = FontFactory.getFont(FontFactory.HELVETICA, 10);
    private final Font sectionFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12);
    private final Font bodyFont = FontFactory.getFont(FontFactory.HELVETICA, 9);
    private final Font headFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9);
    private final Font kpiLabelFont = FontFactory.getFont(FontFactory.HELVETICA, 8);
    private final Font kpiValueFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 14);

    public byte[] render(String title,
                         String subtitle,
                         List<Map<String, Object>> kpis,
                         Map<String, List<Map<String, Object>>> sections,
                         Map<String, String> chartImagesBySection) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Document document = new Document(PageSize.A4, 36, 36, 48, 48);
        try {
            PdfWriter.getInstance(document, out);
            document.open();
            addTitlePage(document, title, subtitle, kpis);
            for (Map.Entry<String, List<Map<String, Object>>> entry : sections.entrySet()) {
                document.newPage();
                String name = entry.getKey();
                List<Map<String, Object>> rows = entry.getValue();
                String chart = chartImagesBySection == null ? null : chartImagesBySection.get(name);
                addSection(document, name, rows, chart);
            }
            document.close();
            return out.toByteArray();
        } catch (DocumentException e) {
            throw new IllegalStateException("Unable to render PDF report", e);
        } finally {
            if (document.isOpen()) {
                document.close();
            }
        }
    }

    public byte[] render(String title, Map<String, List<Map<String, Object>>> sections) {
        return render(title, "Generated at: " + LocalDateTime.now(VIETNAM_ZONE), List.of(), sections, Map.of());
    }

    private void addTitlePage(Document document, String title, String subtitle, List<Map<String, Object>> kpis)
            throws DocumentException {
        Paragraph titleParagraph = new Paragraph(title, titleFont);
        titleParagraph.setAlignment(Element.ALIGN_LEFT);
        document.add(titleParagraph);
        document.add(new Paragraph(subtitle == null ? "" : subtitle, subtitleFont));
        document.add(new Paragraph(" "));
        if (kpis != null && !kpis.isEmpty()) {
            addKpiGrid(document, kpis);
            document.add(new Paragraph(" "));
        }
    }

    private void addKpiGrid(Document document, List<Map<String, Object>> kpis) throws DocumentException {
        int cols = Math.min(4, Math.max(1, kpis.size()));
        PdfPTable table = new PdfPTable(cols);
        table.setWidthPercentage(100);
        for (Map<String, Object> kpi : kpis) {
            PdfPCell cell = new PdfPCell();
            cell.setPadding(8);
            Paragraph label = new Paragraph(safe(kpi.get("label")), kpiLabelFont);
            Object rawValue = kpi.get("value");
            String valueText = rawValue == null ? "0" : String.valueOf(rawValue);
            Paragraph value = new Paragraph(valueText, kpiValueFont);
            cell.addElement(label);
            cell.addElement(value);
            table.addCell(cell);
        }
        document.add(table);
    }

    private void addSection(Document document, String name, List<Map<String, Object>> rows, String chartBase64)
            throws DocumentException {
        Paragraph sectionTitle = new Paragraph(name.toUpperCase(), sectionFont);
        sectionTitle.setSpacingAfter(6f);
        document.add(sectionTitle);
        if (chartBase64 != null && !chartBase64.isBlank()) {
            try {
                byte[] decoded = Base64.getDecoder().decode(chartBase64);
                Image img = Image.getInstance(decoded);
                float maxWidth = document.getPageSize().getWidth() - document.leftMargin() - document.rightMargin();
                if (img.getScaledWidth() > maxWidth) {
                    img.scaleToFit(maxWidth, 240);
                }
                img.setAlignment(Element.ALIGN_CENTER);
                document.add(img);
                document.add(new Paragraph(" "));
            } catch (Exception e) {
                document.add(new Paragraph("(chart image could not be embedded)", bodyFont));
            }
        }
        if (rows == null || rows.isEmpty()) {
            document.add(new Paragraph("No data", bodyFont));
            return;
        }
        List<String> columns = rows.get(0).keySet().stream().toList();
        PdfPTable table = new PdfPTable(columns.size());
        table.setWidthPercentage(100);
        for (String column : columns) {
            PdfPCell cell = new PdfPCell(new Phrase(column, headFont));
            table.addCell(cell);
        }
        for (Map<String, Object> row : rows) {
            for (String column : columns) {
                Object value = row.get(column);
                table.addCell(new Phrase(value == null ? "" : String.valueOf(value), bodyFont));
            }
        }
        document.add(table);
    }

    private String safe(Object value) {
        return value == null ? "" : String.valueOf(value);
    }
}