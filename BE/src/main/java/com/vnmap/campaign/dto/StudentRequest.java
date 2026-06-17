package com.vnmap.campaign.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDate;

public record StudentRequest(
        @NotBlank String schoolUid,
        @NotBlank String fullName,
        @Email String email,
        String phone,
        LocalDate dateOfBirth,
        String address,
        String grade,
        String className
) {
}
