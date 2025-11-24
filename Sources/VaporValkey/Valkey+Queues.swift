#if Queues
    import Queues
    import Valkey
    import Vapor

    public extension Application.Queues.Provider {
        static func valkey() throws -> Self {
            .init { app in
                app.queues.use(
                    custom: ValkeyQueuesDriver(
                        client: app.valkey,
                        eventLoopGroup: app.eventLoopGroup
                    )
                )
            }
        }
    }

    struct ValkeyQueuesDriver: QueuesDriver {
        let client: any ValkeyClientProtocol
        let eventLoopGroup: EventLoopGroup

        func makeQueue(with context: QueueContext) -> any Queue {
            return ValkeyQueue(client: client, context: context, eventLoopGroup: eventLoopGroup)
        }

        func shutdown() { }

        func asyncShutdown() async { }
    }

    struct ValkeyQueue: Queue {
        let client: any ValkeyClientProtocol
        var context: QueueContext
        let eventLoopGroup: EventLoopGroup
        let decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            return decoder
        }()

        let encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            return encoder
        }()

        var processingKey: String {
            "\(key)-processing"
        }

        func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> {
            eventLoopGroup.makeFutureWithTask {
                // Get the job data
                guard let buffer = try await client.get(.init(id.key)) else {
                    throw ValkeyQueueError.missingJob
                }
                return try decoder.decode(JobData.self, from: buffer)
            }
        }

        func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void> {
            eventLoopGroup.makeFutureWithTask {
                // Set the job data
                try await client.set(.init(id.key), value: encoder.encode(data))
            }
        }

        func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> {
            eventLoopGroup.makeFutureWithTask {
                // Remove all job references from queue processing list
                try await client.lrem(.init(self.processingKey), count: 0, element: id.string)
                // Delete the job
                try await client.del(keys: [.init(id.key)])
            }
        }

        func pop() -> EventLoopFuture<JobIdentifier?> {
            eventLoopGroup.makeFutureWithTask {
                // Move the last job reference from queue list to processing list
                guard let buffer = try await client.rpoplpush(
                    source: .init(self.key),
                    destination: .init(self.processingKey)
                ) else {
                    return nil
                }
                guard let id = buffer.getString(at: 0, length: buffer.readableBytes) else {
                    throw ValkeyQueueError.nonStringIdentifier
                }
                return .init(string: id)
            }
        }

        func push(_ id: JobIdentifier) -> EventLoopFuture<Void> {
            eventLoopGroup.makeFutureWithTask {
                // Add a job reference to the end of the queue list
                try await client.lpush(.init(self.key), elements: [id.string])
                // Remove all job references from our processing list
                try await client.lrem(.init(self.processingKey), count: 0, element: id.string)
            }
        }
    }

    enum ValkeyQueueError: Error {
        case missingJob
        case nonStringIdentifier
    }

    package extension JobIdentifier {
        var key: String {
            return "job:\(string)"
        }
    }
#endif
