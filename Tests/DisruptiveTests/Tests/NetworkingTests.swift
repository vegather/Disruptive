//
//  NetworkingTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 21/11/2020.
//

import XCTest
@testable import Disruptive

class NetworkingTests: DisruptiveTests {
    
    func testDecodePagedResult() {
        struct Dummy: Decodable {
            let foo: String
            let bar: Int
        }
        
        let validPayload = """
        {
            "results": [
                {
                    "foo": "some value",
                    "bar": 42
                }
            ],
            "nextPageToken": "token"
        }
        """.data(using: .utf8)!
        let validOutput = try! JSONDecoder().decode(PagedResult<Dummy>.self, from: validPayload)
        XCTAssertEqual(validOutput.results.count, 1)
        XCTAssertEqual(validOutput.results[0].foo, "some value")
        XCTAssertEqual(validOutput.results[0].bar, 42)
        XCTAssertEqual(validOutput.nextPageToken, "token")
        
        
        let emptyNextPageTokenPayload = """
        {
            "results": [],
            "nextPageToken": ""
        }
        """.data(using: .utf8)!
        let nextPageTokenOutput = try! JSONDecoder().decode(PagedResult<Dummy>.self, from: emptyNextPageTokenPayload)
        XCTAssertNil(nextPageTokenOutput.nextPageToken)
        
        
        let invalidPayload = """
        {
            "results": [
                {
                    "invalid": "some value",
                    "bar": 42
                }
            ],
            "nextPageToken": "token"
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(PagedResult<Dummy>.self, from: invalidPayload))
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
        disruptive.getAllProjects() { result in
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
