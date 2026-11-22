import SwiftUI

/// 能力の一覧。今の読み取り値をそのまま出す。
struct AbilitiesView: View {
    @StateObject private var health = HealthManager()
    @StateObject private var motion = MotionManager()
    @StateObject private var environment = EnvironmentManager()
    @StateObject private var location = LocationManager()

    var body: some View {
        NavigationStack {
            List {
                Section("体の状態") {
                    LabeledContent("心拍", value: health.heartRateText)
                    LabeledContent("ゆうべの睡眠", value: health.sleepText)
                    Button("ヘルスケアの許可と更新") {
                        health.requestAuthorizationAndRefresh()
                    }
                }

                Section("動きと高さ") {
                    LabeledContent("状態", value: motion.activityText)
                    LabeledContent("気圧", value: motion.pressureText)
                    LabeledContent("相対高度", value: motion.altitudeText)
                    Button("計測を開始") { motion.start() }
                }

                Section("耳と電池") {
                    LabeledContent("電池", value: environment.batteryText)
                    LabeledContent("周りの音", value: environment.audioLevelText)
                    Button(environment.isMetering ? "音の計測を止める" : "周りの音を測る") {
                        environment.toggleMetering()
                    }
                    LabeledContent("再生中", value: environment.nowPlayingText)
                    Button("再生中を更新") { environment.refreshNowPlaying() }
                }

                Section("居場所の節目") {
                    LabeledContent("状態", value: location.statusText)
                    Button("今いる場所を節目ポイントに登録") {
                        location.registerGeofenceAtCurrentLocation()
                    }
                    ForEach(location.events, id: \.self) { event in
                        Text(event).font(.footnote)
                    }
                }
            }
            .navigationTitle("能力")
            .onAppear {
                environment.refreshBattery()
                environment.refreshNowPlaying()
            }
        }
    }
}
