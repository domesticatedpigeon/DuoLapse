import CoreGraphics
import DuoLapseCore
import DuoLapseExport
import Foundation
import Observation

@Observable
final class ExportModel {
    enum Phase {
        case preparing
        case ready
        case exporting(progress: Double)
        case finished(URL)
        case failed(String)
    }

    let session: TimelapseSession
    private(set) var phase = Phase.preparing
    private(set) var source: ExportSource?
    private(set) var previewImage: CGImage?

    var settings: ExportSettings {
        didSet {
            persistSettings()
            refreshPreview()
        }
    }

    var outputFolder: URL {
        didSet { defaults.set(outputFolder.path(percentEncoded: false), forKey: PreferenceKey.outputFolderPath) }
    }

    var customDurationSeconds: Int {
        didSet {
            if durationOption == .custom {
                settings.duration = .seconds(customDurationSeconds)
            }
        }
    }

    @ObservationIgnored private let store: SessionStore
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let exporter = VideoExporter()
    @ObservationIgnored private var exportTask: Task<Void, Never>?
    @ObservationIgnored private var previewTask: Task<Void, Never>?

    init(session: TimelapseSession, store: SessionStore, defaults: UserDefaults = .standard) {
        self.session = session
        self.store = store
        self.defaults = defaults
        let storedSettings = defaults.data(forKey: PreferenceKey.settings)
            .flatMap { try? JSONDecoder().decode(ExportSettings.self, from: $0) }
        self.settings = storedSettings ?? ExportSettings()
        self.outputFolder =
            defaults.string(forKey: PreferenceKey.outputFolderPath).map {
                URL(filePath: $0, directoryHint: .isDirectory)
            }
            ?? URL.moviesDirectory.appending(path: "DuoLapse Recordings", directoryHint: .isDirectory)
        if case .seconds(let seconds)? = storedSettings?.duration {
            self.customDurationSeconds = seconds
        } else {
            self.customDurationSeconds = 60
        }
    }

    var availableFrameCount: Int {
        source?.frames.count ?? 0
    }

    var hasScreenAndCamera: Bool {
        source?.screenSize != nil && source?.cameraSize != nil
    }

    var fullLengthSeconds: Double {
        ExportDuration.fullLengthSeconds(availableFrames: availableFrameCount)
    }

    var maximumCustomSeconds: Int {
        max(1, Int(fullLengthSeconds.rounded(.down)))
    }

    var durationOption: ExportDurationOption {
        get { ExportDurationOption(settings.duration) }
        set { settings.duration = newValue.duration(customSeconds: customDurationSeconds) }
    }

    var filenamePreview: String {
        settings.filenameTemplate.filename(for: session.createdAt) + ".mp4"
    }

    var isExporting: Bool {
        if case .exporting = phase { true } else { false }
    }

    var selectableDurationOptions: [ExportDurationOption] {
        ExportDurationOption.allCases.filter { fits($0) || $0 == durationOption }
    }

    func fits(_ option: ExportDurationOption) -> Bool {
        option == .custom
            || option.duration(customSeconds: customDurationSeconds).fits(availableFrames: availableFrameCount)
    }

    func prepare() async {
        do {
            let source = try await exporter.prepareSource(for: session, store: store)
            self.source = source
            guard !source.frames.isEmpty else {
                phase = .failed(ExportError.noFrames.localizedDescription)
                return
            }
            if !settings.duration.fits(availableFrames: source.frames.count) {
                settings.duration = .fullLength
            }
            customDurationSeconds = min(customDurationSeconds, maximumCustomSeconds)
            phase = .ready
            refreshPreview()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func startExport() {
        guard let source, case .ready = phase else { return }
        let destination = FilenameTemplate.availableURL(
            in: outputFolder,
            baseName: settings.filenameTemplate.filename(for: session.createdAt),
            pathExtension: "mp4"
        ) { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }
        let settings = settings
        let outputFolder = outputFolder
        phase = .exporting(progress: 0)
        exportTask = Task {
            do {
                try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
                try await exporter.export(source, settings: settings, to: destination) { progress in
                    Task { @MainActor in self.updateProgress(progress) }
                }
                phase = .finished(destination)
            } catch is CancellationError {
                phase = .ready
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func cancelExport() {
        exportTask?.cancel()
    }

    func cancelBackgroundWork() {
        exportTask?.cancel()
        previewTask?.cancel()
    }

    private func updateProgress(_ progress: Double) {
        guard isExporting else { return }
        phase = .exporting(progress: progress)
    }

    private func refreshPreview() {
        guard let source else { return }
        let settings = settings
        previewTask?.cancel()
        previewTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            let image = try? await exporter.previewImage(of: source, settings: settings)
            guard !Task.isCancelled else { return }
            previewImage = image ?? nil
        }
    }

    private func persistSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: PreferenceKey.settings)
    }
}

enum ExportDurationOption: Hashable, CaseIterable {
    case thirtySeconds
    case oneMinute
    case threeMinutes
    case fullLength
    case custom

    init(_ duration: ExportDuration) {
        switch duration {
        case .seconds(30): self = .thirtySeconds
        case .seconds(60): self = .oneMinute
        case .seconds(180): self = .threeMinutes
        case .fullLength: self = .fullLength
        case .seconds: self = .custom
        }
    }

    func duration(customSeconds: Int) -> ExportDuration {
        switch self {
        case .thirtySeconds: .seconds(30)
        case .oneMinute: .seconds(60)
        case .threeMinutes: .seconds(180)
        case .fullLength: .fullLength
        case .custom: .seconds(customSeconds)
        }
    }
}

private enum PreferenceKey {
    static let settings = "export.settings"
    static let outputFolderPath = "export.outputFolderPath"
}
