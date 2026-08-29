import ImageDropCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var viewModel: ConversionViewModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 16) {
            Text("画像をドロップするだけで、Web向けJPEGを元画像と同じフォルダに保存します。")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 44, weight: .light))
                Text("画像をここにドロップ")
                    .font(.title2)
                Text("HEIC / HEIF / JPEG / PNG / 複数可")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(isTargeted ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(isTargeted ? Color.accentColor : Color.secondary.opacity(0.28), style: StrokeStyle(lineWidth: 1.5, dash: [7])))
            .dropDestination(for: URL.self, action: { urls, _ in
                viewModel.process(urls: urls)
                return true
            }, isTargeted: { isTargeted = $0 })

            status
            if !viewModel.results.isEmpty { ResultListView(results: viewModel.results) }
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Text("変換設定")
                    .font(.body.weight(.semibold))
                SettingsControls()
            }
        }
        .padding(28)
        .frame(minHeight: 460, maxHeight: 460)
    }

    @ViewBuilder private var status: some View {
        switch viewModel.state {
        case .idle: EmptyView()
        case let .converting(completed, total):
            VStack(spacing: 4) { Text("\(total)枚の画像を変換中…"); Text("\(completed) / \(total)").foregroundStyle(.secondary) }
        case let .finished(summary):
            VStack(spacing: 4) {
                Text("\(summary.converted)枚の画像を変換しました")
                Text("\(ByteCountFormatter.string(fromByteCount: summary.inputBytes, countStyle: .file)) → \(ByteCountFormatter.string(fromByteCount: summary.outputBytes, countStyle: .file))")
                    .foregroundStyle(.secondary)
                if summary.failed + summary.skipped > 0 { Text("失敗 \(summary.failed)件・スキップ \(summary.skipped)件").foregroundStyle(.orange) }
            }
        }
    }
}

struct ResultListView: View {
    let results: [ConversionResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(results.suffix(3)) { result in
                HStack {
                    Text(result.sourceURL.lastPathComponent).lineLimit(1)
                Spacer()
                switch result.outcome {
                    case .converted: Label("変換済み", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    case let .skipped(reason): Label("スキップ: \(reason)", systemImage: "minus.circle").foregroundStyle(.secondary)
                    case let .failed(reason): Label("エラー: \(reason)", systemImage: "exclamationmark.circle.fill").foregroundStyle(.red)
                    }
                }
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
