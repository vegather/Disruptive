//
//  Disruptive.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 18/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

public struct Disruptive {
    public static var baseURL = "https://api.disruptive-technologies.com/v2/"
    public static var authURL = "https://identity.disruptive-technologies.com/oauth2/token"
    
    /// Whether or not the DisruptiveAPI should log to the console. Defaults to `false`
    public static var loggingEnabled = true
    
    internal static var authProvider: AuthProvider?

    public init(authProvider: AuthProvider) {
        Disruptive.self.authProvider = authProvider
    }
}
