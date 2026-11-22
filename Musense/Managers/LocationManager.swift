import Foundation
import CoreLocation

/// 居場所の「節目」だけを知る係。
/// 常時の追跡はしない。登録した場所への到着・出発だけを記録する。
final class LocationManager: NSObject, ObservableObject {
    @Published var statusText: String = "未登録"
    @Published var events: [String] = []

    private let manager = CLLocationManager()
    private var pendingRegistration = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// 今いる場所を節目ポイント（半径100m）として登録する。
    func registerGeofenceAtCurrentLocation() {
        pendingRegistration = true
        manager.requestAlwaysAuthorization()
        manager.requestLocation()
        statusText = "現在地を取得中…"
    }

    private func addEvent(_ text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        events.insert("\(formatter.string(from: Date())) \(text)", at: 0)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard pendingRegistration, let location = locations.last else { return }
        pendingRegistration = false
        let region = CLCircularRegion(center: location.coordinate, radius: 100, identifier: "sao-point")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        manager.startMonitoring(for: region)
        statusText = "節目ポイントを登録しました"
        addEvent("節目ポイントを登録")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        pendingRegistration = false
        statusText = "位置を取得できませんでした"
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        addEvent("節目ポイントに着いた")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        addEvent("節目ポイントを出た")
    }
}
