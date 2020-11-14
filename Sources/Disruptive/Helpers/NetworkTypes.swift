//
//  Types.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

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

/// Takes a dictionary of keys and values, and encodes it in a body format
/// appropriate for requests where the `Content-Type` header is set
/// to `application/x-www-form-urlencoded`.
internal func formURLEncodedBody(keysAndValues: [String: String]) -> Data? {
    var urlComponents = URLComponents()
    urlComponents.queryItems = keysAndValues.map { URLQueryItem(name: $0.key, value: $0.value) }
    return urlComponents.query?.data(using: .utf8)
}
