package com.vnmap.geo;

import com.vnmap.geo.entity.AdministrativeUnit;
import com.vnmap.geo.repository.AdministrativeUnitRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@DisplayName("AdministrativeUnitRepository Integration Tests (2025 Reform)")
class GeoRepositoryIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>(DockerImageName.parse("postgis/postgis:16-3.4").asCompatibleSubstituteFor("postgres"))
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    @Autowired
    private AdministrativeUnitRepository repository;

    private static final String KIND_PROVINCE = "province";
    private static final String KIND_COMMUNE = "commune";

    @BeforeEach
    void setUp() {
        repository.deleteAll();
    }

    @Test
    @DisplayName("should save and retrieve administrative unit")
    void shouldSaveAndRetrieveUnit() {
        AdministrativeUnit unit = createUnit("01", "Hà Nội", KIND_PROVINCE, null);
        repository.save(unit);

        Optional<AdministrativeUnit> found = repository.findByCode("01");

        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Hà Nội");
        assertThat(found.get().getKind()).isEqualTo(KIND_PROVINCE);
    }

    @Test
    @DisplayName("should find by kind")
    void shouldFindByKind() {
        repository.save(createUnit("01", "Hà Nội", KIND_PROVINCE, null));
        repository.save(createUnit("79", "Hồ Chí Minh", KIND_PROVINCE, null));
        repository.save(createUnit("001", "Ba Đình", KIND_COMMUNE, "01"));

        var provinces = repository.findByKind(KIND_PROVINCE);

        assertThat(provinces)
                .hasSize(2)
                .allMatch(u -> KIND_PROVINCE.equals(u.getKind()));
    }

    @Test
    @DisplayName("should find by parent code")
    void shouldFindByParentCode() {
        repository.save(createUnit("01", "Hà Nội", KIND_PROVINCE, null));
        repository.save(createUnit("001", "Ba Đình", KIND_COMMUNE, "01"));
        repository.save(createUnit("002", "Hoàn Kiếm", KIND_COMMUNE, "01"));

        var communes = repository.findByParentCode("01");

        assertThat(communes).hasSize(2);
    }

    @Test
    @DisplayName("should count by parent code")
    void shouldCountByParentCode() {
        repository.save(createUnit("01", "Hà Nội", KIND_PROVINCE, null));
        repository.save(createUnit("001", "Ba Đình", KIND_COMMUNE, "01"));
        repository.save(createUnit("002", "Hoàn Kiếm", KIND_COMMUNE, "01"));

        int count = repository.countByParentCode("01");

        assertThat(count).isEqualTo(2);
    }

    @Test
    @DisplayName("should find by code and kind")
    void shouldFindByCodeAndKind() {
        repository.save(createUnit("01", "Hà Nội", KIND_PROVINCE, null));

        Optional<AdministrativeUnit> found = repository.findByCodeAndKind("01", KIND_PROVINCE);

        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Hà Nội");
    }

    private AdministrativeUnit createUnit(String code, String name, String kind, String parentCode) {
        return AdministrativeUnit.builder()
                .code(code)
                .name(name)
                .kind(kind)
                .parentCode(parentCode)
                .build();
    }
}
