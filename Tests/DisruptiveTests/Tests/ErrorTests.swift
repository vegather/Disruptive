//
//  File.swift
//  
//
//  Created by Vegard Solheim Theriault on 19/09/2021.
//

import XCTest
@testable import Disruptive

class ErrorTests: DisruptiveTests {
    func testRestApiErrorFormat() async throws {
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
        
        do {
            let _: Request.EmptyResponse = try await req.internalSend()
            XCTFail()
        } catch let error as DisruptiveError {
            XCTAssertEqual(error.message, "already exists")
            XCTAssertEqual(error.type, .resourceAlreadyExists)
            XCTAssertEqual(error.helpLink, "https://docs.d21s.com/error/#409")
        } catch {
            XCTFail()
        }
    }
}
