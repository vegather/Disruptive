//
//  Disruptive.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 18/05/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 Contains the shared global state of the `Disruptive` package. Any changes made to the static
 variables in this struct will affect all requests made after the change
 */
public struct Disruptive {
        
    /// The base URL for the Disruptive Technologies REST API.
    public static var baseURL = DefaultURLs.baseURL
    
    /// The base URL for the Disruptive Technologies emulator REST API.
    public static var emulatorBaseURL = DefaultURLs.baseEmulatorURL
    
    /// The authentication mechanism used by `Disruptive`. This will be
    /// checked to see if it has a non-expired access token before every request
    /// is sent to the Disruptive backend. If no non-expired access token were found
    /// the `refreshAccessToken` method will be called before attempting to send the request.
    public static var authenticator: Authenticator?
    
    /// An enum of the available logging levels for the Disruptive package.
    /// Each level enables all the levels above it. For example, the `.info`
    /// logging level enables `.info`, `.warning`, and `.error`.
    public enum LoggingLevel: Int {
        case off     = 0
        case error   = 1
        case warning = 2
        case info    = 3
        case debug   = 4
    }
    
    /// The logging level to use for the Disruptive package. Provides details useful
    /// information in a nice format about what is going on while data is being fetched
    /// from the Disruptive APIs. Defaults to `.off`.
    public static var loggingLevel: LoggingLevel = .off
}

public extension Disruptive {
    struct DefaultURLs {
        /// The default base URL for the Disruptive Technologies REST API.
        public static let baseURL = "https://api.disruptive-technologies.com/v2/"
        
        /// The default base URL for the Disruptive Technologies emulator REST API.
        public static let baseEmulatorURL = "https://emulator.disruptive-technologies.com/v2/"
        
        /// The default endpoint for authenticating against the Disruptive Technologies REST API.
        public static let oauthTokenEndpoint = "https://identity.disruptive-technologies.com/oauth2/token"
    }
}
