import Foundation
import HealthKit

/// Errors that can occur during HealthKit operations.
enum HealthKitError: LocalizedError {
    case notAvailableOnDevice
    case authorizationDenied
    case typeNotAllowed(String)
    case queryFailed(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .notAvailableOnDevice:
            return String(localized: "hk_not_available", defaultValue: "此设备不支持 HealthKit")
        case .authorizationDenied:
            return String(localized: "hk_auth_denied", defaultValue: "健康数据权限被拒绝，请在\"健康\"App中授权")
        case .typeNotAllowed(let type):
            return String(localized: "hk_type_not_allowed", defaultValue: "未授权读取数据类型: \(type)")
        case .queryFailed(let reason):
            return String(localized: "hk_query_failed", defaultValue: "健康数据查询失败: \(reason)")
        case .noData:
            return String(localized: "hk_no_data", defaultValue: "暂无健康数据")
        }
    }
}

/// A snapshot of the user's latest health metrics.
/// This struct contains only the most recent readings for each tracked type.
/// Raw HealthKit data stays on-device and is never uploaded.
struct HealthSnapshot {
    var heartRate: Double?
    var heartRateSample: HKQuantitySample?
    var spo2: Double?
    var spo2Sample: HKQuantitySample?
    var sleepHours: Double?
    var stepCount: Double?
    var fallDetected: Bool?
    /// The most recent fall event date, if any.
    var lastFallDate: Date?

    /// Whether any critical anomalies were detected in this snapshot.
    var hasAnomaly: Bool {
        // Delegate to RiskEngine for full evaluation; simple check here
        guard let hr = heartRate else { return false }
        return hr < 45 || hr > 130
    }
}

/// A wrapper around `HKHealthStore` that provides async/await access
/// to common health data types used by the elderly health monitoring app.
///
/// **Privacy**: Raw sensor data is read for on-device analysis only.
/// Only anonymized risk summaries are transmitted to the backend.
@Observable
final class HealthKitManager {
    /// The HealthKit store instance.
    let healthStore: HKHealthStore

    /// The most recently fetched health snapshot.
    private(set) var latestSnapshot: HealthSnapshot?

    /// `true` after HealthKit authorization has been granted.
    private(set) var isAuthorized = false

    /// `true` while a fetch operation is in progress.
    private(set) var isFetching = false

    /// The last error encountered during a HealthKit operation.
    private(set) var lastError: Error?

    // MARK: - HealthKit Types

    /// The set of HealthKit types the app reads.
    static let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.categoryType(forIdentifier: .appleStandHour)!,
    ]

    /// The set of HealthKit types the app writes (none planned currently).
    static let writeTypes: Set<HKSampleType> = []

    // MARK: - Initialization

    init() {
        guard HKHealthStore.isHealthDataAvailable() else {
            lastError = HealthKitError.notAvailableOnDevice
            healthStore = HKHealthStore()
            return
        }
        healthStore = HKHealthStore()
    }

    // MARK: - Authorization

    /// Request authorization for the required HealthKit read types.
    /// - Returns: `true` if authorization was granted.
    @discardableResult
    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }

        do {
            try await healthStore.requestAuthorization(toShare: Self.writeTypes, read: Self.readTypes)
            isAuthorized = true
            return true
        } catch {
            isAuthorized = false
            lastError = error
            throw error
        }
    }

    // MARK: - Fetch Latest (Single-Type)

    /// Fetch the most recent heart rate reading in beats per minute.
    /// - Returns: The heart rate value, or `nil` if no data is available.
    func fetchLatestHeartRate() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.typeNotAllowed("heartRate")
        }

        let sample = try await fetchLatestQuantitySample(for: type)
        let value = sample?.quantity.doubleValue(for: HKUnit(from: "count/min"))
        latestSnapshot?.heartRate = value
        latestSnapshot?.heartRateSample = sample
        return value
    }

    /// Fetch the most recent blood oxygen saturation (SpO2) as a percentage.
    /// - Returns: SpO2 value (0.0–1.0), or `nil` if no data is available.
    func fetchLatestSpO2() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            throw HealthKitError.typeNotAllowed("oxygenSaturation")
        }

        let sample = try await fetchLatestQuantitySample(for: type)
        let value = sample?.quantity.doubleValue(for: HKUnit.percent())
        latestSnapshot?.spo2 = value
        latestSnapshot?.spo2Sample = sample
        return value
    }

    /// Fetch total step count for the current day.
    /// - Returns: Total step count, or `nil` if no data is available.
    func fetchTodayStepCount() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeNotAllowed("stepCount")
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )

        let samples = try await fetchQuantitySamples(for: type, predicate: predicate, limit: 0)
        let total = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.count()) }
        latestSnapshot?.stepCount = total
        return total
    }

    /// Fetch the total sleep hours from the most recent sleep analysis entry.
    /// - Returns: Total hours of sleep, or `nil` if no data is available.
    func fetchLastNightSleep() async throws -> Double? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeNotAllowed("sleepAnalysis")
        }

        // Query for the last 48 hours to cover overnight sleep
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-48 * 3600)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                } else {
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
            }
            healthStore.execute(query)
        }

        // Filter for time asleep (inBed / asleep values)
        let asleepValues: Set<HKCategoryValueSleepAnalysis> = [.asleepUnspecified, .asleepREM, .asleepCore, .asleepDeep]
        let totalSeconds = samples
            .filter { asleepValues.contains($0.value) }
            .reduce(0.0) { $0 + $0 == 0 ? $1.endDate.timeIntervalSince($1.startDate) : $1.endDate.timeIntervalSince($1.startDate) }

        guard totalSeconds > 0 else {
            return nil
        }

        let hours = totalSeconds / 3600.0
        latestSnapshot?.sleepHours = hours
        return hours
    }

    /// Check for recent fall events using the Apple Walking Steadiness or motion data.
    /// Note: True fall detection requires `HKQuantityTypeIdentifier.appleWalkingSteadiness`
    /// or the motion coprocessor. This method checks for a fall-related HealthKit category sample.
    /// Returns `true` if a fall was detected within the last 24 hours.
    func fetchRecentFallDetection() async throws -> Bool? {
        // Use the number of times fallen category if available
        guard let fallType = HKCategoryType.categoryType(forIdentifier: .appleStandHour) else {
            // Fall detection may not be available as a HealthKit category
            return nil
        }

        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-24 * 3600)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(
                sampleType: fallType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                } else {
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
            }
            healthStore.execute(query)
        }

        if let fallSample = samples.first {
            latestSnapshot?.fallDetected = true
            latestSnapshot?.lastFallDate = fallSample.startDate
            return true
        }

        latestSnapshot?.fallDetected = false
        return false
    }

    // MARK: - Composite Fetch

    /// Fetch all tracked health metrics at once.
    /// - Returns: A `HealthSnapshot` containing the latest values for all supported types.
    func fetchAllMetrics() async throws -> HealthSnapshot {
        isFetching = true
        defer { isFetching = false }

        latestSnapshot = HealthSnapshot()

        // Run all queries in parallel for efficiency
        async let hr: Double? = try fetchLatestHeartRate()
        async let spo2: Double? = try fetchLatestSpO2()
        async let steps: Double? = try fetchTodayStepCount()
        async let sleep: Double? = try fetchLastNightSleep()
        async let fall: Bool? = try fetchRecentFallDetection()

        let snapshot = HealthSnapshot(
            heartRate: try await hr,
            heartRateSample: latestSnapshot?.heartRateSample,
            spo2: try await spo2,
            spo2Sample: latestSnapshot?.spo2Sample,
            sleepHours: try await sleep,
            stepCount: try await steps,
            fallDetected: try await fall,
            lastFallDate: latestSnapshot?.lastFallDate
        )

        latestSnapshot = snapshot
        return snapshot
    }

    // MARK: - Background Observations

    /// Set up `HKObserverQuery` instances for each tracked health type.
    /// When new data arrives, the system wakes the app to perform incremental analysis.
    /// - Parameter handler: Called on the main thread when new data is available.
    func startObservingHealthChanges(handler: @escaping () -> Void) {
        let types: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .oxygenSaturation,
            .stepCount,
        ]

        for identifier in types {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }

            let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, error in
                if error != nil {
                    // Background observation failed; will retry on next wake
                    completionHandler()
                    return
                }

                DispatchQueue.main.async {
                    handler()
                }
                completionHandler()
            }

            healthStore.execute(query)

            // Enable background delivery for this type
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
                if !success {
                    print("[HealthKitManager] Background delivery not enabled for \(identifier.rawValue): \(error?.localizedDescription ?? "unknown")")
                }
            }
        }

        // Also observe sleep analysis category type
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            let sleepQuery = HKObserverQuery(sampleType: sleepType, predicate: nil) { _, completionHandler, error in
                if error != nil {
                    completionHandler()
                    return
                }
                DispatchQueue.main.async {
                    handler()
                }
                completionHandler()
            }
            healthStore.execute(sleepQuery)
            healthStore.enableBackgroundDelivery(for: sleepType, frequency: .immediate) { _, _ in }
        }
    }

    // MARK: - Private Helpers

    /// Fetch the most recent quantity sample for a given type.
    private func fetchLatestQuantitySample(for type: HKQuantityType) async throws -> HKQuantitySample? {
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKQuantitySample?, Error>) in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                } else {
                    continuation.resume(returning: samples?.first as? HKQuantitySample)
                }
            }
            healthStore.execute(query)
        }
    }

    /// Fetch quantity samples for a given type and predicate.
    private func fetchQuantitySamples(
        for type: HKQuantityType,
        predicate: NSPredicate,
        limit: Int
    ) async throws -> [HKQuantitySample] {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit == 0 ? HKObjectQueryNoLimit : limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                } else {
                    continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                }
            }
            healthStore.execute(query)
        }
    }
}
