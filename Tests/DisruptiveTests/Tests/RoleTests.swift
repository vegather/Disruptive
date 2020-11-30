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
    
    private func createRoleJSONString(from role: Role) -> String {
        return """
        {
            "name": "roles/\(role.identifier)",
            "displayName": "\(role.displayName)",
            "description": "\(role.description)"
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
            identifier  : "organization.admin",
            displayName : "Organization administrator",
            description : "Administrator in organization"
        )
    }
}
