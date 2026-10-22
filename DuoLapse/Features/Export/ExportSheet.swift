import AppKit
import DuoLapseCore
import SwiftUI

struct ExportSheet: View {
    @State private var model: ExportModel
    @State private var settingsScrollPosition = ScrollPosition(edge: .top)
    @Environment(\.dismiss) private var dismiss

    init(session: TimelapseSession, store: SessionStore) {
        _model = State(initialValue: ExportModel(session: session, store: store))
    }

    var body: some View {
        content
            .safeAreaBar(edge: .top, spacing: 0) {
                ExportHeader(title: model.session.title)
            }
            .safeAreaBar(edge: .bottom, spacing: 0) {
                ExportActionBar(model: model, close: close)
                    .padding()
            }
            .scrollEdgeEffectStyle(.soft, for: .all)
            .frame(
                minWidth: isVertical ? 760 : 500,
                idealWidth: isVertical ? 800 : 540,
                minHeight: 760,
                idealHeight: 860
            )
            .task {
                await model.prepare()
            }
    }

    private static let verticalPreviewWidth: CGFloat = 260

    @ViewBuilder
    private var content: some View {
        if isVertical {
            HStack(alignment: .top, spacing: 0) {
                ExportPreview(image: model.previewImage, maximumHeight: .infinity)
                    .frame(width: Self.verticalPreviewWidth)
                    .padding([.leading, .vertical], 20)
                settingsForm
            }
        } else {
            settingsForm
                .safeAreaBar(edge: .top, spacing: 0) {
                    ExportPreview(image: model.previewImage, maximumHeight: 240)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
        }
    }

    private var settingsForm: some View {
        Form {
            ExportLengthSection(model: model)
            ExportLayoutSection(model: model)
            ExportFileSection(model: model)
        }
        .formStyle(.grouped)
        .defaultScrollAnchor(.top)
        .scrollPosition($settingsScrollPosition)
        .onChange(of: isEditable) { _, isReady in
            guard isReady else { return }
            Task {
                await Task.yield()
                settingsScrollPosition.scrollTo(edge: .top)
            }
        }
        .disabled(!isEditable)
    }

    private var isVertical: Bool {
        model.settings.layout.orientation == .vertical
    }

    private var isEditable: Bool {
        if case .ready = model.phase { true } else { false }
    }

    private func close() {
        model.cancelBackgroundWork()
        dismiss()
    }
}

private struct ExportHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Export Timelapse")
                .font(.headline)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct ExportPreview: View {
    let image: CGImage?
    let maximumHeight: CGFloat

    var body: some View {
        Group {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 8))
                    .accessibilityLabel("Preview of the exported video")
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160, maxHeight: maximumHeight)
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
            LabeledContent("Orientation") {
                Picker("Orientation", selection: $model.settings.layout.orientation) {
                    Text("Horizontal").tag(ExportOrientation.horizontal)
                    Text("Vertical").tag(ExportOrientation.vertical)
                }
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
                .labelsHidden()
            }

            if model.hasScreenAndCamera {
                switch model.settings.layout.orientation {
                case .horizontal:
                    HorizontalLayoutControls(layout: $model.settings.layout)
                case .vertical:
                    Picker("On top", selection: $model.settings.layout.verticalOrder) {
                        Text("Screen").tag(VerticalOrder.screenOnTop)
                        Text("Camera").tag(VerticalOrder.cameraOnTop)
                    }
                    LabeledContent("Screen height") {
                        HStack {
                            Slider(
                                value: $model.settings.layout.verticalScreenShare,
                                in: ExportLayout.verticalScreenShareRange,
                                step: 0.05
                            )
                            .accessibilityValue(Text(screenSharePercentage))
                            Text(screenSharePercentage)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 40, alignment: .trailing)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }

            if model.framingMatters(for: .screen) {
                FramingPicker(title: "Screen", framing: $model.settings.layout.screenFraming)
            }
            if model.framingMatters(for: .camera) {
                FramingPicker(title: "Camera", framing: $model.settings.layout.cameraFraming)
            }
            Toggle("Show timestamp", isOn: $model.settings.includesTimestamp)
            if model.settings.includesTimestamp, model.settings.layout.orientation == .vertical {
                Picker("Timestamp position", selection: $model.settings.layout.verticalTimestampCorner) {
                    Text("Top left").tag(OverlayCorner.topLeading)
                    Text("Top right").tag(OverlayCorner.topTrailing)
                    Text("Bottom left").tag(OverlayCorner.bottomLeading)
                    Text("Bottom right").tag(OverlayCorner.bottomTrailing)
                }
            }
        }
    }

    private var screenSharePercentage: String {
        model.settings.layout.verticalScreenShare.formatted(.percent.precision(.fractionLength(0)))
    }
}

private struct FramingPicker: View {
    let title: String
    @Binding var framing: SourceFraming

    var body: some View {
        Picker(title, selection: $framing) {
            Text("Fill (crop edges)").tag(SourceFraming.fill)
            Text("Fit (show everything)").tag(SourceFraming.fit)
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
                HStack {
                    Slider(
                        value: $layout.cameraOverlay.cornerRadiusFraction,
                        in: 0...CameraOverlay.maximumCornerRadiusFraction,
                        step: CameraOverlay.maximumCornerRadiusFraction / 10
                    )
                    .accessibilityValue(Text(cornerRadiusPercentage))
                    Text(cornerRadiusPercentage)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 40, alignment: .trailing)
                        .accessibilityHidden(true)
                }
            }
            .disabled(layout.cameraOverlay.isCircular)
        }
    }

    private var cornerRadiusPercentage: String {
        (layout.cameraOverlay.cornerRadiusFraction / CameraOverlay.maximumCornerRadiusFraction)
            .formatted(.percent.precision(.fractionLength(0)))
    }
}

private struct ExportFileSection: View {
    let model: ExportModel

    var body: some View {
        Section("File") {
            LabeledContent("Saves as", value: model.filenamePreview)
            LabeledContent("In", value: model.outputFolder.lastPathComponent)
            SettingsLink {
                Text("Change File Settings…")
            }
            .buttonStyle(.glass)
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
                    .buttonStyle(.glassProminent)
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
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .lineLimit(3)
                Spacer()
                Button("Close", action: close)
            }
        }
        .buttonStyle(.glass)
        .controlSize(.extraLarge)
    }
}
