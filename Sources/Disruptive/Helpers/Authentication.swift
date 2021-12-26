//
//  Authentication.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 20/09/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 Provides mechanisms to authenticate the Disruptive Client
 */
public struct Auth {
    
    /**
     Creates an `Authenticator` that authenticates a Service Account against the
     Disruptive REST API using one of the Service Account's keys.
     
     The returned `Authenticator` will use OAuth2 in the background to authenticate
     the Service Account, and the access token will automatically be refreshed in
     the background. You can read more about that process on the
     [Developer Website](https://developer.disruptive-technologies.com/docs/authentication/oauth2).
     
     A Service Account and its keys can either be created using DT Studio under
     "API Integrations -> Service Accounts". Alternatively, if you already have
     a Service Account, a new one can be created through the API by calling
     `ServiceAccount.create(...)` and `ServiceAccount.createKey(...)`.
     
     Example:
     ```
     Config.authenticator = Auth.serviceAccount(
        email: <EMAIL>,
        keyID: <KEY_ID>,
        secret: <SECRET>
     )
     ```
     
     - Parameter email: The email address of the Service Account
     - Parameter keyID: The identifier of the Service Account key
     - Parameter secret: The secret of the Service Account key
     - Parameter authURL: An optional parameter that specifies the token endpoint URL to exchange a JWT for an access token
     
     - Returns: An object that implements the `Authenticator` protocol that can be set to `Config.authenticator`.
     */
    public static func serviceAccount(
        email   : String,
        keyID   : String,
        secret  : String,
        authURL : String = Config.DefaultURLs.oauthTokenEndpoint
    ) -> Authenticator {
        let credentials = OAuth2Authenticator.Credentials(keyID: keyID, issuer: email, secret: secret)
        return OAuth2Authenticator(credentials: credentials, authURL: authURL)
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
        
    /// A conforming type should call `refreshAccessToken()` to get an initial access token,
    /// and if successful, set `shouldAutoRefreshAccessToken` to `true`.
    func login() async throws
    
    /// A conforming type should clear out any state that was created while logging in,
    /// including setting `authToken` to `nil` and `shouldAutoRefreshAccessToken`
    /// to `false`.
    func logout() async throws
    
    /// A conforming type should use a mechanism to acquire an access token than
    /// can be used to authenticate against the Disruptive Technologies' REST API.
    /// Once that token has been acquired, it should be stored in the `authToken` property
    /// along with a relevant expiration date.
    ///
    /// This will be called automatically when necessary as long as `shouldAutoRefreshAccessToken`
    /// is set to `true`.
    func refreshAccessToken() async throws
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
    /// * Attempt to refresh the auth token (and store it in `authToken`). If successful, return the new token, otherwise return an error.
    func getActiveAccessToken() async throws -> String {
        if shouldAutoRefreshAccessToken == false {
            Logger.error("The `Authenticator` is not logged in. Call `login()` on the `Authenticator` to log back in.")
            
            // We should no longer be logged in. Just return the `.loggedOut` error code
            throw DisruptiveError(
                type: .loggedOut,
                message: "Not authenticated",
                helpLink: nil
            )
        } else if let authToken = getLocalAuthToken() {
            // There already exists a non-expired auth token
            return authToken
        } else {
            // The authenticator is either not authenticated, or the auth
            // token too close to getting expired. Will re-authenticate the authenticator
            Logger.info("Authenticating the authenticator...")
            
            
            do {
                try await refreshAccessToken()
            } catch {
                Logger.error("Failed to authenticate the authenticator with error: \(error)")
                throw error
            }
                
                if let authToken = getLocalAuthToken() {
                    Logger.info("Authentication successful")
                    return authToken
                } else {
                    Logger.error("The authenticator authenticated successfully, but unexpectedly there was not a non-expired local access token available.")
                    
                    throw DisruptiveError(
                        type: .unknownError,
                        message: "Authentication error",
                        helpLink: nil
                    )
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
    
    /// Refreshes the access token, stores it in the `authToken` property, and sets
    /// `shouldAutoRefreshAccessToken` to `true`.
    func login() async throws {
        try await refreshAccessToken()
        shouldAutoRefreshAccessToken = true
    }
    
    /// Logs out the authenticator by setting `authToken` to `nil` and `shouldAutoRefreshAccessToken`
    /// to `false`. Call `login()` to log the authenticator back in again.
    func logout() async throws {
        authToken = nil
        shouldAutoRefreshAccessToken = false
    }
    
    /// Used internally to create a JWT from the service account passed in to the initializer, which is then exchanged
    /// with an access token from the authentication endpoint. This access token is stored in the `authToken` property
    /// along with the received expiration date.
    ///
    /// This flow is described in more detail on the [Developer Website](https://developer.disruptive-technologies.com/docs/authentication/oauth2).
    func refreshAccessToken() async throws {
        guard let authJWT = JWT.serviceAccount(
            authURL : authURL,
            keyID   : credentials.keyID,
            issuer  : credentials.issuer,
            secret  : credentials.secret
        ) else {
            Logger.error("Failed to create a JWT from service account credentials: \(credentials)")
            
            throw DisruptiveError(
                type: .unknownError,
                message: "Failed to authenticate",
                helpLink: nil
            )
        }
        
        let header = HTTPHeader(
            field: "Content-Type",
            value: "application/x-www-form-urlencoded"
        )
        let body = formURLEncodedBody(keysAndValues: [
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion" : authJWT
        ])!
        
        // Prepare the request
        var request: Request
        do {
            request = try Request(
                method: .post,
                baseURL: authURL,
                endpoint: "",
                headers: [header],
                body: body
            )
        } catch {
            Logger.error("Failed to encode body: \(body). Error: \(error)")
            throw DisruptiveError(error: error)
        }
        
        // Send the request
        do {
            let response: AccessTokenResponse = try await request.internalSend()
            
            authToken = AuthToken(
                token: "Bearer \(response.accessToken)",
                expirationDate: Date(timeIntervalSinceNow: TimeInterval(response.expiresIn))
            )
            
            Logger.info("OAuth2 authentication successful")
        } catch {
            Logger.error("OAuth2 authentication failed with error: \(error)")
            throw error
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
