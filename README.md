# Vapor Valkey

This project provides [valkey-swift](https://github.com/valkey-io/valkey-swift) as a driver for [Vapor](https://github.com/vapor/vapor) caching and sessions.

## Usage

To use this package, create a Valkey client and assign it to `Application.valkey`:

```swift
let vaporApp = Application.make(.detect)

let valkeyClient = ValkeyClient(
    .hostname("localhost", port: 6379),
    eventLoopGroup: app.eventLoopGroup,
    logger: app.logger
)

// Attach Valkey service to enable `Application.valkey` & `Request.valkey`
vaporApp.valkey = valkeyClient

// Use Valkey for caching
vaporApp.caches.use(.valkey())

// Use Valkey for sessions
vaporApp.sessions.use(.valkey())
```

When assigning the Application's `valkey` property (the `vaporApp.valkey = valkeyClient` line above), the Application will take ownership of the Valkey client's lifecycle. Specifically, this assignment operation will automatically run the client, and it will be automatically cancelled when the Application is shut down.
