package com.hyp.health.dto;

import lombok.Data;
import java.time.Instant;
import java.util.Map;

@Data
public class HealthSnapshotRequest {
    private Long elderUserId;
    private Map<String, Double> metrics; // e.g. {"heartRate": 72, "spo2": 98, "sleepHours": 7.2}
    private Instant recordedAt;
}
