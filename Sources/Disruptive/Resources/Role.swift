//
//  Role.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 30/11/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 Represents a role that a user can have within a project or an organization.
 
 A `Role` is typically used when inviting a new member to a project or an organization, or when
 listing out the members of a project or an organization.
*/
public struct Role: Decodable, Equatable {
    
    /// The level of access that is given to the role.
    public let roleType: RoleType
    
    /// The display name of the `Role`. Example: `Project user`.
    public let displayName: String
    
    /// The description of the `Role`. Example: `User in project`.
    public let description: String
    
    /// A list of permissions the role has. Indicates which actions can be
    /// taken on various resources
    public let permissions: [Permission]
}


extension Role {
    
    /**
     Get a list of all the available roles that can be assigned to a member of a project or an organization.
     
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the array of `Role`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Role], DisruptiveError>`
     */
    public static func getAll(
        completion: @escaping (_ result: Result<[Role], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: "roles")
        
        // Send the request
        request.send(pagingKey: "roles") { completion($0) }
    }
    
    /**
     Get the details for a specific role.
     
     - Parameter roleType: The type of role to get.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Role`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Role, DisruptiveError>`
     */
    public static func get(
        roleType: Role.RoleType,
        completion: @escaping (_ result: Result<Role, DisruptiveError>) -> ())
    {
        guard let resourceName = roleType.resourceName else {
            Disruptive.log("Can't get role for roleType: \(roleType)", level: .error)
            completion(.failure(DisruptiveError(
                type: .badRequest,
                message: "Can't get role for roleType: \(roleType)",
                helpLink: nil
            )))
            return
        }
        
        // Create the request
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: resourceName)
        
        // Send the request
        request.send() { completion($0) }
    }
}

extension Role {
    
    /// The level of access that is given to a role.
    public enum RoleType: Codable, Equatable {
        
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
                throw ParseError.identifier(resourceName: resourceName)
            }
            switch parts[1] {
                case "project.user"       : self = .projectUser
                case "project.developer"  : self = .projectDeveloper
                case "project.admin"      : self = .projectAdmin
                case "organization.admin" : self = .organizationAdmin
                default                   : self = .unknown(value: resourceName)
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            if let resourceName = resourceName {
                var container = encoder.singleValueContainer()
                try container.encode(resourceName)
            } else {
                Disruptive.log("Can't encode Role.RoleType with case .unknown", level: .error)
                throw DisruptiveError(
                    type: .badRequest,
                    message: "Can't use role \(self)",
                    helpLink: nil
                )
            }
        }
        
        internal var resourceName: String? {
            switch self {
                case .projectUser       : return "roles/project.user"
                case .projectDeveloper  : return "roles/project.developer"
                case .projectAdmin      : return "roles/project.admin"
                case .organizationAdmin : return "roles/organization.admin"
                case .unknown           : return nil
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case resourceName = "name"
        case displayName
        case description
        case permissions
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.roleType    = try container.decode(RoleType.self, forKey: .resourceName)
        self.displayName = try container.decode(String.self,   forKey: .displayName)
        self.description = try container.decode(String.self,   forKey: .description)
        self.permissions = try container
            .decode([PermissionWrapper].self, forKey: .permissions)
            .compactMap { $0.permission }
    }
}
