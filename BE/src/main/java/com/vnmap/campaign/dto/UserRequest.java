package com.vnmap.campaign.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UserRequest(
        @Email @NotBlank String email,
        @Size(min = 8) @NotBlank String password,
        @NotBlank String role,
        String status,
        Long employeeId,
        Long studentId
) {
}
