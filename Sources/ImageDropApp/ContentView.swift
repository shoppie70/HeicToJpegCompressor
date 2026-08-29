import ImageDropCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var viewModel: ConversionViewModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 44, weight: .light))
                Text("画像をここにドロップ")
                    .font(.title2)
                Text("HEIC / HEIF / JPEG / PNG / 複数可")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 230)
            .background(isTargeted ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(isTargeted ? Color.accentColor : Color.secondary.opacity(0.28), style: StrokeStyle(lineWidth: 1.5, dash: [7])))
            .dropDestination(for: URL.self, action: { urls, _ in
                viewModel.process(urls: urls)
                return true
            }, isTargeted: { isTargeted = $0 })

            status
            if !viewModel.results.isEmpty { ResultListView(results: viewModel.results) }
            Text(settingsSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(28)
    }

    @ViewBuilder private var status: some View {
        switch viewModel.state {
        case .idle: EmptyView()
        case let .converting(completed, total):
            VStack(spacing: 4) { Text("Converting \(total) images…"); Text("\(completed) / \(total)").foregroundStyle(.secondary) }
        case let .finished(summary):
            VStack(spacing: 4) {
                Text("\(summary.converted) images converted")
                Text("\(ByteCountFormatter.string(fromByteCount: summary.inputBytes, countStyle: .file)) → \(ByteCountFormatter.string(fromByteCount: summary.outputBytes, countStyle: .file))")
                    .foregroundStyle(.secondary)
                if summary.failed + summary.skipped > 0 { Text("\(summary.failed) failed, \(summary.skipped) skipped").foregroundStyle(.orange) }
            }
        }
    }

    private var settingsSummary: String {
        let settings = AppPreferences.snapshot
        let edge = settings.maxLongEdge.map { "max \($0) px" } ?? "original size"
        return "JPEG / \(edge) / quality \(settings.jpegQuality.formatted(.number.precision(.fractionLength(2)))) / \(settings.removeMetadata ? "metadata removed" : "metadata kept")"
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
                    case .converted: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    case .skipped: Image(systemName: "minus.circle").foregroundStyle(.secondary)
                    case .failed: Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
                    }
                }
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
