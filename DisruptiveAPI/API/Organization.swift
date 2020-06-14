//
//  Organization.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 18/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

public struct Organization: Codable {
    public let identifier: String
    public let name: String
}

extension Organization {
    private enum CodingKeys: String, CodingKey {
        case identifier = "name"
        case name = "displayName"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Organization identifiers are formatted as "organizations/b7s3e550fee000ba5dhg"
        // Setting the identifier to the last component of the path
        let orgPath = try values.decode(String.self, forKey: .identifier)
        self.identifier = orgPath.components(separatedBy: "/").last ?? ""
        
        // Getting the name property without any modifications
        self.name  = try values.decode(String.self, forKey: .name)
    }
}

extension Disruptive {
    public func getOrganizations(
        completion: @escaping (Result<[Organization], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, endpoint: "organizations")
        
        // Send the request
        sendRequest(request: request, pageingKey: "organizations") { response in
            completion(response)
        }
    }
}
