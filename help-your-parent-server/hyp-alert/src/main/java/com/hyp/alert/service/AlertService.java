package com.hyp.alert.service;

import com.hyp.alert.*;
import com.hyp.alert.dto.AlertResponse;
import com.hyp.alert.dto.AlertTriggerRequest;
import com.hyp.alert.entity.*;
import com.hyp.common.Constants;
import com.hyp.guardian.GuardianBindingRepository;
import com.hyp.guardian.entity.GuardianBinding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AlertService {

    private final AlertRecordRepository alertRepo;
    private final AlertDispatchRepository dispatchRepo;
    private final GuardianBindingRepository bindingRepo;
    private final NotificationPreferenceRepository prefRepo;
    private final DeviceTokenRepository deviceTokenRepo;
    private final APNsService apnsService;
    private final StringRedisTemplate redisTemplate;

    @Value("${alert.merge-window-seconds:300}")
    private int mergeWindowSeconds;

    @Transactional
    public AlertResponse trigger(AlertTriggerRequest req) {
        // Check merge window
        String mergeKey = "alert:merge:" + req.getElderUserId() + ":" + req.getRiskType();
        String existing = redisTemplate.opsForValue().get(mergeKey);

        AlertRecord alert;
        if (existing != null) {
            alert = alertRepo.findById(Long.valueOf(existing)).orElse(null);
            if (alert != null) {
                alert.setMerged(true);
                alert.setSummary(buildSummary(req));
                alertRepo.save(alert);
                return toResponse(alert);
            }
        }

        alert = new AlertRecord();
        alert.setElderUserId(req.getElderUserId());
        alert.setAlertLevel(req.getAlertLevel());
        alert.setRiskType(req.getRiskType());
        alert.setSummary(buildSummary(req));
        alertRepo.save(alert);

        // Set merge window
        redisTemplate.opsForValue().set(mergeKey, String.valueOf(alert.getId()),
                Duration.ofSeconds(mergeWindowSeconds));

        // Dispatch to elder + guardians with different messages
        dispatchToBoth(alert);

        alert.setDispatchedAt(LocalDateTime.now());
        alertRepo.save(alert);

        return toResponse(alert);
    }

    public List<AlertResponse> getHistory(Long elderUserId) {
        return alertRepo.findByElderUserIdOrderByCreatedAtDesc(elderUserId)
                .stream().map(this::toResponse).toList();
    }

    private void dispatchToBoth(AlertRecord alert) {
        // 1. Notify the elder: reassuring, tell them help is on the way
        notifyElder(alert);

        // 2. Notify all guardians: detailed alert, urge them to check
        notifyGuardians(alert);
    }

    private void notifyElder(AlertRecord alert) {
        DeviceToken elderToken = deviceTokenRepo.findByUserId(alert.getElderUserId()).orElse(null);
        if (elderToken == null) {
            log.warn("Elder {} has no device token registered", alert.getElderUserId());
            return;
        }
        String title = "💗 健康提醒";
        String body = switch (alert.getAlertLevel()) {
            case Constants.ALERT_RED -> "检测到异常情况，已通知您的守护者，请保持冷静，必要时拨打120";
            case Constants.ALERT_ORANGE -> "检测到轻微异常，已提醒守护者关注您的状态";
            default -> "检测到指标波动，已同步给守护者，请放心";
        };
        try {
            apnsService.sendPush(elderToken.getToken(), title, body,
                    Map.of("alertId", alert.getId(), "role", "elder"));
            log.info("Elder notification sent for alert {}", alert.getId());
        } catch (Exception e) {
            log.error("Failed to notify elder {}: {}", alert.getElderUserId(), e.getMessage());
        }
    }

    private void notifyGuardians(AlertRecord alert) {
        List<GuardianBinding> bindings = bindingRepo.findByElderUserId(alert.getElderUserId());
        if (bindings.isEmpty()) return;

        List<Long> guardianIds = bindings.stream().map(GuardianBinding::getGuardianUserId).toList();
        List<DeviceToken> tokens = deviceTokenRepo.findByUserIdIn(guardianIds);

        String title = switch (alert.getAlertLevel()) {
            case Constants.ALERT_RED -> "⚠️ 紧急：老人健康异常";
            case Constants.ALERT_ORANGE -> "🔔 提醒：老人健康指标需关注";
            default -> "💡 老人健康关注";
        };
        String body = alert.getSummary() + "，请尽快联系老人确认状况";
        Map<String, Object> payload = Map.of(
                "alertId", alert.getId(),
                "riskType", alert.getRiskType(),
                "level", alert.getAlertLevel(),
                "role", "guardian"
        );

        for (GuardianBinding binding : bindings) {
            NotificationPreference pref = prefRepo.findByUserId(binding.getGuardianUserId()).orElse(null);
            if (pref != null && !pref.isPushEnabled()) continue;

            DeviceToken deviceToken = tokens.stream()
                    .filter(t -> t.getUserId().equals(binding.getGuardianUserId()))
                    .findFirst().orElse(null);

            AlertDispatch dispatch = new AlertDispatch();
            dispatch.setAlertId(alert.getId());
            dispatch.setGuardianUserId(binding.getGuardianUserId());
            dispatch.setChannel(Constants.CHANNEL_PUSH);
            dispatch.setStatus(Constants.STATUS_PENDING);
            dispatchRepo.save(dispatch);

            if (deviceToken != null) {
                try {
                    apnsService.sendPush(deviceToken.getToken(), title, body, payload);
                    dispatch.setStatus(Constants.STATUS_SENT);
                    dispatch.setSentAt(LocalDateTime.now());
                } catch (Exception e) {
                    dispatch.setStatus(Constants.STATUS_FAILED);
                    dispatch.setErrorMsg(e.getMessage());
                }
            } else {
                dispatch.setStatus(Constants.STATUS_FAILED);
                dispatch.setErrorMsg("Guardian device token not registered");
            }
            dispatchRepo.save(dispatch);
        }
    }

    private String buildSummary(AlertTriggerRequest req) {
        Map<String, Double> m = req.getMetrics();
        return switch (req.getRiskType()) {
            case Constants.RISK_HEART_RATE -> "心率异常: " + (m != null ? m.getOrDefault("heartRate", 0.0).intValue() + " bpm" : "");
            case Constants.RISK_SPO2 -> "血氧偏低: " + (m != null ? m.getOrDefault("spo2", 0.0).intValue() + "%" : "");
            case Constants.RISK_FALL -> "检测到疑似跌倒事件";
            case Constants.RISK_INACTIVITY -> "长时间未检测到活动";
            case Constants.RISK_SLEEP -> "睡眠异常";
            default -> "健康指标异常";
        };
    }

    private AlertResponse toResponse(AlertRecord a) {
        return new AlertResponse(a.getId(), a.getAlertLevel(), a.getRiskType(),
                a.getSummary(), a.getAiAdvice(), a.isMerged(), a.getCreatedAt());
    }
}
