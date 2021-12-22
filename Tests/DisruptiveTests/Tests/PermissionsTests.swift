//
//  PermissionsTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 24/11/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class PermissionsTests: DisruptiveTests {
    
    func testDecodePermission() {
        let permission = "\"project.create\"".data(using: .utf8)!
        let wrapper = try! JSONDecoder().decode(PermissionWrapper.self, from: permission)
        XCTAssertEqual(wrapper.permission, Permission.projectCreate)
    }
    
    func testDecodePermissionFail() {
        let notActualPermission = "\"project.crate\"".data(using: .utf8)!
        var wrapper = try! JSONDecoder().decode(PermissionWrapper.self, from: notActualPermission)
        XCTAssertNil(wrapper.permission)
        
        let notEvenAString = "42".data(using: .utf8)!
        wrapper = try! JSONDecoder().decode(PermissionWrapper.self, from: notEvenAString)
        XCTAssertNil(wrapper.permission)
    }
    
    func testGetPermissionsForOrganization() async throws {
        let reqOrgID = "org1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("organizations/\(reqOrgID)/permissions")
        
        let respPermissions: [Permission] = [.organizationRead, .organizationUpdate]
        let respData = createPermissionsJSON(from: respPermissions)
        
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
        
        let perms = try await Permission.getAll(organizationID: reqOrgID)
        XCTAssertEqual(perms, respPermissions)
    }
    
    func testGetPermissionsForProject() async throws {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/permissions")
        
        let respPermissions: [Permission] = [.projectRead, .projectCreate]
        let respData = createPermissionsJSON(from: respPermissions)
        
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
        
        let perms = try await Permission.getAll(projectID: reqProjectID)
        XCTAssertEqual(perms, respPermissions)
    }
}



// -------------------------------
// MARK: Helpers
// -------------------------------

extension PermissionsTests {
    
    private func createPermissionJSONString(from permission: Permission) -> String {
        return "\"\(permission.rawValue)\""
    }
    
    fileprivate func createPermissionsJSON(from permissions: [Permission]) -> Data {
        return """
        {
            "permissions": [
                \(permissions.map({ createPermissionJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": ""
        }
        """.data(using: .utf8)!
    }
}
