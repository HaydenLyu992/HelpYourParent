package com.hyp.health.service;

import com.hyp.health.dto.HealthSnapshotRequest;
import com.hyp.health.dto.HealthSnapshotResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class HealthService {

    private final Map<Long, List<HealthSnapshotResponse>> storage = new LinkedHashMap<>();

    public HealthSnapshotResponse recordSnapshot(HealthSnapshotRequest req) {
        double hr = req.getMetrics().getOrDefault("heartRate", 0.0);
        double spo2 = req.getMetrics().getOrDefault("spo2", 0.0);
        double sleep = req.getMetrics().getOrDefault("sleepHours", 0.0);

        String summary = buildSummary(hr, spo2, sleep);
        var resp = new HealthSnapshotResponse(req.getElderUserId(), req.getMetrics(),
                req.getRecordedAt() != null ? req.getRecordedAt() : Instant.now(), summary);

        storage.computeIfAbsent(req.getElderUserId(), k -> new ArrayList<>()).add(resp);
        if (storage.get(req.getElderUserId()).size() > 168) { // keep 7 days hourly
            storage.get(req.getElderUserId()).remove(0);
        }

        log.info("Health snapshot recorded for user {}: hr={}, spo2={}, sleep={}",
                req.getElderUserId(), hr, spo2, sleep);

        return resp;
    }

    public List<HealthSnapshotResponse> getHistory(Long elderUserId, int hours) {
        List<HealthSnapshotResponse> all = storage.getOrDefault(elderUserId, List.of());
        int from = Math.max(0, all.size() - hours);
        return all.subList(from, all.size());
    }

    private String buildSummary(double hr, double spo2, double sleep) {
        StringBuilder sb = new StringBuilder();
        if (hr > 0) sb.append("心率 ").append((int) hr).append(" bpm · ");
        if (spo2 > 0) sb.append("血氧 ").append((int) spo2).append("% · ");
        if (sleep > 0) sb.append("睡眠 ").append(String.format("%.1f", sleep)).append("h");
        return sb.toString().trim();
    }
}
