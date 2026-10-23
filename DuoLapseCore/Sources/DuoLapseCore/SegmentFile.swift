import Foundation

public enum SegmentFile {
    public static let pathExtension = "mp4"

    public static func name(startingAt date: Date) -> String {
        "\(millisecondsSince1970(date)).\(pathExtension)"
    }

    public static func startDate(ofSegmentNamed name: String) -> Date? {
        let suffix = ".\(pathExtension)"
        guard name.hasSuffix(suffix), let milliseconds = Int64(name.dropLast(suffix.count)) else {
            return nil
        }
        return Date(timeIntervalSince1970: Double(milliseconds) / 1000)
    }

    private static func millisecondsSince1970(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000).rounded(.down))
    }
}
