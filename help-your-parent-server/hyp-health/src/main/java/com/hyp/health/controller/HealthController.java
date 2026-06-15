package com.hyp.health.controller;

import com.hyp.common.ApiResponse;
import com.hyp.health.dto.HealthSnapshotRequest;
import com.hyp.health.dto.HealthSnapshotResponse;
import com.hyp.health.service.HealthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/health")
@RequiredArgsConstructor
public class HealthController {

    private final HealthService healthService;

    @PostMapping("/snapshot")
    public ResponseEntity<ApiResponse<HealthSnapshotResponse>> submitSnapshot(
            @RequestBody HealthSnapshotRequest req, Authentication auth) {
        if (req.getElderUserId() == null) {
            req.setElderUserId(Long.valueOf(auth.getName()));
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
}
