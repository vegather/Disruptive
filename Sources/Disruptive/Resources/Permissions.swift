//
//  Permissions.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 21/06/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 A permission is a specific action that an authenticated account is allowed to do within
 a specific project or organization.
 
 Permissions for the four different roles:
 
 Project.User:
 * emulator.read
 * device.read
 * dataconnector.read
 * serviceaccount.key.read
 * sensor.read
 * serviceaccount.read
 * membership.read
 * project.read
 
 Project.Developer:
 * emulator.delete
 * dataconnector.update
 * serviceaccount.read
 * dataconnector.create
 * project.read
 * dataconnector.delete
 * dataconnector.read
 * device.read
 * sensor.read
 * device.update
 * emulator.read
 * emulator.create
 * emulator.update
 * sensor.update
 * membership.read
 * serviceaccount.key.read
 
 Project.Admin:
 * serviceaccount.key.create
 * project.delete
 * dataconnector.create
 * membership.read
 * emulator.create
 * device.read
 * serviceaccount.update
 * sensor.read
 * serviceaccount.read
 * emulator.update
 * membership.create
 * project.update
 * project.read
 * device.transfer
 * emulator.delete
 * serviceaccount.delete
 * dataconnector.update
 * dataconnector.delete
 * dataconnector.read
 * serviceaccount.key.read
 * emulator.read
 * membership.delete
 * serviceaccount.key.delete
 * serviceaccount.create
 * sensor.update
 * device.update
 * membership.update
 
 Organization.Admin:
 * device.update
 * membership.read
 * serviceaccount.key.create
 * serviceaccount.delete
 * serviceaccount.key.read
 * membership.create
 * dataconnector.create
 * project.delete
 * device.transfer
 * serviceaccount.key.delete
 * sensor.update
 * membership.update
 * project.read
 * dataconnector.delete
 * device.read
 * dataconnector.read
 * serviceaccount.read
 * emulator.read
 * emulator.create
 * emulator.delete
 * sensor.read
 * serviceaccount.create
 * emulator.update
 * project.update
 * serviceaccount.update
 * dataconnector.update
 * membership.delete
 * project.create
 * organization.update
 * organization.read
 */

public enum Permission: String, Codable {
    case dataConnectorCreate     = "dataconnector.create"
    case dataConnectorDelete     = "dataconnector.delete"
    case dataConnectorRead       = "dataconnector.read"
    case dataConnectorUpdate     = "dataconnector.update"
    
    case deviceRead              = "device.read"
    case deviceTransfer          = "device.transfer"
    case deviceUpdate            = "device.update"
    
    case emulatorCreate          = "emulator.create"
    case emulatorDelete          = "emulator.delete"
    case emulatorRead            = "emulator.read"
    case emulatorUpdate          = "emulator.update"
    
    case membershipCreate        = "membership.create"
    case membershipDelete        = "membership.delete"
    case membershipRead          = "membership.read"
    case membershipUpdate        = "membership.update"
    
    case organizationRead        = "organization.read"
    case organizationUpdate      = "organization.update"
    
    case projectCreate           = "project.create"
    case projectDelete           = "project.delete"
    case projectRead             = "project.read"
    case projectUpdate           = "project.update"
    
    case serviceAccountCreate    = "serviceaccount.create"
    case serviceAccountDelete    = "serviceaccount.delete"
    case serviceAccountKeyCreate = "serviceaccount.key.create"
    case serviceAccountKeyDelete = "serviceaccount.key.delete"
    case serviceAccountKeyRead   = "serviceaccount.key.read"
    case serviceAccountRead      = "serviceaccount.read"
    case serviceAccountUpdate    = "serviceaccount.update"
}

extension Disruptive {
    /**
     Gets all the permissions the currently logged in user has for the given organization.
     
     - Parameter forOrganizationID: The identifier of the organization to get the permissions for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned containing an array of all the available permissions. Otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<[Permission], DisruptiveError>`
     */
    public func getPermissions(
        forOrganizationID orgID : String,
        completion            : @escaping (_ result: Result<[Permission], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "organizations/\(orgID)/permissions")
        
        // Send the request
        sendRequest(request, pagingKey: "permissions") { (response: Result<[PermissionWrapper], DisruptiveError>) in
            switch response {
                case .success(let wrappers) : completion(.success(wrappers.compactMap { $0.permission }))
                case .failure(let error)    : completion(.failure(error))
            }
        }
    }
    
    /**
    Gets all the permissions the currently logged in user has for the given project.
    
    - Parameter forProjectID: The identifier of the project to get the permissions for.
    - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned containing an array of all the available permissions. Otherwise a `DisruptiveError` is returned in the `.failure` case.
    - Parameter result: `Result<[Permission], DisruptiveError>`
    */
    public func getPermissions(
        forProjectID projectID : String,
        completion           : @escaping (_ result: Result<[Permission], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "projects/\(projectID)/permissions")
        
        // Send the request
        sendRequest(request, pagingKey: "permissions") { (response: Result<[PermissionWrapper], DisruptiveError>) in
            switch response {
                case .success(let wrappers) : completion(.success(wrappers.compactMap { $0.permission }))
                case .failure(let error)    : completion(.failure(error))
            }
        }
    }
}


/// Enables optional JSON parsing of Permissions.
/// Eg. if a new permission gets added to the REST API, that will simply
/// be ignored until it gets added to the `Permission` enum above.
internal struct PermissionWrapper: Decodable {
    let permission: Permission?
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let str = try? container.decode(String.self) {
            self.permission = Permission(rawValue: str)
        } else {
            self.permission = nil
        }
    }
}
