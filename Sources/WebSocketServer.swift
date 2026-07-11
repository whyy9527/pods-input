import Foundation
import NIO
import NIOHTTP1
import NIOPosix
import NIOWebSocket
import PodsInputCore

final class WebSocketServer {
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var channel: Channel?
    private var clients: [ObjectIdentifier: Channel] = [:]
    private let clientsLock = NSLock()
    private let onCalibrate: @Sendable () -> Void

    init(onCalibrate: @escaping @Sendable () -> Void) {
        self.onCalibrate = onCalibrate
    }

    func start(port: Int) throws {
        let upgrader = NIOWebSocketServerUpgrader(
            shouldUpgrade: { channel, request in
                let origin = request.headers.first(name: "Origin")
                let allowed = origin == nil || origin == "null" || Self.isLocalOrigin(origin)
                return channel.eventLoop.makeSucceededFuture(allowed ? HTTPHeaders() : nil)
            },
            upgradePipelineHandler: { [weak self] channel, _ in
                guard let self else { return channel.eventLoop.makeSucceededVoidFuture() }
                return channel.pipeline.addHandler(WebSocketHandler(
                    onConnect: { self.add($0) },
                    onDisconnect: { self.remove($0) },
                    onCalibrate: self.onCalibrate
                ))
            }
        )
        let configuration = NIOHTTPServerUpgradeConfiguration(
            upgraders: [upgrader],
            completionHandler: { _ in }
        )
        channel = try ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: configuration)
            }
            .bind(host: "127.0.0.1", port: port)
            .wait()
    }

    func broadcast(_ event: MotionEvent) {
        let payload: String
        do {
            payload = try event.encoded()
        } catch {
            fputs("Motion event encoding failed: \(error)\n", stderr)
            return
        }
        clientsLock.lock()
        let activeClients = Array(clients.values)
        clientsLock.unlock()
        for client in activeClients where client.isActive {
            var buffer = client.allocator.buffer(capacity: payload.utf8.count)
            buffer.writeString(payload)
            client.writeAndFlush(WebSocketFrame(fin: true, opcode: .text, data: buffer), promise: nil)
        }
    }

    func stop() {
        try? channel?.close().wait()
        try? group.syncShutdownGracefully()
    }

    private func add(_ channel: Channel) {
        clientsLock.lock()
        clients[ObjectIdentifier(channel)] = channel
        clientsLock.unlock()
    }

    private func remove(_ channel: Channel) {
        clientsLock.lock()
        clients.removeValue(forKey: ObjectIdentifier(channel))
        clientsLock.unlock()
    }

    private static func isLocalOrigin(_ origin: String?) -> Bool {
        guard let origin, let host = URL(string: origin)?.host else { return false }
        return host == "localhost" || host == "127.0.0.1" || host == "::1"
    }
}

private final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame
    private let onConnect: (Channel) -> Void
    private let onDisconnect: (Channel) -> Void
    private let onCalibrate: @Sendable () -> Void
    private var isClosing = false

    init(
        onConnect: @escaping (Channel) -> Void,
        onDisconnect: @escaping (Channel) -> Void,
        onCalibrate: @escaping @Sendable () -> Void
    ) {
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.onCalibrate = onCalibrate
    }

    func handlerAdded(context: ChannelHandlerContext) { onConnect(context.channel) }
    func handlerRemoved(context: ChannelHandlerContext) {
        if !isClosing { onDisconnect(context.channel) }
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        if frame.opcode == .ping {
            context.writeAndFlush(wrapOutboundOut(WebSocketFrame(fin: true, opcode: .pong, data: frame.data)), promise: nil)
        } else if frame.opcode == .connectionClose {
            isClosing = true
            onDisconnect(context.channel)
            let response = WebSocketFrame(fin: true, opcode: .connectionClose, data: frame.unmaskedData)
            context.writeAndFlush(wrapOutboundOut(response)).whenComplete { _ in
                context.close(promise: nil)
            }
        } else if frame.opcode == .text {
            let data = Data(frame.unmaskedData.readableBytesView)
            guard let command = try? JSONDecoder().decode(ControlCommand.self, from: data),
                  command.protocolVersion == PodsInputProtocol.version,
                  command.type == "calibrate" else {
                return
            }
            onCalibrate()
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        context.close(promise: nil)
    }
}
