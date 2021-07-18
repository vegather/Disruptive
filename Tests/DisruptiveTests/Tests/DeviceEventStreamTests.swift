//
//  DeviceEventStreamTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 25/12/2020.
//

import XCTest
@testable import Disruptive

class DeviceEventStreamTests: DisruptiveTests {
    
    func testSingleMessage() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        let respTemp: Float = 22.65
        let respIdentifier = "dev1"
        let payload = """
        data: {"result":{"event":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/\(respIdentifier)","eventType":"temperature","data":{"temperature":{"value":\(respTemp),"updateTime":"2020-12-25T17:57:02.560000Z"}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}

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
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/event-stream"])!
            return [(payload, resp, nil)]
        }
        
        let exp = expectation(description: "")
        let stream = disruptive.subscribeToDevices(projectID: reqProjectID)
        stream?.onTemperature = { deviceID, temp in
            XCTAssertEqual(deviceID, respIdentifier)
            XCTAssertEqual(temp.celsius, respTemp)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }
    
    func testSplitMessage() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        let respTemp: Float = 22.65
        let respIdentifier = "dev1"
        let payload = """
        data: {"result":{"event":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/\(respIdentifier)","eventType":"temperature","data":{"temper
        data: ature":{"value":\(respTemp),"updateTime":"2020-12-25T17:57:02.560000Z"}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}

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
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/event-stream"])!
            return [(payload, resp, nil)]
        }
        
        let exp = expectation(description: "")
        let stream = disruptive.subscribeToDevices(projectID: reqProjectID)
        stream?.onTemperature = { deviceID, temp in
            XCTAssertEqual(deviceID, respIdentifier)
            XCTAssertEqual(temp.celsius, respTemp)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func testMessageForAllEventTypes() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        let payload = """
        data: {"result": {"event": {"eventId":"bjehn6sdm92f9pd7f4s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"touch","data":{"touch":{"updateTime":"2019-05-16T08:13:15.361624Z"}},"timestamp":"2019-05-16T08:13:15.361624Z"}}}

        data: {"result": {"event": {"eventId":"bjeho5nlafj3bdrehgsg","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"temperature","data":{"temperature":{"value":24.9,"updateTime":"2019-05-16T08:15:18.318751Z"}},"timestamp":"2019-05-16T08:15:18.318751Z"}}}

        data: {"result": {"event": {"eventId":"bjei2dia9k365r1ntb20","targetName":"projects/bhmh0143iktucae701vg/devices/bchonol7rihjtvdmd7bg","eventType":"objectPresent","data":{"objectPresent":{"state":"NOT_PRESENT","updateTime":"2019-05-16T08:37:10.711412Z"}},"timestamp":"2019-05-16T08:37:10.711412Z"}}}

        data: {"result": {"event": {"eventId":"bnpio6iuvvg2ninodrgg","targetName":"projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji86g","eventType":"humidity","data":{"humidity":{"temperature":22.45,"relativeHumidity":17,"updateTime":"2019-05-16T06:13:46.369000Z"}},"timestamp":"2019-05-16T06:13:46.369000Z"}}}

        data: {"result": {"event": {"eventId":"bnpkl3quvvg2ninq0fng","targetName":"projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji860","eventType":"objectPresentCount","data":{"objectPresentCount":{"total":4176,"updateTime":"2019-05-16T08:23:43.209000Z"}},"timestamp":"2019-05-16T08:23:43.209000Z"}}}

        data: {"result": {"event": {"eventId":"bnpklsfkh4f8r5td2b70","targetName":"projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji870","eventType":"touchCount","data":{"touchCount":{"total":469,"updateTime":"2019-05-16T08:25:21.604000Z"}},"timestamp":"2019-05-16T08:25:21.604000Z"}}}

        data: {"result": {"event": {"eventId":"bnpku97kh4f8r5td9rb0","targetName":"projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji85g","eventType":"waterPresent","data":{"waterPresent":{"state":"PRESENT","updateTime":"2019-05-16T08:43:16.266000Z"}},"timestamp":"2019-05-16T08:43:16.266000Z"}}}

        data: {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"networkStatus","data":{"networkStatus":{"signalStrength":45,"rssi":-83,"updateTime":"2019-05-16T08:21:21.076013Z","cloudConnectors":[{"id":"bdkjbo2v0000uk377c4g","signalStrength":45,"rssi":-83}],"transmissionMode":"LOW_POWER_STANDARD_MODE"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}

        data: {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"batteryStatus","data":{"batteryStatus":{"percentage":100,"updateTime":"2019-05-16T08:21:21.076013Z"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}

        data: {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"labelsChanged","data":{"added":{"add":"added"},"modified":{"name":"Sensorname"},"removed":["removed"]},"timestamp":"2019-05-16T08:21:21.076013Z"}}}

        data: {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"connectionStatus","data":{"connectionStatus":{"connection":"ETHERNET","available":["CELLULAR","ETHERNET"],"updateTime":"2019-05-16T08:21:21.076013Z"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}

        data: {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"ethernetStatus","data":{"ethernetStatus":{"macAddress":"f0:b5:b7:00:0a:08","ipAddress":"10.0.0.1","errors":[],"updateTime":"2019-05-16T08:21:21.076013Z"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}

        data: {"result": {"event": {"eventId":"bjehr0ig1me000dm66s0","targetName":"projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg","eventType":"cellularStatus","data":{"cellularStatus":{"signalStrength":80,"errors":[],"updateTime":"2019-05-16T08:21:21.076013Z"}},"timestamp":"2019-05-16T08:21:21.076013Z"}}}

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
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/event-stream"])!
            return [(payload, resp, nil)]
        }
        
        let expectations = EventType.allCases.reduce(into: [EventType: XCTestExpectation]()) {
            $0[$1] = expectation(description: $1.rawValue)
        }
                
        let stream = disruptive.subscribeToDevices(projectID: reqProjectID)
        stream?.onTouch              = { _, _ in expectations[.touch]!             .fulfill() }
        stream?.onTemperature        = { _, _ in expectations[.temperature]!       .fulfill() }
        stream?.onObjectPresent      = { _, _ in expectations[.objectPresent]!     .fulfill() }
        stream?.onHumidity           = { _, _ in expectations[.humidity]!          .fulfill() }
        stream?.onObjectPresentCount = { _, _ in expectations[.objectPresentCount]!.fulfill() }
        stream?.onTouchCount         = { _, _ in expectations[.touchCount]!        .fulfill() }
        stream?.onWaterPresent       = { _, _ in expectations[.waterPresent]!      .fulfill() }
        stream?.onNetworkStatus      = { _, _ in expectations[.networkStatus]!     .fulfill() }
        stream?.onBatteryStatus      = { _, _ in expectations[.batteryStatus]!     .fulfill() }
        stream?.onLabelsChanged      = { _, _ in expectations[.labelsChanged]!     .fulfill() }
        stream?.onConnectionStatus   = { _, _ in expectations[.ethernetStatus]!    .fulfill() }
        stream?.onEthernetStatus     = { _, _ in expectations[.cellularStatus]!    .fulfill() }
        stream?.onCellularStatus     = { _, _ in expectations[.connectionStatus]!  .fulfill() }
        
        wait(for: Array(expectations.values), timeout: 2)
    }
    
    
    
    // Makes sure it doesn't crash, and fails silently if it receives
    // an unexpected message (such as a gRPC error message)
    func testGRPCErrorMessage() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        let payload = """
        data: {"error":{"grpcCode":1,"httpCode":408,"message":"closing stream","httpStatus":"Request Timeout","details":[]}}

        """.data(using: .utf8)!
        
        MockStreamURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : ["Accept": "text/event-stream", "Cache-Control": "no-cache"],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/event-stream"])!
            return [(payload, resp, nil)]
        }
        
        let exp = expectation(description: "")
        exp.isInverted = true
        let stream = disruptive.subscribeToDevices(projectID: reqProjectID)
        stream?.onError = { _ in
            exp.fulfill()
        }
        stream?.onTemperature = { _, _ in
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 0.3)
    }
    
//    func testReestablishConnection() {
//        let reqProjectID = "proj1"
//        let reqURL = URL(string: Disruptive.defaultBaseURL)!
//            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
//        
//        let payload = """
//        data: {"result":{"event":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/dev","eventType":"temperature","data":{"temperature":{"value":22.70,"updateTime":"2020-12-25T17:57:02.560000Z"}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}
//
//        """.data(using: .utf8)!
//        let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/event-stream"])!
//        
//        // Sending one connection lost callback first, expecting the
//        // connection to re-establish, and then send a temp message callback.
//        let callbacks: [MockStreamURLProtocol.Callback] = [
//            (nil, nil, URLError(.networkConnectionLost)),   // Lose connection
//            (payload, resp, nil)                            // Expecting connection to re-establish
//        ]
//        
//        MockStreamURLProtocol.requestHandler = { request in
//            self.assertRequestParams(
//                for           : request,
//                authenticated : true,
//                method        : "GET",
//                queryParams   : [:],
//                headers       : [:],
//                url           : reqURL,
//                body          : nil
//            )
//            
//            return callbacks
//        }
//        
//        let exp = expectation(description: "")
//        let stream = disruptive.subscribeToDevices(projectID: reqProjectID)
//        stream?.onTemperature = { deviceID, temp in
//            exp.fulfill()
//        }
//        
//        wait(for: [exp], timeout: 1)
//    }
    
    // Tests that various other stream lines are parsed correctly
    func testMiscStreamValues() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        let respTemp: Float = 22.65
        let respIdentifier = "dev1"
        let payload = """
        event: dummy

        : This is a comment
        id: identifier

        :this is also a comment

        data:{"result":{"event":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/\(respIdentifier)","eventType":"temperature","data":{"temperature":{"value":\(respTemp),"updateTime":"2020-12-25T17:57:02.560000Z"}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}

        this is a field name




        data: {"result":{"eve
        data:nt":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/\(respIdentifier)","eventType":"temperature","data":{"temperature":{"value":\(respTemp),"updateTime":"2020-12-25T17:57:02.560000Z"}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}


        :

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
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/event-stream"])!
            return [(payload, resp, nil)]
        }
        
        let exp = expectation(description: "")
        exp.expectedFulfillmentCount = 2
        let stream = disruptive.subscribeToDevices(projectID: reqProjectID)
        stream?.onTemperature = { deviceID, temp in
            XCTAssertEqual(deviceID, respIdentifier)
            XCTAssertEqual(temp.celsius, respTemp)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func testNoMessageIfNoResponse() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        let payload = """
        data: {"result":{"event":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/dev1","eventType":"temperature","data":{"temperature":{"value":22.65,"updateTime":"2020-12-25T17:57:02.560000Z"}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}

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
        
        wait(for: [exp], timeout: 0.1)
    }
    
    func testCloseStream() {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices:stream")
        
        let payload = """
        data: {"result":{"event":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/dev1","eventType":"temperature","data":{"temperature":{"value":22.65,"updateTime":"2020-12-25T17:57:02.560000Z"}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}

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
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/event-stream"])!
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
        data: {"result":{"event":{"eventId":"bvj2frmmj123c0m4keng","targetName":"projects/proj/devices/dev1","eventType":"unknownEvent","data":{"unknownEvent":{"value":0,"updateTime":"2020-12-25T17:57:02.560000Z"}},"timestamp":"2020-12-25T17:57:02.560000Z"}}}

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
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/event-stream"])!
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
