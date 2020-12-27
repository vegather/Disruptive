//
//  MockStreamURLProtocol.swift
//  
//
//  Created by Vegard Solheim Theriault on 27/12/2020.
//

import Foundation

class MockStreamURLProtocol: URLProtocol {
    
    typealias Callback = (data: Data?, response: HTTPURLResponse?, error: Error?)
    static var requestHandler: ((URLRequest) throws -> [Callback])? {
        didSet {
            // Resetting callbacks when the requestHandler is reset. Likely
            // due to a new test running.
            callbacks = nil
        }
    }
    
    // Allows keeping track of a queue of callbacks even if connections
    // gets lost, and new MockStreamURLProtocol instances is allocated.
    private static var callbacks: [Callback]?
    
    // Data races were not actually possible, but Thread Sanitizer indicated
    // that multiple threads were using the shared `callbacks` array.
    private static let callbacksQ = DispatchQueue(label: "callbacksQ")
    
    override func startLoading() {
        
        if Self.callbacks == nil {
            guard let handler = MockStreamURLProtocol.requestHandler else {
                fatalError("MockURLProtocol.requestHandler is not set")
            }
            
            Self.callbacksQ.sync {
                do {
                    Self.callbacks = try handler(request)
                } catch {
                    client?.urlProtocol(self, didFailWithError: error)
                }
            }
        }
        
        handleNextCallback()
    }
    
    private func handleNextCallback() {
        Self.callbacksQ.sync {
            guard let count = Self.callbacks?.count, count > 0 else { return }
            let callback = Self.callbacks!.removeFirst()
            
            if let error = callback.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            if let response = callback.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let data = callback.data {
                client?.urlProtocol(self, didLoad: data)
            }
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.handleNextCallback()
        }
    }
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}
}
