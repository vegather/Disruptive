//
//  Permissions.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 21/06/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

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
    
    case sensorRead              = "sensor.read"
    case sensorTransfer          = "sensor.transfer"
    case sensorUpdate            = "sensor.update"
    
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
     
     - Parameter forOrganization: The identifier of the organization to get the permissions for
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned containing an array of all the available permissions. Otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<[Permission], DisruptiveError>`
     */
    public func getPermissions(
        forOrganization orgID : String,
        completion            : @escaping (_ result: Result<[Permission], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "organizations/\(orgID)/permissions")
        
        // Send the request
        sendRequest(request, pageingKey: "permissions") { (response: Result<[PermissionWrapper], DisruptiveError>) in
            switch response {
                case .success(let wrappers) : completion(.success(wrappers.compactMap { $0.permission }))
                case .failure(let error)    : completion(.failure(error))
            }
        }
    }
    
    /**
    Gets all the permissions the currently logged in user has for the given project.
    
    - Parameter forProject: The identifier of the project to get the permissions for
    - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned containing an array of all the available permissions. Otherwise a `DisruptiveError` is returned in the `.failure` case.
    - Parameter result: `Result<[Permission], DisruptiveError>`
    */
    public func getPermissions(
        forProject projectID : String,
        completion           : @escaping (_ result: Result<[Permission], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "projects/\(projectID)/permissions")
        
        // Send the request
        sendRequest(request, pageingKey: "permissions") { (response: Result<[PermissionWrapper], DisruptiveError>) in
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
private struct PermissionWrapper: Decodable {
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
