package com.hyp.health.controller;

import com.hyp.common.ApiResponse;
import com.hyp.health.dto.HealthSnapshotRequest;
import com.hyp.health.dto.HealthSnapshotResponse;
import com.hyp.health.service.HealthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
@RequiredArgsConstructor
public class HealthController {

    private final HealthService healthService;

    @PostMapping("/snapshot")
    public ResponseEntity<ApiResponse<HealthSnapshotResponse>> submitSnapshot(
            @RequestBody HealthSnapshotRequest req,
            @RequestAttribute("userId") Long userId) {
        if (req.getElderUserId() == null) {
            req.setElderUserId(userId);
        }
        var resp = healthService.recordSnapshot(req);
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }

    @GetMapping("/history/{elderUserId}")
    public ResponseEntity<ApiResponse<List<HealthSnapshotResponse>>> getHistory(
            @PathVariable Long elderUserId,
            @RequestParam(defaultValue = "24") int hours) {
        var history = healthService.getHistory(elderUserId, hours);
        return ResponseEntity.ok(ApiResponse.ok(history));
    }

    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getSummary(
            @RequestParam Long elderId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getSummary(elderId)));
    }

    @GetMapping("/trend")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getTrend(
            @RequestParam String type,
            @RequestParam String from,
            @RequestParam String to,
            @RequestParam(defaultValue = "24") Long elderId,
            @RequestAttribute("userId") Long userId) {
        Long targetId = elderId != null ? elderId : userId;
        return ResponseEntity.ok(ApiResponse.ok(healthService.getTrend(targetId, type, from, to)));
    }
}
