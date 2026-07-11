# PodsInput protocol

The protocol is a local transport contract between a headphone-motion source and input adapters.

## Compatibility

- Receivers must ignore unknown fields.
- Senders increment `protocolVersion` only for breaking changes.
- A connection carries UTF-8 JSON text frames.
- Protocol v1 sends only `motion` events.

## Coordinate data

`orientation` contains relative pitch, yaw, and roll in radians. The source establishes a neutral orientation before publishing relative movement.

`sequence` is monotonically increasing within one source process. `timestamp` is Unix time in seconds.
