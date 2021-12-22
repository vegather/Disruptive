//
//  DeviceTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 21/11/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class DeviceTests: DisruptiveTests {
    
    func testDecodeDevice() {
        let deviceIn = DeviceTests.createDummyDevice()
        let deviceOut = try! JSONDecoder().decode(Device.self, from: DeviceTests.createDeviceJSON(from: deviceIn))
        
        XCTAssertEqual(deviceIn, deviceOut)
    }
    
    func testDecodeDeviceWithUnknownValues() {
        let data = """
        {
          "name": "projects/proj1/devices/dev1",
          "type": "unknownDeviceType",
          "labels": {
            "name": "Device"
          },
          "reported": {
            "unknownEvent": {
              "value": "Some Value",
              "updateTime": "\(Date().iso8601String())"
            },
            "temperature": {
              "value": 25,
              "updateTime": "\(Date().iso8601String())",
              "samples": [
                {
                  "value": 24.9,
                  "sampleTime": "2019-05-16T08:15:18.318751Z"
                },
                {
                  "value": 24.2,
                  "sampleTime": "2019-05-16T08:15:13.318751Z"
                },
                {
                  "value": 24.5,
                  "sampleTime": "2019-05-16T08:15:08.318751Z"
                }
              ]
            }
          },
          "productNumber": "102150",
          "unknownKey": "unknownValue"
        }
        """.data(using: .utf8)!
        
        
        XCTAssertNoThrow(try JSONDecoder().decode(Device.self, from: data))
    }
    
    func testDecodeEmulatedDevice() {
        let deviceIn = DeviceTests.createDummyDevice(isEmulated: true)
        let deviceOut = try! JSONDecoder().decode(Device.self, from: DeviceTests.createDeviceJSON(from: deviceIn))
        
        XCTAssertEqual(deviceIn, deviceOut)
    }
    
    func testDecodeDeviceType() {
        func assert(_ str: String, equals type: Device.DeviceType) {
            XCTAssertEqual(
                try! JSONDecoder().decode(Device.DeviceType.self, from: "\"\(str)\"".data(using: .utf8)!),
                type
            )
        }
        
        assert("proximity",        equals: .proximity)
        assert("touch",            equals: .touch)
        assert("temperature",      equals: .temperature)
        assert("proximityCounter", equals: .proximityCounter)
        assert("touchCounter",     equals: .touchCounter)
        assert("humidity",         equals: .humidity)
        assert("ccon",             equals: .cloudConnector)
        assert("waterDetector",    equals: .waterDetector)
        assert("shinyNewSensor",   equals: .unknown(value: "shinyNewSensor"))
    }
    
    func testDeviceTypeRawValue() {
        XCTAssertEqual(Device.DeviceType.proximity         .rawValue, "proximity")
        XCTAssertEqual(Device.DeviceType.touch             .rawValue, "touch")
        XCTAssertEqual(Device.DeviceType.temperature       .rawValue, "temperature")
        XCTAssertEqual(Device.DeviceType.proximityCounter  .rawValue, "proximityCounter")
        XCTAssertEqual(Device.DeviceType.touchCounter      .rawValue, "touchCounter")
        XCTAssertEqual(Device.DeviceType.humidity          .rawValue, "humidity")
        XCTAssertEqual(Device.DeviceType.cloudConnector    .rawValue, "ccon")
        XCTAssertEqual(Device.DeviceType.waterDetector     .rawValue, "waterDetector")
        XCTAssertEqual(Device.DeviceType.unknown(value: "").rawValue, nil)
    }
    
    func testGetDevice() async throws {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices/\(reqDeviceID)")
        
        let respDevice = DeviceTests.createDummyDevice()
        let respData = DeviceTests.createDeviceJSON(from: respDevice)
        
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
        
        let device = try await Device.get(projectID: reqProjectID, deviceID: reqDeviceID)
        XCTAssertEqual(device, respDevice)
    }
    
    func testGetDeviceLookup() async throws {
        let reqDeviceID = "dev1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/-/devices/\(reqDeviceID)")
        
        let respDevice = DeviceTests.createDummyDevice()
        let respData = DeviceTests.createDeviceJSON(from: respDevice)
        
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
        
        let device = try await Device.get(deviceID: reqDeviceID)
        XCTAssertEqual(device, respDevice)
    }
    
    func testGetDevicesNoParameters() async throws {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices")
        
        let respDevices = [DeviceTests.createDummyDevice(), DeviceTests.createDummyDevice()]
        let respData = DeviceTests.createDevicesJSON(from: respDevices)
        
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
        
        let devices = try await Device.getAll(projectID: reqProjectID)
        XCTAssertEqual(devices, respDevices)
    }
    
    func testGetDevicesAllParameters() async throws {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices")
        let reqParams: [String: [String]] = [
            "query"           : ["search query"],
            "device_ids"      : ["dev1", "dev2"],
            "device_types"    : ["humidity", "touch"],
            "product_numbers" : ["pn1", "pn2"],
            "label_filters"   : ["key1=value1", "key2=value2"],
            "order_by"        : ["-reported.temperature.value"]
        ]
        
        let respDevices = [DeviceTests.createDummyDevice(), DeviceTests.createDummyDevice()]
        let respData = DeviceTests.createDevicesJSON(from: respDevices)
        
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
        
        let devices = try await Device.getAll(
            projectID   : reqProjectID,
            query       : "search query",
            deviceIDs   : ["dev1", "dev2"],
            deviceTypes : [.humidity, .touch],
            productNumbers: ["pn1", "pn2"],
            labelFilters: ["key1": "value1", "key2": "value2"],
            orderBy     : (field: "reported.temperature.value", ascending: false)
        )
        XCTAssertEqual(devices, respDevices)
    }
    
    func testGetDevicesPageNoParameters() async throws {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices")
        
        let respDevices = [DeviceTests.createDummyDevice(), DeviceTests.createDummyDevice()]
        let respData = DeviceTests.createDevicesJSON(from: respDevices, nextPageToken: "nextToken")
        
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
        
        let page = try await Device.getPage(projectID: reqProjectID, pageSize: 2, pageToken: "token")
        XCTAssertEqual(page.nextPageToken, "nextToken")
        XCTAssertEqual(page.devices, respDevices)
    }
    
    func testGetDevicesPageAllParameters() async throws {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices")
        let reqParams: [String: [String]] = [
            "query"           : ["search query"],
            "device_ids"      : ["dev1", "dev2"],
            "device_types"    : ["humidity", "touch"],
            "product_numbers" : ["pn1", "pn2"],
            "label_filters"   : ["key1=value1", "key2=value2"],
            "order_by"        : ["-reported.temperature.value"],
            "page_size"       : ["2"],
            "page_token"      : ["token"]
        ]
        
        let respDevices = [DeviceTests.createDummyDevice(), DeviceTests.createDummyDevice()]
        let respData = DeviceTests.createDevicesJSON(from: respDevices, nextPageToken: "nextToken")
        
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
        
        let page = try await Device.getPage(
            projectID      : reqProjectID,
            query          : "search query",
            deviceIDs      : ["dev1", "dev2"],
            deviceTypes    : [.humidity, .touch],
            productNumbers : ["pn1", "pn2"],
            labelFilters   : ["key1": "value1", "key2": "value2"],
            orderBy        : (field: "reported.temperature.value", ascending: false),
            pageSize       : 2,
            pageToken      : "token"
        )
        XCTAssertEqual(page.nextPageToken, "nextToken")
        XCTAssertEqual(page.devices, respDevices)
    }
    
    func testUpdateDeviceDisplayName() async throws {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqDisplayName = "Dummy"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
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
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        try await Device.updateDisplayName(
            projectID      : reqProjectID,
            deviceID       : reqDeviceID,
            newDisplayName : reqDisplayName
        )
    }
    
    func testRemoveDeviceLabel() async throws {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqLabelKeyToRemove = "labelKey"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
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
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        try await Device.deleteLabel(
            projectID : reqProjectID,
            deviceID  : reqDeviceID,
            labelKey  : reqLabelKeyToRemove
        )
    }
    
    func testSetDeviceLabel() async throws {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqLabelKey = "key"
        let reqLabelValue = "value"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
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
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        try await Device.setLabel(
            projectID  : reqProjectID,
            deviceID   : reqDeviceID,
            labelKey   : reqLabelKey,
            labelValue : reqLabelValue
        )
    }
    
    func testBatchUpdateDeviceLabels() async throws {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqLabelKeyToSet = "key"
        let reqLabelValueToSet = "value"
        let reqLabelKeyToRemove = "labelToRemove"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
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
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        try await Device.batchUpdateLabels(
            projectID      : reqProjectID,
            deviceIDs      : [reqDeviceID],
            labelsToSet    : [reqLabelKeyToSet: reqLabelValueToSet],
            labelsToRemove : [reqLabelKeyToRemove]
        )
    }
    
    func testMoveDevicesByIDs() async throws {
        let reqFromProjectID = "proj1"
        let reqToProjectID = "proj2"
        let reqDeviceIDs = ["dev1", "dev2"]
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
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
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        try await Device.transfer(
            deviceIDs     : reqDeviceIDs,
            fromProjectID : reqFromProjectID,
            toProjectID   : reqToProjectID
        )
    }
    
    func testDeviceTypeDisplayName() {
        let types: [Device.DeviceType] = [
            .temperature,
            .touch,
            .proximity,
            .humidity,
            .touchCounter,
            .proximityCounter,
            .waterDetector,
            .cloudConnector,
            .unknown(value: "Dummy")
        ]
        
        types.forEach {
            XCTAssertGreaterThan($0.displayName().count, 0)
        }
    }
}



// -------------------------------
// MARK: Helpers
// -------------------------------

extension DeviceTests {
    
    // Only supports temp events for now
    private static func createDeviceJSONString(from device: Device) -> String {
        var reported = ""
        if device.reportedEvents.temperature != nil {
            reported = """
            ,"reported": {
                "temperature": {
                    "value": \(device.reportedEvents.temperature?.celsius ?? 0),
                    "updateTime": "\(device.reportedEvents.temperature?.timestamp.iso8601String() ?? "-")",
                    "samples": [
                        {
                            "value": \(device.reportedEvents.temperature!.samples[2].celsius),
                            "sampleTime": "\(device.reportedEvents.temperature!.samples[2].timestamp.iso8601String())"
                        },
                        {
                            "value": \(device.reportedEvents.temperature!.samples[1].celsius),
                            "sampleTime": "\(device.reportedEvents.temperature!.samples[1].timestamp.iso8601String())"
                        },
                        {
                            "value": \(device.reportedEvents.temperature!.samples[0].celsius),
                            "sampleTime": "\(device.reportedEvents.temperature!.samples[0].timestamp.iso8601String())"
                        }
                    ]
                }
            }
            """
        }
        return """
        {
          "name": "projects/\(device.projectID)/devices/\(device.identifier)",
          "type": "temperature",
          "labels": {
            "name": "\(device.displayName)"
          }
          \(reported),
          "productNumber": "\(device.productNumber ?? "")"
        }
        """
    }
    
    static func createDeviceJSON(from device: Device) -> Data {
        return createDeviceJSONString(from: device).data(using: .utf8)!
    }
    
    static func createDevicesJSON(from devices: [Device], nextPageToken: String = "") -> Data {
        return """
        {
            "devices": [
                \(devices.map({ createDeviceJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": "\(nextPageToken)"
        }
        """.data(using: .utf8)!
    }
    
    // Only supports temp events for now
    static func createDummyDevice(isEmulated: Bool = false) -> Device {
        var reportedEvents = Device.ReportedEvents()
        var productNumber: String?
        if isEmulated == false {
            reportedEvents.temperature = TemperatureEvent(
                celsius: 56,
                timestamp: Date(timeIntervalSince1970: 1605999873),
                samples: [
                    TemperatureEvent.TemperatureSample(celsius: 24.9, timestamp: Date(timeIntervalSince1970: 1605999873)),
                    TemperatureEvent.TemperatureSample(celsius: 24.2, timestamp: Date(timeIntervalSince1970: 1605999573)),
                    TemperatureEvent.TemperatureSample(celsius: 24.5, timestamp: Date(timeIntervalSince1970: 1605999273))
                ]
            )
            productNumber = "102150"
        }
        
        
        return Device(
            identifier: (isEmulated ? "emu" : "") + "b5rj9ed7rihk942p48og",
            displayName: "Dummy project",
            projectID: "b7s3umd0fee000ba5di0",
            labels: ["name": "Dummy project"],
            type: .temperature,
            productNumber: productNumber,
            reportedEvents: reportedEvents,
            isEmulatedDevice: isEmulated
        )
    }
}
