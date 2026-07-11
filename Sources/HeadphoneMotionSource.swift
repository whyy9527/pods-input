import CoreMotion
import Foundation
import PodsInputCore

@available(macOS 14.0, *)
final class HeadphoneMotionSource: NSObject, CMHeadphoneMotionManagerDelegate {
    private var manager = CMHeadphoneMotionManager()
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "io.podsinput.motion"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()
    private var processor = MotionProcessor()
    private let onEvent: @Sendable (MotionEvent) -> Void
    private let stateLock = NSLock()
    private var shouldRun = false
    private var lastSampleTime = Date.distantPast
    private var nextRecoveryTime = Date.distantPast
    private var recoveryDelay: TimeInterval = 3
    private var watchdog: DispatchSourceTimer?
    private var warmupOrientations: [Orientation] = []
    private let warmupSampleCount = 50
    private let calibrationWindowSize = 20

    init(onEvent: @escaping @Sendable (MotionEvent) -> Void) {
        self.onEvent = onEvent
        super.init()
        manager.delegate = self
    }

    func start() throws {
        guard manager.isDeviceMotionAvailable else {
            throw PodsInputError.motionUnavailable
        }
        stateLock.lock()
        shouldRun = true
        lastSampleTime = Date()
        stateLock.unlock()
        startWatchdog()
        queue.addOperation { [weak self] in self?.startMotionUpdates() }
    }

    private func startMotionUpdates() {
        stateLock.lock()
        let canStart = shouldRun
        if canStart { lastSampleTime = Date() }
        stateLock.unlock()
        guard canStart, manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        warmupOrientations.removeAll(keepingCapacity: true)

        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self else { return }
            if let error {
                self.manager.stopDeviceMotionUpdates()
                fputs("Motion updates stopped: \(error)\n", stderr)
                return
            }
            guard let motion else {
                self.manager.stopDeviceMotionUpdates()
                fputs("Motion updates stopped: Core Motion returned no sample.\n", stderr)
                return
            }
            self.stateLock.lock()
            self.lastSampleTime = Date()
            self.nextRecoveryTime = .distantPast
            self.recoveryDelay = 3
            self.stateLock.unlock()
            let orientation = Orientation(
                pitch: motion.attitude.pitch,
                yaw: motion.attitude.yaw,
                roll: motion.attitude.roll
            )
            if self.warmupOrientations.count < self.warmupSampleCount {
                self.warmupOrientations.append(orientation)
                guard self.warmupOrientations.count == self.warmupSampleCount else { return }
                let window = self.warmupOrientations.suffix(self.calibrationWindowSize)
                self.processor = MotionProcessor()
                self.processor.calibrate(to: Self.circularMean(of: window))
                fputs("Neutral pose calibrated from stable motion samples.\n", stdout)
            }

            let event = self.processor.process(
                orientation: orientation,
                rotationRate: Vector3(
                    x: motion.rotationRate.x,
                    y: motion.rotationRate.y,
                    z: motion.rotationRate.z
                ),
                userAcceleration: Vector3(
                    x: motion.userAcceleration.x,
                    y: motion.userAcceleration.y,
                    z: motion.userAcceleration.z
                ),
                timestamp: Date().timeIntervalSince1970
            )
            self.onEvent(event)
        }
    }

    func stop() {
        stateLock.lock()
        shouldRun = false
        stateLock.unlock()
        watchdog?.cancel()
        watchdog = nil
        queue.addOperation { [weak self] in self?.manager.stopDeviceMotionUpdates() }
    }

    func calibrate() {
        queue.addOperation { [weak self] in
            guard let self else { return }
            self.warmupOrientations.removeAll(keepingCapacity: true)
            fputs("Neutral-pose calibration requested. Hold your head naturally centered.\n", stdout)
        }
    }

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        fputs("AirPods motion connected.\n", stdout)
        queue.addOperation { [weak self] in self?.startMotionUpdates() }
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        fputs("AirPods motion disconnected.\n", stdout)
    }

    private func startWatchdog() {
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + 3, repeating: 2)
        timer.setEventHandler { [weak self] in self?.recoverIfStalled() }
        timer.resume()
        watchdog = timer
    }

    private func recoverIfStalled() {
        stateLock.lock()
        let now = Date()
        let stalled = shouldRun && now.timeIntervalSince(lastSampleTime) >= 3 && now >= nextRecoveryTime
        if stalled {
            lastSampleTime = now
            nextRecoveryTime = now.addingTimeInterval(recoveryDelay)
            recoveryDelay = min(recoveryDelay * 2, 60)
        }
        stateLock.unlock()
        guard stalled else { return }

        queue.addOperation { [weak self] in
            guard let self else { return }
            guard self.manager.isDeviceMotionAvailable else { return }
            fputs("No motion samples for 3 seconds; rebuilding Core Motion session.\n", stderr)
            self.manager.stopDeviceMotionUpdates()
            self.manager.delegate = nil
            let replacement = CMHeadphoneMotionManager()
            replacement.delegate = self
            self.manager = replacement
            self.processor = MotionProcessor()
            self.startMotionUpdates()
        }
    }

    private static func circularMean(of orientations: ArraySlice<Orientation>) -> Orientation {
        func mean(_ values: [Double]) -> Double {
            atan2(values.reduce(0) { $0 + sin($1) }, values.reduce(0) { $0 + cos($1) })
        }
        return Orientation(
            pitch: mean(orientations.map(\.pitch)),
            yaw: mean(orientations.map(\.yaw)),
            roll: mean(orientations.map(\.roll))
        )
    }
}

enum PodsInputError: LocalizedError {
    case motionUnavailable

    var errorDescription: String? {
        "No compatible motion-capable headphones are available. Connect and wear your AirPods, then try again."
    }
}
