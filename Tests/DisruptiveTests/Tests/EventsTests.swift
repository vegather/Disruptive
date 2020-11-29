//
//  EventsTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 22/11/2020.
//

import XCTest
@testable import Disruptive

class EventsTests: DisruptiveTests {
    
    func testGetAllEvents() {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices/\(reqDeviceID)/events")
        let reqStart = Date(timeIntervalSince1970: 1606045669)
        let reqEnd   = Date(timeIntervalSince1970: 1606067269)
        let reqQueryParams: [String: [String]] = [
            "start_time": ["2020-11-22T11:47:49Z"],
            "end_time": ["2020-11-22T17:47:49Z"],
            "event_types": EventType.allCases.map { $0.rawValue },
            "page_size": ["1000"]
        ]
                
        let respData = """
        {
            "events": [
                {
                    "eventId": "bjehn6sdm92f9pd7f4s0",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg",
                    "eventType": "touch",
                    "data": {
                      "touch": {
                        "updateTime": "2019-05-16T08:13:15.361624Z"
                      }
                    },
                    "timestamp": "2019-05-16T08:13:15.361624Z"
                },
                {
                    "eventId": "bjeho5nlafj3bdrehgsg",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg",
                    "eventType": "temperature",
                    "data": {
                      "temperature": {
                        "value": 24.9,
                        "updateTime": "2019-05-16T08:15:18.318751Z"
                      }
                    },
                    "timestamp": "2019-05-16T08:15:18.318751Z"
                },
                {
                    "eventId": "bjei2dia9k365r1ntb20",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/bchonol7rihjtvdmd7bg",
                    "eventType": "objectPresent",
                    "data": {
                      "objectPresent": {
                        "state": "NOT_PRESENT",
                        "updateTime": "2019-05-16T08:37:10.711412Z"
                      }
                    },
                    "timestamp": "2019-05-16T08:37:10.711412Z"
                },
                {
                    "eventId": "bnpio6iuvvg2ninodrgg",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji86g",
                    "eventType": "humidity",
                    "data": {
                      "humidity": {
                        "temperature": 22.45,
                        "relativeHumidity": 17,
                        "updateTime": "2019-05-16T06:13:46.369000Z"
                      }
                    },
                    "timestamp": "2019-05-16T06:13:46.369000Z"
                },
                {
                    "eventId": "bnpkl3quvvg2ninq0fng",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji860",
                    "eventType": "objectPresentCount",
                    "data": {
                      "objectPresentCount": {
                        "total": 4176,
                        "updateTime": "2019-05-16T08:23:43.209000Z"
                      }
                    },
                    "timestamp": "2019-05-16T08:23:43.209000Z"
                },
                {
                    "eventId": "bnpklsfkh4f8r5td2b70",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji870",
                    "eventType": "touchCount",
                    "data": {
                      "touchCount": {
                        "total": 469,
                        "updateTime": "2019-05-16T08:25:21.604000Z"
                      }
                    },
                    "timestamp": "2019-05-16T08:25:21.604000Z"
                },
                {
                    "eventId": "bnpku97kh4f8r5td9rb0",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/b6roh6d7rihmn9oji85g",
                    "eventType": "waterPresent",
                    "data": {
                      "waterPresent": {
                        "state": "PRESENT",
                        "updateTime": "2019-05-16T08:43:16.266000Z"
                      }
                    },
                    "timestamp": "2019-05-16T08:43:16.266000Z"
                },
                {
                    "eventId": "bjehr0ig1me000dm66s0",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg",
                    "eventType": "networkStatus",
                    "data": {
                      "networkStatus": {
                        "signalStrength": 45,
                        "rssi": -83,
                        "updateTime": "2019-05-16T08:21:21.076013Z",
                        "cloudConnectors": [
                          {
                            "id": "bdkjbo2v0000uk377c4g",
                            "signalStrength": 45,
                            "rssi": -83
                          }
                        ],
                        "transmissionMode": "LOW_POWER_STANDARD_MODE"
                      }
                    },
                    "timestamp": "2019-05-16T08:21:21.076013Z"
                },
                {
                    "eventId": "bjehr0ig1me000dm66s0",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg",
                    "eventType": "batteryStatus",
                    "data": {
                      "batteryStatus": {
                        "percentage": 100,
                        "updateTime": "2019-05-16T08:21:21.076013Z"
                      }
                    },
                    "timestamp": "2019-05-16T08:21:21.076013Z"
                },
                {
                    "eventId": "bjehr0ig1me000dm66s0",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg",
                    "eventType": "connectionStatus",
                    "data": {
                      "connectionStatus": {
                        "connection": "ETHERNET",
                        "available": [
                          "CELLULAR",
                          "ETHERNET"
                        ],
                        "updateTime": "2019-05-16T08:21:21.076013Z"
                      }
                    },
                    "timestamp": "2019-05-16T08:21:21.076013Z"
                },
                {
                    "eventId": "bjehr0ig1me000dm66s0",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg",
                    "eventType": "ethernetStatus",
                    "data": {
                      "ethernetStatus": {
                        "macAddress": "f0:b5:b7:00:0a:08",
                        "ipAddress": "10.0.0.1",
                        "errors": [],
                        "updateTime": "2019-05-16T08:21:21.076013Z"
                      }
                    },
                    "timestamp": "2019-05-16T08:21:21.076013Z"
                },
                {
                    "eventId": "bjehr0ig1me000dm66s0",
                    "targetName": "projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg",
                    "eventType": "cellularStatus",
                    "data": {
                      "cellularStatus": {
                        "signalStrength": 80,
                        "errors": [],
                        "updateTime": "2019-05-16T08:21:21.076013Z"
                      }
                    },
                    "timestamp": "2019-05-16T08:21:21.076013Z"
                }
            ],
            "nextPageToken": ""
        }
        """.data(using: .utf8)!
        
        //{
        //    "eventId": "bjehr0ig1me000dm66s0",
        //    "targetName": "projects/bhmh0143iktucae701vg/devices/bchonod7rihjtvdmd2vg",
        //    "eventType": "labelsChanged",
        //    "data": {
        //        "added": {},
        //        "modified": {
        //            "name": "Sensor name"
        //        },
        //        "removed": []
        //    },
        //    "timestamp": "2019-05-16T08:21:21.076013Z"
        //},
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : reqQueryParams,
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.getEvents(projectID: reqProjectID, deviceID: reqDeviceID, startDate: reqStart, endDate: reqEnd, eventTypes: EventType.allCases) { result in
            switch result {
                case .success(let events):
                    XCTAssertNotNil(events.touch)
                    XCTAssertNotNil(events.temperature)
                    XCTAssertNotNil(events.objectPresent)
                    XCTAssertNotNil(events.humidity)
                    XCTAssertNotNil(events.objectPresentCount)
                    XCTAssertNotNil(events.touchCount)
                    XCTAssertNotNil(events.waterPresent)
                    XCTAssertNotNil(events.networkStatus)
                    XCTAssertNotNil(events.batteryStatus)
//                    XCTAssertNotNil(events.labelsChanged)
                    XCTAssertNotNil(events.connectionStatus)
                    XCTAssertNotNil(events.ethernetStatus)
                    XCTAssertNotNil(events.cellularStatus)
                    XCTAssertNotNil(events.connectionStatus)
                    
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testGetNoEvents() {
        let reqProjectID = "proj1"
        let reqDeviceID = "dev1"
        let reqURL = URL(string: Disruptive.defaultBaseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/devices/\(reqDeviceID)/events")
        let reqQueryParams: [String: [String]] = [
            "page_size": ["1000"]
        ]
        
        let respData = """
        {
            "events": [],
            "nextPageToken": ""
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : reqQueryParams,
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let exp = expectation(description: "")
        disruptive.getEvents(projectID: reqProjectID, deviceID: reqDeviceID) { result in
            switch result {
                case .success(let events):
                    XCTAssertEqual(events, Events())
                case .failure(let err):
                    XCTFail("Unexpected error: \(err)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testMergeNothing() {
        var events = Events()
        events.temperature = [TemperatureEvent(value: 67, timestamp: Date())]
        events.merge(with: Events())
        
        XCTAssertNil(events.touch)
        XCTAssertNotNil(events.temperature)
        XCTAssertNil(events.objectPresent)
        XCTAssertNil(events.humidity)
        XCTAssertNil(events.objectPresentCount)
        XCTAssertNil(events.touchCount)
        XCTAssertNil(events.waterPresent)
        XCTAssertNil(events.networkStatus)
        XCTAssertNil(events.batteryStatus)
        XCTAssertNil(events.connectionStatus)
        XCTAssertNil(events.ethernetStatus)
        XCTAssertNil(events.cellularStatus)
    }
    
    func testMergeSingleEvent() {
        var events = Events()
        var mergee = Events()
        mergee.temperature = [TemperatureEvent(value: 67, timestamp: Date())]
        events.merge(with: mergee)
        
        XCTAssertNil(events.touch)
        XCTAssertNotNil(events.temperature)
        XCTAssertNil(events.objectPresent)
        XCTAssertNil(events.humidity)
        XCTAssertNil(events.objectPresentCount)
        XCTAssertNil(events.touchCount)
        XCTAssertNil(events.waterPresent)
        XCTAssertNil(events.networkStatus)
        XCTAssertNil(events.batteryStatus)
        XCTAssertNil(events.connectionStatus)
        XCTAssertNil(events.ethernetStatus)
        XCTAssertNil(events.cellularStatus)
    }
    
    func testMergeAllEvents() {
        var mergee = Events()
        mergee.touch              = [TouchEvent(timestamp: Date())]
        mergee.temperature        = [TemperatureEvent(value: 67, timestamp: Date())]
        mergee.objectPresent      = [ObjectPresentEvent(objectPresent: true, timestamp: Date())]
        mergee.humidity           = [HumidityEvent(temperature: 67, relativeHumidity: 90, timestamp: Date())]
        mergee.objectPresentCount = [ObjectPresentCountEvent(total: 67, timestamp: Date())]
        mergee.touchCount         = [TouchCountEvent(total: 88, timestamp: Date())]
        mergee.waterPresent       = [WaterPresentEvent(waterPresent: true, timestamp: Date())]
        mergee.networkStatus      = [NetworkStatusEvent(signalStrength: 22, rssi: 33, timestamp: Date(), cloudConnectors: [], transmissionMode: .standard)]
        mergee.batteryStatus      = [BatteryStatusEvent(percentage: 87, timestamp: Date())]
        mergee.connectionStatus   = [ConnectionStatusEvent(connection: .cellular, available: [.cellular], timestamp: Date())]
        mergee.ethernetStatus     = [EthernetStatusEvent(macAddress: "", ipAddress: "", errors: [], timestamp: Date())]
        mergee.cellularStatus     = [CellularStatusEvent(signalStrength: 78, errors: [], timestamp: Date())]
        
        var events = Events()
        events.merge(with: mergee)
        
        XCTAssertNotNil(events.touch)
        XCTAssertNotNil(events.temperature)
        XCTAssertNotNil(events.objectPresent)
        XCTAssertNotNil(events.humidity)
        XCTAssertNotNil(events.objectPresentCount)
        XCTAssertNotNil(events.touchCount)
        XCTAssertNotNil(events.waterPresent)
        XCTAssertNotNil(events.networkStatus)
        XCTAssertNotNil(events.batteryStatus)
        XCTAssertNotNil(events.connectionStatus)
        XCTAssertNotNil(events.ethernetStatus)
        XCTAssertNotNil(events.cellularStatus)
    }
}
