# PodsInput

Turn motion-capable AirPods into an open input device.

PodsInput is an early, hardware-first experiment. It reads three-axis headphone motion on macOS, calibrates the first sample as neutral, and publishes a small versioned JSON protocol over a local WebSocket. The first client is a browser racing demo controlled by tilting your head.

## Why

AirPods already contain low-latency motion sensors, but most software only uses them for spatial audio. PodsInput makes that signal reusable for games, creative tools, hands-free interaction, and accessibility experiments without a camera or cloud service.

## Current milestone

- AirPods motion input through `CMHeadphoneMotionManager`
- Neutral-position calibration and angle-safe smoothing
- Versioned WebSocket protocol on `127.0.0.1:17604`
- Browser connections restricted to local origins
- Simulation mode for development without headphones
- Explicit neutral-pose recalibration over the control protocol
- Zero-build Web Racer example

This is not yet an accessibility product or a production input driver. Hardware behaviour still needs to be measured with AirPods Pro 2 and AirPods 4.

## Try the Web Racer

Requirements: macOS 14+, Swift 5.9+, and motion-capable AirPods for hardware mode.

```bash
swift run pods-input --simulate
open examples/web-racer/index.html
```

Then tilt left or right. Simulation mode generates the same protocol as real hardware.

For AirPods input:

```bash
swift run pods-input
```

Connect and wear the headphones before launching. A distributable signed app bundle with a proper Motion & Fitness permission flow is the next milestone; direct SwiftPM execution may be constrained by macOS privacy controls.

Run the hardware-independent core checks with:

```bash
swift run pods-input-self-test
```

## Protocol v1

Each WebSocket text frame contains one motion event. Angles and rotation rates are radians; acceleration is measured in g.

```json
{
  "protocolVersion": 1,
  "type": "motion",
  "sequence": 42,
  "timestamp": 1770000000.125,
  "orientation": { "pitch": 0.01, "yaw": -0.03, "roll": 0.12 },
  "rotationRate": { "x": 0.0, "y": 0.0, "z": 0.0 },
  "userAcceleration": { "x": 0.0, "y": 0.0, "z": 0.0 }
}
```

The orientation is relative to the first valid sample, which is treated as the neutral pose.

## Roadmap

1. Record sampling rate, latency, drift, disconnect behaviour, and comfort with AirPods Pro 2 and AirPods 4.
2. Add explicit recalibration and a signed menu-bar app.
3. Add OpenTrack/FreeTrack UDP output for racing and flight games.
4. Explore system scrolling, discrete nod/shake gestures, dwell, voice, and switch-assisted input.

## License

MIT
