# SwiftFoundation

Minimal Foundation-shaped `Date` type for Embedded Swift. Real Foundation (and
`FoundationEssentials`) doesn't build for Embedded Swift today — `Calendar`/locale support needs
ICU, which doesn't fit MCU-class targets. This component provides just `Date`: an immutable,
comparable point in time, decoupled from any particular clock source.

## Features

- `Date` — `timeIntervalSince1970: Double`, `Equatable`/`Hashable`/`Comparable`/`Sendable`.
- `Date.now` — current time from `CLOCK_REALTIME`, via a small internal `clock_gettime` facade.
- `addingTimeInterval(_:)`, `timeIntervalSince(_:)`, `distantPast`, `distantFuture`.
- `description` — `CustomStringConvertible`, UTC `"YYYY-MM-DD HH:MM:SS +0000"`, for debug printing.
- No `Calendar`/formatting/`Codable` — out of scope for now (see `CLAUDE.md`).

## Usage

```swift
import Foundation

let start = Date.now
// ... do work ...
let elapsed = Date.now.timeIntervalSince(start)

let deadline = start.addingTimeInterval(30)
if Date.now > deadline {
    // timed out
}
```

`Date.now` is meaningless before the system clock has been synced (NTP, Matter's Time
Synchronization cluster, etc.) — the ESP32 boots near the Unix epoch otherwise. This component
doesn't decide what counts as "synced"; that check stays app-specific.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
