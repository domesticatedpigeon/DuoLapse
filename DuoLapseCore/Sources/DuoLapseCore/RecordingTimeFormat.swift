public enum RecordingTimeFormat {
    public static func compact(seconds: Double) -> String {
        let totalSeconds = max(0, Int(seconds.rounded(.down)))
        let hours = totalSeconds / 3600
        let minutes = totalSeconds % 3600 / 60
        let remainingSeconds = totalSeconds % 60
        guard hours > 0 else {
            return "\(minutes):\(twoDigits(remainingSeconds))"
        }
        return "\(hours):\(twoDigits(minutes)):\(twoDigits(remainingSeconds))"
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
