# SwiftFoundation

Minimal Foundation-shaped types for Embedded Swift, plus libm math bindings. Swift module name:
**`Foundation`**.

Depends on: `esp-swift-support` (`swift_support.h`'s `SWIFT_NAME`, and — as a public `REQUIRES`, not
`PRIV_REQUIRES` — the implicit toolchain include dirs that let `foundation.h`'s `#include <math.h>`
resolve when *consumers* re-parse the umbrella header, not just when this component builds itself;
no `esp-swift-platform`, no ESP-IDF driver components).

## Why this exists

Real Foundation (and `FoundationEssentials`) doesn't build for Embedded Swift — see
[the wiki's writeup](/Users/nicolas/bob/wiki/esp32-swift/foundation-embedded-swift.md) of the
still-open [Swift Forums thread](https://forums.swift.org/t/foundation-in-embedded-swift/84483).
Blockers: `Calendar`/locale need ICU (too big for MCU targets), `Data` needs an embedded-compatible
allocator story, JSON needs existential types Embedded Swift doesn't have. None of that blocks a
bare `Date` value type, though — this component picks off just that piece.

Before this existed, every app needing time (`matter-time-test`) hand-rolled a local C shim over
`<time.h>` (`TimeUtil.c`) with no shared Swift type. This component is that shared type.

## Design: `Date` is decoupled from the clock

Per the forum thread's consensus (Avi/Sore, 2026-02-05): a `Date` value type should not assume an
RTC/clock exists — bare `Date()` in real Foundation assumes one, which doesn't hold on boards
without an RTC. Here, `Date` is just an immutable `timeIntervalSince1970: Double` wrapper —
`Comparable`/`Equatable`/`Hashable`, arithmetic via `addingTimeInterval`/`timeIntervalSince`.

The **only** clock-touching code is `Date.now`, backed by `src/foundation.c`'s
`foundation_clock_now_seconds()` (a `clock_gettime(CLOCK_REALTIME)` facade, `SWIFT_NAME`'d).
`Date.swift` imports the raw Clang module with `@_exported import ESP_Foundation` so that libm
(re-exported through `foundation.h`'s `#include <math.h>`, see below) reaches `import Foundation`
callers too; `foundation_clock_now_seconds`/
`foundation_format_description` ride along as an incidental, undocumented part of that re-export
(harmless — they're an internal implementation detail callers have no reason to call directly, just
no longer hidden at the type-system level). `Date.now` is meaningless
before the system clock has actually been synced (NTP, Matter's Time Synchronization cluster, etc.)
— the ESP32 boots near the Unix epoch otherwise. Callers needing "has the clock been synced yet"
still need their own threshold check (e.g. `matter-time-test/main.swift`'s
`Date.now >= syncedTimeThreshold`); that check wasn't folded in here since "synced" is app-defined
(what counts as a sane threshold varies).

## Files

| File | Role |
|---|---|
| `src/Date.swift` | `Date`, `TimeInterval` — the public API |
| `src/foundation.h` / `src/foundation.c` | Internal `clock_gettime` facade backing `Date.now`; also the umbrella header re-exporting libm |
| `module.modulemap` | Clang module `ESP_Foundation` — umbrella over `src/foundation.h` |

## libm math functions (sin/cos/exp/log/pow/...)

`src/foundation.h` does a plain `#include <math.h>`, so libm's declarations become part of the raw
Clang module `ESP_Foundation`. `Date.swift`'s `@_exported import ESP_Foundation` is what actually
carries them through to `import Foundation` callers — a plain (non-`@_exported`) import would only
make them visible inside `esp-swift-foundation`'s own sources, not to downstream consumers. No
`SWIFT_NAME` wrapping needed since the C names (`sin`, `cosf`, `sqrt`, `atan2f`, ...) already match
Swift's naming convention. There is no `Glibc`/`Darwin`-style overlay module for this target (see
[the wiki study](/Users/nicolas/bob/wiki/esp32-swift/embedded-swift-math-functions.md)) — libm
itself is already linked (same newlib backing `clock_gettime` above), just not otherwise exposed to
Swift.

Covers the full Tier-1 table: trig (`sin/cos/tan/asin/acos/atan/atan2`), hyperbolic
(`sinh/cosh/tanh/asinh/acosh/atanh`), exp/log (`exp/exp2/expm1/log/log2/log10/log1p`), power/root
(`pow/sqrt/cbrt/hypot`), rounding (`ceil/floor/round/trunc/nearbyint/rint`), misc
(`fabs/fmod/fdim/fma/copysign/frexp/ldexp/modf`), and newlib's special-function extensions
(`erf/erfc/tgamma/lgamma/j0/j1/jn/y0/y1/yn`) — each with a `Double` and an `f`-suffixed `Float`
variant.

**Prefer the `f`-suffixed `Float` variants** (`sinf`, `cosf`, `sqrtf`, ...) in real call sites.
ESP32C6 is RV32IMC — no double-precision FPU extension — so `Double` trig is soft-float and slow.
Waveform-generation callers (LEDC PWM curves, MCPWM motor profiles) should default to `Float`.

Out of scope: `swift-numerics`' `RealModule`/`Real` protocol layer — a separate, generic wrapper
around this same libm surface, unverified for Embedded Swift buildability. This component only
provides the raw C-level bindings.

## Public API

```swift
import Foundation

public typealias TimeInterval = Double

public struct Date: Equatable, Hashable, Comparable, CustomStringConvertible, Sendable {
    public let timeIntervalSince1970: TimeInterval
    public init(timeIntervalSince1970: TimeInterval)
    public static var now: Date { get }
    public static let distantPast: Date   // ~0001-01-01T00:00:00Z
    public static let distantFuture: Date // ~4001-01-01T00:00:00Z
    public func addingTimeInterval(_ interval: TimeInterval) -> Date
    public func timeIntervalSince(_ other: Date) -> TimeInterval
    public var description: String // "YYYY-MM-DD HH:MM:SS +0000", UTC
}
```

## `distantPast`/`distantFuture` are byte-exact against upstream, not recomputed

Verified against `apple/swift-foundation`'s `Sources/FoundationEssentials/Date.swift` directly
(cloned locally, not from memory): `distantFuture = 63113904000.0` and `distantPast =
-63114076800.0`, both `timeIntervalSinceReferenceDate` (ref date 2001-01-01, offset
`978307200.0` from the 1970 epoch). Converted to `timeIntervalSince1970`: `distantFuture =
64_092_211_200`, `distantPast = -62_135_769_600`.

`distantPast` is **not** a clean proleptic-Gregorian `0001-01-01T00:00:00Z` — it's 2 days
(`172800` sec) off that, a historical Julian/Gregorian calendar-cutover quirk baked into
CoreFoundation's original constant (confirmed in upstream's own `DateTests.swift`, which shows
`Date.distantPast.description` rendering as `"0000-12-30 00:00:00 +0000"` under some calendar
contexts). First pass here used the clean calendar-computed value
(`-62_135_596_800`) before this was checked against upstream — fixed to the exact constant so
literal `Date` comparisons behave the same as real Foundation.

## `Date.description` (debug printing)

Ported directly from `apple/swift-foundation`'s `FoundationEssentials/Date.swift`: UTC
`"YYYY-MM-DD HH:MM:SS +0000"` via `gmtime_r`/`strftime` (`foundation_format_description` in
`src/foundation.c`), same `distantPast`/`distantFuture` bounds check and `"<description
unavailable>"` fallback as upstream. `CustomStringConvertible` conformance means `"\(someDate)"`
and `logger.i("\(someDate)")` just work.

**Gotcha hit while testing this**: `String.hasSuffix`/`String.count` (grapheme-cluster-based)
pulled in Unicode normalization tables (`_swift_stdlib_getNormData` etc.) that aren't linked for
this embedded target, causing link errors. Fix was comparing `Array(str.utf8)` (byte-level,
`Collection`-only APIs like `.count`/`.suffix(_:).elementsEqual(_:)`) instead of the
`Character`-based String APIs. Worth remembering for any future string-comparison code in this
component or its test-app.

## Explicitly out of scope for v0

No `Calendar`, `DateFormatter`, `DateComponents`, ISO8601 formatting, or `Codable`. Apps needing
formatted output beyond `Date`'s own `CustomStringConvertible` (`YYYY-MM-DD HH:MM:SS +0000`, UTC
only) still write their own C/Swift formatting code against `timeIntervalSince1970` — this
component doesn't attempt to replace that, only to give call sites a shared, comparable value type
instead of each app passing around raw `Double`/`time_t`.
