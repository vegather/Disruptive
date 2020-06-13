//
//  Types.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

public struct ServiceAccount: Codable {
    public let email  : String
    public let key    : String
    public let secret : String
    
    public init(email: String, key: String, secret: String) {
        self.email = email
        self.key = key
        self.secret = secret
    }
    
    internal func authorization() -> String {
        return "Basic " + "\(key):\(secret)".data(using: .utf8)!.base64EncodedString()
    }
}

internal enum HTTPMethod: String {
    case get    = "GET"
    case patch  = "PATCH"
    case post   = "POST"
    case delete = "DELETE"
}

internal struct HTTPHeader {
    let field: String
    let value: String
}
    
internal struct PagedResult<T: Decodable>: Decodable {
    let results: [T]
    let nextPageToken: String
}

internal struct PagedKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

internal struct Request {
    let method: HTTPMethod
    let endpoint: String
    let headers: [HTTPHeader]
    var params: [String: [String]]
    let body: Data?
    
    init(
        method: HTTPMethod,
        endpoint: String,
        headers: [HTTPHeader] = [],
        params: [String: [String]] = [:])
    {
        self.method = method
        self.endpoint = endpoint
        self.headers = headers
        self.params = params
        self.body = nil
    }
    
    init<Body: Encodable>(
        method: HTTPMethod,
        endpoint: String,
        headers: [HTTPHeader] = [],
        params: [String: [String]] = [:],
        body: Body) throws
    {
        self.body = try JSONEncoder().encode(body)
        self.method = method
        self.endpoint = endpoint
        self.headers = [HTTPHeader(field: "Content-Type", value: "application/json")] + headers
        self.params = params
    }
    
    func urlRequest(authorization: String) -> URLRequest? {
        
        // Construct the URL
        
        guard var urlComponents = URLComponents(string: Disruptive.baseURL + endpoint) else {
            return nil
        }
        urlComponents.queryItems = params.flatMap { paramName, paramValues in
            return paramValues.map { URLQueryItem(name: paramName, value: $0) }
        }
        guard let url = urlComponents.url(relativeTo: nil) else {
            return nil
        }
        
        // Create the request
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.httpBody = body
        
        // Add the headers
        headers.forEach { req.addValue($0.value, forHTTPHeaderField: $0.field) }
        
        // Add auth
        req.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        return req
    }
}
