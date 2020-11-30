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
 
 This type is only useful when implementing a type that conforms to `AuthProvider`,
 and does not need to be accessed or created in any other circumstances.
 */
public struct Auth {
    /// The current token to use for authentication. This `String` needs to
    /// be prefixed with the authentication scheme. Eg: "Basic ..." or "Bearer ..."
    public let token: String
    
    /// The expiration date of the `token`.
    public let expirationDate: Date
    
    /// Creates a new `Auth` instance
    public init(token: String, expirationDate: Date) {
        self.token = token
        self.expirationDate = expirationDate
    }
}

/**
 Defines the interface required to authenticate the `Disruptive` struct.
 
 Any conforming types needs a mechanism to aquire an access token that
 can be used to authenticate against the Disruptive Technologies' REST API.
 */
public protocol AuthProvider {
    
    /// The authentication data (token, and expiration date). This should be set by
    /// a conforming type after a call to `refreshAccessToken()`.
    var auth: Auth? { get }
    
    /// Indicates whether the auth provider should automatically attempt to
    /// refresh the access token if the local one is expired, or if no local access token is available.
    /// This is intended to prevent any accidental reauthentications being made
    /// after the client has logged out.
    var shouldAutoRefreshAccessToken: Bool { get }
    
    /// The completion closure type used by the auth functions
    typealias AuthHandler = (Result<Void, DisruptiveError>) -> ()
    
    /// A conforming type should call `refreshAccessToken()` to get an initial access token,
    /// and if successful, set `shouldAutoRefreshAccessToken` to `true`.
    func login(completion: @escaping AuthHandler)
    
    /// A conforming type should clear out any state that was created while logging in,
    /// including setting `auth` to `nil` and `shouldAutoRefreshAccessToken`
    /// to `false`.
    func logout(completion: @escaping AuthHandler)
    
    /// A conforming type should use a mechanism to aquire an access token than
    /// can be used to authenticate against the Disruptive Technologies' REST API.
    /// Once that token has been aquired, it should be stored in the `auth` property
    /// along with a relevant expiration date.
    ///
    /// This will be called automatically when necessary as long as `shouldAutoRefreshAccessToken`
    /// is set to `true`.
    func refreshAccessToken(completion: @escaping AuthHandler)
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
    
    /// Will check things in the following order:
    /// * If the auth provider is logged out, return a `loggedOut` error
    /// * If there is a local auth token that is not expired (or less than a minute away from expiring), return it
    /// * Attempt to refresh the auth token (and store it in `auth`). If successful, return the new token, otherwise return an error.
    func getActiveAccessToken(completion: @escaping (Result<String, DisruptiveError>) -> ()) {
        if shouldAutoRefreshAccessToken == false {
            // We should no longer be logged in. Just return the `.loggedOut` error code
            DTLog("The `AuthProvider` is not logged in. Call `login()` on the `AuthProvider` to log back in.")
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
                        DTLog("The auth provider authenticated successfully, but unexpectedly there was not a non-expired local access token available.", isError: true)
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
 
 A `BasicAuthAuthenticator` is authenticated by default, so there is no need to call `login()`.
 However if you'd like the authenticator to no longer be authenticated, you can call `logout()`,
 and then `login()` if you want it to be authenticated again.
 
 See [AuthProvider](../AuthProvider) for more details about the properties
 and methods.
 
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
    
    /// The authentication details.
    private(set) public var auth: Auth?
    
    /// A `BasicAuthAuthenticator` will default to automatically get a fresh access token.
    /// This will be switched on and off when `logout()` and `login()` is called.
    private(set) public var shouldAutoRefreshAccessToken = true
    
    /**
     Initializes a `BasicAuthAuthenticator` using a `ServiceAccount`.
     
     - Parameter account: The `ServiceAccount` to use for authentication. It can be created in [DT Studio](https://studio.disruptive-technologies.com) by clicking the `Service Account` tab under `API Integrations` in the side menu.
     */
    public init(account: ServiceAccount) {
        self.account = account
    }
    
    /// Refreshes the access token, stores it in the `auth` property, and sets
    /// `shouldAutoRefreshAccessToken` to `true`.
    public func login(completion: @escaping AuthHandler) {
        refreshAccessToken { [weak self] result in
            if case .success = result {
                self?.shouldAutoRefreshAccessToken = true
            }
            completion(result)
        }
    }
    
    /// Logs out the auth provider by setting `auth` to `nil` and `shouldAutoRefreshAccessToken`
    /// to `false`. Call `login()` to log the auth provider back in again.
    public func logout(completion: @escaping AuthHandler) {
        auth = nil
        shouldAutoRefreshAccessToken = false
        completion(.success(()))
    }
    
    /// Used internally to create a new access token from the service account passed in to the initializer.
    /// This access token is stored in the `auth` property along with an expiration date in the `.distantFuture`.
    public func refreshAccessToken(completion: @escaping AuthHandler) {
        auth = Auth(
            token: "Basic " + "\(account.key):\(account.secret)".data(using: .utf8)!.base64EncodedString(),
            expirationDate: .distantFuture
        )
        completion(.success(()))
    }
}

/**
 An `AuthProvider` that logs in a service account using OAuth2. This is a more
 secure flow than the basic auth counter-part, and is the recommended way to authenticate
 a service account in a production environment.
 
 An `OAuth2Authenticator` is authenticated by default, so there is no need to call `login()`.
 However if you'd like the authenticator to no longer be authenticated, you can call `logout()`,
 and then `login()` if you want it to be authenticated again.
 
 See [AuthProvider](../AuthProvider) for more details about the properties
 and methods.
 
 See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360011534099-Authentication) for details about OAuth2 authentication using a Service Account.
 
 Example:
 ```
 let serviceAccount = ServiceAccount(email: "<EMAIL>", key: "<KEY_ID>", secret: "<SECRET>")
 let authenticator = OAuth2Authenticator(account: serviceAccount)
 let disruptive = Disruptive(authProvider: authenticator)
 ```
 */
public class OAuth2Authenticator: AuthProvider {

    /// The service account used to authenticate against the Disruptive Technologies' REST API.
    public let account : ServiceAccount
    
    /// The authentication endpoint to fetch the access token from.
    public let authURL: String

    /// The authentication details.
    private(set) public var auth: Auth?
    
    /// An `OAuth2Authenticator` will default to automatically get a fresh access token.
    /// This will be switched on and off when `login()` and `logout()` is called respectively.
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
    
    /// Refreshes the access token, stores it in the `auth` property, and sets
    /// `shouldAutoRefreshAccessToken` to `true`.
    public func login(completion: @escaping AuthHandler) {
        refreshAccessToken { [weak self] result in
            self?.shouldAutoRefreshAccessToken = true
            completion(result)
        }
    }
    
    /// Logs out the auth provider by setting `auth` to `nil` and `shouldAutoRefreshAccessToken`
    /// to `false`. Call `login()` to log the auth provider back in again.
    public func logout(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
        auth = nil
        shouldAutoRefreshAccessToken = false
        completion(.success(()))
    }
    
    /// Used internally to create a JWT from the service account passed in to the initializer, which is then exchanged
    /// with an access token from the authentication endpoint. This access token is stored in the `auth` property
    /// along with the received expiration date.
    ///
    /// This flow is described in more detail on the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360011534099-Authentication).
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
