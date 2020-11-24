//
//  NetworkingTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 21/11/2020.
//

import XCTest
@testable import Disruptive

class NetworkingTests: DisruptiveTests {
    func testServerUnavailable() {
        MockURLProtocol.requestHandler = { request in
            return (nil, nil, URLError(.badServerResponse))
        }
        
        let exp = expectation(description: "")
        disruptive.getProjects() { result in
            switch result {
                case .success(_): XCTFail("Expected failure")
                case .failure(let err): XCTAssertEqual(err, .serverUnavailable)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testPagination() {
        // TODO: Implement
    }
}
