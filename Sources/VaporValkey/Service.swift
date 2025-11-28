import ServiceLifecycle
import Valkey
import Vapor

extension Application {
    public var valkey: any ValkeyClientProtocol & ServiceLifecycle.Service {
        get {
            guard let valkeyClientStorage = storage[ValkeyClientKey.self] else {
                fatalError("No valkey client has been configured. Check configuration for `application.valkey = ...`")
            }
            return valkeyClientStorage.client
        }
        set {
            let valkeyClientStorage = ValkeyClientStorage(
                client: newValue,
                task: Task {
                    try await newValue.run()
                }
            )
            storage.set(
                ValkeyClientKey.self,
                to: valkeyClientStorage,
                onShutdown: { valkeyClientStorage in
                    valkeyClientStorage.task.cancel()
                }
            )
        }
    }

    struct ValkeyClientKey: StorageKey {
        typealias Value = ValkeyClientStorage
    }
}

actor ValkeyClientStorage {
    let client: any ValkeyClientProtocol & ServiceLifecycle.Service
    let task: Task<Void, any Error>

    init(
        client: any ValkeyClientProtocol & ServiceLifecycle.Service,
        task: Task<Void, any Error>
    ) {
        self.client = client
        self.task = task
    }
}

public extension Request {
    var valkey: any ValkeyClientProtocol {
        application.valkey
    }
}
