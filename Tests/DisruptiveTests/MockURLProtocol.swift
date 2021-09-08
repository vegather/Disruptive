//
//  MockURLProtocol.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 21/11/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

// Based on the following blog-posts:
// - https://www.hackingwithswift.com/articles/153/how-to-test-ios-networking-code-the-easy-way
// - https://medium.com/@dhawaldawar/how-to-mock-urlsession-using-urlprotocol-8b74f389a67a

class MockURLProtocol: URLProtocol {
    
    static var requestHandler: ((URLRequest) throws -> (Data?, HTTPURLResponse?, Error?))?
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol.requestHandler is not set")
        }
        
        do {
            let (data, response, error) = try handler(request)
            
            if let error = error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            if let response = response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
}
