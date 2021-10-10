//
//  Organization.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 18/05/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 Represents an organization registered with Disruptive Technologies.
*/
public struct Organization: Decodable, Equatable {
    
    /// The unique identifier for the organization. This will be different from the `name` field in the REST API
    /// in that it is just the identifier without the `organizations/` prefix.
    public let identifier: String
    
    /// The display name of the organization.
    public let displayName: String
}


extension Organization {
    /**
     Gets all the organizations available to the authenticated account.
     
     This will handle pagination automatically and send multiple network requests in
     the background if necessary. If a lot of organizations are expected to be available,
     it might be better to load pages of organizations as they're needed using the
     `getPage` function instead.
     
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Organization`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Organization], DisruptiveError>`
     */
    public static func getAll(
        completion: @escaping (_ result: Result<[Organization], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: "organizations")
        
        // Send the request
        request.send(pagingKey: "organizations") { completion($0) }
    }
    
    /**
     Gets one page of organizations available to the authenticated account.
     
     Useful if a lot of organizations are expected to be available. This function
     provides better control for when to get organizations and how many to get at a time so
     that organizations are only fetch when they are needed. This can also improve performance,
     at a cost of convenience compared to the `getAll` function.
     
     - Parameter pageSize: The maximum number of organizations to get for this page. The maximum page size is 100, which is also the default
     - Parameter pageToken: The token of the page to get. For the first page, set this to `nil`. For subsequent pages, use the `nextPageToken` received when getting the previous page.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain a tuple with both an array of `Organization`s, as well as the token for the next page. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<(nextPageToken: String?, organizations: [Organization]), DisruptiveError>`
     */
    public static func getPage(
        pageSize   : Int = 100,
        pageToken  : String?,
        completion : @escaping (_ result: Result<(nextPageToken: String?, organizations: [Organization]), DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: "organizations")
        
        // Send the request
        request.send(pageSize: pageSize, pageToken: pageToken, pagingKey: "organizations") { (result: Result<PagedResult<Organization>, DisruptiveError>) in
            switch result {
                case .success(let page) : completion(.success((nextPageToken: page.nextPageToken, organizations: page.results)))
                case .failure(let err)  : completion(.failure(err))
            }
        }
    }
    
    /**
     Gets a single organization based on an organization identifier.
     
     - Parameter organizationID: The identifier of the organization to get.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Organization`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Organization, DisruptiveError>`
     */
    public static func get(
        organizationID: String,
        completion: @escaping (_ result: Result<Organization, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "organizations/\(organizationID)"
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: endpoint)
        
        // Send the request
        request.send() { completion($0) }
    }
}


extension Organization {
    private enum CodingKeys: String, CodingKey {
        case resourceName = "name"
        case displayName
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Organization identifiers are formatted as "organizations/b7s3e550fee000ba5dhg"
        // Setting the identifier to the last component of the resource name
        let orgResourceName = try values.decode(String.self, forKey: .resourceName)
        self.identifier = orgResourceName.components(separatedBy: "/").last ?? ""
        
        // Getting the display name property without any modifications
        self.displayName  = try values.decode(String.self, forKey: .displayName)
    }
}
