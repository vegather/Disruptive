//
//  MemberTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 31/12/2020.
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
    
    func testGetProjectMembers() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.getMembers(projectID: reqProjectID) { result in
            switch result {
                case .success(let members):
                    XCTAssertEqual(members, respMembers)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetOrgMembers() {
        let reqOrgID = "org1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.getMembers(organizationID: reqOrgID) { result in
            switch result {
                case .success(let members):
                    XCTAssertEqual(members, respMembers)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetProjectMember() {
        let reqProjectID = "proj1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.getMember(projectID: reqProjectID, memberID: reqMemberID) { result in
            switch result {
                case .success(let member):
                    XCTAssertEqual(member, respMember)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetOrgMember() {
        let reqOrgID = "org1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.getMember(organizationID: reqOrgID, memberID: reqMemberID) { result in
            switch result {
                case .success(let member):
                    XCTAssertEqual(member, respMember)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testInviteProjectMember() {
        let reqProjectID = "proj1"
        let reqRoles = [Role.RoleType.projectUser]
        let reqEmail = "test@dt.com"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.inviteMember(projectID: reqProjectID, roles: reqRoles, email: reqEmail) { result in
            switch result {
                case .success(let member):
                    XCTAssertEqual(member, respMember)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testInviteOrgMember() {
        let reqOrgID = "org1"
        let reqRoles = [Role.RoleType.organizationAdmin]
        let reqEmail = "test@dt.com"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.inviteMember(organizationID: reqOrgID, roles: reqRoles, email: reqEmail) { result in
            switch result {
                case .success(let member):
                    XCTAssertEqual(member, respMember)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testUpdateProjectMember() {
        let reqProjectID = "proj1"
        let reqMemberID = "member1"
        let reqRoles = [Role.RoleType.projectAdmin]
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/members/\(reqMemberID)")
        
        let reqBody = """
        {
            "displayName": "",
            "roles": ["roles/project.admin"],
            "status": "PENDING"
        }
        """.data(using: .utf8)!
        
        let respMember = createDummyMember()
        let respData = createMemberJSON(from: respMember)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "PATCH",
                queryParams   : ["update_mask": ["roles"]],
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.updateMember(projectID: reqProjectID, memberID: reqMemberID, roles: reqRoles) { result in
            switch result {
                case .success(let member):
                    XCTAssertEqual(member, respMember)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testDeleteProjectMember() {
        let reqProjectID = "proj1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.deleteMember(projectID: reqProjectID, memberID: reqMemberID) { result in
            switch result {
                case .success():
                    break
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testDeleteOrgMember() {
        let reqOrgID = "org1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.deleteMember(organizationID: reqOrgID, memberID: reqMemberID) { result in
            switch result {
                case .success():
                    break
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetProjectMemberInviteURL() {
        let reqProjectID = "proj1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/members/\(reqMemberID)")
        
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
        
        let exp = expectation(description: "")
        disruptive.getMemberInviteURL(projectID: reqProjectID, memberID: reqMemberID) { result in
            switch result {
                case .success(let url):
                    XCTAssertEqual(url.absoluteString, respURL)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetOrgMemberInviteURL() {
        let reqOrgID = "org1"
        let reqMemberID = "member1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("organizations/\(reqOrgID)/members/\(reqMemberID)")
        
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
        
        let exp = expectation(description: "")
        disruptive.getMemberInviteURL(organizationID: reqOrgID, memberID: reqMemberID) { result in
            switch result {
                case .success(let url):
                    XCTAssertEqual(url.absoluteString, respURL)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
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
    
    fileprivate func createMembersJSON(from members: [Member]) -> Data {
        return """
        {
            "members": [
                \(members.map({ createMemberJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": ""
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
