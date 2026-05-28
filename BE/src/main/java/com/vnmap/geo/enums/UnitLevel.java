package com.vnmap.geo.enums;

public enum UnitLevel {
    PROVINCE,
    DISTRICT,
    WARD;

    public static UnitLevel fromString(String value) {
        if (value == null) {
            throw new IllegalArgumentException("Unit level cannot be null");
        }
        return switch (value.toUpperCase().trim()) {
            case "PROVINCE", "TINH", "THANH_PHO" -> PROVINCE;
            case "DISTRICT", "HUYEN", "QUAN" -> DISTRICT;
            case "WARD", "XA", "PHUONG", "THI_TRAN" -> WARD;
            default -> throw new IllegalArgumentException("Invalid unit level: " + value);
        };
    }
}
