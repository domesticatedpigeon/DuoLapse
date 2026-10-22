import DuoLapseCore
import SwiftUI

struct RecorderForm: View {
    @Bindable var model: RecorderModel

    var body: some View {
        Form {
            Section("Capture") {
                Picker("Display", selection: $model.selectedDisplayUUID) {
                    ForEach(model.displays) { display in
                        Text(display.name).tag(Optional(display.uuid))
                    }
                }

                Stepper(value: $model.captureIntervalSeconds, in: 1...300) {
                    LabeledContent("Interval", value: intervalDescription)
                }

                Picker("Quality", selection: $model.storageResolution) {
                    ForEach(StorageResolution.allCases, id: \.self) { resolution in
                        Text(resolution.displayName).tag(resolution)
                    }
                }
            }
            .disabled(!model.canEditSettings)

            if let recorder = model.recorder {
                RecordingStatusSection(recorder: recorder)
            }
        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .bottom) {
            RecorderControls(model: model)
                .padding()
        }
        .task {
            await model.loadDisplays()
        }
    }

    private var intervalDescription: String {
        let interval = Duration.seconds(model.captureIntervalSeconds)
        return "Every \(interval.formatted(.units(allowed: [.minutes, .seconds], width: .wide)))"
    }
}

extension StorageResolution {
    fileprivate var displayName: String {
        switch self {
        case .standard: "Standard (1080p)"
        case .high: "High (1440p)"
        }
    }
}
