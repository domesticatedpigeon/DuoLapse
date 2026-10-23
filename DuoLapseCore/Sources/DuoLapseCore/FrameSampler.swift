public enum FrameSampler {
    public static func indices(selecting targetCount: Int, from availableCount: Int) -> [Int] {
        guard targetCount > 0, availableCount > 0 else { return [] }
        guard targetCount < availableCount else { return Array(0..<availableCount) }
        guard targetCount > 1 else { return [0] }
        let step = Double(availableCount - 1) / Double(targetCount - 1)
        return (0..<targetCount).map { Int((Double($0) * step).rounded()) }
    }
}
