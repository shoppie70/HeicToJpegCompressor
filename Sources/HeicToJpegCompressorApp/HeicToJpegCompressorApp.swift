import AppKit
import HeicToJpegCompressorCore
import SwiftUI
@preconcurrency import UserNotifications

@main
struct HeicToJpegCompressorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = ConversionViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onAppear { appDelegate.receive = viewModel.process(urls:) }
        }
        .defaultSize(width: 560, height: 460)

        Settings {
            SettingsView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var receive: (([URL]) -> Void)? {
        didSet {
            guard let receive, !pendingURLs.isEmpty else { return }
            receive(pendingURLs)
            pendingURLs = []
        }
    }
    private var pendingURLs: [URL] = []

    func application(_ application: NSApplication, open urls: [URL]) {
        deliver(urls)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        deliver(filenames.map(URL.init(fileURLWithPath:)))
        sender.reply(toOpenOrPrint: .success)
    }

    private func deliver(_ urls: [URL]) {
        guard let receive else { pendingURLs.append(contentsOf: urls); return }
        receive(urls)
    }
}

@MainActor
final class ConversionViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case converting(completed: Int, total: Int)
        case finished(summary: BatchSummary)
    }

    struct BatchSummary: Equatable, Sendable {
        let converted: Int
        let failed: Int
        let skipped: Int
        let inputBytes: Int64
        let outputBytes: Int64
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var results: [ConversionResult] = []

    func process(urls: [URL]) {
        guard !urls.isEmpty else { return }
        let settings = AppPreferences.snapshot
        state = .converting(completed: 0, total: urls.count)
        results = []

        Task { [weak self] in
            var batch: [ConversionResult] = []
            for url in urls {
                let result = await Task.detached(priority: .userInitiated) {
                    ImageConversionService().convert(url: url, settings: settings)
                }.value
                batch.append(result)
                self?.results = batch
                self?.state = .converting(completed: batch.count, total: urls.count)
            }
            let summary = Self.summary(for: batch)
            self?.state = .finished(summary: summary)
            NotificationService.post(summary: summary)
        }
    }

    nonisolated private static func summary(for results: [ConversionResult]) -> BatchSummary {
        var converted = 0, failed = 0, skipped = 0
        var inputBytes: Int64 = 0, outputBytes: Int64 = 0
        for result in results {
            switch result.outcome {
            case let .converted(_, input, output, _):
                converted += 1; inputBytes += input; outputBytes += output
            case .failed: failed += 1
            case .skipped: skipped += 1
            }
        }
        return BatchSummary(converted: converted, failed: failed, skipped: skipped, inputBytes: inputBytes, outputBytes: outputBytes)
    }
}

enum AppPreferences {
    static let maxLongEdgeKey = "maxLongEdge"
    static let jpegQualityKey = "jpegQuality"
    static let removeMetadataKey = "removeMetadata"
    static let autoRotateKey = "autoRotateEnabled"
    static let customLongEdgeKey = "customLongEdge"

    static var snapshot: ConversionSettings {
        let defaults = UserDefaults.standard
        let selection = defaults.object(forKey: maxLongEdgeKey) as? Int ?? LongEdgeOption.pixels1980.rawValue
        let maximumLongEdge: Int?
        if selection == LongEdgeOption.original.rawValue { maximumLongEdge = nil }
        else if selection == LongEdgeOption.custom.rawValue { maximumLongEdge = Swift.max(1, defaults.object(forKey: customLongEdgeKey) as? Int ?? ConversionSettings.defaultMaxLongEdge) }
        else { maximumLongEdge = selection > 0 ? selection : ConversionSettings.defaultMaxLongEdge }
        return ConversionSettings(
            maxLongEdge: maximumLongEdge,
            jpegQuality: defaults.object(forKey: jpegQualityKey) as? Double ?? ConversionSettings.defaultJPEGQuality,
            removeMetadata: defaults.object(forKey: removeMetadataKey) as? Bool ?? true,
            autoRotateEnabled: defaults.object(forKey: autoRotateKey) as? Bool ?? true
        )
    }
}

enum NotificationService {
    static func post(summary: ConversionViewModel.BatchSummary) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "HEICをJPEGへ縮小圧縮するだけ"
            content.body = summary.failed == 0 && summary.skipped == 0
                ? "\(summary.converted)枚の画像を変換しました"
                : "\(summary.converted)枚を変換、\(summary.failed + summary.skipped)件は変換されませんでした"
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        }
    }
}
