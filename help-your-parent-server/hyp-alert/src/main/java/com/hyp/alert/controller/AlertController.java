package com.hyp.alert.controller;

import com.hyp.alert.dto.AlertResponse;
import com.hyp.alert.dto.AlertTriggerRequest;
import com.hyp.alert.service.AlertService;
import com.hyp.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/alert")
@RequiredArgsConstructor
public class AlertController {

    private final AlertService alertService;

    @PostMapping("/trigger")
    public ResponseEntity<ApiResponse<AlertResponse>> trigger(@RequestBody AlertTriggerRequest req, Authentication auth) {
        if (req.getElderUserId() == null) {
            req.setElderUserId(Long.valueOf(auth.getName()));
        }
        AlertResponse resp = alertService.trigger(req);
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<AlertResponse>>> getHistory(Authentication auth) {
        Long elderId = Long.valueOf(auth.getName());
        return ResponseEntity.ok(ApiResponse.ok(alertService.getHistory(elderId)));
    }
}
