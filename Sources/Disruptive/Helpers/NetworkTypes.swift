//
//  NetworkTypes.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
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
    
/// Used as an intermediary structure to decode paginated results.
/// If the received `nextPageToken` is an empty string, it will be replaced
/// with `nil` as this makes more sense as a sentinel value.
internal struct PagedResult<T: Decodable>: Decodable {
    let results: [T]
    let nextPageToken: String?
    
    private enum CodingKeys: String, CodingKey {
        case results
        case nextPageToken
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.results = try container.decode([T].self, forKey: .results)
        
        let nextString = try container.decode(String.self, forKey: .nextPageToken)
        if nextString.count == 0 {
            self.nextPageToken = nil
        } else {
            self.nextPageToken = nextString
        }
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
