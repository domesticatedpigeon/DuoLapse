import AppKit
import DuoLapseCore
import SwiftUI

struct ExportSheet: View {
    @State private var model: ExportModel
    @State private var settingsScrollPosition = ScrollPosition(edge: .top)
    @State private var settingsContentHeight: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    init(session: TimelapseSession, store: SessionStore) {
        _model = State(initialValue: ExportModel(session: session, store: store))
    }

    var body: some View {
        content
            .safeAreaBar(edge: .bottom, spacing: 0) {
                ExportActionBar(model: model, close: close)
                    .padding()
            }
            .scrollEdgeEffectStyle(.soft, for: .all)
            .frame(
                minWidth: isVertical ? 760 : 500,
                idealWidth: isVertical ? 800 : 540,
                minHeight: sheetHeight,
                maxHeight: sheetHeight
            )
            .task {
                await model.prepare()
            }
    }

    private static let verticalPreviewWidth: CGFloat = 260
    private static let verticalPreviewHeight: CGFloat = verticalPreviewWidth * 16 / 9
    private static let verticalPreviewColumnChrome: CGFloat = 160
    private static let placeholderSheetHeight: CGFloat = 600
    private static let maximumHorizontalSheetHeight: CGFloat = 720
    private static let maximumVerticalSheetHeight: CGFloat = 900

    private var sheetHeight: CGFloat {
        guard settingsContentHeight > 0 else { return Self.placeholderSheetHeight }
        let contentHeight =
            isVertical
            ? max(settingsContentHeight, Self.verticalPreviewHeight + Self.verticalPreviewColumnChrome)
            : settingsContentHeight
        let maximumHeight = isVertical ? Self.maximumVerticalSheetHeight : Self.maximumHorizontalSheetHeight
        return min(contentHeight.rounded(.up), maximumHeight)
    }

    @ViewBuilder
    private var content: some View {
        if isVertical {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    ExportHeader(title: model.session.title)
                    ExportPreview(image: model.previewImage, maximumHeight: Self.verticalPreviewHeight)
                }
                .frame(width: Self.verticalPreviewWidth, alignment: .top)
                .padding([.leading, .top], 20)
                settingsForm
            }
        } else {
            settingsForm
                .safeAreaBar(edge: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        ExportHeader(title: model.session.title)
                        ExportPreview(image: model.previewImage, maximumHeight: 240)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
        }
    }

    private var settingsForm: some View {
        Form {
            ExportLengthSection(model: model)
            ExportLayoutSection(model: model)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .defaultScrollAnchor(.top)
        .scrollPosition($settingsScrollPosition)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom
        } action: { _, height in
            settingsContentHeight = height
        }
        .onChange(of: isEditable) { _, isReady in
            guard isReady, case .ready = model.phase else { return }
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
        model.acceptsSettingChanges
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
                    Picker("Arrangement", selection: $model.settings.layout.horizontalArrangement) {
                        Text("Picture in picture").tag(HorizontalArrangement.pictureInPicture)
                        Text("Side by side").tag(HorizontalArrangement.sideBySide)
                    }
                case .vertical:
                    Picker("On top", selection: $model.settings.layout.verticalOrder) {
                        Text("Screen").tag(VerticalOrder.screenOnTop)
                        Text("Camera").tag(VerticalOrder.cameraOnTop)
                    }
                    LabeledContent("Screen / camera split") {
                        HStack {
                            Slider(
                                value: $model.settings.layout.verticalScreenShare,
                                in: ExportLayout.verticalScreenShareRange,
                                step: 0.05
                            )
                            .accessibilityValue(Text(splitAccessibilityDescription))
                            Text(splitDescription)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 40, alignment: .trailing)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }

        }

        if showsCameraOverlay {
            Section("Camera overlay") {
                CameraOverlayControls(overlay: $model.settings.layout.cameraOverlay)
            }
        }

        if model.framingMatters(for: .screen) || model.framingMatters(for: .camera) {
            Section("Framing") {
                if model.framingMatters(for: .screen) {
                    FramingPicker(title: "Screen", framing: $model.settings.layout.screenFraming)
                }
                if model.framingMatters(for: .camera) {
                    FramingPicker(title: "Camera", framing: $model.settings.layout.cameraFraming)
                }
            }
        }

        Section("Timestamp") {
            Toggle("Show timestamp", isOn: $model.settings.includesTimestamp)
            if model.settings.includesTimestamp, model.settings.layout.orientation == .vertical {
                Picker("Position", selection: $model.settings.layout.verticalTimestampCorner) {
                    Text("Top left").tag(OverlayCorner.topLeading)
                    Text("Top right").tag(OverlayCorner.topTrailing)
                    Text("Bottom left").tag(OverlayCorner.bottomLeading)
                    Text("Bottom right").tag(OverlayCorner.bottomTrailing)
                }
            }
        }
    }

    private var showsCameraOverlay: Bool {
        let layout = model.settings.layout
        return model.hasScreenAndCamera && layout.orientation == .horizontal
            && layout.horizontalArrangement == .pictureInPicture
    }

    private var screenSharePercent: Int {
        Int((model.settings.layout.verticalScreenShare * 100).rounded())
    }

    private var splitDescription: String {
        "\(screenSharePercent) / \(100 - screenSharePercent)"
    }

    private var splitAccessibilityDescription: String {
        "Screen \(screenSharePercent) percent, camera \(100 - screenSharePercent) percent"
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

private struct CameraOverlayControls: View {
    @Binding var overlay: CameraOverlay

    var body: some View {
        Picker("Position", selection: $overlay.corner) {
            Text("Top left").tag(OverlayCorner.topLeading)
            Text("Top right").tag(OverlayCorner.topTrailing)
            Text("Bottom left").tag(OverlayCorner.bottomLeading)
            Text("Bottom right").tag(OverlayCorner.bottomTrailing)
        }
        Picker("Size", selection: $overlay.size) {
            Text("Small").tag(OverlaySize.small)
            Text("Medium").tag(OverlaySize.medium)
            Text("Large").tag(OverlaySize.large)
        }
        Toggle("Circle", isOn: $overlay.isCircular)
        LabeledContent("Corner radius") {
            HStack {
                Slider(
                    value: $overlay.cornerRadiusFraction,
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
        .disabled(overlay.isCircular)
    }

    private var cornerRadiusPercentage: String {
        (overlay.cornerRadiusFraction / CameraOverlay.maximumCornerRadiusFraction)
            .formatted(.percent.precision(.fractionLength(0)))
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
