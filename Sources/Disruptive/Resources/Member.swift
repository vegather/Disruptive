//
//  Member.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 27/12/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 A `Member` assigns a specific role to an account within a project
 or an organization. The account can be either a user or a service account.
*/
public struct Member: Decodable, Equatable {
    
    /// The identifier of the Member.
    public let identifier: String
    
    /// If the member is associated with a project, this will be populated
    /// with the identifier of the project.
    public let projectID: String?
    
    /// If the member is associated with an organization, this will be populated
    /// with the identifier of the organization.
    public let organizationID: String?
    
    /// The display name of the Member.
    public let displayName: String
    
    /// The roles assigned to the Member within the project or organization
    /// it is associated with.
    public let roles: [Role.RoleType]
    
    /// The status of the Member. Useful to check if a user has accepted
    /// the invitation.
    public let status: Status
    
    /// The email of the Member. Can be both a user email or a service
    /// account email.
    public let email: String
    
    /// The type of account the Member is for.
    public let accountType: AccountType
    
    /// The timestamp of when the Member was created.
    public let createTime: Date
}

extension Member {
    
    /**
     Gets all the Members for a specific organization.
     
     This will handle pagination automatically and send multiple network requests in
     the background if necessary. If a lot of Members are expected to be in the organization,
     it might be better to load pages of Members as they're needed using the
     `getPage` function instead.
     
     - Parameter organizationID: The identifier of the organization to get Members for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Member`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Member], DisruptiveError>`
     */
    public static func getAll(organizationID: String) async throws -> [Member] {
        return try await getAll(endpoint: "organizations/\(organizationID)/members")
    }
    
    /**
     Gets all the Members for a specific project.
     
     This will handle pagination automatically and send multiple network requests in
     the background if necessary. If a lot of Members are expected to be in the project,
     it might be better to load pages of Members as they're needed using the
     `getPage` function instead.
     
     - Parameter projectID: The identifier of the project to get Members for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Member`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Member], DisruptiveError>`
     */
    public static func getAll(projectID: String) async throws -> [Member] {
        return try await getAll(endpoint: "projects/\(projectID)/members")
    }
    
    // Helper function to get Members for either Projects or Organizations.
    private static func getAll(endpoint: String) async throws -> [Member] {
        // Create the request
        let request = Request(method: .get, endpoint: endpoint)
        
        // Send the request
        return try await request.send(pagingKey: "members")
    }
    
    
    
    /**
     Gets one page of Members for a specific organization.
     
     Useful if a lot of Members are expected in the specified organization. This function
     provides better control for when to get Members and how many to get at a time so
     that Members are only fetch when they are needed. This can also improve performance,
     at a cost of convenience compared to the `getAll` function.
     
     - Parameter organizationID: The identifier of the organization to get Members from.
     - Parameter pageSize: The maximum number of Members to get for this page. The maximum page size is 100, which is also the default.
     - Parameter pageToken: The token of the page to get. For the first page, set this to `nil`. For subsequent pages, use the `nextPageToken` received when getting the previous page.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain a tuple with both an array of `Member`s, as well as the token for the next page. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<(nextPageToken: String?, members: [Member]), DisruptiveError>`
     */
    public static func getPage(
        organizationID : String,
        pageSize       : Int = 100,
        pageToken      : String?
    ) async throws -> (nextPageToken: String?, members: [Member]) {
        return try await getPage(endpoint: "organizations/\(organizationID)/members", pageSize: pageSize, pageToken: pageToken)
    }
    
    /**
     Gets one page of Members for a specific project.
     
     Useful if a lot of Members are expected in the specified project. This function
     provides better control for when to get Members and how many to get at a time so
     that Members are only fetch when they are needed. This can also improve performance,
     at a cost of convenience compared to the `getAll` function.
     
     - Parameter projectID: The identifier of the project to get Members from.
     - Parameter pageSize: The maximum number of Members to get for this page. The maximum page size is 100, which is also the default.
     - Parameter pageToken: The token of the page to get. For the first page, set this to `nil`. For subsequent pages, use the `nextPageToken` received when getting the previous page.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain a tuple with both an array of `Member`s, as well as the token for the next page. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<(nextPageToken: String?, members: [Member]), DisruptiveError>`
     */
    public static func getPage(
        projectID : String,
        pageSize  : Int = 100,
        pageToken : String?
    ) async throws -> (nextPageToken: String?, members: [Member]) {
        return try await getPage(endpoint: "projects/\(projectID)/members", pageSize: pageSize, pageToken: pageToken)
    }
    
    // Helper function to get a Members page for either Projects or Organizations.
    private static func getPage(
        endpoint  : String,
        pageSize  : Int,
        pageToken : String?
    ) async throws -> (nextPageToken: String?, members: [Member]) {
        // Create the request
        let request = Request(method: .get, endpoint: endpoint)
        
        // Send the request
        let page: PagedResult<Member> = try await request.send(pageSize: pageSize, pageToken: pageToken, pagingKey: "members")
        return (nextPageToken: page.nextPageToken, members: page.results)
    }
    
    
    
    /**
     Gets a specific Member within an organization by its identifier.
     
     - Parameter organizationID: The identifier of the organization to get the Member from.
     - Parameter memberID: The identifier of the Member to get within the specific organization.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Member`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Member, DisruptiveError>`
     */
    public static func get(
        organizationID : String,
        memberID       : String
    ) async throws -> Member {
        return try await get(endpoint: "organizations/\(organizationID)/members/\(memberID)")
    }
    
    /**
     Gets a specific Member within a project by its identifier.
     
     - Parameter projectID: The identifier of the project to get the Member from.
     - Parameter memberID: The identifier of the Member to get within the specific project.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Member`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Member, DisruptiveError>`
     */
    public static func get(
        projectID : String,
        memberID  : String
    ) async throws -> Member {
        return try await get(endpoint: "projects/\(projectID)/members/\(memberID)")
    }
    
    // Helper function to get a specific Member in either a Project or an Organization.
    private static func get(endpoint: String) async throws -> Member {
        // Create the request
        let request = Request(method: .get, endpoint: endpoint)
        
        // Send the request
        return try await request.send()
    }
    
    
    
    /**
     Invites a new member to an organization.
     
     If the email belongs to a user that already has an account or a service account, the member
     will get the status `.accepted` immediately. Otherwise, the member will get the status `.pending`,
     and an invite email will be sent to the user.
     
     - Parameter organizationID:The identifier of the organization to invite a member to.
     - Parameter roles: The list of roles for the member. Currently, only one role is allowed for a member.
     The role has to be an organization based role (ie. `.organizationAdmin`).
     - Parameter email: The email of the member to invite. Could be the email of a user or a service account.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the new `Member`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Member, DisruptiveError>`
     */
    public static func invite(
        organizationID : String,
        roles          : [Role.RoleType],
        email          : String
    ) async throws -> Member {
        return try await invite(
            endpoint: "organizations/\(organizationID)/members",
            roles: roles,
            email: email
        )
    }
    
    /**
     Invites a new member to a project.
     
     If the email belongs to a user that already has an account or a service account, the member
     will get the status `.accepted` immediately. Otherwise, the member will get the status `.pending`,
     and an invite email will be sent to the user.
     
     - Parameter projectID:The identifier of the project to invite a member to.
     - Parameter roles: The list of roles for the member. Currently, only one role is allowed for a member.
     The role has to be a project based role (ie. `.projectUser`).
     - Parameter email: The email of the member to invite. Could be the email of a user or a service account.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the new `Member`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Member, DisruptiveError>`
     */
    public static func invite(
        projectID : String,
        roles     : [Role.RoleType],
        email     : String
    ) async throws -> Member {
        return try await invite(
            endpoint: "projects/\(projectID)/members",
            roles: roles,
            email: email
        )
    }
    
    // Helper function to invite Members to either Projects or Organizations.
    private static func invite(
        endpoint : String,
        roles    : [Role.RoleType],
        email    : String
    ) async throws -> Member {
        // Prepare the payload
        struct MemberPayload: Encodable {
            let roles: [Role.RoleType]
            let email: String
        }
        let payload = MemberPayload(roles: roles, email: email)
        
        // Create the request
        let request: Request
        do {
            request = try Request(method: .post, endpoint: endpoint, body: payload)
        } catch {
            Logger.error("Failed to init create member request with payload \(payload). Error: \(error)")
            throw (error as? DisruptiveError) ?? DisruptiveError(type: .unknownError, message: "", helpLink: nil)
        }
        
        // Send the request
        return try await request.send()
    }
    
    
    
//    /**
//     Updates the Member of an organization.
//     
//     - Parameter organizationID: The identifier of the organization the Member is in.
//     - Parameter memberID: The identifier of the Member to update.
//     - Parameter roles: The new role to assign to the Member. Must be a role appropriate an organization (ie. `.organizationAdmin`).
//     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the updated `Member`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
//     - Parameter result: `Result<Member, DisruptiveError>`
//     */
//    public func update(
//        organizationID : String,
//        memberID       : String,
//        roles          : [Role.RoleType],
//        completion     : @escaping (_ result: Result<Member, DisruptiveError>) -> ())
//    {
//        update(
//            endpoint    : "organizations/\(organizationID)/members/\(memberID)",
//            roles       : roles
//        ) { completion($0) }
//    }

    /**
     Updates the Member of a project.
     
     - Parameter projectID: The identifier of the project the Member is in.
     - Parameter memberID: The identifier of the Member to update.
     - Parameter roles: The new role to assign to the Member. Must be a role appropriate a project (ie. `.projectUser`).
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the updated `Member`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Member, DisruptiveError>`
     */
    public static func update(
        projectID : String,
        memberID  : String,
        roles     : [Role.RoleType]
    ) async throws -> Member {
        return try await update(
            endpoint : "projects/\(projectID)/members/\(memberID)",
            roles    : roles
        )
    }

    private static func update(
        endpoint : String,
        roles    : [Role.RoleType]
    ) async throws -> Member {
        struct MemberPatch: Encodable {
            var roles: [Role.RoleType]
        }

        // At least one of the fields has to be set so that `updateMask` is non-empty
        if roles.count == 0 {
            Logger.error("At least one of the fields in `update` has to be set")
            throw DisruptiveError(
                type: .badRequest,
                message: "No roles set",
                helpLink: nil
            )
        }
        
        // Prepare the payload
        let patch = MemberPatch(roles: roles)

        // Create the request
        let request: Request
        do {
            request = try Request(method: .patch, endpoint: endpoint, body: patch)
        } catch (let error) {
            Logger.error("Failed to init update request with payload: \(patch). Error: \(error)")
            throw (error as? DisruptiveError) ?? DisruptiveError(type: .unknownError, message: "", helpLink: nil)
        }
        
        // Send the request
        return try await request.send()
    }
    
    
    /**
     Deletes a member from an organization.
     
     - Parameter organizationID: The identifier of the organization the member is a part of.
     - Parameter memberID: The identifier of the member to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public static func delete(
        organizationID : String,
        memberID       : String
    ) async throws {
        try await delete(endpoint: "organizations/\(organizationID)/members/\(memberID)")
    }
    
    /**
     Deletes a member from a project.
     
     - Parameter projectID: The identifier of the project the member is a part of.
     - Parameter memberID: The identifier of the member to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public static func delete(
        projectID : String,
        memberID  : String
    ) async throws {
        try await delete(endpoint: "projects/\(projectID)/members/\(memberID)")
    }
    
    private static func delete(endpoint: String) async throws {
        // Create the request
        let request = Request(method: .delete, endpoint: endpoint)
        
        // Send the request
        try await request.send()
    }
    
    
    
    /**
     Retrieves the invite URL that allows a new user to set up their account in an organization.
     
     - Note: An invite URL is only available for new users that have not yet
     accepted the invitation to create an account. If the following conditions
     are not true, a `.badRequest` error will be returned:
     * The `accountType` of the member must be `.user`.
     * The `status` of the member must be `.pending`.
     
     - Parameter organizationID: The identifier of the organization the member is a part of.
     - Parameter memberID: The identifier of the member to get an invite URL for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned with the invite URL as a `URL`, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<URL, DisruptiveError>`
     */
    public static func getInviteURL(
        organizationID : String,
        memberID       : String
    ) async throws -> URL {
        return try await getInviteURL(endpoint: "organizations/\(organizationID)/members/\(memberID):getInviteUrl")
    }
    
    /**
     Retrieves the invite URL that allows a new user to set up their account in a project.
     
     - Note: An invite URL is only available for new users that have not yet
     accepted the invitation to create an account. If the following conditions
     are not true, a `.badRequest` error will be returned:
     * The `accountType` of the member must be `.user`.
     * The `status` of the member must be `.pending`.
     
     - Parameter projectID: The identifier of the project the member is a part of.
     - Parameter memberID: The identifier of the member to get an invite URL for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned with the invite URL as a `URL`, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<URL, DisruptiveError>`
     */
    public static func getInviteURL(
        projectID : String,
        memberID  : String
    ) async throws -> URL {
        return try await getInviteURL(endpoint: "projects/\(projectID)/members/\(memberID):getInviteUrl")
    }
    
    private static func getInviteURL(endpoint: String) async throws -> URL {
        struct InviteURLResponse: Decodable {
            let inviteUrl: String
        }
        
        // Create the request
        let request = Request(method: .get, endpoint: endpoint)
        
        // Send the request
        let response: InviteURLResponse = try await request.send()
        guard let url = URL(string: response.inviteUrl) else {
            Logger.error("Failed to convert the inviteUrl response to a URL: \(response.inviteUrl)")
            throw DisruptiveError(
                type: .unknownError,
                message: "Unknown error",
                helpLink: nil
            )
        }
        
        return url
    }
}

extension Member {
    
    /// Indicates the current status of the membership.
    public enum Status: Codable, Equatable {
        /// Pending on the User to acknowledge the membership.
        /// The UI can use this to indicate that the member is
        /// not yet active.
        case pending
        
        /// User has accepted the membership.
        case accepted
        
        /// The status received for the member was unknown.
        /// Used for backwards compatibility in case a new status
        /// is added on the backend, and not yet added to this
        /// client library.
        case unknown(value: String)
        
        public init(from decoder: Decoder) throws {
            let str = try decoder.singleValueContainer().decode(String.self)
            
            switch str {
                case "PENDING"  : self = .pending
                case "ACCEPTED" : self = .accepted
                default         : self = .unknown(value: str)
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
                case .pending  : try container.encode("PENDING")
                case .accepted : try container.encode("ACCEPTED")
                case .unknown:
                    let error = DisruptiveError(
                        type: .badRequest,
                        message: "Unknown member status \"\(self)\"",
                        helpLink: nil
                    )
                    Logger.error("Can't encode Member.Status with case .unknown")
                    throw error
            }
        }
    }
    
    /// The type of account the membership represents.
    public enum AccountType: Decodable, Equatable {
        /// Indicates that the account linked to the Member is a user.
        case user
        
        /// Indicates that the account linked to the Member
        /// is a Service Account.
        case serviceAccount
        
        /// The account type received for the member was unknown.
        /// Added for backwards compatibility in case a new status
        /// is added on the backend, and not yet added to this client library.
        case unknown(value: String)
        
        public init(from decoder: Decoder) throws {
            let str = try decoder.singleValueContainer().decode(String.self)
            
            switch str {
                case "USER"            : self = .user
                case "SERVICE_ACCOUNT" : self = .serviceAccount
                default                : self = .unknown(value: str)
            }
        }
    }
    
    
    private enum CodingKeys: String, CodingKey {
        case resourceName = "name"
        case displayName
        case roles
        case status
        case email
        case accountType
        case createTime
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // A `Member` can either belong to a project or an organization. As such,
        // the resource name can either have the format "organizations/<org_id>/members/<member_id>"
        // or "projects/<project_id>/members/<member_id>".
        let resourceName = try container.decode(String.self, forKey: .resourceName)
        let resourceNameParts = resourceName.components(separatedBy: "/")
        guard resourceNameParts.count == 4 else {
            throw ParseError.identifier(resourceName: resourceName)
        }
        self.identifier = resourceNameParts[3]
        if resourceNameParts[0] == "organizations" {
            self.projectID = nil
            self.organizationID = resourceNameParts[1]
        } else if resourceNameParts[0] == "projects" {
            self.projectID = resourceNameParts[1]
            self.organizationID = nil
        } else {
            throw ParseError.identifier(resourceName: resourceName)
        }
        
        self.displayName    = try container.decode(String.self,          forKey: .displayName)
        self.roles          = try container.decode([Role.RoleType].self, forKey: .roles)
        self.status         = try container.decode(Status.self,          forKey: .status)
        self.email          = try container.decode(String.self,          forKey: .email)
        self.accountType    = try container.decode(AccountType.self,     forKey: .accountType)
        
        // Extract the timestamp
        let timeString      = try container.decode(String.self, forKey: .createTime)
        self.createTime     = try Date(iso8601String: timeString)
    }
}
