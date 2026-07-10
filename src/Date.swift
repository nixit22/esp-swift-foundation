// Copyright (c) 2026 Nicolas Christe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import ESP_Foundation

/// Interval, in seconds, between two dates. Matches Foundation's `TimeInterval`.
public typealias TimeInterval = Double

/// A point in time, stored as seconds since the Unix epoch (1970-01-01T00:00:00Z).
///
/// No `Calendar`/formatting — ICU-backed calendrical support doesn't fit Embedded Swift
/// (see swift-esp-foundation's CLAUDE.md). Apps needing local-time display still format
/// their own strings (e.g. `matter-time-test`'s `TimeUtil.c`).
public struct Date: Equatable, Hashable, Sendable {
    public let timeIntervalSince1970: TimeInterval

    public init(timeIntervalSince1970: TimeInterval) {
        self.timeIntervalSince1970 = timeIntervalSince1970
    }

    /// The current time, read from the system clock (`CLOCK_REALTIME`).
    ///
    /// Meaningless before the clock has been synced (e.g. via NTP or Matter's Time
    /// Synchronization cluster) — the ESP32 boots near the Unix epoch otherwise.
    public static var now: Date {
        Date(timeIntervalSince1970: foundationClockNowSeconds())
    }

    /// Approximately 0001-01-01T00:00:00Z. Bit-for-bit the same constant Foundation uses
    /// (`-63114076800` relative to its 2001 reference date) — not a clean calendar computation;
    /// Foundation's own value is 2 days off a pure proleptic-Gregorian 0001-01-01 due to a
    /// historical Julian/Gregorian calendar-cutover quirk in CoreFoundation.
    public static let distantPast = Date(timeIntervalSince1970: -62_135_769_600)

    /// Approximately 4001-01-01T00:00:00Z. Matches Foundation's `Date.distantFuture`.
    public static let distantFuture = Date(timeIntervalSince1970: 64_092_211_200)

    /// Returns a new date offset from this one by `interval` seconds.
    public func addingTimeInterval(_ interval: TimeInterval) -> Date {
        Date(timeIntervalSince1970: timeIntervalSince1970 + interval)
    }

    /// Seconds between this date and `other` (positive if `self` is later).
    public func timeIntervalSince(_ other: Date) -> TimeInterval {
        timeIntervalSince1970 - other.timeIntervalSince1970
    }
}

extension Date: Comparable {
    public static func < (lhs: Date, rhs: Date) -> Bool {
        lhs.timeIntervalSince1970 < rhs.timeIntervalSince1970
    }
}

extension Date: CustomStringConvertible {
    /// UTC "YYYY-MM-DD HH:MM:SS +0000" — same format and bounds check as Foundation's
    /// `Date.description` (which itself is just `gmtime_r` + `strftime`, no `Calendar` involved).
    public var description: String {
        let unavailable = "<description unavailable>"
        guard self >= Date.distantPast, self <= Date.distantFuture else {
            return unavailable
        }

        let bufferSize = 32
        var len = 0
        let buffer = [CChar](unsafeUninitializedCapacity: bufferSize) { ptr, initializedCount in
            len = foundationFormatDescription(
                secondsSince1970: timeIntervalSince1970, buffer: ptr.baseAddress, length: bufferSize)
            initializedCount = len
        }
        guard len > 0 else { return unavailable }
        return String(decoding: buffer.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}
