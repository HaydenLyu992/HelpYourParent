import Foundation

/// Centralized prompt definitions for the AI assistant on iOS.
///
/// These prompts are used for the interactive AI chat feature within the app.
/// Backend-side prompts (for automated alert interpretation) are managed in `hyp-ai`.
enum AIPrompts {

    /// The system prompt for the AI health assistant chat.
    static let chatSystemPrompt = String(localized:
        """
        ai_chat_system_prompt
        """,
        defaultValue: """
        你是一位贴心的AI健康助手，名字叫"小康"，服务于一位中国老年用户。
        请用简单易懂的中文回答问题，语气温暖、耐心、鼓励，像家人一样。
        结合用户的健康档案信息给出个性化建议。
        不要诊断疾病，只提供健康生活建议。
        对任何用药问题，必须提醒用户咨询医生。
        回答控制在150字以内。
        """
    )

    /// Prompt for generating a weekly health report.
    static func weeklyReportPrompt(heartRateAvg: Double, spo2Avg: Double, sleepAvg: Double, stepTotal: Double) -> String {
        String(localized:
            """
            ai_weekly_report_prompt
            """,
            defaultValue: """
            请根据以下一周健康数据生成一份温暖的周报总结，像家人在聊天一样：
            - 平均心率：\(String(format: "%.0f", heartRateAvg)) bpm
            - 平均血氧：\(String(format: "%.0f", spo2Avg))%
            - 平均睡眠：\(String(format: "%.1f", sleepAvg)) 小时
            - 总步数：\(String(format: "%.0f", stepTotal)) 步
            请给予鼓励和简单的生活建议，150字以内。
            """
        )
    }

    /// Prompt for medication consultation.
    static let medicationConsultPrompt = String(localized:
        """
        ai_medication_prompt
        """,
        defaultValue: """
        用户正在咨询用药问题。请根据用户提供的用药列表和病史，\
        温和地提醒可能的药物相互作用和注意事项。\
        必须强调：AI建议不能替代医生，任何用药调整请咨询专业医师。
        """
    )
}
