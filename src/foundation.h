/*
 * Copyright (c) 2026 Nicolas Christe
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * Internal C facade over <time.h> — the clock read backing `Date.now`, and the
 * gmtime_r/strftime formatting backing `Date.description`. Not re-exported to
 * Swift callers; both are internal implementation details behind Date's API.
 *
 * Also pulls in <math.h>: this umbrella header's `export *` (see module.modulemap)
 * re-exports newlib's full libm surface (sin/cos/exp/log/pow/... and float variants)
 * to Swift callers as part of this module's public API — no SWIFT_NAME needed since
 * the C names already match Swift's naming convention. There is no Glibc/Darwin-style
 * overlay module for this target otherwise, so this is the only path to libm from Swift.
 */

#pragma once

#include <math.h>
#include <stddef.h>
#include <swift_support.h>

/** Seconds since the Unix epoch (1970-01-01T00:00:00Z), including fractional
 *  seconds, read from CLOCK_REALTIME. Returns 0.0 if the read fails.
 */
SWIFT_NAME("foundationClockNowSeconds()")
double foundation_clock_now_seconds(void);

/** Formats `secondsSince1970` as UTC "YYYY-MM-DD HH:MM:SS +0000" (matches Foundation's
 *  `Date.description` format) into `buffer` (at least 26 bytes). Returns the number of
 *  characters written (excluding the null terminator), or 0 on failure.
 */
SWIFT_NAME("foundationFormatDescription(secondsSince1970:buffer:length:)")
size_t foundation_format_description(double seconds_since_1970, char *buffer, size_t length);
