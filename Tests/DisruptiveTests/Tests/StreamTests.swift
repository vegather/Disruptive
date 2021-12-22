//
//  StreamTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 27/12/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class StreamTests: DisruptiveTests {

    func testSubscribeToDevicesNoParameters() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
                
        MockStreamURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            return [(nil, nil, nil)]
        }
        
        let stream = Device.subscribeToDevices(projectID: reqProjectID)
        
        // Wait a bit to let the request go through (and be asserted)
        let exp = expectation(description: "testSubscribeToDevicesNoParameters")
        exp.isInverted = true
        stream.onTouch = { _, _ in exp.fulfill() }
        wait(for: [exp], timeout: 0.05)
    }
    
    func testSubscribeToDevicesAllParameters() {
        let reqProjectID = "proj1"
        let reqDeviceIDs = ["dev1", "dev2"]
        let reqDeviceTypes = [Device.DeviceType.temperature, .touch]
        let productNumbers = ["pn1", "pn2"]
        let reqLabelFilters = ["foo", "bar"]
        let reqEventTypes = [EventType.touch, .batteryStatus, .networkStatus]
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        MockStreamURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [
                    "device_ids"      : reqDeviceIDs,
                    "label_filters"   : reqLabelFilters,
                    "device_types"    : reqDeviceTypes.map { $0.rawValue! },
                    "product_numbers" : productNumbers,
                    "event_types"     : reqEventTypes .map { $0.rawValue }
                ],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            return [(nil, nil, nil)]
        }
        
        let stream = Device.subscribeToDevices(
            projectID      : reqProjectID,
            deviceIDs      : reqDeviceIDs,
            deviceTypes    : reqDeviceTypes,
            productNumbers : productNumbers,
            labelFilters   : reqLabelFilters,
            eventTypes     : reqEventTypes
        )
        
        // Wait a bit to let the request go through (and be asserted)
        let exp = expectation(description: "testSubscribeToDevicesAllParameters")
        exp.isInverted = true
        stream.onTouch = { _, _ in exp.fulfill() }
        wait(for: [exp], timeout: 0.05)
    }
    
    func testSubscribeToDeviceNoParameters() {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        MockStreamURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : ["device_ids": [reqDeviceID]],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            return [(nil, nil, nil)]
        }
        
        let stream = Device.subscribeToDevice(projectID: reqProjectID, deviceID: reqDeviceID)
        
        // Wait a bit to let the request go through (and be asserted)
        let exp = expectation(description: "testSubscribeToDeviceNoParameters")
        exp.isInverted = true
        stream.onTouch = { _, _ in exp.fulfill() }
        wait(for: [exp], timeout: 0.05)
    }
    
    func testSubscribeToDeviceAllParameters() {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqEventTypes = [EventType.touch, .batteryStatus, .networkStatus]
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        MockStreamURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [
                    "device_ids"  : [reqDeviceID],
                    "event_types" : reqEventTypes .map { $0.rawValue }
                ],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            return [(nil, nil, nil)]
        }
        
        let stream = Device.subscribeToDevice(
            projectID  : reqProjectID,
            deviceID   : reqDeviceID,
            eventTypes : reqEventTypes
        )
        
        // Wait a bit to let the request go through (and be asserted)
        let exp = expectation(description: "testSubscribeToDeviceAllParameters")
        exp.isInverted = true
        stream.onTouch = { _, _ in exp.fulfill() }
        wait(for: [exp], timeout: 0.05)
    }
    
    func testStreamError() {
        let errorPayload = """
        {
            "error": {
                "code": 5,
                "message": "not found",
                "details":[
                    {
                        "help": "https://developer.disruptive-technologies.com/docs/error-codes#404"
                    }
                ]
            }
        }
        """.data(using: .utf8)!
        
        let reqProjectID = "proj1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        MockStreamURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            return [(errorPayload, nil, nil)]
        }
        
        let stream = Device.subscribeToDevices(projectID: reqProjectID)
        
        // Wait a bit to let the request go through (and be asserted)
        let exp = expectation(description: "testStreamError")
        exp.isInverted = true
        stream.onError = { err in
            XCTAssertEqual(err.type, .notFound)
            XCTAssertEqual(err.message, "not found")
            XCTAssertEqual(err.helpLink, "https://developer.disruptive-technologies.com/docs/error-codes#404")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 0.05)
    }
}
