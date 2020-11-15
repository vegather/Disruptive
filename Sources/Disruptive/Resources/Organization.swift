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


extension Disruptive {
    /**
     Gets a list of all the organizations available to the authenticated account.
     
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Organization`s. If a failure occured, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Organization], DisruptiveError>`
     */
    public func getOrganizations(
        completion: @escaping (_ result: Result<[Organization], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "organizations")
        
        // Send the request
        sendRequest(request, pageingKey: "organizations") { completion($0) }
    }
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