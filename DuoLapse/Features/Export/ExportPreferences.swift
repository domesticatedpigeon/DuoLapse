import DuoLapseCore
import Foundation

enum ExportPreferences {
    static let defaultOutputFolder = URL.moviesDirectory.appending(
        path: "DuoLapse Recordings",
        directoryHint: .isDirectory
    )

    private static let settingsKey = "export.settings"
    private static let outputFolderPathKey = "export.outputFolderPath"

    static func storedSettings(in defaults: UserDefaults = .standard) -> ExportSettings? {
        defaults.data(forKey: settingsKey).flatMap { try? JSONDecoder().decode(ExportSettings.self, from: $0) }
    }

    static func settings(in defaults: UserDefaults = .standard) -> ExportSettings {
        storedSettings(in: defaults) ?? ExportSettings()
    }

    static func save(_ settings: ExportSettings, in defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    static func outputFolder(in defaults: UserDefaults = .standard) -> URL {
        defaults.string(forKey: outputFolderPathKey).map { URL(filePath: $0, directoryHint: .isDirectory) }
            ?? defaultOutputFolder
    }

    static func save(outputFolder: URL, in defaults: UserDefaults = .standard) {
        defaults.set(outputFolder.path(percentEncoded: false), forKey: outputFolderPathKey)
    }
}
