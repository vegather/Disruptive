//
//  TestUtils.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 21/11/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

extension InputStream {
    func readData(maxLength length: Int = 1024) -> Data {
        open()
        
        guard hasBytesAvailable else { return Data() }
        
        var buffer = [UInt8](repeating: 0, count: length)
        let result = self.read(&buffer, maxLength: buffer.count)
        if result < 0 {
            fatalError("Unexpected bytes read: \(result)")
        } else {
            return Data(buffer.prefix(result))
        }
    }
}

extension URLRequest {
    /// Extracts the query parameters as a dictionary from the requests URL queryItems
    func extractQueryParameters() -> [String: [String]] {
        guard let url = url else { return [:] }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return [:] }
        guard let queryItems = components.queryItems else { return [:] }
        
        var out = [String: [String]]()
        for item in queryItems {
            guard let value = item.value else { continue }
            
            if out.keys.contains(item.name) {
                out[item.name]?.append(value)
            } else {
                out[item.name] = [value]
            }
        }
        
        return out
    }
}

extension DisruptiveTests {
    func assertRequestParams(
        for request: URLRequest,
        authenticated: Bool,
        method: String,
        queryParams: [String: [String]],
        headers: [String: String],
        url: URL,
        body: Data?
    ) {
        // Validate HTTP method
        XCTAssertEqual(request.httpMethod, method)
        
        // Validate query parameters (with sorted values)
        XCTAssertEqual(
            request.extractQueryParameters().mapValues { $0.sorted() },
            queryParams                     .mapValues { $0.sorted() }
        )
        
        // Validate URL
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        components.queryItems = nil
        XCTAssertEqual(components.url, url)
        
        // Validate "Authorization" header
        if authenticated {
            XCTAssertNotNil(request.allHTTPHeaderFields?["Authorization"])
        } else {
            XCTAssertNil(request.allHTTPHeaderFields?["Authorization"])
        }
        
        // Validate other headers
        for (key, value) in headers {
            XCTAssertEqual(request.allHTTPHeaderFields?[key], value)
        }
        
        // Validate body
        if let body = body {
            assertJSONDatasAreEqual(a: body, b: request.httpBodyStream!.readData())
        }
    }
    
    func assertJSONDatasAreEqual(a: Data, b: Data) {
        let jsonA = try! JSONSerialization.jsonObject(with: a) as! JSONValue
        let jsonB = try! JSONSerialization.jsonObject(with: b) as! JSONValue
        XCTAssertTrue(jsonA.isEqual(to: jsonB), "\(jsonA) does not equal \(jsonB)")
    }
}


// The following is used to check for equality between JSON `Data` payloads
// Source: https://forums.swift.org/t/dynamic-equality-checking-and-equatable/24556/4
protocol JSONValue {
    func isEqual(to: JSONValue) -> Bool
}
extension JSONValue where Self: Equatable {
    func isEqual(to: JSONValue) -> Bool {
        guard let other = to as? Self else { return false }
        return self == other
    }
}
extension String       : JSONValue {}
extension Date         : JSONValue {}
extension Int          : JSONValue {}
extension Bool         : JSONValue {}
extension Double       : JSONValue {}
extension NSNull       : JSONValue {}
extension AnyHashable  : JSONValue {}
extension NSArray      : JSONValue {}
extension NSDictionary : JSONValue {}
extension Array: JSONValue where Element: JSONValue {
    func isEqual(to: JSONValue) -> Bool {
        guard let other = to as? Self, count == other.count else { return false }
        return (0..<count).allSatisfy { self[$0].isEqual(to: other[$0]) }
    }
}
extension Dictionary: JSONValue where Value: JSONValue {
    func isEqual(to: JSONValue) -> Bool {
        guard let other = to as? Self, count == other.count else { return false }
        return allSatisfy { (k, v) in other[k].map { v.isEqual(to: $0) } ?? false }
    }
}
