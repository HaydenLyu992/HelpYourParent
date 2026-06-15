package com.hyp.guardian.controller;

import com.hyp.common.ApiResponse;
import com.hyp.guardian.dto.BindRequest;
import com.hyp.guardian.dto.GuardianInfo;
import com.hyp.guardian.dto.PendingRequestInfo;
import com.hyp.guardian.service.GuardianService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/guardian")
@RequiredArgsConstructor
public class GuardianController {

    private final GuardianService guardianService;

    @PostMapping("/request-bind")
    public ResponseEntity<ApiResponse<Void>> requestBind(@Valid @RequestBody BindRequest req, Authentication auth) {
        Long fromUserId = Long.valueOf(auth.getName());
        guardianService.requestBind(fromUserId, req);
        return ResponseEntity.ok(ApiResponse.ok());
    }

    @GetMapping("/pending-requests")
    public ResponseEntity<ApiResponse<List<PendingRequestInfo>>> pendingRequests(Authentication auth) {
        Long userId = Long.valueOf(auth.getName());
        return ResponseEntity.ok(ApiResponse.ok(guardianService.pendingRequests(userId)));
    }

    @PostMapping("/accept-bind/{requestId}")
    public ResponseEntity<ApiResponse<Void>> acceptBind(@PathVariable Long requestId, Authentication auth) {
        Long userId = Long.valueOf(auth.getName());
        guardianService.acceptBind(requestId, userId);
        return ResponseEntity.ok(ApiResponse.ok());
    }

    @PostMapping("/reject-bind/{requestId}")
    public ResponseEntity<ApiResponse<Void>> rejectBind(@PathVariable Long requestId, Authentication auth) {
        Long userId = Long.valueOf(auth.getName());
        guardianService.rejectBind(requestId, userId);
        return ResponseEntity.ok(ApiResponse.ok());
    }

    @GetMapping("/list-guardians")
    public ResponseEntity<ApiResponse<List<GuardianInfo>>> listGuardians(Authentication auth) {
        Long elderId = Long.valueOf(auth.getName());
        return ResponseEntity.ok(ApiResponse.ok(guardianService.listGuardians(elderId)));
    }

    @GetMapping("/list-elders")
    public ResponseEntity<ApiResponse<List<GuardianInfo>>> listElders(Authentication auth) {
        Long guardianId = Long.valueOf(auth.getName());
        return ResponseEntity.ok(ApiResponse.ok(guardianService.listElders(guardianId)));
    }

    @DeleteMapping("/unbind/{targetUserId}")
    public ResponseEntity<ApiResponse<Void>> unbind(@PathVariable Long targetUserId, Authentication auth) {
        Long userId = Long.valueOf(auth.getName());
        guardianService.unbind(userId, targetUserId);
        return ResponseEntity.ok(ApiResponse.ok());
    }
}
