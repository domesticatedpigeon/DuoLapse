import Foundation

public struct FilenameTemplate: Hashable, Codable, Sendable {
    public static let defaultPattern = "DuoLapse Recording {YYYY}-{MM}-{DD} at {hh}.{mm}.{ss}"
    public static let fallbackName = "DuoLapse Recording"
    public static let tokens = ["{YYYY}", "{YY}", "{MM}", "{DD}", "{hh}", "{mm}", "{ss}"]
    static let maximumLength = 200

    public var pattern: String

    public init(pattern: String = Self.defaultPattern) {
        self.pattern = pattern
    }

    public func filename(for date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let replacements = [
            "{YYYY}": padded(parts.year, digits: 4),
            "{YY}": padded((parts.year ?? 0) % 100, digits: 2),
            "{MM}": padded(parts.month, digits: 2),
            "{DD}": padded(parts.day, digits: 2),
            "{hh}": padded(parts.hour, digits: 2),
            "{mm}": padded(parts.minute, digits: 2),
            "{ss}": padded(parts.second, digits: 2),
        ]
        let expanded = replacements.reduce(pattern) { $0.replacingOccurrences(of: $1.key, with: $1.value) }
        return Self.sanitized(expanded)
    }

    public static func availableURL(
        in directory: URL,
        baseName: String,
        pathExtension: String,
        fileExists: (URL) -> Bool
    ) -> URL {
        var copyNumber = 1
        while true {
            let name = copyNumber == 1 ? baseName : "\(baseName) \(copyNumber)"
            let url = directory.appending(path: name, directoryHint: .notDirectory).appendingPathExtension(
                pathExtension)
            if !fileExists(url) {
                return url
            }
            copyNumber += 1
        }
    }

    static func sanitized(_ name: String) -> String {
        let cleaned =
            name
            .replacingOccurrences(of: ":", with: ".")
            .replacingOccurrences(of: "/", with: "-")
            .filter { !$0.isNewline && $0.asciiValue.map { $0 >= 0x20 } ?? true }
            .trimmingCharacters(in: .whitespaces)
        let withoutLeadingDots = String(cleaned.drop { $0 == "." })
        let limited = String(withoutLeadingDots.prefix(maximumLength))
        return limited.isEmpty ? fallbackName : limited
    }

    private func padded(_ value: Int?, digits: Int) -> String {
        let text = String(value ?? 0)
        return String(repeating: "0", count: max(0, digits - text.count)) + text
    }
}
