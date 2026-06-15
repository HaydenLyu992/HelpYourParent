package com.hyp.ai.controller;

import com.hyp.ai.service.AIService;
import com.hyp.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AIController {

    private final AIService aiService;

    @PostMapping("/analyze-risk")
    public ResponseEntity<ApiResponse<Map<String, String>>> analyzeRisk(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        Map<String, Double> metrics = (Map<String, Double>) request.get("metrics");
        String history = (String) request.getOrDefault("medicalHistory", "");
        String advice = aiService.analyzeRisk(metrics, history);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("advice", advice)));
    }

    @PostMapping("/chat")
    public ResponseEntity<ApiResponse<Map<String, String>>> chat(@RequestBody Map<String, String> request) {
        String message = request.getOrDefault("message", "");
        String reply = aiService.chat(message);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("reply", reply)));
    }
}
