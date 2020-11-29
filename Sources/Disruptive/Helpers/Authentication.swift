//
//  Authentication.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 20/09/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 A ServiceAccount is used to authenticate against the Disruptive Technologies API.
 It can be created in [DT Studio](https://studio.disruptive-technologies.com) by clicking
 the `Service Account` tab under `API Integrations` in the side menu.
 */
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

/**
 Encapsulates authentication details like access token and expiration date.
 
 This type is only useful to implement an `AuthProvider`, and does not
 need to be accessed or created in any other circumstances.
 */
public struct Auth {
    /// The current token to use for authentication. This `String` needs to
    /// be prefixed with the authentication scheme. Eg: "Basic ..." or "Bearer ..."
    public let token: String
    
    /// The expiration date of the `authToken`. If there is less than a minute until
    /// expiration, and a request is made on the network, the `authenticate` function
    /// will be called first.
    public let expirationDate: Date
    
    /// Creates a new `Auth` instance
    public init(token: String, expirationDate: Date) {
        self.token = token
        self.expirationDate = expirationDate
    }
}

/**
 Defines the interface required to authenticate the `Disruptive` struct.
 */
public protocol AuthProvider {
    
    /// The authentication data (token, and expiration date)
    var auth: Auth? { get }
    
    /// Indicates whether the `authProvider` should be logged in or not.
    /// This is intended to prevent any accidental reauthentications being made
    /// after the client has logged out.
    var shouldAutoRefreshAccessToken: Bool { get }
    
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
    private func getLocalAuthToken() -> String? {
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
    func getActiveAccessToken(completion: @escaping (Result<String, DisruptiveError>) -> ()) {
        if shouldAutoRefreshAccessToken == false {
            // We should no longer be logged in. Just return the `.loggedOut` error code
            DTLog("The `authProvider` is not logged in. Call `login()` on the `authProvider` to log back in.")
            completion(.failure(.loggedOut))
        } else if let authToken = getLocalAuthToken() {
            // There already exists a non-expired auth token
            completion(.success(authToken))
        } else {
            // The auth provider is either not authenticated, or the auth
            // token too close to getting expired. Will reauthenticate the auth provider
            DTLog("Authenticating the auth provider...")
            refreshAccessToken { result in
                switch result {
                case .success():
                    if let authToken = getLocalAuthToken() {
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

/**
 An `AuthProvider` that logs in a service account using basic auth.
 
 See [AuthProvider](../AuthProvider) for more details about the properties
 and methods. Only the initializer (`init(account:)`) is relevant externally.
 
 __Note__: This should only be used for development/testing. For production use-cases the [`OAuth2Authenticator`](../OAuth2Authenticator) should be used.
 
 Example:
 ```
 let serviceAccount = ServiceAccount(email: "<EMAIL>", key: "<KEY_ID>", secret: "<SECRET>")
 let authenticator = BasicAuthAuthenticater(account: serviceAccount)
 let disruptive = Disruptive(authProvider: authenticator)
 ```
 */
public class BasicAuthAuthenticator: AuthProvider {
    public let account : ServiceAccount
    
    /// The authentication details. Will always be set
    private(set) public var auth: Auth?
    
    /// A basic authenticator is always logged in
    private(set) public var shouldAutoRefreshAccessToken = true
    
    /**
     Initializes a `BasicAuthAuthenticator` using a `ServiceAccount`
     
     - Parameter account: The `ServiceAccount` to use for authentication. It can be created in [DT Studio](https://studio.disruptive-technologies.com) by clicking the `Service Account` tab under `API Integrations` in the side menu.
     */
    public init(account: ServiceAccount) {
        self.account = account
    }
    
    public func login(completion: @escaping AuthHandler) {
        refreshAccessToken { [weak self] result in
            if case .success = result {
                self?.shouldAutoRefreshAccessToken = true
            }
            completion(result)
        }
    }
    
    public func logout(completion: @escaping AuthHandler) {
        auth = nil
        shouldAutoRefreshAccessToken = false
        completion(.success(()))
    }
    
    public func refreshAccessToken(completion: @escaping AuthHandler) {
        auth = Auth(
            token: "Basic " + "\(account.key):\(account.secret)".data(using: .utf8)!.base64EncodedString(),
            expirationDate: .distantFuture
        )
        completion(.success(()))
    }
}

/**
 An `AuthProvider` that logs in a service account using OAuth2.
 
 See [AuthProvider](../AuthProvider) for more details about the properties
 and methods. Only the initializer (`init(account:)`) is relevant externally.
 
 This is a more secure flow than the basic auth counter-part, and is the
 recommended way to authenticate a service account in a production environment.
 
 Example:
 ```
 let serviceAccount = ServiceAccount(email: "<EMAIL>", key: "<KEY_ID>", secret: "<SECRET>")
 let authenticator = OAuth2Authenticator(account: serviceAccount)
 let disruptive = Disruptive(authProvider: authenticator)
 ```
 */
public class OAuth2Authenticator: AuthProvider {

    public let account : ServiceAccount
    public let authURL: String

    private(set) public var auth: Auth?
    
    private(set) public var shouldAutoRefreshAccessToken = true

    
    
    /**
     Initializes an `OAuth2Authenticator` using a `ServiceAccount`
     
     - Parameter account: The `ServiceAccount` to use for authentication. It can be created in [DT Studio](https://studio.disruptive-technologies.com) by clicking the `Service Account` tab under `API Integrations` in the side menu.
     - Parameter authURL: Optional parameter. Used to specify the endpoint to exchange a JWT for an access token. The default value is `Disruptive.defaultAuthURL`
     */
    public init(account: ServiceAccount, authURL: String = Disruptive.defaultAuthURL) {
        self.authURL = authURL
        self.account = account
    }
    
    // Fetches the auth token using the `reauthenticate` function, and
    // sets `shouldBeLoggedIn` to `true` when done.
    public func login(completion: @escaping AuthHandler) {
        refreshAccessToken { [weak self] result in
            self?.shouldAutoRefreshAccessToken = true
            completion(result)
        }
    }
    
    public func logout(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
        auth = nil
        shouldAutoRefreshAccessToken = false
        completion(.success(()))
    }
    
    public func refreshAccessToken(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
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
                        DTLog("OAuth2 authentication successful")
                        DispatchQueue.main.async {
                            self?.auth = Auth(
                                token: "Bearer \(response.accessToken)",
                                expirationDate: Date(timeIntervalSinceNow: TimeInterval(response.expiresIn))
                            )
                            completion(.success(()))
                        }
                    case .failure(let e):
                        DTLog("OAuth2 authentication failed with error: \(e)")
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
