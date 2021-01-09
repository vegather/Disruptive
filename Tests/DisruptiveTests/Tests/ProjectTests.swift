//
//  ProjectTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 21/11/2020.
//

import XCTest
@testable import Disruptive

class ProjectTests: DisruptiveTests {
    
    func testDecodeProject() {
        let projectIn = createDummyProject()
        let projectOut = try! JSONDecoder().decode(Project.self, from: createProjectJSON(from: projectIn))
        
        XCTAssertEqual(projectIn, projectOut)
    }
    
    
    
    func testGetProjects() {
        let reqOrgID = "abc"
        let reqQuery = "dummy"
        let reqParams = ["organization": [reqOrgID], "query": [reqQuery]]
        let reqURL = URL(string: Disruptive.defaultBaseURL)!.appendingPathComponent("projects")
        
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
        
        let exp = expectation(description: "")
        disruptive.getProjects(organizationID: reqOrgID, query: reqQuery) { result in
            switch result {
                case .success(let projectsOut):
                    XCTAssertEqual(projectsOut, respProjects)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetProject() {
        let reqProjectID = "abc"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.getProject(projectID: reqProjectID) { result in
            switch result {
                case .success(let p):
                    XCTAssertEqual(p, respProject)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testCreateProject() {
        let reqOrgID = "abc"
        let reqDisplayName = "dummy"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!.appendingPathComponent("projects")
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
        
        let exp = expectation(description: "")
        disruptive.createProject(organizationID: reqOrgID, displayName: reqDisplayName) { result in
            switch result {
                case .success(let p):
                    XCTAssertEqual(p, respProject)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testDeleteProject() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.deleteProject(projectID: reqProjectID) { result in
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
    
    func testUpdateProjectDisplayName() {
        let reqProjectID = "abc"
        let reqDisplayName = "dummy"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
        
        let exp = expectation(description: "")
        disruptive.updateProjectDisplayName(projectID: reqProjectID, newDisplayName: reqDisplayName) { result in
            switch result {
                case .success(let p):
                    XCTAssertEqual(p, respProject)
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
    
    fileprivate func createProjectsJSON(from projects: [Project]) -> Data {
        return """
        {
            "projects": [
                \(projects.map({ createProjectJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": ""
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
