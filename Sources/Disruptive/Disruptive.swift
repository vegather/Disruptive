//
//  Disruptive.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 18/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

public struct Disruptive {
    
    public static let defaultBaseURL = "https://api.disruptive-technologies.com/v2/"
    public static let defaultAuthURL = "https://identity.disruptive-technologies.com/oauth2/token"
    
    /// The base URL for the Disruptive REST API.
    /// This is a settable, member property, meaning that multiple instances
    /// of `Disruptive` clients can be used at the same time with different
    /// base URLs (eg. to the dev environment or somewhere else for testing).
    public var baseURL = Disruptive.defaultBaseURL
    
    /// The authentication URL for the Disruptive REST API.
    /// This is a settable, member property, meaning that multiple instances
    /// of `Disruptive` clients can be used at the same time with different
    /// authentication URLs (eg. to the dev environment or somewhere else for testing).
    public var authURL = Disruptive.defaultAuthURL
    
    /// Whether or not the DisruptiveAPI should log to the console. Defaults to `false`
    public static var loggingEnabled = false
    
    /// The authentication mechanism used by `Disruptive`. This will be
    /// checked to see if it has a non-expired `authToken` before every request
    /// is sent to the Disruptive backend. If no non-expired `authToken` were found
    /// the `authenticate` method will be called before attempting to send the request.
    public let authProvider: AuthProvider

    public init(authProvider: AuthProvider) {
        self.authProvider = authProvider
    }
}

