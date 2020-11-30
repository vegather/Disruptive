//
//  Role.swift
//  
//
//  Created by Vegard Solheim Theriault on 30/11/2020.
//

import Foundation

/**
 Represents a role that a user can have within a project or an organization.
 
 A `Role` is typically used when inviting a new member to a project or an organization, or when
 listing out the members of a project or an organization.
 
 Relevant methods for `Role` can be found on the [Disruptive](../Disruptive) struct.
 */
public struct Role: Codable, Equatable {
    
    /// The identifier of the `Role`. Will be in the format `<resource>.<role>`. Example: `project.user`.
    public let identifier: String
    
    /// The display name of the `Role`. Example: `Project user`.
    public let displayName: String
    
    /// The description of the `Role`. Example: `User in project`.
    public let description: String
}


extension Disruptive {
    
    /**
     Get a list of all the available roles that can be assigned to a member of a project or an organization.
     
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the array of `Role`s. If a failure occured, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Role], DisruptiveError>`
     */
    public func getRoles(
        completion: @escaping (_ result: Result<[Role], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "roles")
        
        // Send the request
        sendRequest(request, pageingKey: "roles") { completion($0) }
    }
    
    /**
     Get the details for a specific role by its identifier.
     
     - Parameter roleID: The identifier of the role to get.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Role`. If a failure occured, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Role, DisruptiveError>`
     */
    public func getRole(
        roleID: String,
        completion: @escaping (_ result: Result<Role, DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "roles/\(roleID)")
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
}

extension Role {
    private enum CodingKeys: String, CodingKey {
        case identifier = "name"
        case displayName
        case description
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Role identifiers are formatted as "role/organization.admin"
        // Setting the identifier to the last component of the resource name
        let roleResourceName = try values.decode(String.self, forKey: .identifier)
        self.identifier = roleResourceName.components(separatedBy: "/").last ?? ""
        
        // Getting the display name and description properties without any modifications
        self.displayName = try values .decode(String.self, forKey: .displayName)
        self.description = try values .decode(String.self, forKey: .description)
    }
}
