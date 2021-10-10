//
//  Project.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 20/05/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 Represents a project within an `Organization`.
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


extension Project {
    /**
     Gets a list of all projects that matches the `query`/`organizationID`.
     
     If an `organizationID` is specified, only projects within this organization are fetched.
     Otherwise, all the projects the authenticated account has access to is returned. A `query`
     string can also be used for simple keyword based search.
     
     This will handle pagination automatically and send multiple network requests in
     the background if necessary. If a lot of projects are expected to be available,
     it might be better to load pages of projects as they're needed using the
     `getPage` function instead.
     
     - Parameter organizationID: Optional parameter. The identifier of the organization to get projects from. If not specified (or nil), will fetch all the project the authenticated account has access to.
     - Parameter query: Optional parameter. Simple keyword based search. If not specified (or nil), all projects will be returned.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Project`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Project], DisruptiveError>`
     */
    public static func getAll(
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
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: "projects", params: params)
        
        // Send the request
        request.send(pagingKey: "projects") { completion($0) }
    }
    
    /**
     Gets one page of projects that matches the `query`/`organizationID`
     
     If an `organizationID` is specified, only projects within this organization are fetched.
     Otherwise, one page of the projects the authenticated account has access to is returned.
     A `query` string can also be used for simple keyword based search.
     
     Useful if a lot of projects are expected to be available. This function
     provides better control for when to get projects and how many to get at a time so
     that projects are only fetch when they are needed. This can also improve performance,
     at a cost of convenience compared to the `getAll` function.
     
     - Parameter organizationID: Optional parameter. The identifier of the organization to get projects from. If not specified (or nil), will fetch projects the authenticated account has access to from all organizations.
     - Parameter query: Optional parameter. Simple keyword based search. If not specified (or nil), any projects will be returned.
     - Parameter pageSize: The maximum number of projects to get for this page. The maximum page size is 100, which is also the default
     - Parameter pageToken: The token of the page to get. For the first page, set this to `nil`. For subsequent pages, use the `nextPageToken` received when getting the previous page.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain a tuple with both an array of `Project`s, as well as the token for the next page. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<(nextPageToken: String?, projects: [Project]), DisruptiveError>`
     */
    public static func getPage(
        organizationID : String? = nil,
        query          : String? = nil,
        pageSize       : Int = 100,
        pageToken      : String?,
        completion     : @escaping (_ result: Result<(nextPageToken: String?, projects: [Project]), DisruptiveError>) -> ())
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
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: "projects", params: params)
        
        // Send the request
        request.send(pageSize: pageSize, pageToken: pageToken, pagingKey: "projects") { (result: Result<PagedResult<Project>, DisruptiveError>) in
            switch result {
                case .success(let page) : completion(.success((nextPageToken: page.nextPageToken, projects: page.results)))
                case .failure(let err)  : completion(.failure(err))
            }
        }
    }
    
    /**
     Gets details for a specific project.
     
     - Parameter projectID: The identifier of the project to get details for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Project`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Project, DisruptiveError>`
     */
    public static func get(
        projectID  : String,
        completion : @escaping (_ result: Result<Project, DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: "projects/\(projectID)")
        
        // Send the request
        request.send() { completion($0) }
    }
    
    /**
     Creates a new project in a specific organization. The newly created project will be returned (including it's identifier, etc) if successful.
     
     - Parameter organizationID: The identifier of the organization to create the project in.
     - Parameter displayName: The display name of the new project.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Project`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Project, DisruptiveError>`
     */
    public static func create(
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
            let request = try Request(method: .post, baseURL: Disruptive.baseURL, endpoint: "projects", body: payload)
            
            // Create the new project
            request.send() { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to init create request with payload: \(payload). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? DisruptiveError(type: .unknownError, message: "", helpLink: nil)))
        }
    }
    
    /**
     Deletes a project. Deleting a project can only be done if it has no devices, Service Accounts, or
     Data Connectors in it. Otherwise, an error will be returned.
     
     - Parameter projectID: The identifier of the project to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public static func delete(
        projectID  : String,
        completion : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)"
        let request = Request(method: .delete, baseURL: Disruptive.baseURL, endpoint: endpoint)
        
        // Send the request
        request.send() { completion($0) }
    }
    
    /**
     Updates the display name of a project, and returns the new project (with the updated name) if successful.
     
     - Parameter projectID: The identifier of the project to update the display name of.
     - Parameter newDisplayName: The new display name to set for the project.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Project` with the updated display name. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Project, DisruptiveError>`
     */
    public static func updateDisplayName(
        projectID      : String,
        newDisplayName : String,
        completion     : @escaping (_ result: Result<Project, DisruptiveError>) -> ())
    {
        let payload = [
            "displayName": newDisplayName
        ]
        
        do {
            // Create the request
            let request = try Request(method: .patch, baseURL: Disruptive.baseURL, endpoint: "projects/\(projectID)", body: payload)
            
            // Update the project display name
            request.send() { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to init the update project request with payload: \(payload). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? DisruptiveError(type: .unknownError, message: "", helpLink: nil)))
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
