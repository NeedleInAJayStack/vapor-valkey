import Valkey
import Vapor

public extension Application.Sessions.Provider {
    /// Provides a Valkey sessions driver. If client is not provided, then `Application.valkey` must be configured.
    static func valkey(
        _ client: (any ValkeyClientProtocol)? = nil,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) -> Self {
        return .init {
            $0.sessions.use { _ in
                ValkeySessionsDriver(
                    client: client,
                    encoder: encoder,
                    decoder: decoder
                )
            }
        }
    }
}

struct ValkeySessionsDriver: SessionDriver {
    let client: (any ValkeyClientProtocol)?
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    func createSession(_ data: SessionData, for request: Request) -> EventLoopFuture<SessionID> {
        let sessionID = makeSessionID()
        let key = makeKey(sessionID: sessionID)

        return request.eventLoop.makeFutureWithTask {
            try await (client ?? request.valkey).set(.init(key), value: encoder.encode(data))
            return sessionID
        }
    }

    func readSession(_ sessionID: SessionID, for request: Request) -> EventLoopFuture<SessionData?> {
        let key = makeKey(sessionID: sessionID)

        return request.eventLoop.makeFutureWithTask {
            try await (client ?? request.valkey).get(.init(key)).map { buffer in
                try decoder.decode(SessionData.self, from: buffer)
            }
        }
    }

    func updateSession(_ sessionID: SessionID, to data: SessionData, for request: Request) -> EventLoopFuture<SessionID> {
        let key = makeKey(sessionID: sessionID)

        return request.eventLoop.makeFutureWithTask {
            try await (client ?? request.valkey).set(.init(key), value: encoder.encode(data))
            return sessionID
        }
    }

    func deleteSession(_ sessionID: SessionID, for request: Request) -> EventLoopFuture<Void> {
        let key = makeKey(sessionID: sessionID)

        return request.eventLoop.makeFutureWithTask {
            try await (client ?? request.valkey).del(keys: [.init(key)])
        }
    }

    private func makeSessionID() -> SessionID {
        var bytes = Data()
        for _ in 0 ..< 32 {
            bytes.append(.random(in: .min ..< .max))
        }
        return SessionID(string: bytes.base64EncodedString())
    }

    private func makeKey(sessionID: SessionID) -> String {
        return "vvs-\(sessionID.string)"
    }
}
