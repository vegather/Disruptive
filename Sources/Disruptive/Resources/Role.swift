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
public struct Role: Decodable, Equatable {
    
    /// The level of access that is given to the role.
    public let accessLevel: AccessLevel
    
    /// The display name of the `Role`. Example: `Project user`.
    public let displayName: String
    
    /// The description of the `Role`. Example: `User in project`.
    public let description: String
}


extension Disruptive {
    
    /**
     Get a list of all the available roles that can be assigned to a member of a project or an organization.
     
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the array of `Role`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Role], DisruptiveError>`
     */
    public func getRoles(
        completion: @escaping (_ result: Result<[Role], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "roles")
        
        // Send the request
        sendRequest(request, pagingKey: "roles") { completion($0) }
    }
    
    /**
     Get the details for a specific role by its identifier.
     
     - Parameter roleID: The identifier of the role to get.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Role`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
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
    
    /// The level of access that is given to a role.
    public enum AccessLevel: Decodable, Equatable {
        
        /// Can only view data in projects, no editing rights.
        case projectUser
        
        /// Can edit devices and project settings.
        case projectDeveloper
        
        /// Can move devices between projects inside the organization.
        /// Can add and remove users in the project.
        case projectAdmin
        
        /// Can create new Projects and have Project administrator access in all
        /// Projects of the Organization.
        case organizationAdmin
        
        /// The access level received for the role was unknown.
        /// Added for backwards compatibility in case a new access level
        /// is added on the backend, and not yet added to this client library.
        case unknown(value: String)
        
        // Assumes the data to decode is a role resource name.
        // Format: "roles/organization.admin"
        public init(from decoder: Decoder) throws {
            let resourceName = try decoder
                .singleValueContainer()
                .decode(String.self)
            let parts = resourceName.components(separatedBy: "/")
            
            guard parts.count == 2, parts[0] == "roles" else {
                throw ParseError.identifier(path: resourceName)
            }
            switch parts[1] {
                case "project.user"       : self = .projectUser
                case "project.developer"  : self = .projectDeveloper
                case "project.admin"      : self = .projectAdmin
                case "organization.admin" : self = .organizationAdmin
                default                   : self = .unknown(value: resourceName)
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case accessLevel = "name"
        case displayName
        case description
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.accessLevel = try container.decode(AccessLevel.self, forKey: .accessLevel)
        self.displayName = try container.decode(String.self,      forKey: .displayName)
        self.description = try container.decode(String.self,      forKey: .description)
    }
}
