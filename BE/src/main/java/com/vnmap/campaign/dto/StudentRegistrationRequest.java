package com.vnmap.campaign.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record StudentRegistrationRequest(
        @NotBlank String schoolUid,
        @NotBlank String fullName,
        @Email @NotBlank String email,
        @NotBlank String phone,
        @Size(min = 8) @NotBlank String password,
        @NotBlank String grade,
        @NotBlank String className,
        LocalDate dateOfBirth,
        String address,
        String note
) {
}
