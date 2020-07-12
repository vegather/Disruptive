//
//  Project.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 20/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

public struct Project: Codable {
    public let identifier: String
    public var name: String
    public let isInventory: Bool
    public let organizationID: String
    public let organizationName: String
    public let sensorCount: Int
    public let cloudConnectorCount: Int
    
    public init(identifier: String, name: String, isInventory: Bool, organizationID: String, organizationName: String, sensorCount: Int, cloudConnectorCount: Int) {
        self.identifier = identifier
        self.name = name
        self.isInventory = isInventory
        self.organizationID = organizationID
        self.organizationName = organizationName
        self.sensorCount = sensorCount
        self.cloudConnectorCount = cloudConnectorCount
    }
}


extension Disruptive {
    /**
     Gets a list of projects. If an `organizationID` is specified, only projects within this organization is fetched. Otherwise, all the projects the authenticated account has access to is returned.
     
     - Parameter organizationID: The identifier of the organization to get projects from. If not specified (or nil), will fetch all the project the authenticated account has access to.
     - Parameter query: Simple keyword based search. If not specified (or nil), all projects will be returned.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Project`s. If a failure occured, the `.failure` case will contain a `DisruptiveError`
     - Parameter result: `Result<[Project], DisruptiveError>`
     */
    public func getProjects(
        organizationID : String? = nil,
        query          : String? = nil,
        completion     : @escaping (_ result: Result<[Project], DisruptiveError>) -> ())
    {
        // Set up the query parameters
        var params: [String: [String]] = [:]
        if let orgID = organizationID {
            params["organization"] = [orgID]
        }
        if let query = query {
            params["query"] = [query]
        }
        
        // Create the request
        let request = Request(method: .get, endpoint: "projects", params: params)
        
        // Send the request
        sendRequest(request: request, pageingKey: "projects") { completion($0) }
    }
    
    /**
     Gets details for a specific project
     
     - Parameter projectID: The identifier of the project to get details for
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Project`. If a failure occured, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Project, DisruptiveError>`
     */
    public func getProject(
        projectID  : String,
        completion : @escaping (_ result: Result<Project, DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, endpoint: "projects/\(projectID)")
        
        // Send the request
        sendRequest(request: request) { completion($0) }
    }
    
    /**
     Creates a new project in a specific organization. The newly created project will be returned (including it's identifier, etc) if successful
     
     - Parameter name: The name of the new project
     - Parameter organizationID: The identifier of the organization to create the project in
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Project`. If a failure occured, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Project, DisruptiveError>`
     */
    public func createProject(
        name           : String,
        organizationID : String,
        completion     : @escaping (_ result: Result<Project, DisruptiveError>) -> ())
    {
        // Create body for new project
        let payload = [
            "displayName" : name,
            "organization": "organizations/\(organizationID)"
        ]
        
        do {
            // Create the request
            let request = try Request(method: .post, endpoint: "projects", body: payload)
            
            // Create the new project
            sendRequest(request: request) { completion($0) }
        } catch (let error) {
            DTLog("Failed to init createProject request with payload: \(payload). Error: \(error)", isError: true)
            completion(.failure(.unknownError))
        }
    }
    
    /**
     Updates the name of a project, and returns the new project (with the updated name) if successful
     
     - Parameter projectID: The identifier of the project to update the name of
     - Parameter newName: The new name to set for the project
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Project` with the updated name. If a failure occured, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Project, DisruptiveError>`
     */
    public func updateProjectName(
        projectID: String,
        newName: String,
        completion: @escaping (_ result: Result<Project, DisruptiveError>) -> ())
    {
        let payload = [
            "displayName": newName
        ]
        
        do {
            // Create the request
            let request = try Request(method: .patch, endpoint: "projects/\(projectID)", body: payload)
            
            // Update the project name
            sendRequest(request: request) { completion($0) }
        } catch (let error) {
            DTLog("Failed to init the update project request with payload: \(payload). Error: \(error)", isError: true)
            completion(.failure(.unknownError))
        }
    }
}


extension Project {
    private enum CodingKeys: String, CodingKey {
        case identifier       = "name"
        case name             = "displayName"
        case isInventory      = "inventory"
        case organizationID   = "organization"
        case organizationName = "organizationDisplayName"
        case sensorCount
        case cloudConnectorCount
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Project identifiers are formatted as "projects/b7s3e550fee000ba5dhg"
        // Setting the identifier to the last component of the path
        let projectPath = try values.decode(String.self, forKey: .identifier)
        self.identifier = projectPath.components(separatedBy: "/").last ?? ""
        
        // Organization identifiers are formatted as "organizations/b7s3e550fee000ba5dhg"
        // Setting the identifier to the last component of the path
        let orgPath = try values.decode(String.self, forKey: .organizationID)
        self.organizationID = orgPath.components(separatedBy: "/").last ?? ""
        
        // Getting the other properties without any modifications
        self.name                = try values.decode(String.self, forKey: .name)
        self.isInventory         = try values.decode(Bool.self,   forKey: .isInventory)
        self.organizationName    = try values.decode(String.self, forKey: .organizationName)
        self.sensorCount         = try values.decode(Int.self,    forKey: .sensorCount)
        self.cloudConnectorCount = try values.decode(Int.self,    forKey: .cloudConnectorCount)
    }
}
