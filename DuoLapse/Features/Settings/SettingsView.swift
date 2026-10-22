import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            LabeledContent("Version", value: Bundle.main.marketingVersion)
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }
}

extension Bundle {
    fileprivate var marketingVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
}

#Preview {
    SettingsView()
}
