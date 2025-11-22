import Valkey
import Vapor

extension Application {
    public var valkey: any ValkeyClientProtocol {
        get {
            guard let client = storage[ValkeyClientKey.self] else {
                fatalError("No valkey client has been configured. Check configuration for `application.valkey = ...`")
            }
            return client
        }
        set {
            storage[ValkeyClientKey.self] = newValue
        }
    }

    struct ValkeyClientKey: StorageKey {
        typealias Value = any ValkeyClientProtocol
    }
}

public extension Request {
    var valkey: any ValkeyClientProtocol {
        application.valkey
    }
}
