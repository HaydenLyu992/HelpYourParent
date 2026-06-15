package com.hyp.user.controller;

import com.hyp.common.ApiResponse;
import com.hyp.common.NotificationPreference;
import com.hyp.common.NotificationPreferenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class NotificationPreferenceController {

    private final NotificationPreferenceRepository prefRepo;

    @GetMapping("/notifications")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> getPreferences(
            @RequestAttribute("userId") Long userId) {
        NotificationPreference pref = prefRepo.findByUserId(userId)
                .orElseGet(() -> createDefault(userId));
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "pushEnabled", pref.isPushEnabled(),
                "smsEnabled", pref.isSmsEnabled(),
                "emailEnabled", pref.isEmailEnabled()
        )));
    }

    @PutMapping("/notifications")
    public ResponseEntity<ApiResponse<Void>> updatePreferences(
            @RequestAttribute("userId") Long userId,
            @RequestBody Map<String, Boolean> body) {
        NotificationPreference pref = prefRepo.findByUserId(userId)
                .orElseGet(() -> createDefault(userId));
        if (body.containsKey("pushEnabled")) pref.setPushEnabled(body.get("pushEnabled"));
        if (body.containsKey("smsEnabled")) pref.setSmsEnabled(body.get("smsEnabled"));
        if (body.containsKey("emailEnabled")) pref.setEmailEnabled(body.get("emailEnabled"));
        prefRepo.save(pref);
        return ResponseEntity.ok(ApiResponse.ok());
    }

    private NotificationPreference createDefault(Long userId) {
        NotificationPreference pref = new NotificationPreference();
        pref.setUserId(userId);
        pref.setPushEnabled(true);
        pref.setSmsEnabled(true);
        pref.setEmailEnabled(false);
        return prefRepo.save(pref);
    }
}
