//
//  ProjectTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 21/11/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class ProjectTests: DisruptiveTests {
    
    func testDecodeProject() {
        let projectIn = createDummyProject()
        let projectOut = try! JSONDecoder().decode(Project.self, from: createProjectJSON(from: projectIn))
        
        XCTAssertEqual(projectIn, projectOut)
    }
    
    
    
    func testGetProjects() async throws {
        let reqOrgID = "abc"
        let reqQuery = "dummy"
        let reqParams = ["organization": [reqOrgID], "query": [reqQuery]]
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!.appendingPathComponent("projects")
        
        let respProjects = [createDummyProject(), createDummyProject()]
        let respData = createProjectsJSON(from: respProjects)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : reqParams,
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let projectsOut = try await Project.getAll(organizationID: reqOrgID, query: reqQuery)
        XCTAssertEqual(projectsOut, respProjects)
    }
    
    func testGetProjectsPage() async throws {
        let reqOrgID = "abc"
        let reqQuery = "dummy"
        let reqParams = ["organization": [reqOrgID], "query": [reqQuery], "page_size": ["2"], "page_token": ["token"]]
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!.appendingPathComponent("projects")
        
        let respProjects = [createDummyProject(), createDummyProject()]
        let respData = createProjectsJSON(from: respProjects, nextPageToken: "nextToken")
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : reqParams,
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let page = try await Project.getPage(organizationID: reqOrgID, query: reqQuery, pageSize: 2, pageToken: "token")
        XCTAssertEqual(page.nextPageToken, "nextToken")
        XCTAssertEqual(page.projects, respProjects)
    }
    
    func testGetProject() async throws {
        let reqProjectID = "abc"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)")
        
        let respProject = createDummyProject()
        let respData = createProjectJSON(from: respProject)
        
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
        
        let p = try await Project.get(projectID: reqProjectID)
        XCTAssertEqual(p, respProject)
    }
    
    func testCreateProject() async throws {
        let reqOrgID = "abc"
        let reqDisplayName = "dummy"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!.appendingPathComponent("projects")
        let reqBody = try! JSONEncoder().encode([
            "displayName": reqDisplayName,
            "organization": "organizations/\(reqOrgID)"
        ])
        
        let respProject = createDummyProject()
        let respData = createProjectJSON(from: respProject)
        
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
                
        let p = try await Project.create(organizationID: reqOrgID, displayName: reqDisplayName)
        XCTAssertEqual(p, respProject)
    }
    
    func testDeleteProject() async throws {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)")
        
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
        
        try await Project.delete(projectID: reqProjectID)
    }
    
    func testUpdateProjectDisplayName() async throws {
        let reqProjectID = "abc"
        let reqDisplayName = "dummy"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)")
        let reqBody = try! JSONEncoder().encode([
            "displayName": reqDisplayName,
        ])
        
        let respProject = createDummyProject()
        let respData = createProjectJSON(from: respProject)
        
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
        
        let p = try await Project.updateDisplayName(projectID: reqProjectID, newDisplayName: reqDisplayName)
        XCTAssertEqual(p, respProject)
    }
}



// -------------------------------
// MARK: Helpers
// -------------------------------

extension ProjectTests {
    
    private func createProjectJSONString(from project: Project) -> String {
        return """
            {
              "name": "projects/\(project.identifier)",
              "displayName": "\(project.displayName)",
              "inventory": \(project.isInventory),
              "organization": "organizations/\(project.organizationID)",
              "organizationDisplayName": "\(project.organizationDisplayName)",
              "sensorCount": \(project.sensorCount),
              "cloudConnectorCount": \(project.cloudConnectorCount)
            }
        """
    }
    
    fileprivate func createProjectJSON(from project: Project) -> Data {
        return createProjectJSONString(from: project).data(using: .utf8)!
    }
    
    fileprivate func createProjectsJSON(from projects: [Project], nextPageToken: String = "") -> Data {
        return """
        {
            "projects": [
                \(projects.map({ createProjectJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": "\(nextPageToken)"
        }
        """.data(using: .utf8)!
    }
    
    fileprivate func createDummyProject() -> Project {
        return Project(
            identifier              : "b7s3e550fee000ba5dhg",
            displayName             : "Vaskebakken 45, 4. etasje",
            isInventory             : true,
            organizationID          : "b8ntihoaplm0028st07g",
            organizationDisplayName : "Disruptive Technologies",
            sensorCount             : 6,
            cloudConnectorCount     : 9
        )
    }
}
