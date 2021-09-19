//
//  File.swift
//  
//
//  Created by Vegard Solheim Theriault on 19/09/2021.
//

import XCTest
@testable import Disruptive

class ErrorTests: DisruptiveTests {
    func testRestApiErrorFormat() {
        let errorPayload = """
        {
            "error": "already exists",
            "code": 409,
            "help":"https://docs.d21s.com/error/#409"
        }
        """.data(using: .utf8)!
        
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("getError")
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : false,
                method        : "POST",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 409, httpVersion: nil, headerFields: nil)!
            return (errorPayload, resp, nil)
        }
        
        let req = Request(
            method: .post,
            baseURL: "https://api.disruptive-technologies.com/v2/",
            endpoint: "getError"
        )
        
        let exp = expectation(description: "testRestApiErrorFormat")
        
        req.internalSend { (result: Result<Request.EmptyResponse, DisruptiveError>) in
            switch result {
                case .success(_): XCTFail()
                case .failure(let err):
                    XCTAssertEqual(err.message, "already exists")
                    XCTAssertEqual(err.type, .resourceAlreadyExists)
                    XCTAssertEqual(err.helpLink, "https://docs.d21s.com/error/#409")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
}
