import Foundation
import CoreMotion

/// 動きの状態（歩行・乗り物・静止）と、気圧・相対高度を読む係。
final class MotionManager: ObservableObject {
    @Published var activityText: String = "未計測"
    @Published var pressureText: String = "未計測"
    @Published var altitudeText: String = "未計測"

    private let activityManager = CMMotionActivityManager()
    private let altimeter = CMAltimeter()
    private var started = false

    func start() {
        guard !started else { return }
        started = true

        if CMMotionActivityManager.isActivityAvailable() {
            activityManager.startActivityUpdates(to: .main) { [weak self] activity in
                guard let activity else { return }
                Task { @MainActor in
                    self?.activityText = Self.describe(activity)
                }
            }
        } else {
            activityText = "この端末では使えません"
        }

        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
                guard let data else { return }
                Task { @MainActor in
                    self?.pressureText = String(format: "%.2f hPa", data.pressure.doubleValue * 10)
                    self?.altitudeText = String(format: "%+.1f m", data.relativeAltitude.doubleValue)
                }
            }
        } else {
            pressureText = "この端末では使えません"
        }
    }

    private static func describe(_ activity: CMMotionActivity) -> String {
        if activity.stationary { return "止まっている" }
        if activity.walking { return "歩いている" }
        if activity.running { return "走っている" }
        if activity.automotive { return "乗り物に乗っている" }
        if activity.cycling { return "自転車に乗っている" }
        return "不明"
    }
}
