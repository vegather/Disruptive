//
//  DeviceEventStreamTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 25/12/2020.
//

import XCTest
@testable import Disruptive

class DeviceEventStreamTests: DisruptiveTests {
    
    func testTouchEvent() {
        let payload = """
        {"result": {"event": {"eventId":"bjehn6sdm92f9pd7f4s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"touch","data":{"touch":{"updateTime":"2019-05-16T08:13:15.361624Z"}},"timestamp":"2019-05-16T08:13:15.361624Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onTouch = { deviceID, touch in
                XCTAssertEqual(deviceID, "bchonod7rihjtvdmd2vg")
                XCTAssertEqual(touch.timestamp, try! Date(iso8601String: "2019-05-16T08:13:15.361624Z"))
                exp.fulfill()
            }
        }
    }
    
    func testTemperatureEvent() {
        let payload = """
        {"result":{"event":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/dev1","eventType":"temperature","data":{"temperature":{"value":22.65,"updateTime":"2020-12-25T17:57:02.560000Z","samples":[{"value":24.9,"sampleTime": "2019-05-16T08:15:18.318751Z"},{"value":24.2,"sampleTime":"2019-05-16T08:15:13.318751Z"},{"value": 24.5,"sampleTime":"2019-05-16T08:15:08.318751Z"}]}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}
        
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onTemperature = { deviceID, temp in
                XCTAssertEqual(deviceID, "dev1")
                XCTAssertEqual(temp.celsius, 22.65)
                XCTAssertEqual(temp.timestamp, try! Date(iso8601String: "2020-12-25T17:57:02.560000Z"))
                XCTAssertEqual(temp.samples, [
                    TemperatureEvent.TemperatureSample(celsius: 24.9, timestamp: try! Date(iso8601String: "2019-05-16T08:15:18.318751Z")),
                    TemperatureEvent.TemperatureSample(celsius: 24.2, timestamp: try! Date(iso8601String: "2019-05-16T08:15:13.318751Z")),
                    TemperatureEvent.TemperatureSample(celsius: 24.5, timestamp: try! Date(iso8601String: "2019-05-16T08:15:08.318751Z"))
                ])
                exp.fulfill()
            }
        }
    }
    
    func testObjectPresentEvent() {
        let payload = """
        {"result": {"event": {"eventId":"bjei2dia9k365r1ntb20","targetName":"projects/bhmh0143iktucae701vg/devices/bchonol7rihjtvdmd7bg","eventType":"objectPresent","data":{"objectPresent":{"state":"NOT_PRESENT","updateTime":"2019-05-16T08:37:10.711412Z"}},"timestamp":"2019-05-16T08:37:10.711412Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onObjectPresent = { deviceID, objectPresent in
                XCTAssertEqual(deviceID, "bchonol7rihjtvdmd7bg")
                XCTAssertEqual(objectPresent.state, .objectNotPresent)
                XCTAssertEqual(objectPresent.timestamp, try! Date(iso8601String: "2019-05-16T08:37:10.711412Z"))
                exp.fulfill()
            }
        }
    }
    
    func testHumidityEvent() {
        let payload = """
        {"result": {"event": {"eventId":"bnpio6iuvvg2ninodrgg","targetName":"projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji86g","eventType":"humidity","data":{"humidity":{"temperature":22.45,"relativeHumidity":17,"updateTime":"2019-05-16T06:13:46.369000Z"}},"timestamp":"2019-05-16T06:13:46.369000Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onHumidity = { deviceID, hum in
                XCTAssertEqual(deviceID, "b6roh6d7rihmn9oji86g")
                XCTAssertEqual(hum.celsius, 22.45)
                XCTAssertEqual(hum.relativeHumidity, 17)
                XCTAssertEqual(hum.timestamp, try! Date(iso8601String: "2019-05-16T06:13:46.369000Z"))
                exp.fulfill()
            }
        }
    }
    
    func testObjectPresentCount() {
        let payload = """
        {"result": {"event": {"eventId":"bnpkl3quvvg2ninq0fng","targetName":"projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji860","eventType":"objectPresentCount","data":{"objectPresentCount":{"total":4176,"updateTime":"2019-05-16T08:23:43.209000Z"}},"timestamp":"2019-05-16T08:23:43.209000Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onObjectPresentCount = { deviceID, objectPresentCount in
                XCTAssertEqual(deviceID, "b6roh6d7rihmn9oji860")
                XCTAssertEqual(objectPresentCount.total, 4176)
                XCTAssertEqual(objectPresentCount.timestamp, try! Date(iso8601String: "2019-05-16T08:23:43.209000Z"))
                exp.fulfill()
            }
        }
    }
    
    func testTouchCount() {
        let payload = """
        {"result": {"event": {"eventId":"bnpklsfkh4f8r5td2b70","targetName":"projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji870","eventType":"touchCount","data":{"touchCount":{"total":469,"updateTime":"2019-05-16T08:25:21.604000Z"}},"timestamp":"2019-05-16T08:25:21.604000Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onTouchCount = { deviceID, touchCount in
                XCTAssertEqual(deviceID, "b6roh6d7rihmn9oji870")
                XCTAssertEqual(touchCount.total, 469)
                XCTAssertEqual(touchCount.timestamp, try! Date(iso8601String: "2019-05-16T08:25:21.604000Z"))
                exp.fulfill()
            }
        }
    }
    
    func testWaterPresent() {
        let payload = """
        {"result": {"event": {"eventId":"bnpku97kh4f8r5td9rb0","targetName":"projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji85g","eventType":"waterPresent","data":{"waterPresent":{"state":"PRESENT","updateTime":"2019-05-16T08:43:16.266000Z"}},"timestamp":"2019-05-16T08:43:16.266000Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onWaterPresent = { deviceID, waterPresent in
                XCTAssertEqual(deviceID, "b6roh6d7rihmn9oji85g")
                XCTAssertEqual(waterPresent.state, .waterPresent)
                XCTAssertEqual(waterPresent.timestamp, try! Date(iso8601String: "2019-05-16T08:43:16.266000Z"))
                exp.fulfill()
            }
        }
    }
    
    func testNetworkStatus() {
        let payload = """
        {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"networkStatus","data":{"networkStatus":{"signalStrength":45,"rssi":-83,"updateTime":"2019-05-16T08:21:21.076013Z","cloudConnectors":[{"id":"bdkjbo2v0000uk377c4g","signalStrength":45,"rssi":-83}],"transmissionMode":"LOW_POWER_STANDARD_MODE"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onNetworkStatus = { deviceID, networkStatus in
                XCTAssertEqual(deviceID, "bchonod7rihjtvdmd2vg")
                XCTAssertEqual(networkStatus.signalStrength, 45)
                XCTAssertEqual(networkStatus.rssi, -83)
                XCTAssertEqual(networkStatus.timestamp, try! Date(iso8601String: "2019-05-16T08:21:21.076013Z"))
                XCTAssertEqual(networkStatus.cloudConnectors, [
                    NetworkStatusEvent.CloudConnector(identifier: "bdkjbo2v0000uk377c4g", signalStrength: 45, rssi: -83)
                ])
                XCTAssertEqual(networkStatus.transmissionMode, .standard)
                exp.fulfill()
            }
        }
    }
    
    func testBatterStatus() {
        let payload = """
        {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"batteryStatus","data":{"batteryStatus":{"percentage":100,"updateTime":"2019-05-16T08:21:21.076013Z"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onBatteryStatus = { deviceID, batteryStatus in
                XCTAssertEqual(deviceID, "bchonod7rihjtvdmd2vg")
                XCTAssertEqual(batteryStatus.percentage, 100)
                XCTAssertEqual(batteryStatus.timestamp, try! Date(iso8601String: "2019-05-16T08:21:21.076013Z"))
                exp.fulfill()
            }
        }
    }
    
    func testLabelsChanged() {
        let payload = """
        {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"labelsChanged","data":{"added":{"add":"added"},"modified":{"name":"Sensorname"},"removed":["removed"]},"timestamp":"2019-05-16T08:21:21.076013Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onLabelsChanged = { deviceID, labelsChanged in
                XCTAssertEqual(deviceID, "bchonod7rihjtvdmd2vg")
                XCTAssertEqual(labelsChanged.added, ["add": "added"])
                XCTAssertEqual(labelsChanged.modified, ["name": "Sensorname"])
                XCTAssertEqual(labelsChanged.removed, ["removed"])
                XCTAssertEqual(labelsChanged.timestamp, try! Date(iso8601String: "2019-05-16T08:21:21.076013Z"))
                exp.fulfill()
            }
        }
    }
    
    func testConnectionStatus() {
        let payload = """
        {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"connectionStatus","data":{"connectionStatus":{"connection":"ETHERNET","available":["CELLULAR","ETHERNET"],"updateTime":"2019-05-16T08:21:21.076013Z"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onConnectionStatus = { deviceID, connectionStatus in
                XCTAssertEqual(deviceID, "bchonod7rihjtvdmd2vg")
                XCTAssertEqual(connectionStatus.connection, .ethernet)
                XCTAssertEqual(connectionStatus.available, [.cellular, .ethernet])
                XCTAssertEqual(connectionStatus.timestamp, try! Date(iso8601String: "2019-05-16T08:21:21.076013Z"))
                exp.fulfill()
            }
        }
    }
    
    func testEthernetStatus() {
        let payload = """
        {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"ethernetStatus","data":{"ethernetStatus":{"macAddress":"f0:b5:b7:00:0a:08","ipAddress":"10.0.0.1","errors":[],"updateTime":"2019-05-16T08:21:21.076013Z"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onEthernetStatus = { deviceID, ethernetStatus in
                XCTAssertEqual(deviceID, "bchonod7rihjtvdmd2vg")
                XCTAssertEqual(ethernetStatus.macAddress, "f0:b5:b7:00:0a:08")
                XCTAssertEqual(ethernetStatus.ipAddress, "10.0.0.1")
                XCTAssertEqual(ethernetStatus.errors, [])
                XCTAssertEqual(ethernetStatus.timestamp, try! Date(iso8601String: "2019-05-16T08:21:21.076013Z"))
                exp.fulfill()
            }
        }
    }
    
    func testCellularStatus() {
        let payload = """
        {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"cellularStatus","data":{"cellularStatus":{"signalStrength":80,"errors":[],"updateTime":"2019-05-16T08:21:21.076013Z"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            stream.onCellularStatus = { deviceID, cellularStatus in
                XCTAssertEqual(deviceID, "bchonod7rihjtvdmd2vg")
                XCTAssertEqual(cellularStatus.signalStrength, 80)
                XCTAssertEqual(cellularStatus.errors, [])
                XCTAssertEqual(cellularStatus.timestamp, try! Date(iso8601String: "2019-05-16T08:21:21.076013Z"))
                exp.fulfill()
            }
        }
    }
    
    func testMultipleEvents() {
        let payload = """
        {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"batteryStatus","data":{"batteryStatus":{"percentage":100,"updateTime":"2019-05-16T08:21:21.076013Z"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}
        {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"networkStatus","data":{"networkStatus":{"signalStrength":45,"rssi":-83,"updateTime":"2019-05-16T08:21:21.076013Z","cloudConnectors":[{"id":"bdkjbo2v0000uk377c4g","signalStrength":45,"rssi":-83}],"transmissionMode":"LOW_POWER_STANDARD_MODE"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}
        """.data(using: .utf8)!
        
        runEventTest(payload: payload) { stream, exp in
            exp.expectedFulfillmentCount = 2
            
            stream.onNetworkStatus = { deviceID, networkStatus in
                XCTAssertEqual(deviceID, "bchonod7rihjtvdmd2vg")
                XCTAssertEqual(networkStatus.signalStrength, 45)
                XCTAssertEqual(networkStatus.rssi, -83)
                XCTAssertEqual(networkStatus.timestamp, try! Date(iso8601String: "2019-05-16T08:21:21.076013Z"))
                XCTAssertEqual(networkStatus.cloudConnectors, [
                    NetworkStatusEvent.CloudConnector(identifier: "bdkjbo2v0000uk377c4g", signalStrength: 45, rssi: -83)
                ])
                XCTAssertEqual(networkStatus.transmissionMode, .standard)
                exp.fulfill()
            }
            
            stream.onBatteryStatus = { deviceID, batteryStatus in
                XCTAssertEqual(deviceID, "bchonod7rihjtvdmd2vg")
                XCTAssertEqual(batteryStatus.percentage, 100)
                XCTAssertEqual(batteryStatus.timestamp, try! Date(iso8601String: "2019-05-16T08:21:21.076013Z"))
                exp.fulfill()
            }
        }
    }
    
    func runEventTest(payload: Data, handler: (DeviceEventStream, XCTestExpectation) -> ()) {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
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
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return [(payload, resp, nil)]
        }
        
        let exp = expectation(description: "")
        let stream = disruptive.subscribeToDevices(projectID: reqProjectID)!
        handler(stream, exp)
        
        wait(for: [exp], timeout: 1)
    }
    
    func testErrorMessage() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        let payload = """
        {"error":{"code":400,"message":"bad request","details":[{"help": "https://developer.disruptive-technologies.com/docs/error-codes#400"}]}}
        """.data(using: .utf8)!
        
        MockStreamURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : ["Accept": "application/json", "Cache-Control": "no-cache"],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return [(payload, resp, nil)]
        }
        
        let exp = expectation(description: "")
        let stream = disruptive.subscribeToDevices(projectID: reqProjectID)
        stream?.onError = { err in
            XCTAssertEqual(err, .badRequest)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 0.3)
    }
    
    func testNoMessageIfNoResponse() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        let payload = """
        {"result":{"event":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/dev1","eventType":"temperature","data":{"temperature":{"value":22.65,"updateTime":"2020-12-25T17:57:02.560000Z"}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}

        """.data(using: .utf8)!
        
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
            
            return [(payload, nil, nil)]
        }
        
        let exp = expectation(description: "")
        exp.isInverted = true
        let stream = disruptive.subscribeToDevices(projectID: reqProjectID)
        stream?.onTemperature = { deviceID, temp in
            exp.fulfill()
        }
        stream?.onError = { err in
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 0.1)
    }
    
    func testCloseStream() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        let payload = """
        {"result":{"event":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/dev1","eventType":"temperature","data":{"temperature":{"value":22.65,"updateTime":"2020-12-25T17:57:02.560000Z"}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}

        """.data(using: .utf8)!
        
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
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return [(payload, resp, nil)]
        }
        
        let exp = expectation(description: "")
        exp.isInverted = true
        let stream = disruptive.subscribeToDevices(projectID: reqProjectID)
        stream?.onTemperature = { deviceID, temp in
            exp.fulfill()
        }
        stream?.close()
        
        wait(for: [exp], timeout: 0.1)
    }
    
    func testUnknownEvent() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        let payload = """
        {"result":{"event":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/dev1","eventType":"unknownEvent","data":{"unknownEvent":{"value":0,"updateTime":"2020-12-25T17:57:02.560000Z"}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}

        """.data(using: .utf8)!
        
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
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            return [(payload, resp, nil)]
        }
        
        let exp = expectation(description: "")
        exp.isInverted = true
        let stream = disruptive.subscribeToDevices(projectID: reqProjectID)
        stream?.onTemperature = { _, _ in exp.fulfill() }
        stream?.onError = { _ in exp.fulfill()}
        
        wait(for: [exp], timeout: 1)
    }
}
