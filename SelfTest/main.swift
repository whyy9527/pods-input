import Foundation
import PodsInputCore

enum SelfTestFailure: Error, CustomStringConvertible {
    case failed(String)
    var description: String {
        switch self { case .failed(let message): return message }
    }
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw SelfTestFailure.failed(message) }
}

do {
    var processor = MotionProcessor(smoothing: 0.5)
    let neutral = processor.process(
        orientation: Orientation(pitch: 0.4, yaw: -0.2, roll: 0.1),
        timestamp: 1
    )
    try require(neutral.orientation == Orientation(pitch: 0, yaw: 0, roll: 0), "first sample did not calibrate")

    let relative = processor.process(
        orientation: Orientation(pitch: 0.6, yaw: -0.6, roll: 0.7),
        timestamp: 2
    )
    try require(abs(relative.orientation.pitch - 0.1) < 0.0001, "pitch smoothing failed")
    try require(abs(relative.orientation.yaw + 0.2) < 0.0001, "yaw smoothing failed")
    try require(abs(relative.orientation.roll - 0.3) < 0.0001, "roll smoothing failed")
    try require(abs(MotionProcessor.wrappedAngle(.pi * 2 + 0.2) - 0.2) < 0.0001, "angle wrapping failed")

    let encoded = try relative.encoded()
    let decoded = try JSONDecoder().decode(MotionEvent.self, from: Data(encoded.utf8))
    try require(decoded.protocolVersion == 1, "protocol version failed")
    try require(decoded.type == "motion", "event type failed")
    try require(decoded.sequence == 2, "sequence failed")

    print("PodsInput self-test passed: calibration, smoothing, angle wrapping, protocol v1")
} catch {
    fputs("PodsInput self-test failed: \(error)\n", stderr)
    exit(1)
}
