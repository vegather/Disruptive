//
//  EmulatorTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 03/01/2021.
//

import XCTest
@testable import Disruptive

class EmulatorTests: DisruptiveTests {
    
    func testGetAllEmulatedDevices() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseEmulatorURL)!
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
        
        let exp = expectation(description: "")
        disruptive.getAllEmulatedDevices(projectID: reqProjectID) { result in
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
    
    func t() {
        
        var fetchedDevices = [Device]()
        var nextPageToken: String?
        
        func fetchNextPage(pageToken: String?) {
            disruptive.getDevicesPage(projectID: "<PROJECT_ID>", pageSize: 25, pageToken: pageToken) { result in
                switch result {
                    case .success(let page):
                        // Keep track of the page token to use for the next page.
                        // Note that this will be `nil` when the last page is received.
                        nextPageToken = page.nextPageToken
                        
                        // Update the list of all the devices we have found so far
                        fetchedDevices.append(contentsOf: page.devices)
                        
                        print("Fetched \(page.devices.count) more devices. \(fetchedDevices.count) devices fetched in total")
                    case .failure(let error):
                        print("Failed to get devices: \(error)")
                }
            }
        }
        
        // Fetch the first page
        fetchNextPage(pageToken: nil)
        
        // Fetch subsequent pages when it makes sense (for example when pre-fetching data
        // for a UITableView). Note that `nextPageToken` will be set to `nil` when the last
        // page is received.
        if let pageToken = nextPageToken {
            fetchNextPage(pageToken: pageToken)
        }
    }
    
    func testGetEmulatedDevicesPage() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseEmulatorURL)!
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
        
        let exp = expectation(description: "")
        disruptive.getEmulatedDevicesPage(projectID: reqProjectID, pageSize: 2, pageToken: "token") { result in
            switch result {
                case .success(let page):
                    XCTAssertEqual(page.nextPageToken, "nextToken")
                    XCTAssertEqual(page.devices, respDevices)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetEmulatedDevice() {
        let reqProjectID = "proj1"
        let reqDeviceID = "emudev1"
        let reqURL = URL(string: Disruptive.defaultBaseEmulatorURL)!
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
        
        let exp = expectation(description: "")
        disruptive.getEmulatedDevice(projectID: reqProjectID, deviceID: reqDeviceID) { result in
            switch result {
                case .success(let device):
                    XCTAssertEqual(device, respDevice)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testCreateEmulatedDeviceWithLabels() {
        let reqProjectID = "abc"
        let reqDeviceType = Device.DeviceType.temperature
        let reqDisplayName = "dummy"
        let reqLabels = ["foo": "bar"]
        let reqURL = URL(string: Disruptive.defaultBaseEmulatorURL)!
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
        
        let exp = expectation(description: "")
        disruptive.createEmulatedDevice(projectID: reqProjectID, deviceType: reqDeviceType, displayName: reqDisplayName, labels: reqLabels) { result in
            switch result {
                case .success(let d):
                    XCTAssertEqual(d, respDevice)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testCreateEmulatedDeviceNoLabels() {
        let reqProjectID = "abc"
        let reqDeviceType = Device.DeviceType.temperature
        let reqDisplayName = "dummy"
        let reqURL = URL(string: Disruptive.defaultBaseEmulatorURL)!
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
        
        let exp = expectation(description: "")
        disruptive.createEmulatedDevice(projectID: reqProjectID, deviceType: reqDeviceType, displayName: reqDisplayName) { result in
            switch result {
                case .success(let d):
                    XCTAssertEqual(d, respDevice)
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testCreateEmulatedDeviceUnknownDeviceType() {
        let exp = expectation(description: "")
        disruptive.createEmulatedDevice(projectID: "proj1", deviceType: .unknown(value: "NOT_A_DEVICE"), displayName: "") { result in
            switch result {
                case .success(_)       : XCTFail("Unexpected success")
                case .failure(let err) : XCTAssertEqual(err, .badRequest)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testDeleteEmulatedDevice() {
        let reqProjectID = "proj1"
        let reqDeviceID = "emudev1"
        let reqURL = URL(string: Disruptive.defaultBaseEmulatorURL)!
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
        
        let exp = expectation(description: "")
        disruptive.deleteEmulatedDevice(projectID: reqProjectID, deviceID: reqDeviceID) { result in
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
    
    func testPublishEmulatedEventOneEvent() {
        func assertEvent<T: PublishableEvent>(event: T, expectedPayload: Data) {
            let reqProjectID = "proj1"
            let reqDeviceID = "dev1"
            let reqURL = URL(string: Disruptive.defaultBaseEmulatorURL)!
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
            
            let exp = expectation(description: "")
            disruptive.publishEmulatedEvent(projectID: reqProjectID, deviceID: reqDeviceID, event: event) { result in
                switch result {
                    case .success()        : break
                    case .failure(let err) : XCTFail("Unexpected error: \(err)")
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 1)
        }
        
        let now = Date()
        
        assertEvent(
            event: TouchEvent(timestamp: now),
            expectedPayload: """
            {
                "touch": {
                    "updateTime": "\(now.iso8601String())"
                }
            }
            """.data(using: .utf8)!
        )
        
        assertEvent(
            event: TemperatureEvent(
                celsius: 15,
                timestamp: now,
                samples: [
                    TemperatureEvent.TemperatureSample(
                        celsius: 24.5,
                        timestamp: try! Date(iso8601String: "2019-05-16T08:15:08.318Z")
                    ),
                    TemperatureEvent.TemperatureSample(
                        celsius: 23.75,
                        timestamp: try! Date(iso8601String: "2019-05-16T08:15:13.318Z")
                    ),
                    TemperatureEvent.TemperatureSample(
                        celsius: 25.25,
                        timestamp: try! Date(iso8601String: "2019-05-16T08:15:18.318Z")
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

        assertEvent(
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

        assertEvent(
            event: HumidityEvent(temperature: 12, relativeHumidity: 13, timestamp: now),
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

        assertEvent(
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
        
        assertEvent(
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

        assertEvent(
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

        assertEvent(
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
        
        assertEvent(
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
        
        assertEvent(
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
        
        assertEvent(
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
        
        assertEvent(
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
