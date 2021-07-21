//
//  File.swift
//  
//
//  Created by Vegard Solheim Theriault on 25/11/2020.
//

import XCTest
@testable import Disruptive

class UtilsTests: XCTestCase {
    
    func testDecodeISO8601String() {
        let input = "2020-11-25T09:16:02.373046Z"
        let output = Date(timeIntervalSince1970: 1606295762.373)
        
        XCTAssertEqual(
            (try! Date(iso8601String: input)).timeIntervalSince1970,
            output.timeIntervalSince1970
        )
    }
    
    func testDecodeISO8601StringFail() {
        let input = "this is not a iso8601 string"
        
        XCTAssertThrowsError(try Date(iso8601String: input))
    }

    func testEncodeISO8601String() {
        let input = Date(timeIntervalSince1970: 1606295762)
        let output = "2020-11-25T09:16:02.000Z"
        
        XCTAssertEqual(input.iso8601String(), output)
    }
    
    func testCelsiusToFahrenheit() {
        let tests: [(input: Float, output: Float)] = [
            (input: 0,   output: 32),
            (input: 1,   output: 33.8),
            (input: -1,  output: 30.2),
            (input: 15,  output: 59),
            (input: -15, output: 5)
        ]
        
        for test in tests {
            XCTAssertEqual(celsiusToFahrenheit(celsius: test.input), test.output)
        }
    }
    
    func testFahrenheitToCelsius() {
        let tests: [(input: Float, output: Float)] = [
            (input: 0,   output: -17.777778),
            (input: 1,   output: -17.222222),
            (input: -1,  output: -18.333333),
            (input: 15,  output: -9.4444444),
            (input: -15, output: -26.111111)
        ]
        
        for test in tests {
            XCTAssertEqual(
                fahrenheitToCelsius(fahrenheit: test.input),
                test.output,
                accuracy: 0.0001
            )
        }
    }
    
}
