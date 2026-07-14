package com.vnmap.campaign.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vnmap.campaign.dto.SchoolGeocodeDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Service to geocode schools on-demand using OpenStreetMap Nominatim API.
 * Does NOT persist results to the database — coordinates are returned for the
 * current request only.
 */
@Service
public class OsmGeocodingService {

    private static final Logger log = LoggerFactory.getLogger(OsmGeocodingService.class);
    private static final String NOMINATIM_SEARCH_PATH = "/search";

    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;
    private final JdbcTemplate jdbc;

    @Value("${nominatim.base-url:https://nominatim.openstreetmap.org}")
    private String nominatimBaseUrl;

    @Value("${nominatim.user-agent:VNMapCampaign/1.0}")
    private String userAgent;

    @Value("${nominatim.timeout-ms:5000}")
    private int timeoutMs;

    public OsmGeocodingService(
            JdbcTemplate jdbc,
            ObjectMapper objectMapper
    ) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
    }

    public List<SchoolGeocodeDto> geocodeSchools(List<String> schoolUids) {
        if (schoolUids == null || schoolUids.isEmpty()) {
            return List.of();
        }
        List<SchoolGeocodeDto> results = new ArrayList<>();
        for (String uid : schoolUids) {
            try {
                SchoolGeocodeDto geocoded = geocodeSingleSchool(uid);
                if (geocoded != null) {
                    results.add(geocoded);
                }
            } catch (Exception e) {
                log.warn("Failed to geocode school {}: {}", uid, e.getMessage());
                // Still try to provide a fallback so the UI can show something
                SchoolGeocodeDto fallback = fallbackFor(uid);
                if (fallback != null) {
                    results.add(fallback);
                }
            }
        }
        return results;
    }

    private SchoolGeocodeDto geocodeSingleSchool(String schoolUid) throws Exception {
        SchoolContext ctx = loadSchoolContext(schoolUid);
        if (ctx == null) {
            return null;
        }

        String query = buildQuery(ctx);
        Optional<double[]> coords = callNominatim(query);

        if (coords.isPresent()) {
            double[] c = coords.get();
            return new SchoolGeocodeDto(
                    schoolUid, ctx.schoolName, c[0], c[1], "OSM", true
            );
        }

        // Fallback to commune centroid
        return fallbackFor(schoolUid, ctx);
    }

    private String buildQuery(SchoolContext ctx) {
        StringBuilder sb = new StringBuilder();
        if (ctx.schoolName != null && !ctx.schoolName.isBlank()) {
            sb.append(ctx.schoolName);
        }
        if (ctx.communeName != null && !ctx.communeName.isBlank()) {
            if (sb.length() > 0) sb.append(", ");
            sb.append(ctx.communeName);
        }
        if (ctx.provinceName != null && !ctx.provinceName.isBlank()) {
            if (sb.length() > 0) sb.append(", ");
            sb.append(ctx.provinceName);
        }
        sb.append(", Vietnam");
        return sb.toString();
    }

    private Optional<double[]> callNominatim(String query) throws Exception {
        String encoded = URLEncoder.encode(query, StandardCharsets.UTF_8);
        String url = nominatimBaseUrl
                + NOMINATIM_SEARCH_PATH
                + "?q=" + encoded
                + "&format=json"
                + "&limit=1"
                + "&countrycodes=vn";

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofMillis(timeoutMs))
                .header("User-Agent", userAgent)
                .header("Accept", "application/json")
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(
                request, HttpResponse.BodyHandlers.ofString()
        );

        if (response.statusCode() != 200) {
            log.warn("Nominatim returned status {}: {}",
                    response.statusCode(), response.body());
            return Optional.empty();
        }

        JsonNode root = objectMapper.readTree(response.body());
        if (!root.isArray() || root.isEmpty()) {
            return Optional.empty();
        }
        JsonNode first = root.get(0);
        JsonNode latNode = first.get("lat");
        JsonNode lonNode = first.get("lon");
        if (latNode == null || lonNode == null) {
            return Optional.empty();
        }
        double lat = latNode.asDouble();
        double lon = lonNode.asDouble();
        return Optional.of(new double[]{lat, lon});
    }

    private SchoolContext loadSchoolContext(String schoolUid) {
        try {
            return jdbc.queryForObject(
                    """
                    SELECT school_name, province_name, commune_name, commune_code
                    FROM schools
                    WHERE school_uid = ?
                    """,
                    (rs, rowNum) -> new SchoolContext(
                            rs.getString("school_name"),
                            rs.getString("province_name"),
                            rs.getString("commune_name"),
                            rs.getString("commune_code")
                    ),
                    schoolUid
            );
        } catch (Exception e) {
            log.warn("School {} not found: {}", schoolUid, e.getMessage());
            return null;
        }
    }

    private SchoolGeocodeDto fallbackFor(String schoolUid) {
        SchoolContext ctx = loadSchoolContext(schoolUid);
        if (ctx == null) return null;
        return fallbackFor(schoolUid, ctx);
    }

    private SchoolGeocodeDto fallbackFor(String schoolUid, SchoolContext ctx) {
        if (ctx.communeCode == null || ctx.communeCode.isBlank()) {
            return new SchoolGeocodeDto(
                    schoolUid, ctx.schoolName, null, null, "FALLBACK", false
            );
        }
        Double[] centroid = queryCentroid(ctx.communeCode);
        if (centroid != null) {
            // centroid[0] = lng, centroid[1] = lat
            Double lng = centroid[0];
            Double lat = centroid[1];
            return new SchoolGeocodeDto(
                    schoolUid, ctx.schoolName, lat, lng, "FALLBACK", false
            );
        }
        return new SchoolGeocodeDto(
                schoolUid, ctx.schoolName, null, null, "FALLBACK", false
        );
    }

    private Double[] queryCentroid(String communeCode) {
        try {
            return jdbc.queryForObject(
                    """
                    SELECT ST_X(centroid), ST_Y(centroid)
                    FROM administrative_units
                    WHERE code = ? AND kind = 'commune' AND centroid IS NOT NULL
                    """,
                    (rs, rowNum) -> new Double[]{rs.getDouble(1), rs.getDouble(2)},
                    communeCode
            );
        } catch (Exception e) {
            log.debug("Centroid not found for commune {}: {}", communeCode, e.getMessage());
            return null;
        }
    }

    private record SchoolContext(
            String schoolName,
            String provinceName,
            String communeName,
            String communeCode
    ) {}
}
