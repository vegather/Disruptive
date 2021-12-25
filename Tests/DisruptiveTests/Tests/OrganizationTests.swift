//
//  OrganizationTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 22/11/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class OrganizationTests: DisruptiveTests {
    
    func testDecodeOrganization() {
        let orgIn = createDummyOrganization()
        let orgOut = try! JSONDecoder().decode(Organization.self, from: createOrganizationJSON(from: orgIn))
        
        XCTAssertEqual(orgIn, orgOut)
    }
    
    func testGetOrganizations() async throws {
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("organizations")
        
        let respOrgs = [createDummyOrganization(), createDummyOrganization()]
        let respData = createOrganizationsJSON(from: respOrgs)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for    : request,
                method : "GET",
                url    : reqURL
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let orgs = try await Organization.getAll()
        XCTAssertEqual(orgs, respOrgs)
    }
    
    func testGetOrganizationsPage() async throws {
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("organizations")
        
        let respOrgs = [createDummyOrganization(), createDummyOrganization()]
        let respData = createOrganizationsJSON(from: respOrgs, nextPageToken: "nextToken")
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for         : request,
                method      : "GET",
                queryParams : ["page_size": ["2"], "page_token": ["token"]],
                url         : reqURL
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let page = try await Organization.getPage(pageSize: 2, pageToken: "token")
        XCTAssertEqual(page.nextPageToken, "nextToken")
        XCTAssertEqual(page.organizations, respOrgs)
    }
    
    func testGetOrganization() async throws {
        let orgID = "dummy"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("organizations/\(orgID)")
        
        let respOrg = createDummyOrganization()
        let respData = createOrganizationJSON(from: respOrg)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for    : request,
                method : "GET",
                url    : reqURL
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let org = try await Organization.get(organizationID: orgID)
        XCTAssertEqual(org, respOrg)
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
