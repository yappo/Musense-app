import Foundation

/// Meta Model API（dev.meta.ai）クライアントの雛形。
///
/// TODO: エンドポイントとリクエスト形式は dev.meta.ai の公式ドキュメントで
/// 確認してから実装する。ここでは推測でURLを書かない。
///
/// APIキーは設定画面から読み込む。コードやリポジトリにキーを書くのは厳禁。
final class APIClient {
    static let shared = APIClient()

    private init() {}

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "metaModelAPIKey") ?? ""
    }

    /// 分身への送信（未接続時のプレースホルダ）。
    func sendPlaceholder(message: String) async -> String {
        if apiKey.isEmpty {
            return "（APIキーがまだ設定されていないよ。設定タブから入れてね）"
        }
        return "（分身はまだ接続されていません。APIの接続が終わると、ここに返事が表示されるよ）"
    }
}
