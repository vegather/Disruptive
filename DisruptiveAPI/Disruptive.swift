//
//  Disruptive.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 18/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

public struct Disruptive {
    internal var authorization: String?
    internal static let baseURL = "https://api.disruptive-technologies.com/v2/"
    
    public static var loggingEnabled = false
    
    public init(serviceAccount: ServiceAccount) {
        self.authorization = serviceAccount.authorization()
    }
    
    
}
