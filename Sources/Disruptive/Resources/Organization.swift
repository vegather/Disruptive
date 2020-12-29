//
//  Organization.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 18/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 Represents an organization registered with Disruptive Technologies.
 
 Relevant methods for `Organization` can be found on the [Disruptive](../Disruptive) struct.
 */
public struct Organization: Codable, Equatable {
    
    /// The unique identifier for the organization. This will be different from the `name` field in the REST API
    /// in that it is just the identifier without the `organizations/` prefix.
    public let identifier: String
    
    /// The display name of the organization.
    public let displayName: String
}


extension Disruptive {
    /**
     Gets a list of all the organizations available to the authenticated account.
     
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Organization`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Organization], DisruptiveError>`
     */
    public func getOrganizations(
        completion: @escaping (_ result: Result<[Organization], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "organizations")
        
        // Send the request
        sendRequest(request, pagingKey: "organizations") { completion($0) }
    }
    
    /**
     Gets a single organization based on an organization identifier.
     
     - Parameter organizationID: The identifier of the organization to get.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Organization`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Organization, DisruptiveError>`
     */
    public func getOrganization(
        organizationID: String,
        completion: @escaping (_ result: Result<Organization, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "organizations/\(organizationID)"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
}


extension Organization {
    private enum CodingKeys: String, CodingKey {
        case resourceName = "name"
        case displayName
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Organization identifiers are formatted as "organizations/b7s3e550fee000ba5dhg"
        // Setting the identifier to the last component of the resource name
        let orgResourceName = try values.decode(String.self, forKey: .resourceName)
        self.identifier = orgResourceName.components(separatedBy: "/").last ?? ""
        
        // Getting the display name property without any modifications
        self.displayName  = try values.decode(String.self, forKey: .displayName)
    }
}
