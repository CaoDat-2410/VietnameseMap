package com.vnmap.campaign.dto;

import jakarta.validation.constraints.NotNull;

public record AssignEmployeeRequest(@NotNull Long employeeId) {
}
