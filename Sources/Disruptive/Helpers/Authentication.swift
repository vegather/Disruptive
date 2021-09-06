//
//  Authentication.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 20/09/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

public extension Disruptive {
    
    /**
     Provides mechanisms to authenticate the Disruptive Client
     */
    struct Auth {
        
        /**
         Creates an `Authenticator` that authenticates a Service Account against the
         Disruptive REST API.
         
         Example:
         ```
         Disruptive.auth = Disruptive.Auth.serviceAccount(email: <EMAIL>, keyID: <KEY_ID>, secret: <SECRET>)
         ```
         */
        static func serviceAccount(
            email   : String,
            keyID   : String,
            secret  : String,
            authURL : String = Disruptive.DefaultURLs.oauthTokenEndpoint
        ) -> Authenticator {
            let credentials = OAuth2Authenticator.Credentials(keyID: keyID, issuer: email, secret: secret)
            return OAuth2Authenticator(credentials: credentials, authURL: authURL)
        }
    }
}

/**
 Encapsulates authentication details like access token and expiration date.
 
 This type is only useful when implementing a type that conforms to `Authenticator`,
 and does not need to be accessed or created in any other circumstances.
 */
public struct AuthToken {
    /// The current token to use for authentication. This `String` needs to
    /// be prefixed with the authentication scheme. Eg: "Bearer ..."
    public let token: String
    
    /// The expiration date of the `token`.
    public let expirationDate: Date
}

/**
 Defines the interface required to authenticate the `Disruptive` struct.
 
 Any conforming types needs a mechanism to acquire an access token that
 can be used to authenticate against the Disruptive Technologies' REST API.
 */
public protocol Authenticator {
    
    /// The authentication data (token, and expiration date). This should be set by
    /// a conforming type after a call to `refreshAccessToken()`.
    var authToken: AuthToken? { get }
    
    /// Indicates whether the authenticator should automatically attempt to
    /// refresh the access token if the local one is expired, or if no local access token is available.
    /// This is intended to prevent any accidental re-authentications being made
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
    
    /// A conforming type should use a mechanism to acquire an access token than
    /// can be used to authenticate against the Disruptive Technologies' REST API.
    /// Once that token has been acquired, it should be stored in the `auth` property
    /// along with a relevant expiration date.
    ///
    /// This will be called automatically when necessary as long as `shouldAutoRefreshAccessToken`
    /// is set to `true`.
    func refreshAccessToken(completion: @escaping AuthHandler)
}

internal extension Authenticator {
    
    /// Returns the auth token if the auth token is non-nil, AND
    /// there's an expiration date that is further away than a minute.
    /// Otherwise returns nil.
    private func getLocalAuthToken() -> String? {
        if let auth = authToken, auth.expirationDate.timeIntervalSinceNow > 60 {
            return auth.token
        } else {
            return nil
        }
    }
    
    /// Will check things in the following order:
    /// * If the authenticator is logged out, return a `loggedOut` error.
    /// * If there is a local auth token that is not expired (or more than a minute away from expiring), return it.
    /// * Attempt to refresh the auth token (and store it in `auth`). If successful, return the new token, otherwise return an error.
    func getActiveAccessToken(completion: @escaping (Result<String, DisruptiveError>) -> ()) {
        if shouldAutoRefreshAccessToken == false {
            // We should no longer be logged in. Just return the `.loggedOut` error code
            Disruptive.log("The `Authenticator` is not logged in. Call `login()` on the `Authenticator` to log back in.", level: .error)
            completion(.failure(.loggedOut))
        } else if let authToken = getLocalAuthToken() {
            // There already exists a non-expired auth token
            completion(.success(authToken))
        } else {
            // The authenticator is either not authenticated, or the auth
            // token too close to getting expired. Will re-authenticate the authenticator
            Disruptive.log("Authenticating the authenticator...")
            refreshAccessToken { result in
                switch result {
                case .success():
                    if let authToken = getLocalAuthToken() {
                        Disruptive.log("Authentication successful")
                        completion(.success(authToken))
                    } else {
                        Disruptive.log("The authenticator authenticated successfully, but unexpectedly there was not a non-expired local access token available.", level: .error)
                        completion(.failure(.unknownError))
                    }
                case .failure(let e):
                    Disruptive.log("Failed to authenticate the authenticator with error: \(e)", level: .error)
                    completion(.failure(e))
                }
            }
        }
    }
}


/**
 An `Authenticator` that logs in a service account using OAuth2 with a JWT Bearer Token as an authorization grant.
 
 An `OAuth2Authenticator` is authenticated by default, so there is no need to call `login()`.
 However if you'd like the authenticator to no longer be authenticated, you can call `logout()`,
 and then `login()` if you want it to be authenticated again.
 
 See the [Developer Website](https://developer.disruptive-technologies.com/docs/authentication/oauth2) for details about OAuth2 authentication using a Service Account.
 */
internal class OAuth2Authenticator: Authenticator {

    /// The authentication endpoint to fetch the access token from.
    let authURL: String

    /// The authentication details.
    var authToken: AuthToken?
    
    /// An `OAuth2Authenticator` will default to automatically get a fresh access token.
    /// This will be switched on and off when `login()` and `logout()` is called respectively.
    var shouldAutoRefreshAccessToken = true
    
    /// The credentials used to authenticate against the Disruptive Technologies' REST API.
    private let credentials: Credentials

    struct Credentials: Codable {
        public let keyID  : String
        public let issuer : String
        public let secret : String
    }
    
    
    /**
     Initializes an `OAuth2Authenticator` using a set of `Credentials`.
     
     - Parameter credentials: The `Credentials` to use for authentication. It can be created in [DT Studio](https://studio.disruptive-technologies.com) by clicking the `Service Account` tab under `API Integrations` in the side menu.
     - Parameter authURL: Used to specify the endpoint to exchange a JWT for an access token.
     */
    init(credentials: Credentials, authURL: String) {
        self.authURL = authURL
        self.credentials = credentials
    }
    
    /// Refreshes the access token, stores it in the `auth` property, and sets
    /// `shouldAutoRefreshAccessToken` to `true`.
    func login(completion: @escaping AuthHandler) {
        refreshAccessToken { [weak self] result in
            self?.shouldAutoRefreshAccessToken = true
            completion(result)
        }
    }
    
    /// Logs out the authenticator by setting `auth` to `nil` and `shouldAutoRefreshAccessToken`
    /// to `false`. Call `login()` to log the authenticator back in again.
    func logout(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
        authToken = nil
        shouldAutoRefreshAccessToken = false
        completion(.success(()))
    }
    
    /// Used internally to create a JWT from the service account passed in to the initializer, which is then exchanged
    /// with an access token from the authentication endpoint. This access token is stored in the `auth` property
    /// along with the received expiration date.
    ///
    /// This flow is described in more detail on the [Developer Website](https://developer.disruptive-technologies.com/docs/authentication/oauth2).
    func refreshAccessToken(completion: @escaping (Result<Void, DisruptiveError>) -> ()) {
        guard let authJWT = JWT.serviceAccount(
            authURL : authURL,
            keyID   : credentials.keyID,
            issuer  : credentials.issuer,
            secret  : credentials.secret
        ) else {
            Disruptive.log("Failed to create a JWT from service account credentials: \(credentials)", level: .error)
            completion(.failure(.unknownError))
            return
        }
        
        let header = HTTPHeader(
            field: "Content-Type",
            value: "application/x-www-form-urlencoded"
        )
        let body = formURLEncodedBody(keysAndValues: [
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
            request.internalSend { [weak self] (result: Result<AccessTokenResponse, DisruptiveError>) in
                switch result {
                    case .success(let response):
                        Disruptive.log("OAuth2 authentication successful")
                        DispatchQueue.main.async {
                            self?.authToken = AuthToken(
                                token: "Bearer \(response.accessToken)",
                                expirationDate: Date(timeIntervalSinceNow: TimeInterval(response.expiresIn))
                            )
                            completion(.success(()))
                        }
                    case .failure(let e):
                        Disruptive.log("OAuth2 authentication failed with error: \(e)", level: .error)
                        DispatchQueue.main.async {
                            completion(.failure(e))
                        }
                }
            }
        } catch {
            Disruptive.log("Failed to encode body: \(body). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? .unknownError))
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
