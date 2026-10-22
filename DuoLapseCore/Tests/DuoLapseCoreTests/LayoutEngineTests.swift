import Testing

@testable import DuoLapseCore

struct LayoutEngineTests {
    let macBookScreen = PixelSize(width: 1920, height: 1200)
    let camera = PixelSize(width: 1280, height: 720)

    @Test func horizontalCanvasFollowsScreenAspectRatio() {
        let plan = LayoutEngine.plan(
            layout: ExportLayout(), screenSize: macBookScreen, cameraSize: camera, longEdge: 1920)
        #expect(plan.canvasSize == PixelSize(width: 1920, height: 1200))
        #expect(plan.screen?.frame == LayoutRect(x: 0, y: 0, width: 1920, height: 1200))
    }

    @Test func pictureInPictureSitsInChosenCornerWithMargin() {
        let layout = ExportLayout(cameraOverlay: CameraOverlay(corner: .bottomTrailing, size: .medium))
        let plan = LayoutEngine.plan(layout: layout, screenSize: macBookScreen, cameraSize: camera, longEdge: 1920)
        #expect(plan.camera?.frame == LayoutRect(x: 1392, y: 882, width: 480, height: 270))
        #expect(plan.camera?.contentMode == .fill)
    }

    @Test func topLeadingOverlayStartsAtMargin() {
        let layout = ExportLayout(cameraOverlay: CameraOverlay(corner: .topLeading, size: .small))
        let plan = LayoutEngine.plan(layout: layout, screenSize: macBookScreen, cameraSize: camera, longEdge: 1920)
        #expect(plan.camera?.frame == LayoutRect(x: 48, y: 48, width: 384, height: 216))
    }

    @Test func cornerRadiusIsFractionOfShorterSide() {
        let layout = ExportLayout(cameraOverlay: CameraOverlay(cornerRadiusFraction: 0.1))
        let plan = LayoutEngine.plan(layout: layout, screenSize: macBookScreen, cameraSize: camera, longEdge: 1920)
        #expect(plan.camera?.cornerRadius == 27)
    }

    @Test func circularOverlayIsSquareAndFullyRounded() {
        let layout = ExportLayout(cameraOverlay: CameraOverlay(size: .medium, isCircular: true))
        let plan = LayoutEngine.plan(layout: layout, screenSize: macBookScreen, cameraSize: camera, longEdge: 1920)
        #expect(plan.camera?.frame.width == 480)
        #expect(plan.camera?.frame.height == 480)
        #expect(plan.camera?.cornerRadius == 240)
    }

    @Test func timestampMovesAwayFromTopTrailingOverlay() {
        let layout = ExportLayout(cameraOverlay: CameraOverlay(corner: .topTrailing))
        let plan = LayoutEngine.plan(layout: layout, screenSize: macBookScreen, cameraSize: camera, longEdge: 1920)
        #expect(plan.timestampCorner == .topLeading)
    }

    @Test func sideBySideShowsBothSourcesWholeAtEqualHeight() {
        let layout = ExportLayout(horizontalArrangement: .sideBySide)
        let plan = LayoutEngine.plan(layout: layout, screenSize: macBookScreen, cameraSize: camera, longEdge: 1920)
        #expect(plan.canvasSize == PixelSize(width: 1920, height: 568))
        #expect(plan.screen?.frame == LayoutRect(x: 0, y: 0, width: 909, height: 568))
        #expect(plan.camera?.frame == LayoutRect(x: 909, y: 0, width: 1011, height: 568))
    }

    @Test func sideBySideKeepsPortraitCameraUncropped() throws {
        let layout = ExportLayout(horizontalArrangement: .sideBySide)
        let portraitCamera = PixelSize(width: 720, height: 1280)
        let plan = LayoutEngine.plan(
            layout: layout, screenSize: macBookScreen, cameraSize: portraitCamera, longEdge: 1920)
        let cameraFrame = try #require(plan.camera?.frame)
        #expect(abs(cameraFrame.width / cameraFrame.height - 720.0 / 1280.0) < 0.01)
    }

    @Test func verticalStacksScreenAtFullWidthOnTop() {
        let layout = ExportLayout(orientation: .vertical, verticalOrder: .screenOnTop)
        let plan = LayoutEngine.plan(layout: layout, screenSize: macBookScreen, cameraSize: camera, longEdge: 1920)
        #expect(plan.canvasSize == PixelSize(width: 1080, height: 1920))
        #expect(plan.screen?.frame == LayoutRect(x: 0, y: 0, width: 1080, height: 675))
        #expect(plan.camera?.frame == LayoutRect(x: 0, y: 675, width: 1080, height: 1245))
    }

    @Test func verticalCanPutCameraOnTop() {
        let layout = ExportLayout(orientation: .vertical, verticalOrder: .cameraOnTop)
        let plan = LayoutEngine.plan(layout: layout, screenSize: macBookScreen, cameraSize: camera, longEdge: 1920)
        #expect(plan.camera?.frame == LayoutRect(x: 0, y: 0, width: 1080, height: 1245))
        #expect(plan.screen?.frame == LayoutRect(x: 0, y: 1245, width: 1080, height: 675))
    }

    @Test func verticalCapsPortraitScreenHeight() {
        let layout = ExportLayout(orientation: .vertical)
        let portrait = PixelSize(width: 1080, height: 1920)
        let plan = LayoutEngine.plan(layout: layout, screenSize: portrait, cameraSize: camera, longEdge: 1920)
        #expect(plan.screen?.frame.height == 1152)
    }

    @Test func highQualityUsesLongerEdge() {
        let layout = ExportLayout(orientation: .vertical)
        let plan = LayoutEngine.plan(layout: layout, screenSize: macBookScreen, cameraSize: camera, longEdge: 2560)
        #expect(plan.canvasSize == PixelSize(width: 1440, height: 2560))
    }

    @Test(arguments: ExportOrientation.allCases)
    func screenOnlyFillsCanvas(orientation: ExportOrientation) {
        let plan = LayoutEngine.plan(
            layout: ExportLayout(orientation: orientation),
            screenSize: macBookScreen,
            cameraSize: nil,
            longEdge: 1920
        )
        #expect(plan.camera == nil)
        #expect(plan.screen?.frame.width == Double(plan.canvasSize.width))
        #expect(plan.screen?.contentMode == .fit)
    }

    @Test func cameraOnlyHorizontalUsesCameraAspectRatio() {
        let plan = LayoutEngine.plan(layout: ExportLayout(), screenSize: nil, cameraSize: camera, longEdge: 1920)
        #expect(plan.canvasSize == PixelSize(width: 1920, height: 1080))
        #expect(plan.camera?.contentMode == .fill)
        #expect(plan.screen == nil)
    }

    @Test func defaultCornerRadiusIsTwentyPercentOfMaximum() {
        let ratio = CameraOverlay().cornerRadiusFraction / CameraOverlay.maximumCornerRadiusFraction
        #expect(abs(ratio - 0.2) < 1e-9)
    }
}
