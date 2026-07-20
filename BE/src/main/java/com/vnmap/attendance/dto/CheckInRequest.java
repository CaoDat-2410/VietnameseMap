package com.vnmap.attendance.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;

public record CheckInRequest(
        @NotNull Long campaignId,
        Long eventId,
        @Size(max = 500) String note,
        @DecimalMin("-90.0") @DecimalMax("90.0") Double lat,
        @DecimalMin("-180.0") @DecimalMax("180.0") Double lng
) {
    @AssertTrue(message = "lat and lng must be provided together")
    public boolean isLocationPairValid() {
        return (lat == null) == (lng == null);
    }
}
