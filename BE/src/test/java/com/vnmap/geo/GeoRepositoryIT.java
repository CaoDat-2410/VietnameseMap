package com.vnmap.geo;

import com.vnmap.geo.entity.AdministrativeUnit;
import com.vnmap.geo.enums.UnitLevel;
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

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@DisplayName("AdministrativeUnitRepository Integration Tests")
class GeoRepositoryIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgis/postgis:16-3.4")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    @Autowired
    private AdministrativeUnitRepository repository;

    @BeforeEach
    void setUp() {
        repository.deleteAll();
    }

    @Test
    @DisplayName("should save and retrieve administrative unit")
    void shouldSaveAndRetrieveUnit() {
        AdministrativeUnit unit = createUnit("01", "Hà Nội", UnitLevel.PROVINCE, null);
        repository.save(unit);

        Optional<AdministrativeUnit> found = repository.findByCode("01");

        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Hà Nội");
        assertThat(found.get().getLevel()).isEqualTo(UnitLevel.PROVINCE);
    }

    @Test
    @DisplayName("should find by level")
    void shouldFindByLevel() {
        repository.save(createUnit("01", "Hà Nội", UnitLevel.PROVINCE, null));
        repository.save(createUnit("79", "Hồ Chí Minh", UnitLevel.PROVINCE, null));
        repository.save(createUnit("001", "Ba Đình", UnitLevel.DISTRICT, 1L));

        var provinces = repository.findByLevel(UnitLevel.PROVINCE);

        assertThat(provinces).hasSize(2);
        assertThat(provinces).allMatch(u -> u.getLevel() == UnitLevel.PROVINCE);
    }

    @Test
    @DisplayName("should find by parent id and level")
    void shouldFindByParentIdAndLevel() {
        AdministrativeUnit province = createUnit("01", "Hà Nội", UnitLevel.PROVINCE, null);
        province = repository.save(province);

        repository.save(createUnit("001", "Ba Đình", UnitLevel.DISTRICT, province.getId()));
        repository.save(createUnit("002", "Hoàn Kiếm", UnitLevel.DISTRICT, province.getId()));

        var districts = repository.findByParentIdAndLevel(province.getId(), UnitLevel.DISTRICT);

        assertThat(districts).hasSize(2);
    }

    @Test
    @DisplayName("should count by parent id")
    void shouldCountByParentId() {
        AdministrativeUnit province = createUnit("01", "Hà Nội", UnitLevel.PROVINCE, null);
        province = repository.save(province);

        repository.save(createUnit("001", "Ba Đình", UnitLevel.DISTRICT, province.getId()));
        repository.save(createUnit("002", "Hoàn Kiếm", UnitLevel.DISTRICT, province.getId()));

        int count = repository.countByParentId(province.getId());

        assertThat(count).isEqualTo(2);
    }

    @Test
    @DisplayName("should find by name and level")
    void shouldFindByNameAndLevel() {
        repository.save(createUnit("01", "Hà Nội", UnitLevel.PROVINCE, null));

        Optional<AdministrativeUnit> found = repository.findByNameAndLevel("Hà Nội", UnitLevel.PROVINCE);

        assertThat(found).isPresent();
        assertThat(found.get().getCode()).isEqualTo("01");
    }

    private AdministrativeUnit createUnit(String code, String name, UnitLevel level, Long parentId) {
        return AdministrativeUnit.builder()
                .code(code)
                .name(name)
                .level(level)
                .parentId(parentId)
                .build();
    }
}
