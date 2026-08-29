import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            SettingsControls()
        }
        .padding(20)
        .frame(width: 430)
    }
}
