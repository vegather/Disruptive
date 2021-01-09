//
//  Project.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 20/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 Represents a project within an `Organization`.
 
 Relevant methods for `Project` can be found on the [Disruptive](../Disruptive) struct.
 */
public struct Project: Decodable, Equatable {
    
    /// The unique identifier of the project. This will be different from the `name` field in the REST API
    /// in that it is just the identifier without the `projects/` prefix.
    public let identifier: String
    
    /// The display name of the project.
    public var displayName: String
    
    /// Specifies whether or not the project is the inventory project. The inventory project in an organization is the project where newly purchased devices will be placed.
    public let isInventory: Bool
    
    /// The identifier of the organization the project is in.
    public let organizationID: String
    
    /// The display name of the organization the project is in.
    public let organizationDisplayName: String
    
    /// The number of Sensors currently in the project.
    public let sensorCount: Int
    
    /// The number of Cloud Connectors currently in the project.
    public let cloudConnectorCount: Int
    
    /// Creates a new `Project`. Creating a new project can be useful for testing purposes.
    public init(identifier: String, displayName: String, isInventory: Bool, organizationID: String, organizationDisplayName: String, sensorCount: Int, cloudConnectorCount: Int) {
        self.identifier = identifier
        self.displayName = displayName
        self.isInventory = isInventory
        self.organizationID = organizationID
        self.organizationDisplayName = organizationDisplayName
        self.sensorCount = sensorCount
        self.cloudConnectorCount = cloudConnectorCount
    }
}


extension Disruptive {
    /**
     Gets a list of projects. If an `organizationID` is specified, only projects within this organization is fetched. Otherwise, all the projects the authenticated account has access to is returned.
     
     - Parameter organizationID: Optional parameter. The identifier of the organization to get projects from. If not specified (or nil), will fetch all the project the authenticated account has access to.
     - Parameter query: Optional parameter. Simple keyword based search. If not specified (or nil), all projects will be returned.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Project`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
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
        sendRequest(request, pagingKey: "projects") { completion($0) }
    }
    
    /**
     Gets details for a specific project.
     
     - Parameter projectID: The identifier of the project to get details for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Project`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
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
     Creates a new project in a specific organization. The newly created project will be returned (including it's identifier, etc) if successful.
     
     - Parameter organizationID: The identifier of the organization to create the project in.
     - Parameter displayName: The display name of the new project.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Project`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Project, DisruptiveError>`
     */
    public func createProject(
        organizationID : String,
        displayName    : String,
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
            Disruptive.log("Failed to init createProject request with payload: \(payload). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? .unknownError))
        }
    }
    
    /**
     Deletes a project. Deleting a project can only be done if it has no devices, Service Accounts, or
     Data Connectors in it. Otherwise, an error will be returned.
     
     - Parameter projectID: The identifier of the project to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func deleteProject(
        projectID  : String,
        completion : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)"
        let request = Request(method: .delete, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Updates the display name of a project, and returns the new project (with the updated name) if successful.
     
     - Parameter projectID: The identifier of the project to update the display name of.
     - Parameter newDisplayName: The new display name to set for the project.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Project` with the updated display name. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
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
            Disruptive.log("Failed to init the update project request with payload: \(payload). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? .unknownError))
        }
    }
}


extension Project {
    private enum CodingKeys: String, CodingKey {
        case resourceName            = "name"
        case displayName
        case isInventory             = "inventory"
        case orgResourceName         = "organization"
        case organizationDisplayName
        case sensorCount
        case cloudConnectorCount
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Project identifiers are formatted as "projects/b7s3e550fee000ba5dhg"
        // Setting the identifier to the last component of the resource name
        let projectResourceName = try container.decode(String.self, forKey: .resourceName)
        self.identifier = projectResourceName.components(separatedBy: "/").last ?? ""
        
        // Organization identifiers are formatted as "organizations/b7s3e550fee000ba5dhg"
        // Setting the identifier to the last component of the resource name
        let orgResourceName = try container.decode(String.self, forKey: .orgResourceName)
        self.organizationID = orgResourceName.components(separatedBy: "/").last ?? ""
        
        // Getting the other properties without any modifications
        self.displayName             = try container.decode(String.self, forKey: .displayName)
        self.isInventory             = try container.decode(Bool.self,   forKey: .isInventory)
        self.organizationDisplayName = try container.decode(String.self, forKey: .organizationDisplayName)
        self.sensorCount             = try container.decode(Int.self,    forKey: .sensorCount)
        self.cloudConnectorCount     = try container.decode(Int.self,    forKey: .cloudConnectorCount)
    }
}
