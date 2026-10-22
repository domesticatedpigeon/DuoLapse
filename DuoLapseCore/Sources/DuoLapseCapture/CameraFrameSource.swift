@preconcurrency import AVFoundation
import CoreMedia
import CoreVideo
import DuoLapseCore
import Foundation
import os

nonisolated final class CameraFrameSource: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private static let warmUpDuration: TimeInterval = 1
    private static let maximumFrameAge: TimeInterval = 5

    private let deviceID: String
    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "DuoLapse.CameraFrameSource.session")
    private let frameQueue = DispatchQueue(label: "DuoLapse.CameraFrameSource.frames")
    private let latestFrame = OSAllocatedUnfairLock<ReceivedFrame?>(uncheckedState: nil)
    private let isActive = OSAllocatedUnfairLock(initialState: false)
    private let acceptsFramesAfter = OSAllocatedUnfairLock(initialState: Date.distantFuture)
    private var notificationObservers: [any NSObjectProtocol] = []

    init(deviceID: String) {
        self.deviceID = deviceID
        super.init()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: frameQueue)
    }

    func start() async throws {
        isActive.withLock { $0 = true }
        observeSessionDisruptions()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            sessionQueue.async {
                do {
                    try self.startSession()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func stop() async {
        isActive.withLock { $0 = false }
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers = []
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                self.session.stopRunning()
                self.latestFrame.withLockUnchecked { $0 = nil }
                continuation.resume()
            }
        }
    }

    func currentFrame() throws -> CVPixelBuffer {
        let frame = latestFrame.withLockUnchecked { $0 }
        guard let frame, Date.now.timeIntervalSince(frame.receivedAt) <= Self.maximumFrameAge else {
            throw CameraCaptureError.noRecentFrame
        }
        return frame.pixelBuffer
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let receivedAt = Date.now
        guard receivedAt >= acceptsFramesAfter.withLock({ $0 }), let pixelBuffer = sampleBuffer.imageBuffer else {
            return
        }
        latestFrame.withLockUnchecked { $0 = ReceivedFrame(pixelBuffer: pixelBuffer, receivedAt: receivedAt) }
    }

    private func startSession() throws {
        guard let device = AVCaptureDevice(uniqueID: deviceID) else { throw CameraCaptureError.deviceUnavailable }
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            throw CameraCaptureError.cannotUseDevice
        }
        session.addInput(input)
        if !session.outputs.contains(output) {
            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                throw CameraCaptureError.cannotUseDevice
            }
            session.addOutput(output)
        }
        output.videoSettings = Self.videoSettings(for: device)
        session.commitConfiguration()

        acceptsFramesAfter.withLock { $0 = Date.now.addingTimeInterval(Self.warmUpDuration) }
        session.startRunning()
        Self.throttleToLowestFrameRate(device)
    }

    private func scheduleRestart() {
        sessionQueue.async { self.restartIfActive() }
    }

    private func restartIfActive() {
        guard isActive.withLock({ $0 }) else { return }
        session.stopRunning()
        try? startSession()
    }

    private func observeSessionDisruptions() {
        let center = NotificationCenter.default
        notificationObservers = [
            center.addObserver(forName: AVCaptureSession.runtimeErrorNotification, object: session, queue: nil) {
                [weak self] _ in
                self?.scheduleRestart()
            },
            center.addObserver(forName: AVCaptureDevice.wasConnectedNotification, object: nil, queue: nil) {
                [weak self, deviceID] notification in
                guard (notification.object as? AVCaptureDevice)?.uniqueID == deviceID else { return }
                self?.scheduleRestart()
            },
        ]
    }

    private static func videoSettings(for device: AVCaptureDevice) -> [String: Any] {
        let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
        let size = StorageResolution.cameraStorageSize(
            for: PixelSize(width: Int(dimensions.width), height: Int(dimensions.height))
        )
        return [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelBufferWidthKey as String: size.width,
            kCVPixelBufferHeightKey as String: size.height,
        ]
    }

    private static func throttleToLowestFrameRate(_ device: AVCaptureDevice) {
        let slowestRange = device.activeFormat.videoSupportedFrameRateRanges.min { $0.minFrameRate < $1.minFrameRate }
        guard let slowestRange, (try? device.lockForConfiguration()) != nil else { return }
        device.activeVideoMinFrameDuration = slowestRange.maxFrameDuration
        device.activeVideoMaxFrameDuration = slowestRange.maxFrameDuration
        device.unlockForConfiguration()
    }
}

nonisolated private struct ReceivedFrame {
    let pixelBuffer: CVPixelBuffer
    let receivedAt: Date
}

nonisolated public enum CameraCaptureError: LocalizedError {
    case deviceUnavailable
    case cannotUseDevice
    case noRecentFrame

    public var errorDescription: String? {
        switch self {
        case .deviceUnavailable: "The selected camera isn’t connected."
        case .cannotUseDevice: "DuoLapse couldn’t start the selected camera. Another app may be using it."
        case .noRecentFrame: "The camera hasn’t sent a picture recently."
        }
    }
}
