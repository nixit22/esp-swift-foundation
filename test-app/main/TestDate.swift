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

import Foundation
import Platform

func testDate(logger: Logger) {
    let start = Date.now
    let later = start.addingTimeInterval(30)

    guard later > start else {
        logger.e("Date: Comparable failed (later should be > start)")
        return
    }
    guard later.timeIntervalSince(start) == 30 else {
        logger.e("Date: timeIntervalSince mismatch")
        return
    }
    guard Date.distantPast < start, start < Date.distantFuture else {
        logger.e("Date: distantPast/distantFuture ordering failed")
        return
    }
    let descriptionBytes = Array(start.description.utf8)
    guard descriptionBytes.count == 25, descriptionBytes.suffix(6).elementsEqual(" +0000".utf8) else {
        logger.e("Date: description malformed")
        return
    }

    logger.i("Date: now = \(start)")
    logger.i("Date: APIs compiled and behaved correctly")
}
