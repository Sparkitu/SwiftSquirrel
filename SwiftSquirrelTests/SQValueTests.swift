//
//  SQValueTests.swift
//  SwiftSquirrel
//
//  Created by Egor Chiglintsev on 06.04.15.
//  Copyright (c) 2015  Egor Chiglintsev
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import XCTest
import SwiftSquirrel

class SQValueTests: XCTestCase {
    
    func testThat_IntSQValueCanAddInteger() {
        let sum = SQValue.Int(1)+2
        XCTAssertEqual(sum, SQValue.Int(3),
            "Integer SQValue should be able to add integer values")
    }
    
    func testThat_IntSQValueCanAddFloat() {
        let sum = SQValue.Int(1)+2.0
        XCTAssertEqual(sum, SQValue.Float(3.0),
            "Integer SQValue should be able to add float values")
    }
    
    func testThat_FloatSQValueCanAddInteger() {
        let sum = SQValue.Int(1)+2
        XCTAssertEqual(sum, SQValue.Int(3),
            "Integer SQValue should be able to add integer values")
    }
    
    func testThat_FloatSQValueCanAddFloat() {
        let sum = SQValue.Int(1)+2.0
        XCTAssertEqual(sum, SQValue.Float(3.0),
            "Integer SQValue should be able to add float values")
    }
}