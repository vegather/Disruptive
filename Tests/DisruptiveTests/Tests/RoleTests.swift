//
//  RoleTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 30/11/2020.
//

import XCTest
@testable import Disruptive

class RoleTests: DisruptiveTests {
    
    func testDecodeRole() {
        let roleIn = createDummyRole()
        let roleOut = try! JSONDecoder().decode(Role.self, from: createRoleJSON(from: roleIn))
        
        XCTAssertEqual(roleIn, roleOut)
    }
    
    func testDecodeRoleType() {
        func assert(type: Role.RoleType, equals input: String) {
            XCTAssertEqual(
                type,
                try! JSONDecoder().decode(Role.RoleType.self, from: "\"\(input)\"".data(using: .utf8)!)
            )
        }

        assert(type: .projectUser,       equals: "roles/project.user")
        assert(type: .projectDeveloper,  equals: "roles/project.developer")
        assert(type: .projectAdmin,      equals: "roles/project.admin")
        assert(type: .organizationAdmin, equals: "roles/organization.admin")
        assert(type: .unknown(value: "roles/not.a.role"), equals: "roles/not.a.role")
        
        XCTAssertThrowsError(try JSONDecoder().decode(Role.RoleType.self, from: "\"bad format\"".data(using: .utf8)!))
    }
    
    func testEncodeRoleType() {
        func assert(type: Role.RoleType, equals input: String) {
            XCTAssertEqual(
                "\"\(input)\"".data(using: .utf8)!,
                try! JSONEncoder().encode(type)
            )
        }
        
        // The JSONEncoder will escape the "/"'es, so the result is "roles\/project.user".
        assert(type: .projectUser,       equals: "roles\\/project.user")
        assert(type: .projectDeveloper,  equals: "roles\\/project.developer")
        assert(type: .projectAdmin,      equals: "roles\\/project.admin")
        assert(type: .organizationAdmin, equals: "roles\\/organization.admin")
        
        XCTAssertThrowsError(try JSONEncoder().encode(Role.RoleType.unknown(value: "")))
    }
    
    func testGetRoles() {
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("roles")
        
        let respRoles = [createDummyRole(), createDummyRole()]
        let respData = createRolesJSON(from: respRoles)
        
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
        disruptive.getRoles { result in
            switch result {
                case .success(let roles):
                    XCTAssertEqual(roles, respRoles)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetRole() {
        let roleID = "dummy"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("roles/\(roleID)")
        
        let respRole = createDummyRole()
        let respData = createRoleJSON(from: respRole)
        
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
        disruptive.getRole(roleID: roleID) { result in
            switch result {
                case .success(let role):
                    XCTAssertEqual(role, respRole)
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

extension RoleTests {
    
    // Only supports org admin access level
    private func createRoleJSONString(from role: Role) -> String {
        return """
        {
            "name": "roles/organization.admin",
            "displayName": "\(role.displayName)",
            "description": "\(role.description)",
            "permissions": [\(role.permissions.map { "\"\($0.rawValue)\"" }.joined(separator: ","))]
        }
        """
    }
    
    fileprivate func createRoleJSON(from role: Role) -> Data {
        return createRoleJSONString(from: role).data(using: .utf8)!
    }
    
    fileprivate func createRolesJSON(from roles: [Role]) -> Data {
        return """
        {
            "roles": [
                \(roles.map({ createRoleJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": ""
        }
        """.data(using: .utf8)!
    }
    
    fileprivate func createDummyRole() -> Role {
        return Role(
            accessLevel : .organizationAdmin,
            displayName : "Organization administrator",
            description : "Administrator in organization",
            permissions: [.organizationRead, .organizationUpdate]
        )
    }
}
