import HeicToJpegCompressorCore
import SwiftUI

struct SettingsControls: View {
    @AppStorage(AppPreferences.maxLongEdgeKey) private var maxLongEdge = LongEdgeOption.pixels1980.rawValue
    @AppStorage(AppPreferences.customLongEdgeKey) private var customLongEdge = ConversionSettings.defaultMaxLongEdge
    @AppStorage(AppPreferences.jpegQualityKey) private var jpegQuality = ConversionSettings.defaultJPEGQuality
    @AppStorage(AppPreferences.removeMetadataKey) private var removeMetadata = true
    @AppStorage(AppPreferences.autoRotateKey) private var autoRotate = true
    @State private var showsAdvancedOptions = false

    var body: some View {
        Group {
            Picker("最大長辺", selection: $maxLongEdge) {
                ForEach(LongEdgeOption.allCases, id: \.rawValue) { option in
                    Text(option.label).tag(option.rawValue)
                }
            }

            if maxLongEdge == LongEdgeOption.custom.rawValue {
                TextField("最大長辺（px）", value: $customLongEdge, format: .number)
            }

            HStack {
                Text("JPEG品質")
                Slider(value: $jpegQuality, in: 0...1)
                Text(jpegQuality.formatted(.number.precision(.fractionLength(2))))
                    .monospacedDigit()
                    .frame(width: 34, alignment: .trailing)
            }

            DisclosureGroup("詳細オプション", isExpanded: $showsAdvancedOptions) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("メタデータを削除", isOn: $removeMetadata)
                    Toggle("画像の向きを自動補正", isOn: $autoRotate)
                }
                .padding(.top, 4)
            }
        }
        .font(.body)
    }
}
