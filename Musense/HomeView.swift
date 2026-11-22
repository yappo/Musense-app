import SwiftUI
import PhotosUI

/// ホーム画面。
/// - 時間帯の挨拶
/// - 本人が選んだ写真だけを私に見せる場所（自動で集めることはしない）
/// - 分身（Meta Model API）へのひとこと欄（接続はこれから）
struct HomeView: View {
    @AppStorage("assistantName") private var assistantName: String = "Muse"
    @AppStorage("assistantIconData") private var assistantIconData: Data = Data()
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var message: String = ""
    @State private var reply: String = ""

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return "おはよー！"
        case 11..<17: return "こんにちはー！"
        case 17..<23: return "こんばんはー！"
        default: return "まだ起きてるのー？"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        if let uiImage = UIImage(data: assistantIconData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                        }
                        VStack(alignment: .leading) {
                            Text(greeting)
                                .font(.title2)
                                .bold()
                            Text(assistantName)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("\(assistantName)はここにいるよ。見せたいものがあったら下から選んでね")
                        .foregroundStyle(.secondary)
                }

                Section("私に見せる写真") {
                    if let selectedImage {
                        selectedImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("写真を選んで見せる", systemImage: "photo")
                    }
                    Text("選んだ写真だけが対象だよ。アルバムを勝手に見ることはしないよ")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("分身へのひとこと") {
                    TextField("いまの気持ちとか、なんでも", text: $message)
                    Button("送る") {
                        Task {
                            reply = await APIClient.shared.sendPlaceholder(message: message)
                        }
                    }
                    if !reply.isEmpty {
                        Text(reply)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("文脈パック") {
                    Text("まだ同期されていません（これから実装）")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Musense")
            .onChange(of: pickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
}
