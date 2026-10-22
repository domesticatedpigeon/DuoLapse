import AppKit
import DuoLapseCore
import SwiftUI
import UniformTypeIdentifiers

struct ExportSheet: View {
    @State private var model: ExportModel
    @State private var isChoosingFolder = false
    @Environment(\.dismiss) private var dismiss

    init(session: TimelapseSession, store: SessionStore) {
        _model = State(initialValue: ExportModel(session: session, store: store))
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                ExportPreviewSection(image: model.previewImage)
                ExportLengthSection(model: model)
                ExportLayoutSection(model: model)
                ExportFileSection(model: model, isChoosingFolder: $isChoosingFolder)
            }
            .formStyle(.grouped)
            .disabled(!isEditable)

            Divider()
            ExportActionBar(model: model, close: close)
                .padding()
        }
        .frame(minWidth: 500, idealWidth: 540, minHeight: 600, idealHeight: 720)
        .task {
            await model.prepare()
        }
        .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder]) { result in
            if case .success(let folder) = result {
                model.outputFolder = folder
            }
        }
    }

    private var isEditable: Bool {
        if case .ready = model.phase { true } else { false }
    }

    private func close() {
        model.cancelBackgroundWork()
        dismiss()
    }
}

private struct ExportPreviewSection: View {
    let image: CGImage?

    var body: some View {
        Section {
            Group {
                if let image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .accessibilityLabel("Preview of the exported video")
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 160)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 240)
        }
    }
}

private struct ExportLengthSection: View {
    @Bindable var model: ExportModel

    var body: some View {
        Section("Length") {
            Picker("Video length", selection: $model.durationOption) {
                ForEach(model.selectableDurationOptions, id: \.self) { option in
                    Text(label(for: option)).tag(option)
                }
            }
            if model.durationOption == .custom {
                Stepper(value: $model.customDurationSeconds, in: 1...model.maximumCustomSeconds) {
                    LabeledContent("Custom length", value: formatted(seconds: Double(model.customDurationSeconds)))
                }
            }
        }
    }

    private func label(for option: ExportDurationOption) -> String {
        switch option {
        case .thirtySeconds: "30 seconds"
        case .oneMinute: "1 minute"
        case .threeMinutes: "3 minutes"
        case .fullLength: "Full length (\(formatted(seconds: model.fullLengthSeconds)))"
        case .custom: "Custom"
        }
    }

    private func formatted(seconds: Double) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
    }
}

private struct ExportLayoutSection: View {
    @Bindable var model: ExportModel

    var body: some View {
        Section("Layout") {
            Picker("Orientation", selection: $model.settings.layout.orientation) {
                Text("Horizontal").tag(ExportOrientation.horizontal)
                Text("Vertical").tag(ExportOrientation.vertical)
            }
            .pickerStyle(.segmented)

            if model.hasScreenAndCamera {
                switch model.settings.layout.orientation {
                case .horizontal:
                    HorizontalLayoutControls(layout: $model.settings.layout)
                case .vertical:
                    Picker("On top", selection: $model.settings.layout.verticalOrder) {
                        Text("Screen").tag(VerticalOrder.screenOnTop)
                        Text("Camera").tag(VerticalOrder.cameraOnTop)
                    }
                }
            }

            Toggle("Show timestamp", isOn: $model.settings.includesTimestamp)
        }
    }
}

private struct HorizontalLayoutControls: View {
    @Binding var layout: ExportLayout

    var body: some View {
        Picker("Arrangement", selection: $layout.horizontalArrangement) {
            Text("Picture in picture").tag(HorizontalArrangement.pictureInPicture)
            Text("Side by side").tag(HorizontalArrangement.sideBySide)
        }

        if layout.horizontalArrangement == .pictureInPicture {
            Picker("Camera position", selection: $layout.cameraOverlay.corner) {
                Text("Top left").tag(OverlayCorner.topLeading)
                Text("Top right").tag(OverlayCorner.topTrailing)
                Text("Bottom left").tag(OverlayCorner.bottomLeading)
                Text("Bottom right").tag(OverlayCorner.bottomTrailing)
            }
            Picker("Camera size", selection: $layout.cameraOverlay.size) {
                Text("Small").tag(OverlaySize.small)
                Text("Medium").tag(OverlaySize.medium)
                Text("Large").tag(OverlaySize.large)
            }
            Toggle("Circle", isOn: $layout.cameraOverlay.isCircular)
            LabeledContent("Corner radius") {
                Slider(
                    value: $layout.cameraOverlay.cornerRadiusFraction,
                    in: 0...CameraOverlay.maximumCornerRadiusFraction
                )
                .accessibilityValue(
                    Text(
                        (layout.cameraOverlay.cornerRadiusFraction / CameraOverlay.maximumCornerRadiusFraction)
                            .formatted(.percent.precision(.fractionLength(0)))
                    )
                )
            }
            .disabled(layout.cameraOverlay.isCircular)
        }
    }
}

private struct ExportFileSection: View {
    @Bindable var model: ExportModel
    @Binding var isChoosingFolder: Bool

    var body: some View {
        Section("File") {
            Picker("Format", selection: $model.settings.codec) {
                Text("HEVC (smaller file)").tag(ExportCodec.hevc)
                Text("H.264 (plays everywhere)").tag(ExportCodec.h264)
            }
            LabeledContent("Save to") {
                HStack {
                    Text(model.outputFolder.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Choose…") { isChoosingFolder = true }
                }
            }
            TextField("File name", text: $model.settings.filenameTemplate.pattern)
            LabeledContent("Preview", value: model.filenamePreview)
            Text("Use {YYYY}, {YY}, {MM}, {DD}, {hh}, {mm} and {ss} for the recording’s start date and time.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ExportActionBar: View {
    let model: ExportModel
    let close: () -> Void

    var body: some View {
        HStack {
            switch model.phase {
            case .preparing:
                ProgressView()
                    .controlSize(.small)
                Text("Reading frames…")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Cancel", role: .cancel, action: close)
            case .ready:
                Spacer()
                Button("Cancel", role: .cancel, action: close)
                Button("Export", action: model.startExport)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            case .exporting(let progress):
                ProgressView(value: progress)
                    .accessibilityLabel("Export progress")
                Button("Stop Export", action: model.cancelExport)
            case .finished(let url):
                Label("Exported \(url.lastPathComponent)", systemImage: "checkmark.circle.fill")
                    .lineLimit(1)
                Spacer()
                Button("Show in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                Button("Done", action: close)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .lineLimit(3)
                Spacer()
                Button("Close", action: close)
            }
        }
        .controlSize(.large)
    }
}
