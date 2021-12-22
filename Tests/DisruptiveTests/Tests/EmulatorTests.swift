//
//  EmulatorTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 03/01/2021.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class EmulatorTests: DisruptiveTests {
    
    func testCreateEmulatedDeviceWithLabels() async throws  {
        let reqProjectID = "abc"
        let reqDeviceType = Device.DeviceType.temperature
        let reqDisplayName = "dummy"
        let reqLabels = ["foo": "bar"]
        let reqURL = URL(string: Config.DefaultURLs.baseEmulatorURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices")
        let reqBody = """
        {
            "type": "\(reqDeviceType.rawValue!)",
            "labels": {"foo": "bar", "name": "\(reqDisplayName)"}
        }
        """.data(using: .utf8)!
        
        let respDevice = DeviceTests.createDummyDevice()
        let respData = DeviceTests.createDeviceJSON(from: respDevice)
        
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
        
        let d = try await DeviceEmulator.create(
            projectID   : reqProjectID,
            deviceType  : reqDeviceType,
            displayName : reqDisplayName,
            labels      : reqLabels
        )
        XCTAssertEqual(d, respDevice)
    }
    
    func testCreateEmulatedDeviceNoLabels() async throws {
        let reqProjectID = "abc"
        let reqDeviceType = Device.DeviceType.temperature
        let reqDisplayName = "dummy"
        let reqURL = URL(string: Config.DefaultURLs.baseEmulatorURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices")
        let reqBody = """
        {
            "type": "\(reqDeviceType.rawValue!)",
            "labels": {"name": "\(reqDisplayName)"}
        }
        """.data(using: .utf8)!
        
        let respDevice = DeviceTests.createDummyDevice()
        let respData = DeviceTests.createDeviceJSON(from: respDevice)
        
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
        
        let d = try await DeviceEmulator.create(
            projectID   : reqProjectID,
            deviceType  : reqDeviceType,
            displayName : reqDisplayName
        )
        XCTAssertEqual(d, respDevice)
    }
    
    func testCreateEmulatedDeviceUnknownDeviceType() async throws {
        do {
            _ = try await DeviceEmulator.create(projectID: "proj1", deviceType: .unknown(value: "NOT_A_DEVICE"), displayName: "")
            XCTFail("Unexpected success")
        } catch let error as DisruptiveError {
            XCTAssertEqual(error.type, .badRequest)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testDeleteEmulatedDevice() async throws {
        let reqProjectID = "proj1"
        let reqDeviceID = "emudev1"
        let reqURL = URL(string: Config.DefaultURLs.baseEmulatorURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices/\(reqDeviceID)")
        
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
        
        try await DeviceEmulator.delete(projectID: reqProjectID, deviceID: reqDeviceID)
    }
    
    func testPublishEmulatedEventOneEvent() async throws {
        func assertEvent<T: PublishableEvent>(event: T, expectedPayload: Data) async throws {
            let reqProjectID = "proj1"
            let reqDeviceID = "dev1"
            let reqURL = URL(string: Config.DefaultURLs.baseEmulatorURL)!
                .appendingPathComponent("projects/\(reqProjectID)/devices/\(reqDeviceID):publish")
            
            
            let respDevice = DeviceTests.createDummyDevice()
            let respData = DeviceTests.createDeviceJSON(from: respDevice)
            
            MockURLProtocol.requestHandler = { request in
                self.assertRequestParams(
                    for           : request,
                    authenticated : true,
                    method        : "POST",
                    queryParams   : [:],
                    headers       : [:],
                    url           : reqURL,
                    body          : expectedPayload
                )
                
                let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (respData, resp, nil)
            }
            
            try await DeviceEmulator.publishEvent(projectID: reqProjectID, deviceID: reqDeviceID, event: event)
        }
        
        let now = Date()
        
        try await assertEvent(
            event: TouchEvent(timestamp: now),
            expectedPayload: """
            {
                "touch": {
                    "updateTime": "\(now.iso8601String())"
                }
            }
            """.data(using: .utf8)!
        )
        
        try await assertEvent(
            event: TemperatureEvent(
                celsius: 15,
                timestamp: now,
                samples: [
                    TemperatureEvent.TemperatureSample(
                        celsius: 25.25,
                        timestamp: try! Date(iso8601String: "2019-05-16T08:15:18.318Z")
                    ),
                    TemperatureEvent.TemperatureSample(
                        celsius: 23.75,
                        timestamp: try! Date(iso8601String: "2019-05-16T08:15:13.318Z")
                    ),
                    TemperatureEvent.TemperatureSample(
                        celsius: 24.5,
                        timestamp: try! Date(iso8601String: "2019-05-16T08:15:08.318Z")
                    )
                ]
            ),
            expectedPayload: """
            {
                "temperature": {
                    "value": 15,
                    "updateTime": "\(now.iso8601String())",
                    "samples": [
                        {
                            "value": 25.25,
                            "sampleTime": "2019-05-16T08:15:18.318Z"
                        },
                        {
                            "value": 23.75,
                            "sampleTime": "2019-05-16T08:15:13.318Z"
                        },
                        {
                            "value": 24.5,
                            "sampleTime": "2019-05-16T08:15:08.318Z"
                        }
                    ]
                }
            }
            """.data(using: .utf8)!
        )

        try await assertEvent(
            event: ObjectPresentEvent(state: .objectPresent, timestamp: now),
            expectedPayload: """
            {
                "objectPresent": {
                    "state": "PRESENT",
                    "updateTime": "\(now.iso8601String())"
                }
            }
            """.data(using: .utf8)!
        )

        try await assertEvent(
            event: HumidityEvent(celsius: 12, relativeHumidity: 13, timestamp: now),
            expectedPayload: """
            {
                "humidity": {
                    "temperature": 12,
                    "relativeHumidity": 13,
                    "updateTime": "\(now.iso8601String())"
                }
            }
            """.data(using: .utf8)!
        )

        try await assertEvent(
            event: ObjectPresentCountEvent(total: 99, timestamp: now),
            expectedPayload: """
            {
                "objectPresentCount": {
                    "total": 99,
                    "updateTime": "\(now.iso8601String())"
                }
            }
            """.data(using: .utf8)!
        )
        
        try await assertEvent(
            event: TouchCountEvent(total: 70, timestamp: now),
            expectedPayload: """
            {
                "touchCount": {
                    "total": 70,
                    "updateTime": "\(now.iso8601String())"
                }
            }
            """.data(using: .utf8)!
        )

        try await assertEvent(
            event: WaterPresentEvent(state: .waterNotPresent, timestamp: now),
            expectedPayload: """
            {
                "waterPresent": {
                    "state": "NOT_PRESENT",
                    "updateTime": "\(now.iso8601String())"
                }
            }
            """.data(using: .utf8)!
        )

        try await assertEvent(
            event: NetworkStatusEvent(
                signalStrength: 65,
                rssi: -30,
                timestamp: now,
                cloudConnectors: [
                    .init(identifier: "ccon_id1", signalStrength: 10, rssi: -10),
                    .init(identifier: "ccon_id2", signalStrength: 20, rssi: -20)
                ],
                transmissionMode: .boost
            ),
            expectedPayload: """
            {
                "networkStatus": {
                    "signalStrength": 65,
                    "rssi": -30,
                    "updateTime": "\(now.iso8601String())",
                    "cloudConnectors": [
                        { "id": "ccon_id1", "signalStrength": 10, "rssi": -10 },
                        { "id": "ccon_id2", "signalStrength": 20, "rssi": -20 }
                    ],
                    "transmissionMode": "HIGH_POWER_BOOST_MODE"
                }
            }
            """.data(using: .utf8)!
        )
        
        try await assertEvent(
            event: BatteryStatusEvent(percentage: 50, timestamp: now),
            expectedPayload: """
            {
                "batteryStatus": {
                    "percentage": 50,
                    "updateTime": "\(now.iso8601String())"
                }
            }
            """.data(using: .utf8)!
        )
        
        try await assertEvent(
            event: ConnectionStatusEvent(connection: .ethernet, available: [.cellular, .ethernet], timestamp: now),
            expectedPayload: """
            {
                "connectionStatus": {
                    "connection": "ETHERNET",
                    "available": ["CELLULAR", "ETHERNET"],
                    "updateTime": "\(now.iso8601String())"
                }
            }
            """.data(using: .utf8)!
        )
        
        try await assertEvent(
            event: EthernetStatusEvent(macAddress: "mac_address", ipAddress: "ip_address", errors: [.init(code: "code", message: "message")], timestamp: now),
            expectedPayload: """
            {
                "ethernetStatus": {
                    "macAddress": "mac_address",
                    "ipAddress": "ip_address",
                    "errors": [ { "code": "code", "message": "message" } ],
                    "updateTime": "\(now.iso8601String())"
                }
            }
            """.data(using: .utf8)!
        )
        
        try await assertEvent(
            event: CellularStatusEvent(signalStrength: 34, errors: [.init(code: "code", message: "message")], timestamp: now),
            expectedPayload: """
            {
                "cellularStatus": {
                    "signalStrength": 34,
                    "errors": [ { "code": "code", "message": "message" } ],
                    "updateTime": "\(now.iso8601String())"
                }
            }
            """.data(using: .utf8)!
        )
    }
}
