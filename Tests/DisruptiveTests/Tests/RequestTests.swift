//
//  RequestTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 10/01/2021.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class RequestTests: DisruptiveTests {
    func testInitWithoutBody() {
        let req = Request(
            method: .get,
            baseURL: "https://example.com/",
            endpoint: "endpoint",
            headers: [HTTPHeader(field: "field", value: "value")],
            params: ["key": ["value"]]
        )
        XCTAssertEqual(req.method, .get)
        XCTAssertEqual(req.baseURL, "https://example.com/")
        XCTAssertEqual(req.endpoint, "endpoint")
        XCTAssertEqual(req.headers[0].field, "field")
        XCTAssertEqual(req.headers[0].value, "value")
        XCTAssertEqual(req.params, ["key": ["value"]])
    }
    
    func testInitWithDataBody() {
        let body = """
        {
            "foo": "bar"
        }
        """.data(using: .utf8)!
        
        do {
            let req = try Request(method: .post, baseURL: "base", endpoint: "endpoint", body: body)
            XCTAssertEqual(req.headers.count, 0)
            XCTAssertEqual(req.body, body)
        } catch {
            XCTFail("Shouldn't throw")
        }
    }
    
    func testInitWithEncodableBody() {
        struct Payload: Encodable {
            let foo: String
        }
        let body = Payload(foo: "bar")
        
        do {
            let req = try Request(method: .post, baseURL: "base", endpoint: "endpoint", body: body)
            XCTAssertEqual(req.headers.count, 1)
            XCTAssertEqual(req.headers[0].field, "Content-Type")
            XCTAssertEqual(req.headers[0].value, "application/json")
            XCTAssertEqual(req.body, try! JSONEncoder().encode(body))
        } catch {
            XCTFail("Shouldn't throw")
        }
    }
    
    func testSetHeader() {
        var req = Request(method: .get, baseURL: "", endpoint: "")
        XCTAssertEqual(req.headers.count, 0)
        
        req.setHeader(field: "foo", value: "bar")
        XCTAssertEqual(req.headers.count, 1)
        XCTAssertEqual(req.headers[0].field, "foo")
        XCTAssertEqual(req.headers[0].value, "bar")
        
        req.setHeader(field: "foo", value: "new value")
        XCTAssertEqual(req.headers.count, 1)
        XCTAssertEqual(req.headers[0].field, "foo")
        XCTAssertEqual(req.headers[0].value, "new value")
        
        req.setHeader(field: "new key", value: "bar")
        XCTAssertEqual(req.headers.count, 2)
        XCTAssertEqual(req.headers[1].field, "new key")
        XCTAssertEqual(req.headers[1].value, "bar")
    }
    
    func testUrlRequestWithMinimalValues() {
        let req = Request(method: .get, baseURL: "https://example.com/", endpoint: "ep")
        let request = req.urlRequest()
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.allHTTPHeaderFields, [:])
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertNil(request?.httpBody)
        XCTAssertEqual(request?.url?.absoluteString, "https://example.com/ep")
    }
    
    func testUrlRequestWithAllValues() {
        let body = """
        empty
        """.data(using: .utf8)!
        
        do {
            let req = try Request(
                method: .delete,
                baseURL: "https://example.com/",
                endpoint: "endpoint",
                headers: [HTTPHeader(field: "first", value: "foo"), HTTPHeader(field: "second", value: "bar")],
                params: ["foo": ["bar1", "bar2"]],
                body: body
            )
            let request = req.urlRequest()
            XCTAssertNotNil(request)
            XCTAssertEqual(request?.allHTTPHeaderFields, ["first": "foo", "second": "bar"])
            XCTAssertEqual(request?.httpMethod, "DELETE")
            XCTAssertEqual(request?.httpBody, body)
            XCTAssertEqual(request?.url?.absoluteString, "https://example.com/endpoint?foo=bar1&foo=bar2")
        } catch {
            XCTFail("Shouldn't throw")
        }
    }
    
    func testUrlRequestInvalidEndpoint() {
        let req = Request(method: .get, baseURL: "https://example.com/", endpoint: "🙃")
        XCTAssertNil(req.urlRequest())
    }
    
    func testSendWithNilUrlRequest() async throws {
        let req = Request(method: .get, baseURL: "", endpoint: "🙃")
        
        do {
            let _: String = try await req.send()
            XCTFail()
        } catch let error as DisruptiveError {
            XCTAssertEqual(error.type, .unknownError)
        } catch {
            XCTFail()
        }
    }
    
    func testSendWithKnownError() async throws {
        let req = Request(method: .get, baseURL: "https://example.com/", endpoint: "ep")
        let reqURL = req.urlRequest()!.url!
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for    : request,
                method : "GET",
                url    : reqURL
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        do {
            let _: String = try await req.send()
            XCTFail()
        } catch let error as DisruptiveError {
            XCTAssertEqual(error.type, .notFound)
        } catch {
            XCTFail()
        }
    }
    
    func testSendWithRateLimitError() async throws {
        let body = """
        {
            "updateTime": "\(Date().iso8601String())"
        }
        """.data(using: .utf8)!
        let req = try! Request(method: .get, baseURL: "https://example.com/", endpoint: "ep", body: body)
        let reqURL = req.urlRequest()!.url!
        
        // The request handler will get called two times.
        // * First time a rate limit of 1 second is returned.
        // * Second time a 200 is returned
        var count = 0
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for    : request,
                method : "GET",
                url    : reqURL,
                body   : body
            )
            
            let resp: HTTPURLResponse
            if count == 0 {
                // Rate-limit
                resp = HTTPURLResponse(url: reqURL, statusCode: 429, httpVersion: nil, headerFields: ["Retry-After": "1"])!
            } else if count == 1 {
                // Success
                resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            } else {
                XCTFail("Should only be called twice")
                return (nil, nil, nil)
            }
            
            count += 1
            
            return (body, resp, nil)
        }
        
        let _: TouchEvent = try await req.send()
    }
    
    func testSendWithEmptyResponse() async throws {
        let req = Request(method: .get, baseURL: "https://example.com/", endpoint: "ep")
        let reqURL = req.urlRequest()!.url!

        MockURLProtocol.requestHandler = { request in
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }

        let _: Request.EmptyResponse = try await req.send()
    }
    
    func testSendWithUnparseableResults() async throws {
        let req = Request(method: .get, baseURL: "https://example.com/", endpoint: "ep")
        let reqURL = req.urlRequest()!.url!
        
        let respBody = """
        this is not JSON
        """.data(using: .utf8)
        
        MockURLProtocol.requestHandler = { request in
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respBody, resp, nil)
        }
        
        do {
            let _: TouchEvent = try await req.send()
            XCTFail()
        } catch let error as DisruptiveError {
            XCTAssertEqual(error.type, .unknownError)
        } catch {
            XCTFail()
        }
    }
    
    func testCheckResponseWithError() {
        let err = Request.checkResponseForErrors(forRequestURL: "", response: nil, data: nil, error: URLError(.networkConnectionLost))
        XCTAssertEqual(err?.type, .serverUnavailable)
    }
    
    func testCheckResponseWithoutHTTPResponse() {
        let err = Request.checkResponseForErrors(forRequestURL: "", response: URLResponse(), data: nil, error: nil)
        XCTAssertEqual(err?.type, .unknownError)
    }
    
    func testCheckResponseWithVariousInvalidStatusCodes() {
        func assertError(is expected: InternalError.ErrorType?, forStatusCode code: Int) {
            let returned = Request.checkResponseForErrors(
                forRequestURL : "",
                response      : HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: code, httpVersion: "2.0", headerFields: nil),
                data          : nil,
                error         : nil
            )
            XCTAssertEqual(expected, returned?.type)
        }
        
        assertError(is: nil,                             forStatusCode: 200)
        assertError(is: .badRequest,                     forStatusCode: 400)
        assertError(is: .unauthorized,                   forStatusCode: 401)
        assertError(is: .unknownError,                   forStatusCode: 402)
        assertError(is: .forbidden,                      forStatusCode: 403)
        assertError(is: .notFound,                       forStatusCode: 404)
        assertError(is: .conflict,                       forStatusCode: 409)
        assertError(is: .internalServerError,            forStatusCode: 500)
        assertError(is: .serviceUnavailable,             forStatusCode: 503)
        assertError(is: .gatewayTimeout,                 forStatusCode: 504)
        assertError(is: .tooManyRequests(retryAfter: 5), forStatusCode: 429)
    }
    
    func testCheckResponseWithErrorMessagePayload() {
        let data = """
        {
            "error": "There was an error",
            "code": 404,
            "help": "https://d21s.com/help"
        }
        """.data(using: .utf8)!
        let err = Request.checkResponseForErrors(
            forRequestURL : "",
            response      : HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 404, httpVersion: "2.0", headerFields: nil),
            data          : data,
            error         : nil
        )
        XCTAssertEqual(err?.type, .notFound)
    }
    
    func testParsePayloadWithNilPayload() {
        let str: String? = Request.parsePayload(nil, decoder: JSONDecoder())
        XCTAssertNil(str)
    }
    
    func testParsePayloadWithUndecodablePayload() {
        let str: String? = Request.parsePayload("5".data(using: .utf8)!, decoder: JSONDecoder())
        XCTAssertNil(str)
    }
    
    func testParsePayloadWithValidPayload() {
        let body = """
        {
            "updateTime": "\(Date().iso8601String())"
        }
        """.data(using: .utf8)!
        let event: TouchEvent? = Request.parsePayload(body, decoder: JSONDecoder())
        XCTAssertNotNil(event)
    }
    
    func testSendRequestSinglePage() async throws {
        let firstResponse = """
        {
            "events": [
                {
                    "updateTime": "\(Date().iso8601String())"
                }
            ],
            "nextPageToken": "token"
        }
        """.data(using: .utf8)!
        
        let secondResponse = """
        {
            "events": [
                {
                    "updateTime": "\(Date().iso8601String())"
                }
            ],
            "nextPageToken": ""
        }
        """.data(using: .utf8)!
        
        let req = Request(method: .get, baseURL: "http://example.com", endpoint: "")
        let reqURL = URL(string: req.baseURL)!
        
        var count = 0
                
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for         : request,
                method      : "GET",
                queryParams : count == 0 ? ["page_size": ["20"]] : ["page_size": ["30"], "page_token": ["token"]],
                url         : reqURL
            )
            
            defer { count += 1 }
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            if count == 0 {
                return (firstResponse, resp, nil)
            } else {
                return (secondResponse, resp, nil)
            }
        }
        
        let page1: PagedResult<TouchEvent> = try await req.send(pageSize: 20, pageToken: nil, pagingKey: "events")
        XCTAssertEqual(page1.nextPageToken, "token")
        XCTAssertEqual(page1.results.count, 1)
        
        let page2: PagedResult<TouchEvent> = try await req.send(pageSize: 30, pageToken: "token", pagingKey: "events")
        XCTAssertNil(page2.nextPageToken)
        XCTAssertEqual(page2.results.count, 1)
    }
    
    func testSendRequestAllPages() async throws {
        let firstResponse = """
        {
            "events": [
                {
                    "updateTime": "\(Date().iso8601String())"
                }
            ],
            "nextPageToken": "token"
        }
        """.data(using: .utf8)!
        
        let secondResponse = """
        {
            "events": [
                {
                    "updateTime": "\(Date().iso8601String())"
                }
            ],
            "nextPageToken": ""
        }
        """.data(using: .utf8)!
        
        let req = Request(method: .get, baseURL: "http://example.com", endpoint: "")
        let reqURL = URL(string: req.baseURL)!
        
        var count = 0
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for         : request,
                method      : "GET",
                queryParams : count == 0 ? [:] : ["page_token": ["token"]],
                url         : reqURL
            )
            
            defer {
                count += 1
            }
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            if count == 0 {
                return (firstResponse, resp, nil)
            } else {
                return (secondResponse, resp, nil)
            }
        }
        
        let events: [TouchEvent] = try await req.send(pagingKey: "events")
        XCTAssertEqual(events.count, 2)
    }
}
