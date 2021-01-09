//
//  PermissionsTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 24/11/2020.
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
    
    func testGetPermissionsForOrganization() {
        let reqOrgID = "org1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.getPermissions(forOrganizationID: reqOrgID) { result in
            switch result {
                case .success(let orgs):
                    XCTAssertEqual(orgs, respPermissions)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetPermissionsForProject() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.getPermissions(forProjectID: reqProjectID) { result in
            switch result {
                case .success(let orgs):
                    XCTAssertEqual(orgs, respPermissions)
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
