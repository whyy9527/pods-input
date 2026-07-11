import Foundation

public enum PodsInputProtocol {
    public static let version = 1
}

public struct Vector3: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

public struct Orientation: Codable, Equatable, Sendable {
    public let pitch: Double
    public let yaw: Double
    public let roll: Double

    public init(pitch: Double, yaw: Double, roll: Double) {
        self.pitch = pitch
        self.yaw = yaw
        self.roll = roll
    }
}

public struct MotionEvent: Codable, Equatable, Sendable {
    public let protocolVersion: Int
    public let type: String
    public let sequence: UInt64
    public let timestamp: TimeInterval
    public let orientation: Orientation
    public let rotationRate: Vector3
    public let userAcceleration: Vector3

    public init(
        sequence: UInt64,
        timestamp: TimeInterval,
        orientation: Orientation,
        rotationRate: Vector3 = .zero,
        userAcceleration: Vector3 = .zero
    ) {
        protocolVersion = PodsInputProtocol.version
        type = "motion"
        self.sequence = sequence
        self.timestamp = timestamp
        self.orientation = orientation
        self.rotationRate = rotationRate
        self.userAcceleration = userAcceleration
    }

    public func encoded() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }
}

public struct ControlCommand: Codable, Equatable, Sendable {
    public let protocolVersion: Int
    public let type: String

    public init(type: String) {
        protocolVersion = PodsInputProtocol.version
        self.type = type
    }
}

public extension Vector3 {
    static let zero = Vector3(x: 0, y: 0, z: 0)
}
