package com.hyp.user.controller;

import com.hyp.common.ApiResponse;
import com.hyp.common.DeviceToken;
import com.hyp.common.DeviceTokenRepository;
import com.hyp.user.dto.*;
import com.hyp.user.service.AuthService;
import com.hyp.user.service.VerificationCodeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final VerificationCodeService codeService;
    private final DeviceTokenRepository deviceTokenRepo;

    // ── Auth endpoints ──

    @PostMapping("/api/auth/code")
    public ResponseEntity<ApiResponse<Void>> sendCode(@Valid @RequestBody SendCodeRequest req) {
        codeService.generate(req.getPhone());
        return ResponseEntity.ok(ApiResponse.ok());
    }

    @PostMapping("/api/auth/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest req) {
        AuthResponse resp = authService.register(req);
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }

    @PostMapping("/api/auth/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest req) {
        AuthResponse resp = authService.login(req);
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }

    @PostMapping("/api/auth/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(@RequestHeader("Authorization") String authHeader) {
        String token = authHeader.replace("Bearer ", "");
        AuthResponse resp = authService.refresh(token);
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }

    // ── User profile endpoints ──

    @GetMapping("/api/user/profile")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getProfile(
            @RequestAttribute("userId") Long userId) {
        return ResponseEntity.ok(ApiResponse.ok(authService.getProfile(userId)));
    }

    @PutMapping("/api/user/profile")
    public ResponseEntity<ApiResponse<Void>> updateProfile(
            @RequestAttribute("userId") Long userId,
            @RequestBody Map<String, String> body) {
        authService.updateProfile(userId, body);
        return ResponseEntity.ok(ApiResponse.ok());
    }

    // ── Device token ──

    @PostMapping("/api/user/register-device")
    public ResponseEntity<ApiResponse<Void>> registerDevice(
            @RequestAttribute("userId") Long userId,
            @RequestBody Map<String, String> body) {
        String token = body.get("deviceToken");
        DeviceToken dt = deviceTokenRepo.findByUserId(userId).orElse(new DeviceToken());
        dt.setUserId(userId);
        dt.setToken(token);
        dt.setPlatform(body.getOrDefault("platform", "IOS"));
        deviceTokenRepo.save(dt);
        return ResponseEntity.ok(ApiResponse.ok());
    }
}
