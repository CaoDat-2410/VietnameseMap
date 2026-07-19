package com.vnmap.attendance.dto;

import jakarta.validation.constraints.Size;

public record CheckOutRequest(
        @Size(max = 500) String note,
        Double lat,
        Double lng
) {
}
