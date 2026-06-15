package com.hyp.user.controller;

import com.hyp.alert.DeviceTokenRepository;
import com.hyp.alert.entity.DeviceToken;
import com.hyp.common.ApiResponse;
import com.hyp.user.dto.*;
import com.hyp.user.service.AuthService;
import com.hyp.user.service.VerificationCodeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final VerificationCodeService codeService;
    private final DeviceTokenRepository deviceTokenRepo;

    @PostMapping("/send-code")
    public ResponseEntity<ApiResponse<Void>> sendCode(@Valid @RequestBody SendCodeRequest req) {
        codeService.generate(req.getPhone());
        return ResponseEntity.ok(ApiResponse.ok());
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest req) {
        AuthResponse resp = authService.register(req);
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest req) {
        AuthResponse resp = authService.login(req);
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(@RequestHeader("Authorization") String authHeader) {
        String token = authHeader.replace("Bearer ", "");
        AuthResponse resp = authService.refresh(token);
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }

    @PostMapping("/register-device")
    public ResponseEntity<ApiResponse<Void>> registerDevice(@RequestBody Map<String, String> body, Authentication auth) {
        Long userId = Long.valueOf(auth.getName());
        String token = body.get("deviceToken");
        DeviceToken dt = deviceTokenRepo.findByUserId(userId).orElse(new DeviceToken());
        dt.setUserId(userId);
        dt.setToken(token);
        dt.setPlatform(body.getOrDefault("platform", "IOS"));
        deviceTokenRepo.save(dt);
        return ResponseEntity.ok(ApiResponse.ok());
    }
}
