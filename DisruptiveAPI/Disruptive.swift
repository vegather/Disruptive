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
    
    /// Whether or not the DisruptiveAPI should log to the console. Defaults to `false`
    public static var loggingEnabled = false
    
    /// The active authentication token
    internal var authorization: String?
    
    /// Authenticates using a service account with basic auth.
    public init(serviceAccountWithBasicAuth: ServiceAccount) {
        self.authorization = serviceAccountWithBasicAuth.authorization()
    }
}
