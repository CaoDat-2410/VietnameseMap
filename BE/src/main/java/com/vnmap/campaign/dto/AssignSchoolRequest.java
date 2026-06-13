package com.vnmap.campaign.dto;

import jakarta.validation.constraints.NotBlank;

public record AssignSchoolRequest(@NotBlank String schoolUid) {
}
