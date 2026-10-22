import SwiftUI

struct RecorderControls: View {
    let model: RecorderModel

    var body: some View {
        HStack {
            Spacer()
            switch model.recorder?.session.state {
            case .recording?:
                Button("Pause", systemImage: "pause.fill", action: model.pause)
                Button("Stop", systemImage: "stop.fill", action: model.stop)
            case .paused?, .idlePaused?:
                Button("Stop", systemImage: "stop.fill", action: model.stop)
                Button("Resume", systemImage: "record.circle", action: model.resume)
                    .buttonStyle(.borderedProminent)
            case .finished?, nil:
                Button("Start Recording", systemImage: "record.circle", action: model.startNewTimelapse)
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canStartRecording)
            }
        }
        .controlSize(.large)
        .disabled(model.isChangingState)
    }
}
