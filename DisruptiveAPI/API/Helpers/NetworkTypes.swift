//
//  Types.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation
import SwiftJWT
import SwiftUI

class AccessToken {
    
    static let shared = AccessToken()
    
    private var token: String?
    
    private init() {}
    
    func setToken(_ newToken: String) {
        print("Token was set")
        print(newToken)
        token = newToken
    }
    
    func getToken() -> String? {
        print("Asked for token")
        return token
    }
    func getAuth() -> String? {
        print("Asked for auth")
        if let token = self.token {
            print("Asked for auth")
            print(token)
            return "Bearer \(token)"
        } else {
            return nil
        }
    }
}

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
        if AccessToken.shared.getToken() == nil {
            print("Access token was not set")
            let authClaims = AuthClaims(iss: email,
                                        iat: Date(),
                                        exp: Date(timeIntervalSinceNow: 3600),
                                        aud: Disruptive.authURL)
            let myHeader = Header(kid: key)
            var myJWT = JWT(header: myHeader, claims: authClaims)
            let jwtSigner = JWTSigner.hs256(key: secret.data(using: .utf8)!)
            var signedJWT = "knut"
            do {
                signedJWT = try myJWT.sign(using: jwtSigner)
                print(signedJWT)
            } catch {
                print("Unable to sign JWT")
            }
            
        // Construct the URL
            
            guard var urlComponents = URLComponents(string: Disruptive.authURL) else {return "mordi"}
            urlComponents.queryItems = [URLQueryItem(name: "grant_type", value:"urn:ietf:params:oauth:grant-type:jwt-bearer"),
                                        URLQueryItem(name: "assertion", value: signedJWT)]
            guard let url = urlComponents.url(relativeTo: nil) else { return "mordi" }
            var req = URLRequest(url: url)
            req.httpMethod = HTTPMethod.post.rawValue
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = urlComponents.query?.data(using: .utf8)

            var result:AccessTokenResponse!
            //print(req)
            URLSession.shared.dataTask(with: req) { (data, response, error) in
                let decoder = JSONDecoder()
                do {
                    result = try decoder.decode(AccessTokenResponse.self, from: data!)
                } catch {
                    if let str = String(data:data!, encoding: .utf8) {
                        print(str)
                    }
                    return
                }
                print("Setting access token")
                AccessToken.shared.setToken(result.access_token)
                //print(response)
                //print(error)
            }.resume()
            return ""
        } else {
            print("Returning access token")
            return "Bearer \(AccessToken.shared.getToken() ?? "")"
        }
    }
}

public struct AccessTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

internal struct AuthClaims: Claims {
    let iss: String
    let iat: Date
    let exp: Date
    let aud: String
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
        
        // Add the headers
        headers.forEach { req.addValue($0.value, forHTTPHeaderField: $0.field) }
        
        // Add auth
        req.setValue(authorization, forHTTPHeaderField: "Authorization")
        print(req)
        print(authorization)
        return req
    }
}
