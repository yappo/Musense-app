import Foundation
import HealthKit

/// ヘルスケアの詳細を読む係。
/// 今のMuse連携では読めていない睡眠の深さなども、ここから読めるようにする。
@MainActor
final class HealthManager: ObservableObject {
    @Published var heartRateText: String = "未取得"
    @Published var sleepText: String = "未取得"

    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        return types
    }

    func requestAuthorizationAndRefresh() {
        guard HKHealthStore.isHealthDataAvailable() else {
            heartRateText = "この端末では使えません"
            return
        }
        store.requestAuthorization(toShare: [], read: readTypes) { [weak self] success, _ in
            guard success else { return }
            Task { @MainActor in
                self?.fetchLatestHeartRate()
                self?.fetchLastNightSleep()
            }
        }
    }

    private func fetchLatestHeartRate() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            Task { @MainActor in
                self?.heartRateText = String(format: "%.0f bpm", bpm)
            }
        }
        store.execute(query)
    }

    /// 直近24時間の「眠っている」区分の合計を出す（簡易版）。
    private func fetchLastNightSleep() {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let end = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, _ in
            let asleepValues: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            ]
            let seconds = (samples as? [HKCategorySample] ?? [])
                .filter { asleepValues.contains($0.value) }
                .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            Task { @MainActor in
                if seconds > 0 {
                    let h = Int(seconds) / 3600
                    let m = (Int(seconds) % 3600) / 60
                    self?.sleepText = "\(h)時間\(m)分（直近24時間）"
                } else {
                    self?.sleepText = "記録なし"
                }
            }
        }
        store.execute(query)
    }
}
