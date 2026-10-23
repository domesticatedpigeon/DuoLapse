import DuoLapseCore
import SwiftUI

struct CaptureTimingSection: View {
    @Bindable var model: NewTimelapseModel

    var body: some View {
        Section("Timing and Quality") {
            LabeledContent("Interval") {
                HStack(spacing: 8) {
                    Text(intervalDescription)
                        .monospacedDigit()
                    Stepper("Interval", value: $model.captureIntervalSeconds, in: 1...300)
                        .labelsHidden()
                    Button(
                        "Reset to Default",
                        systemImage: "arrow.counterclockwise",
                        action: model.resetCaptureInterval
                    )
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Reset to every \(NewTimelapseModel.defaultCaptureIntervalSeconds) seconds")
                    .disabled(model.isCaptureIntervalDefault)
                }
            }

            Picker("Screen quality", selection: $model.storageResolution) {
                ForEach(StorageResolution.allCases, id: \.self) { resolution in
                    Text(resolution.displayName).tag(resolution)
                }
            }
        }
    }

    private var intervalDescription: String {
        let interval = Duration.seconds(model.captureIntervalSeconds)
        return "Every \(interval.formatted(.units(allowed: [.minutes, .seconds], width: .wide)))"
    }
}

extension StorageResolution {
    var displayName: String {
        switch self {
        case .standard: "Standard (1080p)"
        case .high: "High (1440p)"
        }
    }
}
