import Foundation
import UIKit
import AVFoundation
import MediaPlayer

/// 電池・周りの音・再生中を読む係。
final class EnvironmentManager: ObservableObject {
    @Published var batteryText: String = "未取得"
    @Published var audioLevelText: String = "未計測"
    @Published var nowPlayingText: String = "未取得"
    @Published var isMetering: Bool = false

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    // MARK: - 電池

    func refreshBattery() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        if level < 0 {
            batteryText = "不明"
        } else {
            batteryText = "\(Int(level * 100))%"
        }
    }

    // MARK: - 周りの音（録音は保存しない。大きさだけを測る）

    func toggleMetering() {
        if isMetering {
            stopMetering()
        } else {
            startMetering()
        }
    }

    private func startMetering() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard granted else {
                Task { @MainActor in self?.audioLevelText = "マイクの許可がありません" }
                return
            }
            Task { @MainActor in self?.beginMetering() }
        }
    }

    private func beginMetering() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
            let url = URL(fileURLWithPath: "/dev/null")
            recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: Int(kAudioFormatAppleLossless),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
            ])
            recorder?.isMeteringEnabled = true
            recorder?.record()
            isMetering = true
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                guard let self, let recorder = self.recorder else { return }
                recorder.updateMeters()
                let db = recorder.averagePower(forChannel: 0)
                Task { @MainActor in
                    self.audioLevelText = String(format: "%.0f dB（目安）", db)
                }
            }
        } catch {
            audioLevelText = "計測を開始できませんでした"
        }
    }

    private func stopMetering() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        isMetering = false
        audioLevelText = "停止中"
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - 再生中（Musicアプリのシステム再生キュー）

    func refreshNowPlaying() {
        MPMediaLibrary.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                Task { @MainActor in self?.nowPlayingText = "許可がありません" }
                return
            }
            let player = MPMusicPlayerController.systemMusicPlayer
            Task { @MainActor in
                if let item = player.nowPlayingItem {
                    let title = item.title ?? "不明な曲"
                    let artist = item.artist ?? ""
                    self?.nowPlayingText = artist.isEmpty ? title : "\(title) / \(artist)"
                } else {
                    self?.nowPlayingText = "再生していません"
                }
            }
        }
    }
}
