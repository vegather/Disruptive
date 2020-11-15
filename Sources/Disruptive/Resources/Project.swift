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
    public var displayName: String
    public let isInventory: Bool
    public let orgID: String
    public let orgDisplayName: String
    public let sensorCount: Int
    public let cloudConnectorCount: Int
    
    public init(identifier: String, displayName: String, isInventory: Bool, orgID: String, orgDisplayName: String, sensorCount: Int, cloudConnectorCount: Int) {
        self.identifier = identifier
        self.displayName = displayName
        self.isInventory = isInventory
        self.orgID = orgID
        self.orgDisplayName = orgDisplayName
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
        let request = Request(method: .get, baseURL: baseURL, endpoint: "projects", params: params)
        
        // Send the request
        sendRequest(request, pageingKey: "projects") { completion($0) }
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
        let request = Request(method: .get, baseURL: baseURL, endpoint: "projects/\(projectID)")
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Creates a new project in a specific organization. The newly created project will be returned (including it's identifier, etc) if successful
     
     - Parameter displayName: The display name of the new project
     - Parameter organizationID: The identifier of the organization to create the project in
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Project`. If a failure occured, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Project, DisruptiveError>`
     */
    public func createProject(
        displayName    : String,
        organizationID : String,
        completion     : @escaping (_ result: Result<Project, DisruptiveError>) -> ())
    {
        // Create body for new project
        let payload = [
            "displayName" : displayName,
            "organization": "organizations/\(organizationID)"
        ]
        
        do {
            // Create the request
            let request = try Request(method: .post, baseURL: baseURL, endpoint: "projects", body: payload)
            
            // Create the new project
            sendRequest(request) { completion($0) }
        } catch (let error) {
            DTLog("Failed to init createProject request with payload: \(payload). Error: \(error)", isError: true)
            completion(.failure(.unknownError))
        }
    }
    
    /**
     Updates the display name of a project, and returns the new project (with the updated name) if successful
     
     - Parameter projectID: The identifier of the project to update the display name of
     - Parameter newDisplayName: The new display name to set for the project
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Project` with the updated display name. If a failure occured, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Project, DisruptiveError>`
     */
    public func updateProjectDisplayName(
        projectID      : String,
        newDisplayName : String,
        completion     : @escaping (_ result: Result<Project, DisruptiveError>) -> ())
    {
        let payload = [
            "displayName": newDisplayName
        ]
        
        do {
            // Create the request
            let request = try Request(method: .patch, baseURL: baseURL, endpoint: "projects/\(projectID)", body: payload)
            
            // Update the project display name
            sendRequest(request) { completion($0) }
        } catch (let error) {
            DTLog("Failed to init the update project request with payload: \(payload). Error: \(error)", isError: true)
            completion(.failure(.unknownError))
        }
    }
}


extension Project {
    private enum CodingKeys: String, CodingKey {
        case identifier     = "name"
        case displayName
        case isInventory    = "inventory"
        case orgID          = "organization"
        case orgDisplayName = "organizationDisplayName"
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
        let orgPath = try values.decode(String.self, forKey: .orgID)
        self.orgID = orgPath.components(separatedBy: "/").last ?? ""
        
        // Getting the other properties without any modifications
        self.displayName         = try values.decode(String.self, forKey: .displayName)
        self.isInventory         = try values.decode(Bool.self,   forKey: .isInventory)
        self.orgDisplayName      = try values.decode(String.self, forKey: .orgDisplayName)
        self.sensorCount         = try values.decode(Int.self,    forKey: .sensorCount)
        self.cloudConnectorCount = try values.decode(Int.self,    forKey: .cloudConnectorCount)
    }
}
