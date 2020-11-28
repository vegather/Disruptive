//
//  DeviceTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 21/11/2020.
//

import XCTest
@testable import Disruptive

class DeviceTests: DisruptiveTests {
    
    func testDecodeDevice() {
        let deviceIn = createDummyDevice()
        let deviceOut = try! JSONDecoder().decode(Device.self, from: createDeviceJSON(from: deviceIn))
        
        XCTAssertEqual(deviceIn, deviceOut)
    }
    
    func testGetDevice() {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices/\(reqDeviceID)")
        
        let respDevice = createDummyDevice()
        let respData = createDeviceJSON(from: respDevice)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.getDevice(projectID: reqProjectID, deviceID: reqDeviceID) { result in
            switch result {
                case .success(_):
                    break
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetDeviceLookup() {
        let reqDeviceID = "dev1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/-/devices/\(reqDeviceID)")
        
        let respDevice = createDummyDevice()
        let respData = createDeviceJSON(from: respDevice)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.getDevice(deviceID: reqDeviceID) { result in
            switch result {
                case .success(_):
                    break
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetDevices() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices")
        
        let respDevices = [createDummyDevice(), createDummyDevice()]
        let respData = createDevicesJSON(from: respDevices)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.getDevices(projectID: reqProjectID) { result in
            switch result {
                case .success(let devices):
                    XCTAssertEqual(devices, respDevices)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testUpdateDeviceDisplayName() {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqDisplayName = "Dummy"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:batchUpdate")
        let reqBody = """
        {
            "devices": ["projects/\(reqProjectID)/devices/\(reqDeviceID)"],
            "addLabels": {"name": "\(reqDisplayName)"},
            "removeLabels": []
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "POST",
                queryParams   : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.updateDeviceDisplayName(projectID: reqProjectID, deviceID: reqDeviceID, newDisplayName: reqDisplayName) { result in
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
    
    func testRemoveDeviceLabel() {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqLabelKeyToRemove = "labelKey"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:batchUpdate")
        let reqBody = """
        {
            "devices": ["projects/\(reqProjectID)/devices/\(reqDeviceID)"],
            "addLabels": {},
            "removeLabels": ["\(reqLabelKeyToRemove)"]
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "POST",
                queryParams   : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.removeDeviceLabel(projectID: reqProjectID, deviceID: reqDeviceID, labelKey: reqLabelKeyToRemove) { result in
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
    
    func testSetDeviceLabel() {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqLabelKey = "key"
        let reqLabelValue = "value"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:batchUpdate")
        let reqBody = """
        {
            "devices": ["projects/\(reqProjectID)/devices/\(reqDeviceID)"],
            "addLabels": {"\(reqLabelKey)": "\(reqLabelValue)"},
            "removeLabels": []
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "POST",
                queryParams   : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.setDeviceLabel(projectID: reqProjectID, deviceID: reqDeviceID, labelKey: reqLabelKey, labelValue: reqLabelValue) { result in
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
    
    func testBatchUpdateDeviceLabels() {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqLabelKeyToSet = "key"
        let reqLabelValueToSet = "value"
        let reqLabelKeyToRemove = "labelToRemove"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:batchUpdate")
        let reqBody = """
        {
            "devices": ["projects/\(reqProjectID)/devices/\(reqDeviceID)"],
            "addLabels": {"\(reqLabelKeyToSet)": "\(reqLabelValueToSet)"},
            "removeLabels": ["\(reqLabelKeyToRemove)"]
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "POST",
                queryParams   : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.batchUpdateDeviceLabels(projectID: reqProjectID, deviceIDs: [reqDeviceID], labelsToSet: [reqLabelKeyToSet: reqLabelValueToSet], labelsToRemove: [reqLabelKeyToRemove]) { result in
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
    
    func testMoveDevicesByIDs() {
        let reqFromProjectID = "proj1"
        let reqToProjectID = "proj2"
        let reqDeviceIDs = ["dev1", "dev2"]
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqToProjectID)/devices:transfer")
        let reqBody = try! JSONEncoder().encode([
            "devices": reqDeviceIDs.map { "projects/\(reqFromProjectID)/devices/\($0)" }
        ])
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "POST",
                queryParams   : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.moveDevices(deviceIDs: reqDeviceIDs, fromProjectID: reqFromProjectID, toProjectID: reqToProjectID) { result in
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
    
    func testDeviceTypeDisplayName() {
        Device.DeviceType.allCases.forEach {
            XCTAssertTrue($0.displayName().count > 0)
        }
    }
}



// -------------------------------
// MARK: Helpers
// -------------------------------

extension DeviceTests {
    
    private func createDeviceJSONString(from device: Device) -> String {
        return """
        {
          "name": "projects/\(device.projectID)/devices/\(device.identifier)",
          "type": "temperature",
          "labels": {
            "name": "\(device.displayName)"
          },
          "reported": {
            "temperature": {
              "value": \(device.reportedEvents.temperature?.value ?? 0),
              "updateTime": "\(device.reportedEvents.temperature?.timestamp.iso8601String() ?? "-")"
            }
          }
        }
        """
    }
    
    fileprivate func createDeviceJSON(from device: Device) -> Data {
        return createDeviceJSONString(from: device).data(using: .utf8)!
    }
    
    fileprivate func createDevicesJSON(from devices: [Device]) -> Data {
        return """
        {
            "devices": [
                \(devices.map({ createDeviceJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": ""
        }
        """.data(using: .utf8)!
    }
    
    fileprivate func createDummyDevice() -> Device {
        var reportedEvents = Device.ReportedEvents()
        reportedEvents.temperature = TemperatureEvent(
            value: 56,
            timestamp: Date(timeIntervalSince1970: 1605999873)
        )
        
        return Device(
            identifier: "b5rj9ed7rihk942p48og",
            displayName: "Dummy project",
            projectID: "b7s3umd0fee000ba5di0",
            labels: ["name": "Dummy project"],
            type: .temperature,
            reportedEvents: reportedEvents
        )
    }
}
