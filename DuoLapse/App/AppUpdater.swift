import Foundation
import Sparkle
import SwiftUI

final class AppUpdater {
    private let controller: SPUStandardUpdaterController?

    init() {
        let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        controller =
            publicKey.isEmpty
            ? nil
            : SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    var isAvailable: Bool {
        controller != nil
    }

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
}

struct CheckForUpdatesButton: View {
    let updater: AppUpdater

    var body: some View {
        Button("Check for Updates…", action: updater.checkForUpdates)
            .disabled(!updater.isAvailable)
    }
}
