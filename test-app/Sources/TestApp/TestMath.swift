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

func testMath(logger: Logger) {
    let tolerance: Float = 0.0001

    guard abs(sinf(0)) < tolerance else {
        logger.e("Math: sinf(0) mismatch")
        return
    }
    guard abs(cosf(0) - 1) < tolerance else {
        logger.e("Math: cosf(0) mismatch")
        return
    }
    guard abs(sqrtf(4) - 2) < tolerance else {
        logger.e("Math: sqrtf(4) mismatch")
        return
    }
    guard abs(expf(0) - 1) < tolerance else {
        logger.e("Math: expf(0) mismatch")
        return
    }
    guard abs(atan2f(1, 1) - 0.7853982) < tolerance else {
        logger.e("Math: atan2f(1,1) mismatch")
        return
    }

    logger.i("Math: libm APIs compiled and behaved correctly")
}
