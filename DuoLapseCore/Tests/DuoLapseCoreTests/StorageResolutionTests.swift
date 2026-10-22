import Testing

@testable import DuoLapseCore

struct StorageResolutionTests {
    @Test(arguments: [
        (StorageResolution.standard, PixelSize(width: 5120, height: 2880), PixelSize(width: 1920, height: 1080)),
        (.standard, PixelSize(width: 3024, height: 1964), PixelSize(width: 1920, height: 1246)),
        (.high, PixelSize(width: 5120, height: 2880), PixelSize(width: 2560, height: 1440)),
        (.standard, PixelSize(width: 1080, height: 1920), PixelSize(width: 1080, height: 1920)),
    ])
    func scalesScreenLongEdgeDownToLimit(resolution: StorageResolution, source: PixelSize, expected: PixelSize) {
        #expect(resolution.screenStorageSize(for: source) == expected)
    }

    @Test func neverUpscalesSmallerScreens() {
        let source = PixelSize(width: 1280, height: 800)
        #expect(StorageResolution.high.screenStorageSize(for: source) == source)
    }

    @Test(arguments: [
        (PixelSize(width: 1920, height: 1080), PixelSize(width: 1280, height: 720)),
        (PixelSize(width: 1280, height: 720), PixelSize(width: 1280, height: 720)),
        (PixelSize(width: 1920, height: 1440), PixelSize(width: 1280, height: 960)),
    ])
    func scalesCameraLongEdgeTo1280(source: PixelSize, expected: PixelSize) {
        #expect(StorageResolution.cameraStorageSize(for: source) == expected)
    }

    @Test func roundsOddDimensionsDownToEven() {
        let size = PixelSize(width: 1281, height: 801).fitting(longEdge: 1920)
        #expect(size == PixelSize(width: 1280, height: 800))
    }

    @Test func handlesEmptySourceWithoutCrashing() {
        #expect(PixelSize(width: 0, height: 0).fitting(longEdge: 1920) == PixelSize(width: 2, height: 2))
    }
}
