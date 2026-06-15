package com.hyp.user.service;

import com.hyp.common.*;
import com.hyp.user.dto.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final VerificationCodeService codeService;
    private final JwtUtil jwtUtil;

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        if (userRepository.existsByPhone(req.getPhone())) {
            throw BusinessException.alreadyExists("手机号");
        }

        boolean valid = codeService.verify(req.getPhone(), req.getCode());
        if (!valid) {
            throw BusinessException.invalidCode();
        }

        User user = new User();
        user.setPhone(req.getPhone());
        user.setRole(req.getRole());
        user.setNickname(req.getNickname() != null ? req.getNickname() : "用户" + req.getPhone().substring(7));
        userRepository.save(user);

        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getPhone(), user.getRole());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId(), user.getPhone(), user.getRole());

        return new AuthResponse(accessToken, refreshToken, user.getId(), user.getPhone(), user.getRole(), user.getNickname());
    }

    public AuthResponse login(LoginRequest req) {
        User user = userRepository.findByPhone(req.getPhone())
                .orElseThrow(() -> BusinessException.notFound("用户"));

        boolean valid = codeService.verify(req.getPhone(), req.getCode());
        if (!valid) {
            throw BusinessException.invalidCode();
        }

        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getPhone(), user.getRole());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId(), user.getPhone(), user.getRole());

        return new AuthResponse(accessToken, refreshToken, user.getId(), user.getPhone(), user.getRole(), user.getNickname());
    }

    public AuthResponse refresh(String refreshToken) {
        try {
            var claims = jwtUtil.parseToken(refreshToken);
            Long userId = Long.valueOf(claims.getSubject());
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> BusinessException.notFound("用户"));

            String newAccess = jwtUtil.generateAccessToken(user.getId(), user.getPhone(), user.getRole());
            String newRefresh = jwtUtil.generateRefreshToken(user.getId(), user.getPhone(), user.getRole());

            return new AuthResponse(newAccess, newRefresh, user.getId(), user.getPhone(), user.getRole(), user.getNickname());
        } catch (Exception e) {
            throw BusinessException.notFound("登录状态已过期，请重新登录");
        }
    }

    public java.util.Map<String, Object> getProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> BusinessException.notFound("用户"));
        return java.util.Map.of(
                "userId", user.getId(),
                "phone", user.getPhone(),
                "role", user.getRole(),
                "nickname", user.getNickname() != null ? user.getNickname() : "",
                "avatarUrl", user.getAvatarUrl() != null ? user.getAvatarUrl() : ""
        );
    }

    @Transactional
    public void updateProfile(Long userId, java.util.Map<String, String> body) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> BusinessException.notFound("用户"));
        if (body.containsKey("nickname")) {
            user.setNickname(body.get("nickname"));
        }
        if (body.containsKey("avatarUrl")) {
            user.setAvatarUrl(body.get("avatarUrl"));
        }
        userRepository.save(user);
    }
}
