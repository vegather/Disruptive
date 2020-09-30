//
//  Authentication.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 20/09/2020.
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
    func logout(completion: @escaping (Result<Void, DisruptiveError>) -> ())
}

internal extension AuthProvider {
    /// Returns the auth token if the auth token is non-nil, AND
    /// there's an expiration date that is further away than a minute.
    /// Otherwise returns nil.
    private func getAuthToken() -> String? {
        if let authToken = authToken, let expirationDate = expirationDate,
           expirationDate.timeIntervalSinceNow > 60
        {
            return authToken
        } else {
            return nil
        }
    }
    
    /// If the auth provider is already authenticated, and the expiration date is far enough
    /// in the future, this will succeed with the auth providers auth token.
    /// If the auth provider is not authenticated, or the token is too close to expiring, this will
    /// re-authenticate the auth provider and return the new auth token.
    /// If the re-authentication fails, this will result in an error.
    func getNonExpiredAuthToken(completion: @escaping (Result<String, DisruptiveError>) -> ()) {
        if let authToken = getAuthToken() {
            // There already exists a non-expired auth token
            completion(.success(authToken))
        } else {
            // The auth provider is either not authenticated, or the auth
            // token too close to getting expired. Will re-authenticate the auth provider
            DTLog("Authenticating the auth provider...")
            authenticate { result in
                switch result {
                case .success():
                    if let authToken = getAuthToken() {
                        DTLog("Authentication successful")
                        completion(.success(authToken))
                    } else {
                        DTLog("The auth provider authenticated successfully, but unexpectedly there was not a non-expired auth token available. Auth provider: \(self)", isError: true)
                        completion(.failure(.unknownError))
                    }
                case .failure(let e):
                    DTLog("Failed to authenticate the auth provider with error: \(e)", isError: true)
                    completion(.failure(e))
                }
            }
        }
    }
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
    
    public func logout(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
        completion(.success(()))
    }
}

public class JWTAuthServiceAccount: AuthProvider {

    private let account : ServiceAccount

    private(set) public var authToken: String?
    private(set) public var expirationDate: Date?
    
    let authURL: String

    public init(authURL: String, account: ServiceAccount) {
        self.authURL = authURL
        self.account = account
    }
    
    public func authenticate(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
        guard let authJWT = JWT.serviceAccount(authURL: authURL, account: account) else {
            DTLog("Failed to create a JWT from service account: \(account)", isError: true)
            completion(.failure(.unknownError))
            return
        }
        
        let header = HTTPHeader(
            field: "Content-Type",
            value: "application/x-www-form-urlencoded"
        )
        let body =  formURLEncodedBody(keysAndValues: [
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion" : authJWT
        ])!
        
        do {
            let request = try Request(
                method: .post,
                baseURL: authURL,
                endpoint: "",
                headers: [header],
                body: body
            )
            request.send { (result: Result<AccessTokenResponse, DisruptiveError>) in
                switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            self.authToken = "Bearer \(response.accessToken)"
                            self.expirationDate = Date(timeIntervalSinceNow: TimeInterval(response.expiresIn))
                            completion(.success(()))
                        }
                    case .failure(let e):
                        DispatchQueue.main.async {
                            completion(.failure(e))
                        }
                }
            }
        } catch {
            DTLog("Failed to encode body: \(body). Error: \(error)", isError: true)
            completion(.failure(.unknownError))
            return
        }
    }
    
    public func logout(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
        authToken = nil
        expirationDate = nil
        completion(.success(()))
    }

    private struct AccessTokenResponse: Codable {
        let accessToken: String
        let tokenType: String
        let expiresIn: Int
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType   = "token_type"
            case expiresIn   = "expires_in"
        }
    }
}
