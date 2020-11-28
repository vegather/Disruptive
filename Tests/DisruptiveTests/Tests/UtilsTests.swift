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
    
}
