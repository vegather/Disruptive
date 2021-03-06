//
//  Disruptive.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 18/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 This is the core of the `Disruptive` Swift API, and implements the majority of the Disruptive Technologies REST API endpoints.
 
 The most straight-forward usage is to create one single shared instance of this, and use it across
 the entire app (although you can create multiple instances if you need to). When initialized with an
 `Authenticator`, a `Disruptive` instance will keep an access token up-to-date automatically,
 so all requests are authenticated.
 */
public struct Disruptive {
    
    /// The default base URL for the Disruptive Technologies REST API in the production environment.
    public static let defaultBaseURL = "https://api.disruptive-technologies.com/v2/"
    
    /// The default base URL for the Disruptive Technologies emulator REST API in the production environment.
    public static let defaultBaseEmulatorURL = "https://emulator.disruptive-technologies.com/v2/"
    
    /// The default base URL for authenticating against the Disruptive Technologies REST API in the production environment.
    public static let defaultAuthURL = "https://identity.disruptive-technologies.com/oauth2/token"
    
    /// The base URL for the Disruptive Technologies REST API.
    public let baseURL: String
    
    /// The base URL for the Disruptive Technologies emulator REST API.
    public let emulatorBaseURL: String
    
    /// Whether or not the DisruptiveAPI should log to the console. Defaults to `false`.
    public static var loggingEnabled = false
    
    /// The authentication mechanism used by `Disruptive`. This will be
    /// checked to see if it has a non-expired access token before every request
    /// is sent to the Disruptive backend. If no non-expired access token were found
    /// the `refreshAccessToken` method will be called before attempting to send the request.
    public let authenticator: Authenticator

    /**
     Initializes a `Disruptive` instance.
     
     - Parameter authenticator: Used to authenticate against the Disruptive Technologies REST API. It is recommended to pass an `OAuth2Authenticator` instance to this parameter.
     - Parameter baseURL: Optional parameter. The base URL for the REST API. The default value is `Disruptive.defaultBaseURL`.
     */
    public init(authenticator: Authenticator, baseURL: String = Disruptive.defaultBaseURL, emulatorBaseURL: String = Disruptive.defaultBaseEmulatorURL) {
        self.authenticator = authenticator
        self.baseURL = baseURL
        self.emulatorBaseURL = emulatorBaseURL
    }
}

