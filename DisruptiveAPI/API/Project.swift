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
    public let name: String
    public let isInventory: Bool
    public let sensorCount: Int
    public let cloudConnectorCount: Int
}

extension Project {
    private enum CodingKeys: String, CodingKey {
        case identifier  = "name"
        case name        = "displayName"
        case isInventory = "inventory"
        case sensorCount
        case cloudConnectorCount
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Project identifiers are formatted as "projects/b7s3e550fee000ba5dhg"
        // Setting the identifier to the last component of the path
        let projectPath = try values.decode(String.self, forKey: .identifier)
        self.identifier = projectPath.components(separatedBy: "/").last ?? ""
        
        // Getting the other properties without any modifications
        self.name                = try values.decode(String.self, forKey: .name)
        self.isInventory         = try values.decode(Bool.self,   forKey: .isInventory)
        self.sensorCount         = try values.decode(Int.self,    forKey: .sensorCount)
        self.cloudConnectorCount = try values.decode(Int.self,    forKey: .cloudConnectorCount)
    }
}

extension Disruptive {
    public func getProjects(
        organizationID: String? = nil,
        query: String? = nil,
        completion: @escaping (Result<[Project], DisruptiveError>) -> ())
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
        sendRequest(request: request, pageingKey: "projects") { response in
            completion(response)
        }
    }
    
    public func getProject(projectID: String, completion: @escaping (Result<Project, DisruptiveError>) -> ()) {
        // Create the request
        let request = Request(method: .get, endpoint: "projects/\(projectID)")
        
        // Send the request
        sendRequest(request: request) { response in
            completion(response)
        }
    }
    
    public func createProject(name: String, organizationID: String, completion: @escaping (Result<Project, DisruptiveError>) -> ()) {
        // Create body for new project
        let payload = [
            "displayName" : name,
            "organization": "organizations/\(organizationID)"
        ]
        
        do {
            // Create the request
            let request = try Request(method: .post, endpoint: "projects", body: payload)
            
            // Create the new project
            sendRequest(request: request) { response in
                completion(response)
            }
        } catch (let error) {
            DTLog("Failed to create CreateProject request with payload: \(payload). Error: \(error)", isError: true)
            completion(.failure(.unknownError))
        }
    }
}
