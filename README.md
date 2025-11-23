# Vapor Valkey

This project provides [valkey-swift](https://github.com/valkey-io/valkey-swift) as a driver for [Vapor](https://github.com/vapor/vapor) caching and sessions.

## Usage

To use this package, create a Valkey client outside of the Vapor application and inject it in:

```swift
let valkeyClient = ValkeyClient(.hostname("localhost", port: 6379), eventLoopGroup: eventLoopGroup, logger: logger)
async let _ = valkeyClient.run()

let vaporApp = Application.make(.detect)

// Attach Valkey service to enable `Application.valkey` & `Request.valkey`
vaporApp.valkey = valkeyClient

// Use Valkey for caching
vaporApp.caches.use(.valkey(valkeyClient))

// Use Valkey for sessions
vaporApp.sessions.use(.valkey(valkeyClient))
```

You are responsible for managing the lifecycle of the Valkey client itself, which is [documented in `valkey-swift`](https://github.com/valkey-io/valkey-swift/tree/main?tab=readme-ov-file#usage).
