package com.vnmap.campaign.dto;

import java.util.List;

public record SchoolDetailDto(
        SchoolDto school,
        List<StudentDto> students,
        List<PersonDto> persons,
        List<StudentRelativeDto> relatives
) {
}
