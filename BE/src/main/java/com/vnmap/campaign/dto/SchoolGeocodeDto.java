package com.vnmap.campaign.dto;

public record SchoolGeocodeDto(
        String schoolUid,
        String schoolName,
        Double latitude,
        Double longitude,
        String source,        // "OSM" or "FALLBACK"
        boolean isExact       // true if from OSM, false if fallback
) {}
