package com.hyp.alert.controller;

import com.hyp.alert.dto.AlertResponse;
import com.hyp.alert.dto.AlertTriggerRequest;
import com.hyp.alert.service.AlertService;
import com.hyp.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/alert")
@RequiredArgsConstructor
public class AlertController {

    private final AlertService alertService;

    @PostMapping("/trigger")
    public ResponseEntity<ApiResponse<AlertResponse>> trigger(
            @RequestBody AlertTriggerRequest req,
            @RequestAttribute("userId") Long userId) {
        if (req.getElderUserId() == null) {
            req.setElderUserId(userId);
        }
        AlertResponse resp = alertService.trigger(req);
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }

    @GetMapping("/list")
    public ResponseEntity<ApiResponse<List<AlertResponse>>> getHistory(
            @RequestAttribute("userId") Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String level) {
        return ResponseEntity.ok(ApiResponse.ok(alertService.getHistory(userId, page, size, level)));
    }

    @GetMapping("/detail")
    public ResponseEntity<ApiResponse<AlertResponse>> getDetail(
            @RequestParam Long alertId) {
        return ResponseEntity.ok(ApiResponse.ok(alertService.getDetail(alertId)));
    }
}
