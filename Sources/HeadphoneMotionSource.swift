import CoreMotion
import Foundation
import PodsInputCore

@available(macOS 14.0, *)
final class HeadphoneMotionSource: NSObject, CMHeadphoneMotionManagerDelegate {
    private let manager = CMHeadphoneMotionManager()
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "io.podsinput.motion"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()
    private var processor = MotionProcessor()
    private let onEvent: @Sendable (MotionEvent) -> Void

    init(onEvent: @escaping @Sendable (MotionEvent) -> Void) {
        self.onEvent = onEvent
        super.init()
        manager.delegate = self
    }

    func start() throws {
        guard manager.isDeviceMotionAvailable else {
            throw PodsInputError.motionUnavailable
        }
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
            let event = self.processor.process(
                orientation: Orientation(
                    pitch: motion.attitude.pitch,
                    yaw: motion.attitude.yaw,
                    roll: motion.attitude.roll
                ),
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
        manager.stopDeviceMotionUpdates()
    }

    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        fputs("AirPods motion connected.\n", stdout)
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        fputs("AirPods motion disconnected.\n", stdout)
    }
}

enum PodsInputError: LocalizedError {
    case motionUnavailable

    var errorDescription: String? {
        "No compatible motion-capable headphones are available. Connect and wear your AirPods, then try again."
    }
}
