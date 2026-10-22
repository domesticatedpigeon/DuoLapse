import Testing

@testable import DuoLapseCore

struct StorageResolutionTests {
    @Test(arguments: [
        (StorageResolution.standard, PixelSize(width: 5120, height: 2880), PixelSize(width: 1920, height: 1080)),
        (.standard, PixelSize(width: 3024, height: 1964), PixelSize(width: 1920, height: 1246)),
        (.high, PixelSize(width: 5120, height: 2880), PixelSize(width: 2560, height: 1440)),
        (.standard, PixelSize(width: 1080, height: 1920), PixelSize(width: 1080, height: 1920)),
    ])
    func scalesLongEdgeDownToLimit(resolution: StorageResolution, source: PixelSize, expected: PixelSize) {
        #expect(resolution.storageSize(for: source) == expected)
    }

    @Test func neverUpscalesSmallerSources() {
        let source = PixelSize(width: 1280, height: 800)
        #expect(StorageResolution.high.storageSize(for: source) == source)
    }

    @Test func roundsOddDimensionsDownToEven() {
        let size = StorageResolution.standard.storageSize(for: PixelSize(width: 1281, height: 801))
        #expect(size == PixelSize(width: 1280, height: 800))
    }

    @Test func handlesEmptySourceWithoutCrashing() {
        let size = StorageResolution.standard.storageSize(for: PixelSize(width: 0, height: 0))
        #expect(size == PixelSize(width: 2, height: 2))
    }
}
