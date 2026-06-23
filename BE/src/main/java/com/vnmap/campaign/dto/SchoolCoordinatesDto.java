package com.vnmap.campaign.dto;

public record SchoolCoordinatesDto(
    String schoolUid,
    String schoolName,
    String provinceName,
    String communeName,
    String address,
    Double latitude,
    Double longitude,
    String geocodeStatus,     // "FULL" | "APPROXIMATE" | "PENDING"
    String geocodeNote        // e.g., "Tọa độ ước lượng từ cấp xã"
) {}
