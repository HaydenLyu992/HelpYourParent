import SwiftUI

/// Detailed health data view for the elder. Replaces the `ElderHealthPlaceholder`.
///
/// Displays:
/// - Latest health snapshot metrics (heart rate, SpO2, sleep, steps).
/// - Trend charts placeholder with summary data.
/// - Health profile quick-edit entry.
struct HealthDetailView: View {
    @Environment(HealthKitManager.self) private var hkManager
    @Environment(APIClient.self) private var apiClient

    @State private var snapshot: HealthSnapshot?
    @State private var isLoading = true
    @State private var healthStatus: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header card
                DoodleCardView(background: .doodleCoralLight) {
                    HStack(spacing: 16) {
                        Text("💗")
                            .font(.system(size: 42))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "health_detail_title", defaultValue: "健康详情"))
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.doodleInk)
                            Text(healthStatus.isEmpty
                                 ? String(localized: "health_last_updated_unknown", defaultValue: "下拉刷新获取最新数据")
                                 : healthStatus)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                        }
                    }
                }

                if isLoading {
                    ProgressView()
                        .tint(.doodleCoral)
                        .padding(.vertical, 40)
                } else {
                    // Metric grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DetailMetricCardView(
                            emoji: "❤️",
                            title: String(localized: "metric_heart_rate", defaultValue: "静息心率"),
                            value: snapshot?.heartRate != nil ? String(format: "%.0f", snapshot!.heartRate!) : "--",
                            unit: "bpm",
                            color: .doodleCoral
                        )
                        DetailMetricCardView(
                            emoji: "🫁",
                            title: String(localized: "metric_spo2", defaultValue: "血氧饱和度"),
                            value: snapshot?.spo2 != nil ? String(format: "%.0f", snapshot!.spo2! * 100) : "--",
                            unit: "%",
                            color: .doodleSky
                        )
                        DetailMetricCardView(
                            emoji: "😴",
                            title: String(localized: "metric_sleep", defaultValue: "睡眠时长"),
                            value: snapshot?.sleepHours != nil ? String(format: "%.1f", snapshot!.sleepHours!) : "--",
                            unit: "h",
                            color: .doodleSun
                        )
                        DetailMetricCardView(
                            emoji: "🚶",
                            title: String(localized: "metric_steps", defaultValue: "今日步数"),
                            value: snapshot?.stepCount != nil ? String(format: "%.0f", snapshot!.stepCount!) : "--",
                            unit: "步",
                            color: .doodleMint
                        )
                    }

                    // Trend section
                    DoodleCardView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(String(localized: "health_trend_title", defaultValue: "近期趋势"))
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(.doodleInk)

                            Text(String(localized: "health_trend_placeholder", defaultValue: "持续记录几天后，这里将展示您的健康趋势图"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.doodleCream)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    // Health Profile quick entry
                    NavigationLink {
                        HealthProfileView()
                    } label: {
                        DoodleCardView(background: .doodleSkyLight) {
                            HStack(spacing: 12) {
                                Text("📋")
                                    .font(.system(size: 28))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(localized: "health_profile_entry", defaultValue: "个人健康档案"))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.doodleInk)
                                    Text(String(localized: "health_profile_hint", defaultValue: "身高、体重、病史、用药信息"))
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(.doodleInkLight)
                                }
                                Spacer()
                                Text("➡️")
                                    .font(.system(size: 18))
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.doodleCream)
        .navigationTitle(String(localized: "health_tab", defaultValue: "健康"))
        .task { await loadData() }
        .refreshable { await loadData() }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        if !hkManager.isAuthorized {
            try? await hkManager.requestAuthorization()
        }

        do {
            snapshot = try await hkManager.fetchAllMetrics()
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "HH:mm"
            healthStatus = String(localized: "health_last_updated", defaultValue: "最后更新：") + formatter.string(from: Date())
        } catch {
            healthStatus = String(localized: "health_fetch_failed", defaultValue: "获取健康数据失败")
        }
    }
}

// MARK: - Reusable Sub-Views

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

private struct DetailMetricCardView: View {
    let emoji: String
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 26))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.doodleInkLight)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .doodleBorder(.doodleInk, width: 3)
        .shadow(color: .black.opacity(0.06), radius: 0, x: 2, y: 3)
    }
}

// MARK: - Health Profile View

struct HealthProfileView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var bloodType: String = ""
    @State private var medicalHistory: String = ""
    @State private var medications: String = ""
    @State private var allergies: String = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showSaved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DoodleCardView(background: .doodleCoralLight) {
                    VStack(spacing: 12) {
                        Text("📋")
                            .font(.system(size: 42))
                        Text(String(localized: "health_profile_header", defaultValue: "个人健康档案"))
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.doodleInk)
                        Text(String(localized: "health_profile_hint_detail", defaultValue: "完善您的健康信息，帮助AI更准确地分析"))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.doodleInkLight)
                    }
                }

                // Basic info
                DoodleCardView {
                    VStack(spacing: 12) {
                        ProfileFieldView(emoji: "📏", label: String(localized: "profile_height", defaultValue: "身高 (cm)"), text: $height)
                        Divider().background(Color.doodleInkLighter)
                        ProfileFieldView(emoji: "⚖️", label: String(localized: "profile_weight", defaultValue: "体重 (kg)"), text: $weight)
                        Divider().background(Color.doodleInkLighter)
                        ProfileFieldView(emoji: "🩸", label: String(localized: "profile_blood_type", defaultValue: "血型"), text: $bloodType)
                    }
                }

                // Medical info
                DoodleCardView {
                    VStack(spacing: 12) {
                        Text(String(localized: "profile_medical_section", defaultValue: "病史与用药"))
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.doodleInk)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "profile_medical_history", defaultValue: "既往病史"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                            TextEditor(text: $medicalHistory)
                                .font(.system(size: 15, design: .rounded))
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color.doodleCream)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "profile_medications", defaultValue: "当前用药"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                            TextEditor(text: $medications)
                                .font(.system(size: 15, design: .rounded))
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color.doodleCream)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "profile_allergies", defaultValue: "过敏史"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                            TextEditor(text: $allergies)
                                .font(.system(size: 15, design: .rounded))
                                .frame(minHeight: 60)
                                .padding(8)
                                .background(Color.doodleCream)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                // Save button
                Button {
                    saveProfile()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView().tint(.white)
                        }
                        Text(showSaved
                             ? String(localized: "profile_saved", defaultValue: "✅ 已保存")
                             : String(localized: "profile_save", defaultValue: "💾 保存档案"))
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.doodleCoral)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .doodleBorder(.doodleInk, width: 3)
                }
                .disabled(isSaving)
            }
            .padding()
        }
        .background(Color.doodleCream)
        .navigationTitle(String(localized: "health_profile_title", defaultValue: "健康档案"))
        .task { /* Load existing profile from backend */ }
    }

    private func saveProfile() {
        Task {
            isSaving = true
            defer { isSaving = false }
            // POST to backend
            do {
                let _: APIResponse<String>? = try? await apiClient.put(
                    Endpoint.updateProfile.path,
                    body: [
                        "height": height,
                        "weight": weight,
                        "bloodType": bloodType,
                        "medicalHistory": medicalHistory,
                        "medications": medications,
                        "allergies": allergies,
                    ] as [String: String]
                )
                showSaved = true
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showSaved = false
            }
        }
    }
}

private struct ProfileFieldView: View {
    let emoji: String
    let label: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(emoji).font(.system(size: 20))
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.doodleInkLight)
            Spacer()
            TextField("--", text: $text)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HealthDetailView()
            .environment(HealthKitManager())
            .environment(APIClient())
    }
}
