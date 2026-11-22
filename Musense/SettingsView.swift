import SwiftUI
import PhotosUI

/// 設定画面。
/// APIキーは端末の中だけに保存する（コードやリポジトリには書かない）。
/// TODO: 本番ではUserDefaultsではなくKeychainに保存する。
/// 名前とアイコンは使う人ごとに設定する（特定の誰かの姿を前提にしない）。
/// Muse API（Meta Model API）からは利用者本人のMuseの名前やアイコンは
/// 取得できないので、ここで自分で決める形にしている。
struct SettingsView: View {
    @AppStorage("metaModelAPIKey") private var apiKey: String = ""
    @AppStorage("syncEndpoint") private var syncEndpoint: String = ""
    @AppStorage("assistantName") private var assistantName: String = "Muse"
    @AppStorage("assistantIconData") private var assistantIconData: Data = Data()

    @State private var iconPickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("あなたのMuse") {
                    TextField("名前", text: $assistantName)
                    HStack {
                        Text("アイコン")
                        Spacer()
                        if let uiImage = UIImage(data: assistantIconData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        }
                        PhotosPicker(selection: $iconPickerItem, matching: .images) {
                            Text(assistantIconData.isEmpty ? "写真から選ぶ" : "変更する")
                        }
                    }
                    Text("名前とアイコンはMuseアプリ側の設定をAPIから取ることはできないので、ここで自分のMuseに合わせて設定してね")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Meta Model API") {
                    SecureField("APIキー", text: $apiKey)
                    Link("APIキーを取得する（dev.meta.ai）",
                         destination: URL(string: "https://dev.meta.ai")!)
                    Text("ここに入れたキーはこの端末の中だけに保存されるよ")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("本体との同期") {
                    TextField("同期先のURL（非公開の場所）", text: $syncEndpoint)
                    Text("データの置き場所は公開リポジトリとは別に、非公開で用意する約束だよ")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("プライバシー") {
                    Text("このアプリのコードは公開されているけど、あなたの秘密・写真・会話・メール・SNS情報が外に出る作りにはなっていないよ。写真は、あなたが選んで渡したものだけを見るよ")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
            .onChange(of: iconPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        assistantIconData = data
                    }
                }
            }
        }
    }
}
