package com.vnmap.campaign.dto;

/**
 * One slice in the interactions-by-channel donut chart.
 */
public record ChannelBreakdownDto(
        String channel,
        long total
) {
}