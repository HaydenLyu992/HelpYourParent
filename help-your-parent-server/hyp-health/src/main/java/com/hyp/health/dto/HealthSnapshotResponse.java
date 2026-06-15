package com.hyp.health.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.time.Instant;
import java.util.Map;

@Data
@AllArgsConstructor
public class HealthSnapshotResponse {
    private Long elderUserId;
    private Map<String, Double> metrics;
    private Instant recordedAt;
    private String summary;
}
