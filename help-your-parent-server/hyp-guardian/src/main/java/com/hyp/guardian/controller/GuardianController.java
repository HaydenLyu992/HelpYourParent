package com.hyp.guardian.controller;

import com.hyp.common.ApiResponse;
import com.hyp.guardian.dto.BindRequest;
import com.hyp.guardian.dto.GuardianInfo;
import com.hyp.guardian.dto.PendingRequestInfo;
import com.hyp.guardian.service.GuardianService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/guardian")
@RequiredArgsConstructor
public class GuardianController {

    private final GuardianService guardianService;

    @PostMapping("/request-bind")
    public ResponseEntity<ApiResponse<Void>> requestBind(
            @Valid @RequestBody BindRequest req,
            @RequestAttribute("userId") Long userId) {
        guardianService.requestBind(userId, req);
        return ResponseEntity.ok(ApiResponse.ok());
    }

    @GetMapping("/pending-requests")
    public ResponseEntity<ApiResponse<List<PendingRequestInfo>>> pendingRequests(
            @RequestAttribute("userId") Long userId) {
        return ResponseEntity.ok(ApiResponse.ok(guardianService.pendingRequests(userId)));
    }

    @PostMapping("/accept-bind/{requestId}")
    public ResponseEntity<ApiResponse<Void>> acceptBind(
            @PathVariable Long requestId,
            @RequestAttribute("userId") Long userId) {
        guardianService.acceptBind(requestId, userId);
        return ResponseEntity.ok(ApiResponse.ok());
    }

    @PostMapping("/reject-bind/{requestId}")
    public ResponseEntity<ApiResponse<Void>> rejectBind(
            @PathVariable Long requestId,
            @RequestAttribute("userId") Long userId) {
        guardianService.rejectBind(requestId, userId);
        return ResponseEntity.ok(ApiResponse.ok());
    }

    @GetMapping("/list")
    public ResponseEntity<ApiResponse<List<GuardianInfo>>> listGuardians(
            @RequestAttribute("userId") Long userId) {
        return ResponseEntity.ok(ApiResponse.ok(guardianService.listGuardians(userId)));
    }

    @GetMapping("/elders")
    public ResponseEntity<ApiResponse<List<GuardianInfo>>> listElders(
            @RequestAttribute("userId") Long userId) {
        return ResponseEntity.ok(ApiResponse.ok(guardianService.listElders(userId)));
    }

    @DeleteMapping("/remove")
    public ResponseEntity<ApiResponse<Void>> unbind(
            @RequestParam Long guardianUserId,
            @RequestAttribute("userId") Long userId) {
        guardianService.unbind(guardianUserId, userId);
        return ResponseEntity.ok(ApiResponse.ok());
    }
}
