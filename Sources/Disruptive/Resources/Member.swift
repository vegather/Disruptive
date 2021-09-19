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
     `getMembersPage` function instead.
     
     - Parameter organizationID: The identifier of the organization to get Members for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Member`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Member], DisruptiveError>`
     */
    public static func getMembers(
        organizationID : String,
        completion     : @escaping (_ result: Result<[Member], DisruptiveError>) -> ())
    {
        getMembers(endpoint: "organizations/\(organizationID)/members") { completion($0) }
    }
    
    /**
     Gets all the Members for a specific project.
     
     This will handle pagination automatically and send multiple network requests in
     the background if necessary. If a lot of Members are expected to be in the project,
     it might be better to load pages of Members as they're needed using the
     `getMembersPage` function instead.
     
     - Parameter projectID: The identifier of the project to get Members for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Member`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Member], DisruptiveError>`
     */
    public static func getMembers(
        projectID  : String,
        completion : @escaping (_ result: Result<[Member], DisruptiveError>) -> ())
    {
        getMembers(endpoint: "projects/\(projectID)/members") { completion($0) }
    }
    
    // Helper function to get Members for either Projects or Organizations.
    private static func getMembers(
        endpoint   : String,
        completion : @escaping (_ result: Result<[Member], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: endpoint)
        
        // Send the request
        request.send(pagingKey: "members") { completion($0) }
    }
    
    
    
    /**
     Gets one page of Members for a specific organization.
     
     Useful if a lot of Members are expected in the specified organization. This function
     provides better control for when to get Members and how many to get at a time so
     that Members are only fetch when they are needed. This can also improve performance,
     at a cost of convenience compared to the `getMembers` function.
     
     - Parameter organizationID: The identifier of the organization to get Members from.
     - Parameter pageSize: The maximum number of Members to get for this page. The maximum page size is 100, which is also the default.
     - Parameter pageToken: The token of the page to get. For the first page, set this to `nil`. For subsequent pages, use the `nextPageToken` received when getting the previous page.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain a tuple with both an array of `Member`s, as well as the token for the next page. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<(nextPageToken: String?, members: [Member]), DisruptiveError>`
     */
    public static func getMembersPage(
        organizationID : String,
        pageSize   : Int = 100,
        pageToken  : String?,
        completion : @escaping (_ result: Result<(nextPageToken: String?, members: [Member]), DisruptiveError>) -> ())
    {
        getMembersPage(endpoint: "organizations/\(organizationID)/members", pageSize: pageSize, pageToken: pageToken) { completion($0) }
    }
    
    /**
     Gets one page of Members for a specific project.
     
     Useful if a lot of Members are expected in the specified project. This function
     provides better control for when to get Members and how many to get at a time so
     that Members are only fetch when they are needed. This can also improve performance,
     at a cost of convenience compared to the `getMembers` function.
     
     - Parameter projectID: The identifier of the project to get Members from.
     - Parameter pageSize: The maximum number of Members to get for this page. The maximum page size is 100, which is also the default.
     - Parameter pageToken: The token of the page to get. For the first page, set this to `nil`. For subsequent pages, use the `nextPageToken` received when getting the previous page.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain a tuple with both an array of `Member`s, as well as the token for the next page. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<(nextPageToken: String?, members: [Member]), DisruptiveError>`
     */
    public static func getMembersPage(
        projectID  : String,
        pageSize   : Int = 100,
        pageToken  : String?,
        completion : @escaping (_ result: Result<(nextPageToken: String?, members: [Member]), DisruptiveError>) -> ())
    {
        getMembersPage(endpoint: "projects/\(projectID)/members", pageSize: pageSize, pageToken: pageToken) { completion($0) }
    }
    
    // Helper function to get a Members page for either Projects or Organizations.
    private static func getMembersPage(
        endpoint   : String,
        pageSize   : Int = 100,
        pageToken  : String?,
        completion : @escaping (_ result: Result<(nextPageToken: String?, members: [Member]), DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: endpoint)
        
        // Send the request
        request.send(pageSize: pageSize, pageToken: pageToken, pagingKey: "members") { (result: Result<PagedResult<Member>, DisruptiveError>) in
            switch result {
                case .success(let page) : completion(.success((nextPageToken: page.nextPageToken, members: page.results)))
                case .failure(let err)  : completion(.failure(err))
            }
        }
    }
    
    
    
    /**
     Gets a specific Member within an organization by its identifier.
     
     - Parameter organizationID: The identifier of the organization to get the Member from.
     - Parameter memberID: The identifier of the Member to get within the specific organization.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Member`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Member, DisruptiveError>`
     */
    public static func getMember(
        organizationID : String,
        memberID       : String,
        completion     : @escaping (_ result: Result<Member, DisruptiveError>) -> ())
    {
        getMember(endpoint: "organizations/\(organizationID)/members/\(memberID)") { completion($0) }
    }
    
    /**
     Gets a specific Member within a project by its identifier.
     
     - Parameter projectID: The identifier of the project to get the Member from.
     - Parameter memberID: The identifier of the Member to get within the specific project.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Member`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Member, DisruptiveError>`
     */
    public static func getMember(
        projectID  : String,
        memberID   : String,
        completion : @escaping (_ result: Result<Member, DisruptiveError>) -> ())
    {
        getMember(endpoint: "projects/\(projectID)/members/\(memberID)") { completion($0) }
    }
    
    // Helper function to get a specific Member in either a Project or an Organization.
    private static func getMember(
        endpoint   : String,
        completion : @escaping (_ result: Result<Member, DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: endpoint)
        
        // Send the request
        request.send() { completion($0) }
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
    public static func inviteMember(
        organizationID : String,
        roles          : [Role.RoleType],
        email          : String,
        completion     : @escaping (_ result: Result<Member, DisruptiveError>) -> ())
    {
        inviteMember(
            endpoint: "organizations/\(organizationID)/members",
            roles: roles,
            email: email
        ) { completion($0) }
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
    public static func inviteMember(
        projectID  : String,
        roles      : [Role.RoleType],
        email      : String,
        completion : @escaping (_ result: Result<Member, DisruptiveError>) -> ())
    {
        inviteMember(
            endpoint: "projects/\(projectID)/members",
            roles: roles,
            email: email
        ) { completion($0) }
    }
    
    // Helper function to invite Members to either Projects or Organizations.
    private static func inviteMember(
        endpoint   : String,
        roles      : [Role.RoleType],
        email      : String,
        completion : @escaping (_ result: Result<Member, DisruptiveError>) -> ())
    {
        // Prepare the payload
        struct MemberPayload: Encodable {
            let roles: [Role.RoleType]
            let email: String
        }
        let payload = MemberPayload(roles: roles, email: email)
        
        do {
            // Create the request
            let request = try Request(method: .post, baseURL: Disruptive.baseURL, endpoint: endpoint, body: payload)
            
            // Send the request
            request.send() { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to init create member request with payload \(payload). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? DisruptiveError(type: .unknownError, message: "", helpLink: nil)))
        }
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
//    public func updateMember(
//        organizationID : String,
//        memberID       : String,
//        roles          : [Role.RoleType],
//        completion     : @escaping (_ result: Result<Member, DisruptiveError>) -> ())
//    {
//        updateMember(
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
    public static func updateMember(
        projectID   : String,
        memberID    : String,
        roles       : [Role.RoleType],
        completion  : @escaping (_ result: Result<Member, DisruptiveError>) -> ())
    {
        updateMember(
            endpoint    : "projects/\(projectID)/members/\(memberID)",
            roles       : roles
        ) { completion($0) }
    }

    // TODO: Add back displayName and/or status if they're committed to be modifiable.
    private static func updateMember(
        endpoint    : String,
        roles       : [Role.RoleType],
        completion  : @escaping (_ result: Result<Member, DisruptiveError>) -> ())
    {
        struct MemberPatch: Encodable {
            var displayName: String
            var roles: [Role.RoleType]
            var status: Member.Status
        }

        // Prepare the payload
        // Due to some bugs on the backend, the patch body has to include all the fields,
        // and the `roles` field has to contain exactly one element. Only the fields in the
        // `updateMask` will actually be modified.
        var patch = MemberPatch(displayName: "", roles: [.projectUser], status: .pending)
        var updateMask = [String]()

        patch.roles = roles
        updateMask.append("roles")
        
        
        // At least one of the fields has to be set so that `updateMask` is non-empty
        if updateMask.count == 0 {
            let error = DisruptiveError(
                type: .badRequest,
                message: "No roles set",
                helpLink: nil
            )
            Disruptive.log("At least one of the fields in `updateMember` has to be set", level: .error)
            completion(.failure(error))
            return
        }

        do {
            // Create the request
            let params = ["update_mask": [updateMask.joined(separator: ",")]]
            let request = try Request(method: .patch, baseURL: Disruptive.baseURL, endpoint: endpoint, params: params, body: patch)

            // Send the request
            request.send() { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to init updateMember request with payload: \(patch). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? DisruptiveError(type: .unknownError, message: "", helpLink: nil)))
        }
    }
    
    
    /**
     Deletes a member from an organization.
     
     - Parameter organizationID: The identifier of the organization the member is a part of.
     - Parameter memberID: The identifier of the member to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public static func deleteMember(
        organizationID  : String,
        memberID        : String,
        completion      : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        deleteMember(endpoint: "organizations/\(organizationID)/members/\(memberID)") { completion($0) }
    }
    
    /**
     Deletes a member from a project.
     
     - Parameter projectID: The identifier of the project the member is a part of.
     - Parameter memberID: The identifier of the member to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public static func deleteMember(
        projectID  : String,
        memberID   : String,
        completion : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        deleteMember(endpoint: "projects/\(projectID)/members/\(memberID)") { completion($0) }
    }
    
    private static func deleteMember(
        endpoint   : String,
        completion : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .delete, baseURL: Disruptive.baseURL, endpoint: endpoint)
        
        // Send the request
        request.send() { completion($0) }
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
    public static func getMemberInviteURL(
        organizationID  : String,
        memberID        : String,
        completion      : @escaping (_ result: Result<URL, DisruptiveError>) -> ())
    {
        getMemberInviteURL(endpoint: "organizations/\(organizationID)/members/\(memberID):getInviteUrl") { completion($0) }
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
    public static func getMemberInviteURL(
        projectID  : String,
        memberID   : String,
        completion : @escaping (_ result: Result<URL, DisruptiveError>) -> ())
    {
        getMemberInviteURL(endpoint: "projects/\(projectID)/members/\(memberID):getInviteUrl") { completion($0) }
    }
    
    private static func getMemberInviteURL(
        endpoint   : String,
        completion : @escaping (_ result: Result<URL, DisruptiveError>) -> ())
    {
        struct InviteURLResponse: Decodable {
            let inviteUrl: String
        }
        
        // Create the request
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: endpoint)
        
        // Send the request
        request.send() { (result: Result<InviteURLResponse, DisruptiveError>) in
            switch result {
                case .success(let response):
                    if let url = URL(string: response.inviteUrl) {
                        completion(.success(url))
                    } else {
                        let error = DisruptiveError(
                            type: .unknownError,
                            message: "Unknown error",
                            helpLink: nil
                        )
                        Disruptive.log("Failed to convert the inviteUrl response to a URL: \(response.inviteUrl)", level: .error)
                        completion(.failure(error))
                    }
                case .failure(let err):
                    completion(.failure(err))
            }
        }
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
                    Disruptive.log("Can't encode Member.Status with case .unknown", level: .error)
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
        
        // When a new Member is created, the `createTime` field comes back as `null`.
        // This will replace that with the current timestamp (even though it's slightly wrong).
        // TODO: Remove this workaround if a fix is deployed to the backend.
        if let createTimestamp = try container.decodeIfPresent(String.self, forKey: .createTime) {
            self.createTime = try Date(iso8601String: createTimestamp)
        } else if try container.decodeNil(forKey: .createTime) {
            self.createTime = Date()
        } else {
            throw ParseError.dateFormat(date: "")
        }
    }
}
