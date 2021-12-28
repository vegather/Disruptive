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
    func testExponentialBackoffSchemeUnlimitedRetries() {
        var rs: RetryScheme = ExponentialBackoffScheme(initialBackoff: 5, maxRetries: nil)
        
        let epsilon = 0.001
                
        // First increment
        XCTAssertEqual(rs.nextBackoff()!, 5, accuracy: epsilon)
        
        // Second increment
        XCTAssertEqual(rs.nextBackoff()!, 5.3, accuracy: epsilon)
        
        // Third increment
        XCTAssertEqual(rs.nextBackoff()!, 6, accuracy: epsilon)
        
        // ~Infinite increments
        for _ in 0..<30 { let _ = rs.nextBackoff() }
        XCTAssertEqual(rs.nextBackoff()!, 20, accuracy: epsilon)
        
        // First reset
        rs.reset()
        
        // Second reset
        rs.reset()
        
        // First increment after reset
        XCTAssertEqual(rs.nextBackoff()!, 5, accuracy: epsilon)
        
        // Second increment after reset
        XCTAssertEqual(rs.nextBackoff()!, 5.3, accuracy: epsilon)
    }
    
    func testExponentialBackoffSchemeLimitedRetries() {
        var rs: RetryScheme = ExponentialBackoffScheme(initialBackoff: 0, maxRetries: 4)
        
        let epsilon = 0.001
                
        // First increment
        XCTAssertEqual(rs.nextBackoff()!, 0, accuracy: epsilon)
        
        // Second increment
        XCTAssertEqual(rs.nextBackoff()!, 0.3, accuracy: epsilon)
        
        // Third increment
        XCTAssertEqual(rs.nextBackoff()!, 1, accuracy: epsilon)
        
        // Fourth increment
        XCTAssertEqual(rs.nextBackoff()!, 3, accuracy: epsilon)
        
        // Fifth increment
        XCTAssertNil(rs.nextBackoff())
        
        // ~Infinite increments
        for _ in 0..<30 { let _ = rs.nextBackoff() }
        XCTAssertNil(rs.nextBackoff())
        
        // First reset
        rs.reset()
        
        // Second reset
        rs.reset()
        
        // First increment after reset
        XCTAssertEqual(rs.nextBackoff(), 0)
        
        // Second increment after reset
        XCTAssertEqual(rs.nextBackoff(), 0.3)
    }
}
