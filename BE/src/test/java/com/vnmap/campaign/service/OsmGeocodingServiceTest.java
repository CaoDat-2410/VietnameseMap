package com.vnmap.campaign.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpServer;
import com.vnmap.campaign.dto.SchoolGeocodeDto;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.test.util.ReflectionTestUtils;

import java.net.InetSocketAddress;
import java.sql.ResultSet;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class OsmGeocodingServiceTest {

    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final OsmGeocodingService service = new OsmGeocodingService(jdbc, new ObjectMapper());
    private HttpServer server;

    @AfterEach
    void tearDown() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void returnsEmptyListForMissingInput() {
        assertThat(service.geocodeSchools(null)).isEmpty();
        assertThat(service.geocodeSchools(List.of())).isEmpty();
    }

    @Test
    void usesOsmCoordinatesWhenNominatimReturnsResult() throws Exception {
        mockSchoolContext("Coverage School", "Ho Chi Minh", "Ben Nghe", "79001");
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/search", exchange -> {
            byte[] body = "[{\"lat\":\"10.7769\",\"lon\":\"106.7009\"}]".getBytes();
            exchange.sendResponseHeaders(200, body.length);
            exchange.getResponseBody().write(body);
            exchange.close();
        });
        server.start();
        configureNominatim("http://127.0.0.1:" + server.getAddress().getPort(), 1000);

        List<SchoolGeocodeDto> result = service.geocodeSchools(List.of("79-001"));

        assertThat(result).singleElement().satisfies(row -> {
            assertThat(row.schoolUid()).isEqualTo("79-001");
            assertThat(row.schoolName()).isEqualTo("Coverage School");
            assertThat(row.latitude()).isEqualTo(10.7769);
            assertThat(row.longitude()).isEqualTo(106.7009);
            assertThat(row.source()).isEqualTo("OSM");
            assertThat(row.isExact()).isTrue();
        });
    }

    @Test
    void fallsBackToCommuneCentroidWhenOsmHasNoResult() throws Exception {
        mockSchoolContext("Coverage School", "Ho Chi Minh", "Ben Nghe", "79001");
        mockCentroid(106.7, 10.77);
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/search", exchange -> {
            byte[] body = "[]".getBytes();
            exchange.sendResponseHeaders(200, body.length);
            exchange.getResponseBody().write(body);
            exchange.close();
        });
        server.start();
        configureNominatim("http://127.0.0.1:" + server.getAddress().getPort(), 1000);

        List<SchoolGeocodeDto> result = service.geocodeSchools(List.of("79-001"));

        assertThat(result).singleElement().satisfies(row -> {
            assertThat(row.latitude()).isEqualTo(10.77);
            assertThat(row.longitude()).isEqualTo(106.7);
            assertThat(row.source()).isEqualTo("FALLBACK");
            assertThat(row.isExact()).isFalse();
        });
    }

    @Test
    void fallsBackWithoutCoordinatesWhenSchoolHasNoCommune() throws Exception {
        mockSchoolContext("Coverage School", "Ho Chi Minh", "Ben Nghe", "");
        configureNominatim("http://127.0.0.1:1", 50);

        List<SchoolGeocodeDto> result = service.geocodeSchools(List.of("79-001"));

        assertThat(result).singleElement().satisfies(row -> {
            assertThat(row.schoolName()).isEqualTo("Coverage School");
            assertThat(row.latitude()).isNull();
            assertThat(row.longitude()).isNull();
            assertThat(row.source()).isEqualTo("FALLBACK");
            assertThat(row.isExact()).isFalse();
        });
    }

    @Test
    void skipsUnknownSchools() {
        when(jdbc.queryForObject(anyString(), any(RowMapper.class), eq("missing")))
                .thenThrow(new IllegalArgumentException("not found"));

        assertThat(service.geocodeSchools(List.of("missing"))).isEmpty();
    }

    private void configureNominatim(String baseUrl, int timeoutMs) {
        ReflectionTestUtils.setField(service, "nominatimBaseUrl", baseUrl);
        ReflectionTestUtils.setField(service, "userAgent", "coverage-test");
        ReflectionTestUtils.setField(service, "timeoutMs", timeoutMs);
    }

    private void mockSchoolContext(String schoolName, String provinceName, String communeName, String communeCode)
            throws Exception {
        when(jdbc.queryForObject(anyString(), any(RowMapper.class), eq("79-001")))
                .thenAnswer(invocation -> {
                    RowMapper<?> mapper = invocation.getArgument(1);
                    ResultSet rs = mock(ResultSet.class);
                    when(rs.getString("school_name")).thenReturn(schoolName);
                    when(rs.getString("province_name")).thenReturn(provinceName);
                    when(rs.getString("commune_name")).thenReturn(communeName);
                    when(rs.getString("commune_code")).thenReturn(communeCode);
                    return mapper.mapRow(rs, 0);
                });
    }

    private void mockCentroid(double longitude, double latitude) throws Exception {
        when(jdbc.queryForObject(anyString(), any(RowMapper.class), eq("79001")))
                .thenAnswer(invocation -> {
                    RowMapper<?> mapper = invocation.getArgument(1);
                    ResultSet rs = mock(ResultSet.class);
                    when(rs.getDouble(1)).thenReturn(longitude);
                    when(rs.getDouble(2)).thenReturn(latitude);
                    return mapper.mapRow(rs, 0);
                });
    }
}
