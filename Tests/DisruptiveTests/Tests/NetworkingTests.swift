//
//  NetworkingTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 21/11/2020.
//

import XCTest
@testable import Disruptive

class NetworkingTests: DisruptiveTests {
    
    func testPagedKey() {
        let fromString = PagedKey(stringValue: "5")
        XCTAssertEqual(fromString?.intValue, nil)
        XCTAssertEqual(fromString?.stringValue, "5")
        
        let fromInt = PagedKey(intValue: 5)
        XCTAssertEqual(fromInt?.intValue, 5)
        XCTAssertEqual(fromInt?.stringValue, "5")
    }
    
    func testFormURLEncodedBody() {
        XCTAssertEqual(formURLEncodedBody(keysAndValues: [:]), "".data(using: .utf8)!)
        XCTAssertEqual(formURLEncodedBody(keysAndValues: ["foo": "bar"]), "foo=bar".data(using: .utf8)!)
        
        let multi = formURLEncodedBody(keysAndValues: ["foo": "bar", "xyz": "abc"])!
        if multi != "foo=bar&xyz=abc".data(using: .utf8)! && multi != "xyz=abc&foo=bar".data(using: .utf8)! {
            XCTFail("Unexpected result: \(multi)")
        }
    }
    
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
