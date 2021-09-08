//
//  DataConnectorTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 02/12/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class DataConnectorTests: DisruptiveTests {
    
    func testDecodeDataConnector() {
        let dcIn = createDummyDataConnector()
        let dcOut = try! JSONDecoder().decode(DataConnector.self, from: createDataConnectorJSON(from: dcIn))
        
        XCTAssertEqual(dcIn, dcOut)
    }
    
    func testDecodeDataConnectorUnknownValues() {
        let data = """
        {
            "name": "projects/proj1/dataconnectors/dc1",
            "displayName": "DC",
            "status": "UNKNOWN_DC_STATUS",
            "events": ["temperature", "networkStatus", "unknownEvent"],
            "labels": [],
            "type": "UNKNOWN_PUSH_TYPE"
        }
        """.data(using: .utf8)!
        
        let dc = try! JSONDecoder().decode(DataConnector.self, from: data)
        XCTAssertEqual(dc.status, DataConnector.Status.unknown(value: "UNKNOWN_DC_STATUS"))
        XCTAssertEqual(dc.events, [.temperature, .networkStatus])
        XCTAssertEqual(dc.pushType, .unknown(value: "UNKNOWN_PUSH_TYPE"))
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
        
        let invalidMetricsData = """
        {
          "metrics": {
            "successCount": 526,
            "errorCount": 0,
            "latency99p": "invalid"
          }
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(DataConnector.Metrics.self, from: invalidMetricsData))
    }
    
    func testDecodeStatus() {
        func assert(status: DataConnector.Status, equals input: String) {
            let output = try! JSONDecoder().decode(DataConnector.Status.self, from: "\"\(input)\"".data(using: .utf8)!)
            
            XCTAssertEqual(status, output)
            if case .unknown = output {
                XCTAssertNil(output.rawValue)
            } else {
                XCTAssertNotNil(output.rawValue)
                XCTAssertGreaterThan(output.rawValue!.count, 0)
            }
        }
        
        assert(status: .active, equals: "ACTIVE")
        assert(status: .userDisabled, equals: "USER_DISABLED")
        assert(status: .systemDisabled, equals: "SYSTEM_DISABLED")
        assert(status: .unknown(value: "UNKNOWN_STATUS"), equals: "UNKNOWN_STATUS")
    }
    
    func testEncodeStatus() {
        func assert(status: DataConnector.Status, equals input: String?) {
            if let input = input {
                let encoded = try! JSONEncoder().encode(status)
                XCTAssertEqual("\"\(input)\"", String(data: encoded, encoding: .utf8))
            } else {
                XCTAssertThrowsError(try JSONEncoder().encode(status))
            }
        }
        
        assert(status: .active,         equals: "ACTIVE")
        assert(status: .userDisabled,   equals: "USER_DISABLED")
        assert(status: .systemDisabled, equals: "SYSTEM_DISABLED")
        assert(status: .unknown(value: "UNKNOWN_STATUS"), equals: nil)
    }
    
    func testGetDataConnectors() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
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
        DataConnector.getDataConnectors(projectID: reqProjectID) { result in
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
    
    func testGetDataConnectorsPage() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/dataconnectors")
        
        let respDCs = [createDummyDataConnector(), createDummyDataConnector()]
        let respData = createDataConnectorsJSON(from: respDCs, nextPageToken: "nextToken")
        
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
        DataConnector.getDataConnectorsPage(projectID: reqProjectID, pageSize: 2, pageToken: "token") { result in
            switch result {
                case .success(let page):
                    XCTAssertEqual(page.nextPageToken, "nextToken")
                    XCTAssertEqual(page.dataConnectors, respDCs)
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
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
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
        DataConnector.getDataConnector(projectID: reqProjectID, dataConnectorID: reqDcID) { result in
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
        let reqStatus = DataConnector.Status.userDisabled
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/dataconnectors")
        let reqBody = """
        {
          "displayName": "\(reqDisplayName)",
          "events": [\(reqEventTypes.map { "\"\($0.rawValue)\"" }.joined(separator: ","))],
          "labels": [\(reqLabels    .map { "\"\($0)\"" }         .joined(separator: ","))],
          "type": "HTTP_PUSH",
          "status": "\(reqStatus.rawValue!)",
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
        DataConnector.createDataConnector(
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
        let reqStatus = DataConnector.Status.userDisabled
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/dataconnectors/\(reqDcID)")
        let reqBody = """
        {
          "displayName": "\(reqDisplayName)",
          "events": [\(reqEventTypes.map { "\"\($0.rawValue)\"" }.joined(separator: ","))],
          "labels": [\(reqLabels    .map { "\"\($0)\"" }         .joined(separator: ","))],
          "status": "\(reqStatus.rawValue!)",
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
        DataConnector.updateDataConnector(
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
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
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
        DataConnector.updateDataConnector(
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
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
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
        DataConnector.deleteDataConnector(projectID: reqProjectID, dataConnectorID: reqDcID) { result in
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
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
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
        DataConnector.getDataConnectorMetrics(projectID: reqProjectID, dataConnectorID: reqDcID) { result in
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
        let reqURL = URL(string: Disruptive.DefaultURLs.baseURL)!
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
        DataConnector.syncDataConnector(projectID: reqProjectID, dataConnectorID: reqDcID) { result in
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
            "status": "\(dc.status.rawValue!)",
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
    
    private func createDataConnectorsJSON(from dcs: [DataConnector], nextPageToken: String = "") -> Data {
        return """
        {
            "dataConnectors": [
                \(dcs.map({ createDataConnectorJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": "\(nextPageToken)"
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
