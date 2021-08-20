//
//  EventTypesTests.swift
//  
//
//  Created by Vegard Solheim Theriault on 02/01/2021.
//

import XCTest
@testable import Disruptive

class EventTypesTests: DisruptiveTests {
    
    func testDecodeTouchEvent() {
        let event = try! JSONDecoder().decode(TouchEvent.self, from: touchEventData())
        XCTAssertEqual(event.timestamp, eventTimestamp)
    }
    
    func testEncodeTouchEvent() {
        let event = TouchEvent(timestamp: eventTimestamp)
        let output = try! JSONEncoder().encode(event)
        assertJSONDatasAreEqual(a: output, b: touchEventData())
    }
    
    func testDecodeTempEvent() {
        let temp1: Float = 25.75
        let temp2: Float = 27.8
        let temp3: Float = 24.7
        let timeDelta = TimeInterval(300)
        let event = try! JSONDecoder().decode(
            TemperatureEvent.self,
            from: tempEventData(temp1: temp1, temp2: temp2, temp3: temp3, timeDelta: timeDelta)
        )
        XCTAssertEqual(event.timestamp, eventTimestamp)
        XCTAssertEqual(event.celsius, temp1)
        XCTAssertEqual(event.samples, [
            TemperatureEvent.TemperatureSample(celsius: temp1, timestamp: eventTimestamp),
            TemperatureEvent.TemperatureSample(celsius: temp2, timestamp: eventTimestamp.addingTimeInterval(-timeDelta)),
            TemperatureEvent.TemperatureSample(celsius: temp3, timestamp: eventTimestamp.addingTimeInterval(-timeDelta*2))
        ])
    }
    
    func testEncodeTempEvent() {
        let temp1: Float = 25.75
        let temp2: Float = 27.5
        let temp3: Float = 24.25
        let timeDelta = TimeInterval(300)
        var event = TemperatureEvent(
            celsius: temp1,
            timestamp: eventTimestamp,
            samples: [
                TemperatureEvent.TemperatureSample(celsius: temp1, timestamp: eventTimestamp),
                TemperatureEvent.TemperatureSample(celsius: temp2, timestamp: eventTimestamp.addingTimeInterval(-timeDelta)),
                TemperatureEvent.TemperatureSample(celsius: temp3, timestamp: eventTimestamp.addingTimeInterval(-timeDelta*2))
            ]
        )
        var output = try! JSONEncoder().encode(event)
        assertJSONDatasAreEqual(a: output, b: tempEventData(temp1: temp1, temp2: temp2, temp3: temp3, timeDelta: timeDelta))
        XCTAssertEqual(celsiusToFahrenheit(celsius: temp1), event.fahrenheit, accuracy: 0.0001)
        
        let fahrenheit: Float = 1
        event = TemperatureEvent(fahrenheit: fahrenheit, timestamp: eventTimestamp)
        output = try! JSONEncoder().encode(event)
        XCTAssertEqual(fahrenheitToCelsius(fahrenheit: fahrenheit), event.celsius, accuracy: 0.0001)
    }
    
    func testDecodeObjectPresentEvent() {
        let present = try! JSONDecoder().decode(ObjectPresentEvent.self, from: objectPresentData(stateStr: "PRESENT"))
        XCTAssertEqual(present.state, .objectPresent)
        XCTAssertEqual(present.timestamp, eventTimestamp)
        
        let notPresent = try! JSONDecoder().decode(ObjectPresentEvent.self, from: objectPresentData(stateStr: "NOT_PRESENT"))
        XCTAssertEqual(notPresent.state, .objectNotPresent)
        XCTAssertEqual(notPresent.timestamp, eventTimestamp)
        
        let newState = try! JSONDecoder().decode(ObjectPresentEvent.self, from: objectPresentData(stateStr: "NEW_STATE"))
        XCTAssertEqual(newState.state, .unknown(value: "NEW_STATE"))
        XCTAssertEqual(newState.timestamp, eventTimestamp)
    }
    
    func testEncodeObjectPresentEvent() {
        let present = try! JSONEncoder().encode(ObjectPresentEvent(state: .objectPresent, timestamp: eventTimestamp))
        assertJSONDatasAreEqual(a: present, b: objectPresentData(stateStr: "PRESENT"))
        
        let notPresent = try! JSONEncoder().encode(ObjectPresentEvent(state: .objectNotPresent, timestamp: eventTimestamp))
        assertJSONDatasAreEqual(a: notPresent, b: objectPresentData(stateStr: "NOT_PRESENT"))
        
        XCTAssertThrowsError(try JSONEncoder().encode(ObjectPresentEvent(state: .unknown(value: "NEW_STATE"), timestamp: eventTimestamp)))
    }
    
    func testDecodeWaterPresentEvent() {
        let present = try! JSONDecoder().decode(WaterPresentEvent.self, from: waterPresentData(stateStr: "PRESENT"))
        XCTAssertEqual(present.state, .waterPresent)
        XCTAssertEqual(present.timestamp, eventTimestamp)
        
        let notPresent = try! JSONDecoder().decode(WaterPresentEvent.self, from: waterPresentData(stateStr: "NOT_PRESENT"))
        XCTAssertEqual(notPresent.state, .waterNotPresent)
        XCTAssertEqual(notPresent.timestamp, eventTimestamp)
        
        let newState = try! JSONDecoder().decode(WaterPresentEvent.self, from: waterPresentData(stateStr: "NEW_STATE"))
        XCTAssertEqual(newState.state, .unknown(value: "NEW_STATE"))
        XCTAssertEqual(newState.timestamp, eventTimestamp)
    }
    
    func testEncodeWaterPresentEvent() {
        let present = try! JSONEncoder().encode(WaterPresentEvent(state: .waterPresent, timestamp: eventTimestamp))
        assertJSONDatasAreEqual(a: present, b: waterPresentData(stateStr: "PRESENT"))
        
        let notPresent = try! JSONEncoder().encode(WaterPresentEvent(state: .waterNotPresent, timestamp: eventTimestamp))
        assertJSONDatasAreEqual(a: notPresent, b: waterPresentData(stateStr: "NOT_PRESENT"))
        
        XCTAssertThrowsError(try JSONEncoder().encode(WaterPresentEvent(state: .unknown(value: "NEW_STATE"), timestamp: eventTimestamp)))
    }
    
    func testDecodeBatteryEvent() {
        let percentage = 98
        let event = try! JSONDecoder().decode(BatteryStatusEvent.self, from: batteryEventData(percentage: percentage))
        XCTAssertEqual(event.timestamp, eventTimestamp)
        XCTAssertEqual(event.percentage, percentage)
    }
    
    func testEncodeBatteryEvent() {
        let percentage = 0
        let event = BatteryStatusEvent(percentage: percentage, timestamp: eventTimestamp)
        let output = try! JSONEncoder().encode(event)
        assertJSONDatasAreEqual(a: output, b: batteryEventData(percentage: percentage))
    }
    
    func testDecodeHumidityEvent() {
        let temp: Float = 26.75
        let hum: Float = 88
        let event = try! JSONDecoder().decode(HumidityEvent.self, from: humidityEventData(temp: temp, hum: hum))
        XCTAssertEqual(event.timestamp, eventTimestamp)
        XCTAssertEqual(event.temperature, temp)
        XCTAssertEqual(event.relativeHumidity, hum)
    }
    
    func testEncodeHumidityEvent() {
        let temp: Float = 26.75
        let hum: Float = 88
        let event = HumidityEvent(temperature: temp, relativeHumidity: hum, timestamp: eventTimestamp)
        let output = try! JSONEncoder().encode(event)
        assertJSONDatasAreEqual(a: output, b: humidityEventData(temp: temp, hum: hum))
    }
    
    func testDecodeObjectPresentCountEvent() {
        let total = 98
        let event = try! JSONDecoder().decode(ObjectPresentCountEvent.self, from: objectPresentCountData(total: total))
        XCTAssertEqual(event.timestamp, eventTimestamp)
        XCTAssertEqual(event.total, total)
    }
    
    func testEncodeObjectPresentCountEvent() {
        let total = 0
        let event = ObjectPresentCountEvent(total: total, timestamp: eventTimestamp)
        let output = try! JSONEncoder().encode(event)
        assertJSONDatasAreEqual(a: output, b: objectPresentCountData(total: total))
    }
    
    func testDecodeTouchCountEvent() {
        let total = 98
        let event = try! JSONDecoder().decode(TouchCountEvent.self, from: touchCountData(total: total))
        XCTAssertEqual(event.timestamp, eventTimestamp)
        XCTAssertEqual(event.total, total)
    }
    
    func testEncodeTouchCountEvent() {
        let total = 0
        let event = TouchCountEvent(total: total, timestamp: eventTimestamp)
        let output = try! JSONEncoder().encode(event)
        assertJSONDatasAreEqual(a: output, b: touchCountData(total: total))
    }
    
    func testDecodeNetworkStatusEvent() {
        let dataA = networkStatusData(signalStrength: 79, rssi: -67, ccons: [], transmissionModeStr: "LOW_POWER_STANDARD_MODE")
        let eventA = try! JSONDecoder().decode(NetworkStatusEvent.self, from: dataA)
        XCTAssertEqual(eventA.timestamp, eventTimestamp)
        XCTAssertEqual(eventA.signalStrength, 79)
        XCTAssertEqual(eventA.rssi, -67)
        XCTAssertEqual(eventA.cloudConnectors, [])
        XCTAssertEqual(eventA.transmissionMode, .standard)
        
        let dataB = networkStatusData(signalStrength: 0, rssi: 0, ccons: [(id: "id", signalStrength: 50, rssi: -30)], transmissionModeStr: "HIGH_POWER_BOOST_MODE")
        let eventB = try! JSONDecoder().decode(NetworkStatusEvent.self, from: dataB)
        XCTAssertEqual(eventB.timestamp, eventTimestamp)
        XCTAssertEqual(eventB.signalStrength, 0)
        XCTAssertEqual(eventB.rssi, 0)
        XCTAssertEqual(eventB.cloudConnectors, [NetworkStatusEvent.CloudConnector(identifier: "id", signalStrength: 50, rssi: -30)])
        XCTAssertEqual(eventB.transmissionMode, .boost)
        
        let dataC = networkStatusData(signalStrength: 100, rssi: -90, ccons: [(id: "id", signalStrength: 50, rssi: -30), (id: "id2", signalStrength: 40, rssi: -40)], transmissionModeStr: "UNKNOWN_POWER_MODE")
        let eventC = try! JSONDecoder().decode(NetworkStatusEvent.self, from: dataC)
        XCTAssertEqual(eventC.timestamp, eventTimestamp)
        XCTAssertEqual(eventC.signalStrength, 100)
        XCTAssertEqual(eventC.rssi, -90)
        XCTAssertEqual(eventC.cloudConnectors, [NetworkStatusEvent.CloudConnector(identifier: "id", signalStrength: 50, rssi: -30),NetworkStatusEvent.CloudConnector(identifier: "id2", signalStrength: 40, rssi: -40)])
        XCTAssertEqual(eventC.transmissionMode, .unknown(value: "UNKNOWN_POWER_MODE"))
    }
    
    func testEncodeNetworkStatusEvent() {
        let eventA = NetworkStatusEvent(signalStrength: 79, rssi: -67, timestamp: eventTimestamp, cloudConnectors: [], transmissionMode: .standard)
        let outputA = try! JSONEncoder().encode(eventA)
        let eventAData = networkStatusData(signalStrength: 79, rssi: -67, ccons: [], transmissionModeStr: "LOW_POWER_STANDARD_MODE")
        assertJSONDatasAreEqual(a: outputA, b: eventAData)
        
        
        let eventB = NetworkStatusEvent(signalStrength: 0, rssi: 0, timestamp: eventTimestamp, cloudConnectors: [NetworkStatusEvent.CloudConnector(identifier: "id", signalStrength: 40, rssi: -40)], transmissionMode: .boost)
        let outputB = try! JSONEncoder().encode(eventB)
        let eventBData = networkStatusData(signalStrength: 0, rssi: 0, ccons: [(id: "id", signalStrength: 40, rssi: -40)], transmissionModeStr: "HIGH_POWER_BOOST_MODE")
        assertJSONDatasAreEqual(a: outputB, b: eventBData)
        
        
        let eventC = NetworkStatusEvent(signalStrength: 100, rssi: -90, timestamp: eventTimestamp, cloudConnectors: [NetworkStatusEvent.CloudConnector(identifier: "id", signalStrength: 40, rssi: -40),NetworkStatusEvent.CloudConnector(identifier: "id2", signalStrength: 30, rssi: -30)], transmissionMode: .standard)
        let outputC = try! JSONEncoder().encode(eventC)
        let eventCData = networkStatusData(signalStrength: 100, rssi: -90, ccons: [(id: "id", signalStrength: 40, rssi: -40), (id: "id2", signalStrength: 30, rssi: -30)], transmissionModeStr: "LOW_POWER_STANDARD_MODE")
        assertJSONDatasAreEqual(a: outputC, b: eventCData)
        
        
        let eventD = NetworkStatusEvent(signalStrength: 79, rssi: -67, timestamp: eventTimestamp, cloudConnectors: [], transmissionMode: .unknown(value: "UNKNOWN_POWER_MODE"))
        XCTAssertThrowsError(try JSONEncoder().encode(eventD))
    }
    
    func testDecodeConnectionStatusEvent() {
        let a = try! JSONDecoder().decode(ConnectionStatusEvent.self, from: connectionStatusData(connStr: "CELLULAR", availableStrings: []))
        XCTAssertEqual(a.connection, .cellular)
        XCTAssertEqual(a.available, [])
        XCTAssertEqual(a.timestamp, eventTimestamp)
        XCTAssertGreaterThan(a.connection.displayName().count, 0)
        a.available.forEach { XCTAssertGreaterThan($0.displayName().count, 0)}
        
        let b = try! JSONDecoder().decode(ConnectionStatusEvent.self, from: connectionStatusData(connStr: "ETHERNET", availableStrings: ["ETHERNET"]))
        XCTAssertEqual(b.connection, .ethernet)
        XCTAssertEqual(b.available, [.ethernet])
        XCTAssertEqual(b.timestamp, eventTimestamp)
        XCTAssertGreaterThan(b.connection.displayName().count, 0)
        b.available.forEach { XCTAssertGreaterThan($0.displayName().count, 0)}
        
        let c = try! JSONDecoder().decode(ConnectionStatusEvent.self, from: connectionStatusData(connStr: "OFFLINE", availableStrings: ["ETHERNET","OFFLINE","UNKNOWN_NETWORK_TYPE","CELLULAR"]))
        XCTAssertEqual(c.connection, .offline)
        XCTAssertEqual(c.available, [.ethernet, .unknown(value: "OFFLINE"), .unknown(value: "UNKNOWN_NETWORK_TYPE"), .cellular])
        XCTAssertEqual(c.timestamp, eventTimestamp)
        XCTAssertGreaterThan(c.connection.displayName().count, 0)
        c.available.forEach { XCTAssertGreaterThan($0.displayName().count, 0)}
        
        let d = try! JSONDecoder().decode(ConnectionStatusEvent.self, from: connectionStatusData(connStr: "UNKNOWN_CONNECTION", availableStrings: ["CELLULAR", "ETHERNET"]))
        XCTAssertEqual(d.connection, .unknown(value: "UNKNOWN_CONNECTION"))
        XCTAssertEqual(d.available, [.cellular, .ethernet])
        XCTAssertEqual(d.timestamp, eventTimestamp)
        XCTAssertGreaterThan(d.connection.displayName().count, 0)
        d.available.forEach { XCTAssertGreaterThan($0.displayName().count, 0)}
    }
    
    func testEncodeConnectionStatusEvent() {
        let a = try! JSONEncoder().encode(ConnectionStatusEvent(connection: .cellular, available: [], timestamp: eventTimestamp))
        assertJSONDatasAreEqual(a: a, b: connectionStatusData(connStr: "CELLULAR", availableStrings: []))
        
        let b = try! JSONEncoder().encode(ConnectionStatusEvent(connection: .ethernet, available: [.ethernet], timestamp: eventTimestamp))
        assertJSONDatasAreEqual(a: b, b: connectionStatusData(connStr: "ETHERNET", availableStrings: ["ETHERNET"]))
        
        let c = try! JSONEncoder().encode(ConnectionStatusEvent(connection: .offline, available: [.cellular, .ethernet], timestamp: eventTimestamp))
        assertJSONDatasAreEqual(a: c, b: connectionStatusData(connStr: "OFFLINE", availableStrings: ["CELLULAR", "ETHERNET"]))
        
        XCTAssertThrowsError(try JSONEncoder().encode(ConnectionStatusEvent(connection: .unknown(value: ""), available: [], timestamp: eventTimestamp)))
        XCTAssertThrowsError(try JSONEncoder().encode(ConnectionStatusEvent(connection: .offline, available: [.unknown(value: "")], timestamp: eventTimestamp)))
    }
    
    func testDecodeCellularStatusEvent() {
        let a = try! JSONDecoder().decode(CellularStatusEvent.self, from: cellularStatusData(signalStrength: 80, errors: []))
        XCTAssertEqual(a.signalStrength, 80)
        XCTAssertEqual(a.errors, [])
        XCTAssertEqual(a.timestamp, eventTimestamp)
        
        let b = try! JSONDecoder().decode(CellularStatusEvent.self, from: cellularStatusData(signalStrength: 0, errors: [(code: "errorCode", message: "errorMessage")]))
        XCTAssertEqual(b.signalStrength, 0)
        XCTAssertEqual(b.errors, [CellularStatusEvent.ErrorMessage(code: "errorCode", message: "errorMessage")])
        XCTAssertEqual(b.timestamp, eventTimestamp)
    }
    
    func testEncodeCellularStatusEvent() {
        let a = try! JSONEncoder().encode(CellularStatusEvent(signalStrength: 100, errors: [], timestamp: eventTimestamp))
        assertJSONDatasAreEqual(a: a, b: cellularStatusData(signalStrength: 100, errors: []))
        
        let b = try! JSONEncoder().encode(CellularStatusEvent(signalStrength: 10, errors: [CellularStatusEvent.ErrorMessage(code: "errorCode", message: "errorMessage")], timestamp: eventTimestamp))
        assertJSONDatasAreEqual(a: b, b: cellularStatusData(signalStrength: 10, errors: [(code: "errorCode", message: "errorMessage")]))
    }
    
    func testDecodeEthernetStatusEvent() {
        let a = try! JSONDecoder().decode(EthernetStatusEvent.self, from: ethernetStatusData(macAddress: "f0:b5:b7:00:00:09", ipAddress: "10.0.16.199", errors: []))
        XCTAssertEqual(a.macAddress, "f0:b5:b7:00:00:09")
        XCTAssertEqual(a.ipAddress, "10.0.16.199")
        XCTAssertEqual(a.errors, [])
        XCTAssertEqual(a.timestamp, eventTimestamp)
        
        let b = try! JSONDecoder().decode(EthernetStatusEvent.self, from: ethernetStatusData(macAddress: "f0:b5:b7:00:00:09", ipAddress: "10.0.16.199", errors: [(code: "errorCode", message: "errorMessage")]))
        XCTAssertEqual(b.macAddress, "f0:b5:b7:00:00:09")
        XCTAssertEqual(b.ipAddress, "10.0.16.199")
        XCTAssertEqual(b.errors, [EthernetStatusEvent.ErrorMessage(code: "errorCode", message: "errorMessage")])
        XCTAssertEqual(b.timestamp, eventTimestamp)
    }
    
    func testEncodeEthernetStatusEvent() {
        let a = try! JSONEncoder().encode(EthernetStatusEvent(macAddress: "f0:b5:b7:00:00:09", ipAddress: "10.0.16.199", errors: [], timestamp: eventTimestamp))
        assertJSONDatasAreEqual(a: a, b: ethernetStatusData(macAddress: "f0:b5:b7:00:00:09", ipAddress: "10.0.16.199", errors: []))
        
        let b = try! JSONEncoder().encode(EthernetStatusEvent(macAddress: "f0:b5:b7:00:00:09", ipAddress: "10.0.16.199", errors: [EthernetStatusEvent.ErrorMessage(code: "errorCode", message: "errorMessage")], timestamp: eventTimestamp))
        assertJSONDatasAreEqual(a: b, b: ethernetStatusData(macAddress: "f0:b5:b7:00:00:09", ipAddress: "10.0.16.199", errors: [(code: "errorCode", message: "errorMessage")]))
    }
}


// -------------------------------
// MARK: Helpers
// -------------------------------

extension EventTypesTests {
    var eventTimestampString: String { "2020-07-21T07:09:09.603Z" }
    var eventTimestamp: Date { try! Date(iso8601String: eventTimestampString) }
    
    func touchEventData() -> Data {
        return """
        {
            "updateTime": "\(eventTimestampString)"
        }
        """.data(using: .utf8)!
    }
    
    func tempEventData(temp1: Float, temp2: Float, temp3: Float, timeDelta: TimeInterval) -> Data {
        return """
        {
            "value": \(temp1),
            "updateTime": "\(eventTimestampString)",
            "samples": [
                {
                    "value": \(temp1),
                    "sampleTime": "\(eventTimestamp.iso8601String())"
                },
                {
                    "value": \(temp2),
                    "sampleTime": "\(eventTimestamp.addingTimeInterval(-timeDelta).iso8601String())"
                },
                {
                    "value": \(temp3),
                    "sampleTime": "\(eventTimestamp.addingTimeInterval(-timeDelta*2).iso8601String())"
                }
            ]
        }
        """.data(using: .utf8)!
    }
    
    func objectPresentData(stateStr: String) -> Data {
        return """
        {
            "state": "\(stateStr)",
            "updateTime": "\(eventTimestampString)"
        }
        """.data(using: .utf8)!
    }
    
    func waterPresentData(stateStr: String) -> Data {
        return """
        {
            "state": "\(stateStr)",
            "updateTime": "\(eventTimestampString)"
        }
        """.data(using: .utf8)!
    }
    
    func batteryEventData(percentage: Int) -> Data {
        return """
        {
            "percentage": \(percentage),
            "updateTime": "\(eventTimestampString)"
        }
        """.data(using: .utf8)!
    }
    
    func humidityEventData(temp: Float, hum: Float) -> Data {
        return """
        {
            "temperature": \(temp),
            "relativeHumidity": \(hum),
            "updateTime": "\(eventTimestampString)"
        }
        """.data(using: .utf8)!
    }
    
    func objectPresentCountData(total: Int) -> Data {
        return """
        {
            "total": \(total),
            "updateTime": "\(eventTimestampString)"
        }
        """.data(using: .utf8)!
    }
    
    func touchCountData(total: Int) -> Data {
        return """
        {
            "total": \(total),
            "updateTime": "\(eventTimestampString)"
        }
        """.data(using: .utf8)!
    }
    
    func networkStatusData(
        signalStrength      : Int,
        rssi                : Int,
        ccons               : [(id: String, signalStrength: Int, rssi: Int)],
        transmissionModeStr : String) -> Data
    {
        let cconsStr = ccons.map({
            return """
            {
                "id": "\($0.id)",
                "signalStrength": \($0.signalStrength),
                "rssi": \($0.rssi)
            }
            """
        }).joined(separator: ",")
        
        return """
        {
            "signalStrength": \(signalStrength),
            "rssi": \(rssi),
            "updateTime": "\(eventTimestampString)",
            "cloudConnectors": [\(cconsStr)],
            "transmissionMode": "\(transmissionModeStr)"
        }
        """.data(using: .utf8)!
    }
    
    func connectionStatusData(connStr: String, availableStrings: [String]) -> Data {
        return """
        {
            "connection": "\(connStr)",
            "available": [\(availableStrings.map { "\"\($0)\"" }.joined(separator: ",") )],
            "updateTime": "\(eventTimestampString)"
        }
        """.data(using: .utf8)!
    }
    
    func cellularStatusData(signalStrength: Int, errors: [(code: String, message: String)]) -> Data {
        let errorsStr = errors.map({
            return """
            {
                "code": "\($0.code)",
                "message": "\($0.message)"
            }
            """
        }).joined(separator: ",")
        
        return """
        {
            "signalStrength": \(signalStrength),
            "errors": [\(errorsStr)],
            "updateTime": "\(eventTimestampString)"
        }
        """.data(using: .utf8)!
    }
    
    func ethernetStatusData(macAddress: String, ipAddress: String, errors: [(code: String, message: String)]) -> Data {
        let errorsStr = errors.map({
            return """
            {
                "code": "\($0.code)",
                "message": "\($0.message)"
            }
            """
        }).joined(separator: ",")
        
        return """
        {
            "macAddress": "\(macAddress)",
            "ipAddress": "\(ipAddress)",
            "errors": [\(errorsStr)],
            "updateTime": "\(eventTimestampString)"
        }
        """.data(using: .utf8)!
    }
}
