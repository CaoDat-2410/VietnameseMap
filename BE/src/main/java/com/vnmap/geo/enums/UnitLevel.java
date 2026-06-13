package com.vnmap.geo.enums;

public enum UnitLevel {
    PROVINCE,
    COMMUNE;

    public static final String KIND_PROVINCE = "province";
    public static final String KIND_COMMUNE = "commune";

    public static UnitLevel fromKind(String kind) {
        if (kind == null) {
            throw new IllegalArgumentException("kind cannot be null");
        }
        return switch (kind.toLowerCase().trim()) {
            case KIND_PROVINCE, "tinh", "thanh_pho", "thành phố", "tỉnh" -> PROVINCE;
            case KIND_COMMUNE, "xa", "phuong", "thi_tran", "phường", "xã", "thị trấn" -> COMMUNE;
            default -> throw new IllegalArgumentException("Invalid kind: " + kind);
        };
    }

    public String toKind() {
        return switch (this) {
            case PROVINCE -> KIND_PROVINCE;
            case COMMUNE -> KIND_COMMUNE;
        };
    }
}
