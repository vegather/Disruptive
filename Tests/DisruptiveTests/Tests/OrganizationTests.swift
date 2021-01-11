//
//  OrganizationTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 22/11/2020.
//

import XCTest
@testable import Disruptive

class OrganizationTests: DisruptiveTests {
    
    func testDecodeOrganization() {
        let orgIn = createDummyOrganization()
        let orgOut = try! JSONDecoder().decode(Organization.self, from: createOrganizationJSON(from: orgIn))
        
        XCTAssertEqual(orgIn, orgOut)
    }
    
    func testGetAllOrganizations() {
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("organizations")
        
        let respOrgs = [createDummyOrganization(), createDummyOrganization()]
        let respData = createOrganizationsJSON(from: respOrgs)
        
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
        disruptive.getAllOrganizations { result in
            switch result {
                case .success(let orgs):
                    XCTAssertEqual(orgs, respOrgs)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetOrganizationsPage() {
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("organizations")
        
        let respOrgs = [createDummyOrganization(), createDummyOrganization()]
        let respData = createOrganizationsJSON(from: respOrgs, nextPageToken: "nextToken")
        
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
        
        let exp = expectation(description: "")
        disruptive.getOrganizationsPage(pageSize: 2, pageToken: "token") { result in
            switch result {
                case .success(let page):
                    XCTAssertEqual(page.nextPageToken, "nextToken")
                    XCTAssertEqual(page.organizations, respOrgs)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetOrganization() {
        let orgID = "dummy"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("organizations/\(orgID)")
        
        let respOrg = createDummyOrganization()
        let respData = createOrganizationJSON(from: respOrg)
        
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
        disruptive.getOrganization(organizationID: orgID) { result in
            switch result {
                case .success(let org):
                    XCTAssertEqual(org, respOrg)
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

extension OrganizationTests {
    
    private func createOrganizationJSONString(from org: Organization) -> String {
        return """
        {
            "name": "organizations/\(org.identifier)",
            "displayName": "\(org.displayName)"
        }
        """
    }
    
    fileprivate func createOrganizationJSON(from org: Organization) -> Data {
        return createOrganizationJSONString(from: org).data(using: .utf8)!
    }
    
    fileprivate func createOrganizationsJSON(from orgs: [Organization], nextPageToken: String = "") -> Data {
        return """
        {
            "organizations": [
                \(orgs.map({ createOrganizationJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": "\(nextPageToken)"
        }
        """.data(using: .utf8)!
    }
    
    fileprivate func createDummyOrganization() -> Organization {
        return Organization(
            identifier  : "b5rj9ed7rihk942p48og",
            displayName : "Testing Inc."
        )
    }
}
