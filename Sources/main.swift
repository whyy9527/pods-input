import Foundation
import PodsInputCore

let arguments = CommandLine.arguments
let simulate = arguments.contains("--simulate")
let port: Int
if let portIndex = arguments.firstIndex(of: "--port") {
    guard arguments.indices.contains(portIndex + 1),
          let parsedPort = Int(arguments[portIndex + 1]),
          (1...65_535).contains(parsedPort) else {
        fputs("--port requires an integer between 1 and 65535.\n", stderr)
        exit(64)
    }
    port = parsedPort
} else {
    port = 17_604
}

let server = WebSocketServer()
do {
    try server.start(port: port)
    print("PodsInput protocol v\(PodsInputProtocol.version) listening at ws://127.0.0.1:\(port)")
} catch {
    fputs("Unable to start WebSocket server: \(error)\n", stderr)
    exit(1)
}

var source: HeadphoneMotionSource?
var simulationTimer: DispatchSourceTimer?

if simulate {
    let timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInteractive))
    var processor = MotionProcessor(smoothing: 0.35)
    var tick = 0.0
    timer.schedule(deadline: .now(), repeating: .milliseconds(16))
    timer.setEventHandler {
        tick += 0.035
        let event = processor.process(
            orientation: Orientation(
                pitch: sin(tick * 0.7) * 0.08,
                yaw: sin(tick * 0.4) * 0.12,
                roll: sin(tick) * 0.45
            ),
            timestamp: Date().timeIntervalSince1970
        )
        server.broadcast(event)
    }
    timer.resume()
    simulationTimer = timer
    print("Simulation enabled. Open examples/web-racer/index.html to test without AirPods.")
} else {
    let motionSource = HeadphoneMotionSource { server.broadcast($0) }
    do {
        try motionSource.start()
        source = motionSource
        print("Reading AirPods motion. Press Control-C to stop.")
    } catch {
        fputs("\(error.localizedDescription)\nRun with --simulate to test without hardware.\n", stderr)
        server.stop()
        exit(2)
    }
}

signal(SIGINT, SIG_IGN)
let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
signalSource.setEventHandler {
    source?.stop()
    simulationTimer?.cancel()
    server.stop()
    exit(0)
}
signalSource.resume()
dispatchMain()
