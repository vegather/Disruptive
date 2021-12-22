//
//  MemberTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 31/12/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class MemberTests: DisruptiveTests {
    
    func testDecodeMember() {
        let firstData = """
        {
            "name": "projects/proj1/members/member1",
            "displayName": "Member 1",
            "roles": [
                "roles/project.developer"
            ],
            "status": "PENDING",
            "email": "member@dt.com",
            "accountType": "USER",
            "createTime": null
        }
        """.data(using: .utf8)!
        
        let firstMember = try! JSONDecoder().decode(Member.self, from: firstData)
        XCTAssertEqual(firstMember.identifier, "member1")
        XCTAssertEqual(firstMember.projectID, "proj1")
        XCTAssertNil(firstMember.organizationID)
        XCTAssertEqual(firstMember.roles, [Role.RoleType.projectDeveloper])
        XCTAssertEqual(firstMember.status, Member.Status.pending)
        XCTAssertEqual(firstMember.email, "member@dt.com")
        XCTAssertEqual(firstMember.accountType, .user)
        XCTAssertLessThanOrEqual(Date().timeIntervalSince(firstMember.createTime), 1)
        
        
        
        let secondData = """
        {
            "name": "organizations/org1/members/member2",
            "displayName": "Member 1",
            "roles": [
                "roles/organization.admin"
            ],
            "status": "ACCEPTED",
            "email": "member@dt.com",
            "accountType": "SERVICE_ACCOUNT",
            "createTime": "2020-12-30T23:04:16.017228Z"
        }
        """.data(using: .utf8)!
        
        let secondMember = try! JSONDecoder().decode(Member.self, from: secondData)
        XCTAssertEqual(secondMember.identifier, "member2")
        XCTAssertNil(secondMember.projectID)
        XCTAssertEqual(secondMember.organizationID, "org1")
        XCTAssertEqual(secondMember.roles, [Role.RoleType.organizationAdmin])
        XCTAssertEqual(secondMember.status, Member.Status.accepted)
        XCTAssertEqual(secondMember.email, "member@dt.com")
        XCTAssertEqual(secondMember.accountType, .serviceAccount)
        XCTAssertEqual(secondMember.createTime, try! Date(iso8601String: "2020-12-30T23:04:16.017Z"))
    }
    
    func testDecodeStatus() {
        func assert(status: Member.Status, equals input: String) {
            let output = try! JSONDecoder().decode(Member.Status.self, from: "\"\(input)\"".data(using: .utf8)!)
            XCTAssertEqual(status, output)
        }

        assert(status: .pending,  equals: "PENDING")
        assert(status: .accepted, equals: "ACCEPTED")
        assert(status: .unknown(value: "UNKNOWN_STATUS"), equals: "UNKNOWN_STATUS")
    }

    func testEncodeStatus() {
        func assert(status: Member.Status, equals input: String?) {
            if let input = input {
                let encoded = try! JSONEncoder().encode(status)
                XCTAssertEqual("\"\(input)\"", String(data: encoded, encoding: .utf8))
            } else {
                XCTAssertThrowsError(try JSONEncoder().encode(status))
            }
        }

        assert(status: .pending,  equals: "PENDING")
        assert(status: .accepted, equals: "ACCEPTED")
        assert(status: .unknown(value: "UNKNOWN_STATUS"), equals: nil)
    }
    
    func testGetProjectMembers() async throws {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/members")
        
        let respMembers = [createDummyMember(), createDummyMember()]
        let respData = createMembersJSON(from: respMembers)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let members = try await Member.getAll(projectID: reqProjectID)
        XCTAssertEqual(members, respMembers)
    }
    
    func testGetOrgMembers() async throws {
        let reqOrgID = "org1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("organizations/\(reqOrgID)/members")
        
        let respMembers = [createDummyMember(), createDummyMember()]
        let respData = createMembersJSON(from: respMembers)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let members = try await Member.getAll(organizationID: reqOrgID)
        XCTAssertEqual(members, respMembers)
    }
    
    func testGetProjectMembersPage() async throws {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/members")
        
        let respMembers = [createDummyMember(), createDummyMember()]
        let respData = createMembersJSON(from: respMembers, nextPageToken: "nextToken")
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : ["page_size": ["2"], "page_token": ["token"]],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let page = try await Member.getPage(projectID: reqProjectID, pageSize: 2, pageToken: "token")
        XCTAssertEqual(page.nextPageToken, "nextToken")
        XCTAssertEqual(page.members, respMembers)
    }
    
    func testGetOrgMembersPage() async throws {
        let reqOrgID = "org1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("organizations/\(reqOrgID)/members")
        
        let respMembers = [createDummyMember(), createDummyMember()]
        let respData = createMembersJSON(from: respMembers, nextPageToken: "nextToken")
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : ["page_size": ["2"], "page_token": ["token"]],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let page = try await Member.getPage(organizationID: reqOrgID, pageSize: 2, pageToken: "token")
        XCTAssertEqual(page.nextPageToken, "nextToken")
        XCTAssertEqual(page.members, respMembers)
    }
    
    func testGetProjectMember() async throws {
        let reqProjectID = "proj1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/members/\(reqMemberID)")
        
        let respMember = createDummyMember()
        let respData = createMemberJSON(from: respMember)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let member = try await Member.get(projectID: reqProjectID, memberID: reqMemberID)
        XCTAssertEqual(member, respMember)
    }
    
    func testGetOrgMember() async throws {
        let reqOrgID = "org1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("organizations/\(reqOrgID)/members/\(reqMemberID)")
        
        let respMember = createDummyMember()
        let respData = createMemberJSON(from: respMember)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let member = try await Member.get(organizationID: reqOrgID, memberID: reqMemberID)
        XCTAssertEqual(member, respMember)
    }
    
    func testInviteProjectMember() async throws {
        let reqProjectID = "proj1"
        let reqRoles = [Role.RoleType.projectUser]
        let reqEmail = "test@dt.com"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/members")
        
        let reqBody = """
        {
            "roles": ["roles/project.user"],
            "email": "\(reqEmail)"
        }
        """.data(using: .utf8)!
        
        let respMember = createDummyMember()
        let respData = createMemberJSON(from: respMember)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "POST",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let member = try await Member.invite(projectID: reqProjectID, roles: reqRoles, email: reqEmail)
        XCTAssertEqual(member, respMember)
    }
    
    func testInviteOrgMember() async throws {
        let reqOrgID = "org1"
        let reqRoles = [Role.RoleType.organizationAdmin]
        let reqEmail = "test@dt.com"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("organizations/\(reqOrgID)/members")
        
        let reqBody = """
        {
            "roles": ["roles/organization.admin"],
            "email": "\(reqEmail)"
        }
        """.data(using: .utf8)!
        
        let respMember = createDummyMember()
        let respData = createMemberJSON(from: respMember)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "POST",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let member = try await Member.invite(organizationID: reqOrgID, roles: reqRoles, email: reqEmail)
        XCTAssertEqual(member, respMember)
    }
    
    func testUpdateProjectMember() async throws {
        let reqProjectID = "proj1"
        let reqMemberID = "member1"
        let reqRoles = [Role.RoleType.projectAdmin]
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/members/\(reqMemberID)")
        
        let reqBody = """
        {
            "roles": ["roles/project.admin"],
        }
        """.data(using: .utf8)!
        
        let respMember = createDummyMember()
        let respData = createMemberJSON(from: respMember)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "PATCH",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let member = try await Member.update(projectID: reqProjectID, memberID: reqMemberID, roles: reqRoles)
        XCTAssertEqual(member, respMember)
    }
    
    func testDeleteProjectMember() async throws {
        let reqProjectID = "proj1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/members/\(reqMemberID)")
                
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "DELETE",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        try await Member.delete(projectID: reqProjectID, memberID: reqMemberID)
    }
    
    func testDeleteOrgMember() async throws {
        let reqOrgID = "org1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("organizations/\(reqOrgID)/members/\(reqMemberID)")
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "DELETE",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        try await Member.delete(organizationID: reqOrgID, memberID: reqMemberID)
    }
    
    func testGetProjectMemberInviteURL() async throws {
        let reqProjectID = "proj1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/members/\(reqMemberID):getInviteUrl")
        
        let respURL = "https://identity.disruptive-technologies.com/account/invite/foo/bar/?next=https%3A%2F%2Fstudio.disruptive-technologies.com"
        let respData = """
        {
            "inviteUrl": "\(respURL)"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let url = try await Member.getInviteURL(projectID: reqProjectID, memberID: reqMemberID)
        XCTAssertEqual(url.absoluteString, respURL)
    }
    
    func testGetOrgMemberInviteURL() async throws {
        let reqOrgID = "org1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("organizations/\(reqOrgID)/members/\(reqMemberID):getInviteUrl")
        
        let respURL = "https://identity.disruptive-technologies.com/account/invite/foo/bar/?next=https%3A%2F%2Fstudio.disruptive-technologies.com"
        let respData = """
        {
            "inviteUrl": "\(respURL)"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let url = try await Member.getInviteURL(organizationID: reqOrgID, memberID: reqMemberID)
        XCTAssertEqual(url.absoluteString, respURL)
    }
}


// -------------------------------
// MARK: Helpers
// -------------------------------

extension MemberTests {
    
    // Makes a lot of assumptions about the Member returned
    // from `createDummyMember()`
    private func createMemberJSONString(from member: Member) -> String {
        return """
        {
            "name": "projects/proj1/members/member1",
            "displayName": "Member 1",
            "roles": [
                "roles/project.developer"
            ],
            "status": "PENDING",
            "email": "member@dt.com",
            "accountType": "USER",
            "createTime": "\(member.createTime.iso8601String())"
        }
        """
    }
    
    fileprivate func createMemberJSON(from member: Member) -> Data {
        return createMemberJSONString(from: member).data(using: .utf8)!
    }
    
    fileprivate func createMembersJSON(from members: [Member], nextPageToken: String = "") -> Data {
        return """
        {
            "members": [
                \(members.map({ createMemberJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": "\(nextPageToken)"
        }
        """.data(using: .utf8)!
    }
    
    fileprivate func createDummyMember() -> Member {
        return Member(
            identifier     : "member1",
            projectID      : "proj1",
            organizationID : nil,
            displayName    : "Member 1",
            roles          : [.projectDeveloper],
            status         : .pending,
            email          : "member@dt.com",
            accountType    : .user,
            createTime     : Date(timeIntervalSince1970: 1605999873)
        )
    }
}
