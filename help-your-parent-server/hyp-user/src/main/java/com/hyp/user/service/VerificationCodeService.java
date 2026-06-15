package com.hyp.user.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class VerificationCodeService {

    private final StringRedisTemplate redisTemplate;
    private static final String PREFIX = "verify:code:";
    private static final long CODE_TTL_MINUTES = 5;
    private static final SecureRandom RANDOM = new SecureRandom();

    public String generate(String phone) {
        String code = String.format("%06d", RANDOM.nextInt(1_000_000));
        redisTemplate.opsForValue().set(
                PREFIX + phone,
                code,
                CODE_TTL_MINUTES,
                TimeUnit.MINUTES
        );
        log.info("Generated verification code for {}: {}", phone, code);
        return code;
    }

    public boolean verify(String phone, String code) {
        String stored = redisTemplate.opsForValue().get(PREFIX + phone);
        if (stored == null) return false;
        if (!stored.equals(code)) return false;
        redisTemplate.delete(PREFIX + phone);
        return true;
    }
}
