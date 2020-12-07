//
//  DataConnectorTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 02/12/2020.
//

import XCTest
@testable import Disruptive

class DataConnectorTests: DisruptiveTests {
    
    func testDecodeDataConnector() {
        let dcIn = createDummyDataConnector()
        let dcOut = try! JSONDecoder().decode(DataConnector.self, from: createDataConnectorJSON(from: dcIn))
        
        XCTAssertEqual(dcIn, dcOut)
    }
    
    func testDecodeMetrics() {
        let metricsData = """
        {
          "metrics": {
            "successCount": 526,
            "errorCount": 0,
            "latency99p": "0.239s"
          }
        }
        """.data(using: .utf8)!
        
        let decoded = try! JSONDecoder().decode(DataConnector.Metrics.self, from: metricsData)
        
        XCTAssertEqual(decoded.successCount, 526)
        XCTAssertEqual(decoded.errorCount, 0)
        XCTAssertEqual(decoded.latency99p, 0.239)
    }
    
    func testDecodeStatus() {
        struct StatusContainer: Decodable, Equatable {
            let status: DataConnector.Status
        }
        
        XCTAssertEqual(
            StatusContainer(status: .active),
            try! JSONDecoder().decode(StatusContainer.self, from: "{\"status\": \"ACTIVE\"}".data(using: .utf8)!)
        )
        XCTAssertEqual(
            StatusContainer(status: .deactivated),
            try! JSONDecoder().decode(StatusContainer.self, from: "{\"status\": \"DEACTIVATED\"}".data(using: .utf8)!)
        )
        XCTAssertEqual(
            StatusContainer(status: .deactivated),
            try! JSONDecoder().decode(StatusContainer.self, from: "{\"status\": \"USER_DISABLED\"}".data(using: .utf8)!)
        )
        XCTAssertEqual(
            StatusContainer(status: .systemDisabled),
            try! JSONDecoder().decode(StatusContainer.self, from: "{\"status\": \"SYSTEM_DISABLED\"}".data(using: .utf8)!)
        )
    }
    
    func testGetDataConnectors() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/dataconnectors")
        
        let respDCs = [createDummyDataConnector(), createDummyDataConnector()]
        let respData = createDataConnectorsJSON(from: respDCs)
        
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
        disruptive.getDataConnectors(projectID: reqProjectID) { result in
            switch result {
                case .success(let dcs):
                    XCTAssertEqual(dcs, respDCs)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetDataConnector() {
        let reqDcID = "dc1"
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/dataconnectors/\(reqDcID)")
        
        let respDC = createDummyDataConnector()
        let respData = createDataConnectorJSON(from: respDC)
        
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
        disruptive.getDataConnector(projectID: reqProjectID, dataConnectorID: reqDcID) { result in
            switch result {
                case .success(let dc):
                    XCTAssertEqual(dc, respDC)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testCreateDataConnector() {
        let reqProjectID = "proj1"
        let reqDisplayName = "disp_name"
        let reqPushURL = "dummyURL"
        let reqPushSecret = "dummySecret"
        let reqPushHeaders = ["foo": "bar"]
        let reqPushType = DataConnector.PushType.httpPush(url: reqPushURL, signatureSecret: reqPushSecret, headers: reqPushHeaders)
        let reqEventTypes = [EventType.temperature, .batteryStatus, .networkStatus]
        let reqLabels = ["building_nr"]
        let reqStatus = DataConnector.Status.deactivated
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/dataconnectors")
        let reqBody = """
        {
          "displayName": "\(reqDisplayName)",
          "events": [\(reqEventTypes.map { "\"\($0.rawValue)\"" }.joined(separator: ","))],
          "labels": [\(reqLabels    .map { "\"\($0)\"" }         .joined(separator: ","))],
          "type": "HTTP_PUSH",
          "status": "\(reqStatus.rawValue)",
          "httpConfig": {
            "url": "\(reqPushURL)",
            "signatureSecret": "\(reqPushSecret)",
            "headers": {
              \(reqPushHeaders.map { key, value in "\"\(key)\": \"\(value)\"" }.joined(separator: ","))
            }
          }
        }
        """.data(using: .utf8)!
        
        
        let respDC = DataConnector(
            identifier  : "dummy_identifier",
            projectID   : reqProjectID,
            pushType    : reqPushType,
            displayName : reqDisplayName,
            status      : reqStatus,
            events      : reqEventTypes,
            labels      : reqLabels
        )
        let respData = createDataConnectorJSON(from: respDC)
        
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
        disruptive.createDataConnector(
            projectID   : reqProjectID,
            displayName : reqDisplayName,
            pushType    : reqPushType,
            eventTypes  : reqEventTypes,
            labels      : reqLabels,
            isActive    : reqStatus == .active)
        { result in
            switch result {
                case .success(let dc):
                    XCTAssertEqual(dc, respDC)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testUpdateDataConnectorAllParametersSet() {
        let reqProjectID = "proj1"
        let reqDcID = "dc1"
        let reqDisplayName = "disp_name"
        let reqPushURL = "dummyURL"
        let reqPushSecret = "dummySecret"
        let reqPushHeaders = ["foo": "bar"]
        let reqPushType = DataConnector.PushType.httpPush(url: reqPushURL, signatureSecret: reqPushSecret, headers: reqPushHeaders)
        let reqEventTypes = [EventType.temperature, .batteryStatus, .networkStatus]
        let reqLabels = ["building_nr"]
        let reqStatus = DataConnector.Status.deactivated
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/dataconnectors/\(reqDcID)")
        let reqBody = """
        {
          "displayName": "\(reqDisplayName)",
          "events": [\(reqEventTypes.map { "\"\($0.rawValue)\"" }.joined(separator: ","))],
          "labels": [\(reqLabels    .map { "\"\($0)\"" }         .joined(separator: ","))],
          "status": "\(reqStatus.rawValue)",
          "httpConfig": {
            "url": "\(reqPushURL)",
            "signatureSecret": "\(reqPushSecret)",
            "headers": {
              \(reqPushHeaders.map { key, value in "\"\(key)\": \"\(value)\"" }.joined(separator: ","))
            }
          }
        }
        """.data(using: .utf8)!
        
        
        let respDC = DataConnector(
            identifier  : reqDcID,
            projectID   : reqProjectID,
            pushType    : reqPushType,
            displayName : reqDisplayName,
            status      : reqStatus,
            events      : reqEventTypes,
            labels      : reqLabels
        )
        let respData = createDataConnectorJSON(from: respDC)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "PATCH",
                queryParams   : ["update_mask": ["displayName,httpConfig.url,httpConfig.signatureSecret,httpConfig.headers,status,events,labels"]],
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.updateDataConnector(
            projectID       : reqProjectID,
            dataConnectorID : reqDcID,
            displayName     : reqDisplayName,
            httpPush        : (url: reqPushURL, signatureSecret: reqPushSecret, headers: reqPushHeaders),
            isActive        : reqStatus == .active,
            eventTypes      : reqEventTypes,
            labels          : reqLabels)
        { result in
            switch result {
                case .success(let dc):
                    XCTAssertEqual(dc, respDC)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testUpdateDataConnectorNoParametersSet() {
        let reqProjectID = "proj1"
        let reqDcID = "dc1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/dataconnectors/\(reqDcID)")
        let reqBody = """
        { }
        """.data(using: .utf8)!
        
        
        let respDC = DataConnector(
            identifier  : reqDcID,
            projectID   : reqProjectID,
            pushType    : .httpPush(url: "", signatureSecret: "", headers: [:]),
            displayName : "",
            status      : .active,
            events      : [],
            labels      : []
        )
        let respData = createDataConnectorJSON(from: respDC)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "PATCH",
                queryParams   : ["update_mask": [""]],
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.updateDataConnector(
            projectID       : reqProjectID,
            dataConnectorID : reqDcID)
        { result in
            switch result {
                case .success(let dc):
                    XCTAssertEqual(dc, respDC)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testDeleteDataConnector() {
        let reqDcID = "dc1"
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/dataconnectors/\(reqDcID)")
                
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
        disruptive.deleteDataConnector(projectID: reqProjectID, dataConnectorID: reqDcID) { result in
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
    
    func testGetDataConnectorMetrics() {
        let reqDcID = "dc1"
        let reqProjectID = "proj1"
        let reqSuccess = 455
        let reqError = 1
        let reqLatency = 0.123
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/dataconnectors/\(reqDcID):metrics")
        
        let respData = """
        {
          "metrics": {
            "successCount": \(reqSuccess),
            "errorCount": \(reqError),
            "latency99p": "\(reqLatency)s"
          }
        }
        """.data(using: .utf8)!
        
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
        disruptive.getDataConnectorMetrics(projectID: reqProjectID, dataConnectorID: reqDcID) { result in
            switch result {
                case .success(let metrics):
                    XCTAssertEqual(metrics.successCount, reqSuccess)
                    XCTAssertEqual(metrics.errorCount, reqError)
                    XCTAssertEqual(metrics.latency99p, TimeInterval(reqLatency))
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testSyncDataConnector() {
        let reqDcID = "dc1"
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/dataconnectors/\(reqDcID):sync")
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "POST",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.syncDataConnector(projectID: reqProjectID, dataConnectorID: reqDcID) { result in
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
}



// -------------------------------
// MARK: Helpers
// -------------------------------

extension DataConnectorTests {
    
    // Only supports HTTP_PUSH data connectors for now
    private func createDataConnectorJSONString(from dc: DataConnector) -> String {
        guard case let .httpPush(url, secret, headers) = dc.pushType else { fatalError() }
        
        return """
        {
            "name": "projects/\(dc.projectID)/dataconnectors/\(dc.identifier)",
            "displayName": "\(dc.displayName)",
            "status": "\(dc.status.rawValue)",
            "events": [\(dc.events.map({ "\"\($0.rawValue)\"" }).joined(separator: ","))],
            "labels": [\(dc.labels.map({ "\"\($0)\"" }).joined(separator: ","))],
            "type": "HTTP_PUSH",
            "httpConfig": {
                "url": "\(url)",
                "signatureSecret": "\(secret)",
                "headers": {
                  \(headers.map { key, value in "\"\(key)\": \"\(value)\"" }.joined(separator: ","))
                }
            }
        }
        """
    }
    
    private func createDataConnectorJSON(from dc: DataConnector) -> Data {
        return createDataConnectorJSONString(from: dc).data(using: .utf8)!
    }
    
    private func createDataConnectorsJSON(from dcs: [DataConnector]) -> Data {
        return """
        {
            "dataConnectors": [
                \(dcs.map({ createDataConnectorJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": ""
        }
        """.data(using: .utf8)!
    }
    
    fileprivate func createDummyDataConnector() -> DataConnector {
        return DataConnector(
            identifier: "b8n61epb54j0008bnjm0",
            projectID : "b7s3umd0fee000ba5di0",
            pushType: .httpPush(
                url             : "https://dummy.com",
                signatureSecret : "mySecret",
                headers         : ["SomeCustomHeader": "ValueOfCustomHeader"]),
            displayName: "Dummy Data Connector",
            status: .active,
            events: [.temperature, .touch, .networkStatus],
            labels: ["floor", "buildingNumber"]
        )
    }
}
