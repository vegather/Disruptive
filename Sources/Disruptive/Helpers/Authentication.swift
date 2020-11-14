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

public struct Auth {
    /// The current token to use for authentication. This `String` needs to
    /// be prefixed with the authentication scheme. Eg: "Basic ..." or "Bearer ..."
    let token: String
    
    /// The expiration date of the `authToken`. If there is less than a minute until
    /// expiration, and a request is made on the network, the `authenticate` function
    /// will be called first.
    let expirationDate: Date
    
    public init(token: String, expirationDate: Date) {
        self.token = token
        self.expirationDate = expirationDate
    }
}

public protocol AuthProvider {
    
    /// The authentication data (token, and expiration date)
    var auth: Auth? { get }
    
    /// Indicates whether the `authProvider` should be logged in or not.
    /// This is intended to prevent any accidental reauthentications being made
    /// after the client has logged out.
    var shouldBeLoggedIn: Bool { get }
    
    /// The completion closure type used by the auth functions
    typealias AuthHandler = (Result<Void, DisruptiveError>) -> ()
    
    /// This will log the client in by calling the `reauthenticate()` function
    /// (which sets the `auth` property), and set `shouldBeLoggedIn` to `true`.
    func login(completion: @escaping AuthHandler)
    
    /// This will clear any local state related to logging in, including the `auth` property.
    /// It may or may not invoke a URL to log the user out in the default browser as well,
    /// depending on the implementation of the specific `AuthProvider`.
    func logout(completion: @escaping AuthHandler)
    
    /// This will be called internally when the auth token has expired, or is close
    /// to expiring.
    func reauthenticate(completion: @escaping AuthHandler)
}

internal extension AuthProvider {
    
    /// Returns the auth token if the auth token is non-nil, AND
    /// there's an expiration date that is further away than a minute.
    /// Otherwise returns nil.
    private func getAuthToken() -> String? {
        if let auth = auth, auth.expirationDate.timeIntervalSinceNow > 60 {
            return auth.token
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
        if shouldBeLoggedIn == false {
            // We should no longer be logged in. Just return the `.loggedOut` error code
            DTLog("The `authProvider` is not logged in. Call `login()` on the `authProvider` to log back in.")
            completion(.failure(.loggedOut))
        } else if let authToken = getAuthToken() {
            // There already exists a non-expired auth token
            completion(.success(authToken))
        } else {
            // The auth provider is either not authenticated, or the auth
            // token too close to getting expired. Will reauthenticate the auth provider
            DTLog("Authenticating the auth provider...")
            reauthenticate { result in
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
        
    public var auth: Auth? {
        return Auth(
            token: "Basic " + "\(account.key):\(account.secret)".data(using: .utf8)!.base64EncodedString(),
            expirationDate: .distantFuture
        )
    }
    
    // A basic auth provider is always logged in
    public var shouldBeLoggedIn: Bool { return true }
    
    public init(account: ServiceAccount) {
        self.account = account
    }
    
    public func reauthenticate(completion: @escaping AuthHandler) {
        completion(.success(()))
    }
    
    public func login(completion: @escaping AuthHandler) {
        completion(.success(()))
    }
    
    public func logout(completion: @escaping AuthHandler) {
        completion(.success(()))
    }
}

public class JWTAuthServiceAccount: AuthProvider {

    private let account : ServiceAccount

    private(set) public var auth: Auth?
    private(set) public var shouldBeLoggedIn = false
    
    let authURL: String

    public init(authURL: String, account: ServiceAccount) {
        self.authURL = authURL
        self.account = account
    }
    
    // Fetches the auth token using the `reauthenticate` function, and
    // sets `shouldBeLoggedIn` to `true` when done.
    public func login(completion: @escaping AuthHandler) {
        reauthenticate { [weak self] result in
            self?.shouldBeLoggedIn = true
            completion(result)
        }
    }
    
    public func logout(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
        auth = nil
        shouldBeLoggedIn = false
        completion(.success(()))
    }
    
    public func reauthenticate(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
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
            request.send { [weak self] (result: Result<AccessTokenResponse, DisruptiveError>) in
                switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            self?.auth = Auth(
                                token: "Bearer \(response.accessToken)",
                                expirationDate: Date(timeIntervalSinceNow: TimeInterval(response.expiresIn))
                            )
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
