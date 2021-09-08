//
//  RetrySchemeTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 10/01/2021.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class RetrySchemeTests: DisruptiveTests {
    func testRetryScheme() {
        var rs = RetryScheme()
        
        // Initial
        XCTAssertEqual(rs.backoffInterval, 0.1)
        
        // First increment
        XCTAssertEqual(rs.nextBackoff(), 0.1)
        XCTAssertEqual(rs.backoffInterval, 0.1)
        
        // Second increment
        XCTAssertEqual(rs.nextBackoff(), 1)
        XCTAssertEqual(rs.backoffInterval, 1)
        
        // ~Infinite increments
        for _ in 0..<30 { let _ = rs.nextBackoff() }
        XCTAssertEqual(rs.nextBackoff(), 15)
        XCTAssertEqual(rs.backoffInterval, 15)
        
        // First reset
        rs.reset()
        XCTAssertEqual(rs.backoffInterval, 0.1)
        
        // Second reset
        rs.reset()
        XCTAssertEqual(rs.backoffInterval, 0.1)
        
        // First increment after reset
        XCTAssertEqual(rs.nextBackoff(), 0.1)
        XCTAssertEqual(rs.backoffInterval, 0.1)
        
        // Second increment after reset
        XCTAssertEqual(rs.nextBackoff(), 1)
        XCTAssertEqual(rs.backoffInterval, 1)
    }
}
