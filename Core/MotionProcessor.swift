import Foundation

public struct MotionProcessor: Sendable {
    private var neutral: Orientation?
    private var filtered = Orientation(pitch: 0, yaw: 0, roll: 0)
    private var sequence: UInt64 = 0
    private let smoothing: Double

    public init(smoothing: Double = 0.22) {
        self.smoothing = min(max(smoothing, 0), 1)
    }

    public mutating func calibrate(to orientation: Orientation) {
        neutral = orientation
        filtered = Orientation(pitch: 0, yaw: 0, roll: 0)
    }

    public mutating func process(
        orientation: Orientation,
        rotationRate: Vector3 = .zero,
        userAcceleration: Vector3 = .zero,
        timestamp: TimeInterval
    ) -> MotionEvent {
        if neutral == nil {
            calibrate(to: orientation)
        }

        let baseline = neutral ?? orientation
        let relative = Orientation(
            pitch: Self.wrappedAngle(orientation.pitch - baseline.pitch),
            yaw: Self.wrappedAngle(orientation.yaw - baseline.yaw),
            roll: Self.wrappedAngle(orientation.roll - baseline.roll)
        )
        filtered = Orientation(
            pitch: lerp(filtered.pitch, relative.pitch),
            yaw: lerp(filtered.yaw, relative.yaw),
            roll: lerp(filtered.roll, relative.roll)
        )
        sequence &+= 1

        return MotionEvent(
            sequence: sequence,
            timestamp: timestamp,
            orientation: filtered,
            rotationRate: rotationRate,
            userAcceleration: userAcceleration
        )
    }

    private func lerp(_ current: Double, _ target: Double) -> Double {
        current + smoothing * (target - current)
    }

    public static func wrappedAngle(_ angle: Double) -> Double {
        atan2(sin(angle), cos(angle))
    }
}
