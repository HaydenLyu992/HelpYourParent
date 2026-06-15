import SwiftUI
import HealthKit

/// The elder's main dashboard screen in doodle style.
///
/// Displays:
/// - Time-appropriate greeting with avatar emoji and stars decoration.
/// - Overall status card.
/// - Three core health metric cards (heart rate, SpO2, sleep).
/// - Today's health task progress bar.
/// - AI health assistant entry card.
/// - Quick action buttons for emergency, guardians, and health report.
struct ElderHomeView: View {
    @Environment(HealthKitManager.self) private var hkManager

    @State private var isLoading = true
    @State private var heartRate: Double?
    @State private var spo2: Double?
    @State private var sleepHours: Double?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Greeting Card
                DoodleCardView {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(greetingText) \(greetingEmoji)")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(.doodleInk)
                            Text(String(localized: "how_are_you_feeling", defaultValue: "今天感觉怎么样？"))
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                        }
                        Spacer()
                        Text("👴")
                            .font(.system(size: 40))
                            .frame(width: 56, height: 56)
                            .background(Color.doodleCoralLight)
                            .clipShape(Circle())
                            .doodleBorder(.doodleInk, width: 3)
                    }
                }

                // MARK: - Stars Decoration
                HStack(spacing: 12) {
                    Text("⭐")
                        .font(.system(size: 22))
                        .rotationEffect(.degrees(-12))
                    Text("✨")
                        .font(.system(size: 16))
                        .rotationEffect(.degrees(8))
                    Text("🌟")
                        .font(.system(size: 28))
                        .rotationEffect(.degrees(-5))
                }

                // MARK: - Status Card
                DoodleCardView(background: .doodleCoralLight) {
                    HStack(spacing: 16) {
                        Text("💗")
                            .font(.system(size: 42))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "all_normal", defaultValue: "一切正常"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.doodleInk)
                            Text(String(localized: "all_normal_detail", defaultValue: "各项指标都在健康范围内，继续保持！"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                        }
                    }
                }

                // MARK: - Metric Cards
                if isLoading {
                    ProgressView()
                        .tint(.doodleCoral)
                        .padding()
                } else {
                    HStack(spacing: 10) {
                        MetricCardView(
                            emoji: "❤️",
                            value: heartRate != nil ? String(format: "%.0f", heartRate!) : "--",
                            unit: "",
                            color: .doodleCoral,
                            label: String(localized: "resting_hr", defaultValue: "静息心率")
                        )
                        MetricCardView(
                            emoji: "🫁",
                            value: spo2 != nil ? String(format: "%.0f", spo2! * 100) : "--",
                            unit: "%",
                            color: .doodleSky,
                            label: String(localized: "spo2_label", defaultValue: "血氧饱和度")
                        )
                        MetricCardView(
                            emoji: "😴",
                            value: sleepHours != nil ? String(format: "%.1f", sleepHours!) : "--",
                            unit: "h",
                            color: .doodleSun,
                            label: String(localized: "sleep_label", defaultValue: "昨晚睡眠")
                        )
                    }
                }

                // MARK: - Task Progress Card
                DoodleCardView {
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(String(localized: "daily_health_tasks", defaultValue: "今日健康任务"))")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.doodleInk)
                            Spacer()
                            Text("65%")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(.doodleCoral)
                        }
                        ProgressView(value: 0.65)
                            .tint(.doodleCoral)
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                        HStack(spacing: 8) {
                            Text("✅ \(String(localized: "task_hr", defaultValue: "测量心率"))")
                            Text("✅ \(String(localized: "task_medication", defaultValue: "服药提醒"))")
                            Text("⬜ \(String(localized: "task_walk", defaultValue: "散步3000步"))")
                        }
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.doodleInkLight)
                    }
                }

                // MARK: - AI Assistant Entry
                DoodleCardView(background: .doodleSkyLight) {
                    HStack(spacing: 16) {
                        Text("🤖")
                            .font(.system(size: 30))
                            .frame(width: 56, height: 56)
                            .background(Color.doodleSkyLight)
                            .clipShape(Circle())
                            .doodleBorder(.doodleInk, width: 3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "ai_health_assistant", defaultValue: "AI 健康小助手"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.doodleInk)
                            Text(String(localized: "ai_assistant_hint", defaultValue: "点击和我聊聊您的健康问题～"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                        }
                        Spacer()
                        Text("➡️")
                            .font(.system(size: 20))
                    }
                }

                // MARK: - Quick Actions
                HStack(spacing: 8) {
                    QuickActionButtonView(
                        emoji: "📞",
                        title: String(localized: "emergency_call", defaultValue: "紧急求助")
                    )
                    QuickActionButtonView(
                        emoji: "👨‍👩‍👧",
                        title: String(localized: "guardians_quick", defaultValue: "守护者")
                    )
                    QuickActionButtonView(
                        emoji: "📊",
                        title: String(localized: "health_report", defaultValue: "健康报告")
                    )
                }
            }
            .padding()
        }
        .background(Color.doodleCream)
        .navigationTitle(String(localized: "app_name", defaultValue: "康护亲"))
        .task {
            await loadHealthData()
        }
    }

    // MARK: - Helpers

    /// Determine the greeting based on the current time of day.
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return String(localized: "morning_greeting", defaultValue: "早上好")
        case 12..<18:
            return String(localized: "afternoon_greeting", defaultValue: "下午好")
        default:
            return String(localized: "evening_greeting", defaultValue: "晚上好")
        }
    }

    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return "☀️"
        case 12..<18: return "🌤️"
        default:       return "🌙"
        }
    }

    /// Fetch live health metrics from HealthKit.
    private func loadHealthData() async {
        isLoading = true
        defer { isLoading = false }

        // Request HealthKit authorization if not yet granted
        if !hkManager.isAuthorized {
            _ = try? await hkManager.requestAuthorization()
        }

        // Fetch all metrics concurrently
        async let hr = hkManager.fetchLatestHeartRate()
        async let sp = hkManager.fetchLatestSpO2()
        async let sl = hkManager.fetchLastNightSleep()

        heartRate = try? await hr
        spo2 = try? await sp
        sleepHours = try? await sl
    }
}

// MARK: - Reusable Sub-Views

/// A doodle-style card container with thick border and shadow.
private struct DoodleCardView<Content: View>: View {
    let background: Color
    let content: Content

    init(background: Color = .white, @ViewBuilder content: () -> Content) {
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .doodleBorder(.doodleInk, width: 3)
            .shadow(color: .black.opacity(0.1), radius: 0, x: 3, y: 5)
    }
}

/// A single metric display card for a health indicator.
private struct MetricCardView: View {
    let emoji: String
    let value: String
    let unit: String
    let color: Color
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 22))
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(value)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(color)
                }
            }
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.doodleInkLight)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .doodleBorder(.doodleInk, width: 3)
        .shadow(color: .black.opacity(0.08), radius: 0, x: 2, y: 3)
    }
}

/// A quick-action button with emoji and text label.
private struct QuickActionButtonView: View {
    let emoji: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 28))
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.doodleInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .doodleBorder(.doodleInk, width: 3)
        .shadow(color: .black.opacity(0.08), radius: 0, x: 2, y: 3)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ElderHomeView()
            .environment(HealthKitManager())
    }
}
