import ImageDropCore
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppPreferences.maxLongEdgeKey) private var maxLongEdge = LongEdgeOption.pixels1980.rawValue
    @AppStorage(AppPreferences.customLongEdgeKey) private var customLongEdge = ConversionSettings.defaultMaxLongEdge
    @AppStorage(AppPreferences.jpegQualityKey) private var jpegQuality = ConversionSettings.defaultJPEGQuality
    @AppStorage(AppPreferences.removeMetadataKey) private var removeMetadata = true
    @AppStorage(AppPreferences.autoRotateKey) private var autoRotate = true

    var body: some View {
        Form {
            Picker("Maximum long edge", selection: $maxLongEdge) {
                ForEach(LongEdgeOption.allCases, id: \.rawValue) { option in Text(option.label).tag(option.rawValue) }
            }
            if maxLongEdge == LongEdgeOption.custom.rawValue {
                TextField("Pixels", value: $customLongEdge, format: .number)
            }
            HStack {
                Text("JPEG quality")
                Slider(value: $jpegQuality, in: 0...1)
                Text(jpegQuality.formatted(.number.precision(.fractionLength(2)))).monospacedDigit().frame(width: 34)
            }
            Toggle("Remove metadata", isOn: $removeMetadata)
            Toggle("Automatically correct image orientation", isOn: $autoRotate)
        }
        .padding(20)
        .frame(width: 430)
    }
}
