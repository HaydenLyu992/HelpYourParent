package com.hyp.ai.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AIService {

    private final DeepSeekClient deepSeekClient;

    private static final String RISK_SYSTEM_PROMPT = """
            你是一位专业的老年健康顾问。根据以下脱敏后的健康指标，用通俗易懂的中文解释风险，
            并给出具体的就医建议。语气温暖关怀，不超过200字。不要提及任何个人身份信息。
            重要：如果指标正常，请给予鼓励。
            """;

    private static final String CHAT_SYSTEM_PROMPT = """
            你是一位贴心的AI健康助手，服务于一位老年用户。请用简单易懂的中文回答问题，
            字体要大（适合老年人阅读），语气温暖、耐心、鼓励。结合用户的健康档案信息
            给出个性化建议。不要诊断疾病，只提供健康生活建议。对任何用药问题，
            必须提醒用户咨询医生。回答控制在150字以内。
            """;

    public String analyzeRisk(Map<String, Double> metrics, String medicalHistory) {
        StringBuilder userMsg = new StringBuilder("健康指标：\n");
        metrics.forEach((k, v) -> userMsg.append("- ").append(k).append(": ").append(v).append("\n"));
        if (medicalHistory != null && !medicalHistory.isEmpty()) {
            userMsg.append("病史摘要：").append(medicalHistory);
        }
        String result = deepSeekClient.chat(RISK_SYSTEM_PROMPT, userMsg.toString());
        if (result == null) {
            return generateFallbackAdvice(metrics);
        }
        return result;
    }

    public String chat(String userMessage) {
        String result = deepSeekClient.chat(CHAT_SYSTEM_PROMPT, userMessage);
        if (result == null) {
            return "抱歉，AI 助手暂时无法响应。请稍后再试，或联系您的守护者获取帮助。";
        }
        return result;
    }

    private String generateFallbackAdvice(Map<String, Double> metrics) {
        double hr = metrics.getOrDefault("heartRate", 0.0);
        double spo2 = metrics.getOrDefault("spo2", 0.0);

        if (hr > 110) return "您的心率偏高，建议静坐休息15分钟后重新测量。如持续偏高，请及时就医。";
        if (hr < 50 && hr > 0) return "您的心率偏低，如感到头晕请立即坐下，建议联系医生咨询。";
        if (spo2 < 95 && spo2 > 0) return "您的血氧偏低，建议开窗通风并深呼吸。如低于90%请立即就医。";
        return "您的健康指标需要关注，建议联系守护者或医生进行进一步评估。";
    }

    public String generateReport(Long userId, String from, String to) {
        String prompt = """
                请根据以下时间段（%s 至 %s）的用户健康数据，生成一份简短的健康周报。
                用温暖鼓励的语气，总结健康趋势，给出生活建议。150字以内。
                """.formatted(from, to);
        String result = deepSeekClient.chat(CHAT_SYSTEM_PROMPT, prompt);
        if (result == null) {
            return "本周您的健康指标总体平稳。建议继续保持规律作息，适量运动。如有不适请及时联系守护者或就医。";
        }
        return result;
    }
}
