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
}

public protocol AuthProvider {
    
    var authToken: String? { get }
    var expirationDate: Date? { get }
    
    func authenticate(completion: @escaping (Result<Void, DisruptiveError>) -> ())
}

public struct BasicAuthServiceAccount: AuthProvider {
    private let account : ServiceAccount
    
    public var authToken: String? {
        return "Basic " + "\(account.key):\(account.secret)".data(using: .utf8)!.base64EncodedString()
    }
    
    public var expirationDate: Date? { .distantFuture }
    
    public init(account: ServiceAccount) {
        self.account = account
    }
    
    public func authenticate(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
        completion(.success(()))
    }
}

public class JWTAuthServiceAccount: AuthProvider {

    private let account : ServiceAccount

    private(set) public var authToken: String?
    private(set) public var expirationDate: Date?

    public init(account: ServiceAccount) {
        self.account = account
    }
    
    public func authenticate(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
        DTLog("JWT authentication requested")
        guard let request = jwtRequest() else {
            DTLog("Failed to create authentication request from credentials")
            DispatchQueue.main.async {
                completion(.failure(.unknownError))
            }
            return
        }
        Disruptive.defaultSession.dataTask(with: request) { (data, response, error) in
            let decoder = JSONDecoder()
            guard let result: AccessTokenResponse = Disruptive.parsePayload(data, decoder: decoder) else {
                DispatchQueue.main.async {
                   DTLog("Failed to parse the response JSON from")
                   completion(.failure(.unknownError))
                }
                return
            }

            self.authToken = "Bearer \(result.access_token)"
            self.expirationDate = Date(timeIntervalSinceNow: 3600)
            
            DispatchQueue.main.async {
                completion(.success(()))
            }

        }.resume()
    }

    private struct AccessTokenResponse: Codable {
        let access_token: String
        let token_type: String
        let expires_in: Int
    }

    private func jwtRequest() -> URLRequest? {
        
        guard var urlComponents = URLComponents(string: Disruptive.authURL) else {
            return nil
        }
        guard let authJWT = JWT.serviceAccount(account: account) else {
            return nil
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "grant_type",
                                                 value:"urn:ietf:params:oauth:grant-type:jwt-bearer"),
                                    URLQueryItem(name: "assertion",
                                                 value: authJWT)]

        guard let url = urlComponents.url(relativeTo: nil) else {
            return nil
        }
        guard let query = urlComponents.query else {
            return nil
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = HTTPMethod.post.rawValue
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = query.data(using: .utf8)
        return req
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
