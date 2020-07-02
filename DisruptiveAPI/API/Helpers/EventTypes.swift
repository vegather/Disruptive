//
//  Event.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 27/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation


// -------------------------------
// MARK: Events
// -------------------------------

public struct TouchEvent: Decodable {
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case timestamp = "updateTime"
    }
    
    public init(timestamp: Date) {
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
    }
}

public struct TemperatureEvent: Decodable {
    public let value: Float
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case value
        case timestamp = "updateTime"
    }
    
    public init(value: Float, timestamp: Date) {
        self.value = value
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the value
        self.value = try values.decode(Float.self, forKey: .value)
    }
}

public struct ObjectPresentEvent: Decodable {
    public let objectPresent: Bool?
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case objectPresent = "state"
        case timestamp = "updateTime"
    }
    
    public init(objectPresent: Bool?, timestamp: Date) {
        self.objectPresent = objectPresent
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the state
        let stateString = try values.decode(String.self, forKey: .objectPresent)
        switch stateString {
            case "NOT_PRESENT": self.objectPresent = false
            case "PRESENT"    : self.objectPresent = true
            
            // "UNKNOWN"
            default           : self.objectPresent = nil
        }
    }
}

public struct HumidityEvent: Decodable {
    public let temperature: Float
    public let relativeHumidity: Float
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case temperature
        case relativeHumidity
        case timestamp = "updateTime"
    }
    
    public init(temperature: Float, relativeHumidity: Float, timestamp: Date) {
        self.temperature = temperature
        self.relativeHumidity = relativeHumidity
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the values
        self.temperature = try values.decode(Float.self, forKey: .temperature)
        self.relativeHumidity = try values.decode(Float.self, forKey: .relativeHumidity)
    }
}

public struct ObjectPresentCount: Decodable {
    public let total: Int
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case total
        case timestamp = "updateTime"
    }
    
    public init(total: Int, timestamp: Date) {
        self.total = total
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the total
        self.total = try values.decode(Int.self, forKey: .total)
    }
}

public struct TouchCount: Decodable {
    public let total: Int
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case total
        case timestamp = "updateTime"
    }
    
    public init(total: Int, timestamp: Date) {
        self.total = total
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the total
        self.total = try values.decode(Int.self, forKey: .total)
    }
}

public struct WaterPresentEvent: Decodable {
    public let waterPresent: Bool?
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case waterPresent = "state"
        case timestamp = "updateTime"
    }
    
    public init(waterPresent: Bool, timestamp: Date) {
        self.waterPresent = waterPresent
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the state
        let stateString = try values.decode(String.self, forKey: .waterPresent)
        switch stateString {
            case "NOT_PRESENT": self.waterPresent = false
            case "PRESENT"    : self.waterPresent = true
            default           : self.waterPresent = nil
        }
    }
}



// -------------------------------
// MARK: Sensor Status
// -------------------------------

public struct NetworkStatus: Decodable {
    public let signalStrength: Int
    public let rssi: Int
    public let timestamp: Date
    public let cloudConnectors: [CloudConnector]
    public let transmissionMode: TransmissionMode
    
    public struct CloudConnector: Decodable {
        public let id: String
        public let signalStrength: Int
    }
    
    public enum TransmissionMode: String, Decodable {
        case unknown  = "UNKNOWN_MODE"
        case standard = "LOW_POWER_STANDARD_MODE"
        case boost    = "HIGH_POWER_BOOST_MODE"
    }
    
    private enum CodingKeys: String, CodingKey {
        case signalStrength
        case rssi
        case timestamp = "updateTime"
        case cloudConnectors
        case transmissionMode
    }
    
    public init(
        signalStrength   : Int,
        rssi             : Int,
        timestamp        : Date,
        cloudConnectors  : [CloudConnector],
        transmissionMode : TransmissionMode)
    {
        self.signalStrength   = signalStrength
        self.rssi             = rssi
        self.timestamp        = timestamp
        self.cloudConnectors  = cloudConnectors
        self.transmissionMode = transmissionMode
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the other values
        self.signalStrength   = try values.decode(Int.self, forKey: .signalStrength)
        self.rssi             = try values.decode(Int.self, forKey: .rssi)
        self.cloudConnectors  = try values.decode([CloudConnector].self, forKey: .cloudConnectors)
        self.transmissionMode = try values.decode(TransmissionMode.self, forKey: .transmissionMode)
    }
}

public struct BatteryStatus: Decodable {
    public let percentage: Int
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case percentage
        case timestamp = "updateTime"
    }
    
    public init(percentage: Int, timestamp: Date) {
        self.percentage = percentage
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the percentage
        self.percentage = try values.decode(Int.self, forKey: .percentage)
    }
}

/// This will only be available on device stream
public struct LabelsChanged: Decodable {
    public let added    : [String: String]
    public let modified : [String: String]
    public let removed  : [String]
    
    public init(added: [String: String], modified: [String: String], removed: [String]) {
        self.added = added
        self.modified = modified
        self.removed = removed
    }
}



// -------------------------------
// MARK: Cloud Connector
// -------------------------------

public struct ConnectionStatus: Decodable {
    public enum Connection: String, Decodable {
        case offline  = "OFFLINE"
        case ethernet = "ETHERNET"
        case cellular = "CELLULAR"
        
        public func humanReadable() -> String {
            switch self {
                case .offline: return "Offline"
                case .ethernet: return "Ethernet"
                case .cellular: return "Cellular"
            }
        }
    }
    
    public enum Available: String, Decodable {
        case ethernet = "ETHERNET"
        case cellular = "CELLULAR"
        
        public func humanReadable() -> String {
            switch self {
                case .ethernet: return "Ethernet"
                case .cellular: return "Cellular"
            }
        }
    }
    
    public let connection: Connection
    public let available: [Available]
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case connection
        case available
        case timestamp = "updateTime"
    }
    
    public init(connection: Connection, available: [Available], timestamp: Date) {
        self.connection = connection
        self.available = available
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the other values
        self.connection = try values.decode(Connection.self, forKey: .connection)
        self.available  = try values.decode([Available].self, forKey: .available)
    }
}

public struct EthernetStatus: Decodable {
    public struct ErrorMessage: Decodable {
        let code: String
        let message: String
    }
    
    public let macAddress: String
    public let ipAddress: String
    public let errors: [ErrorMessage]
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case macAddress
        case ipAddress
        case errors
        case timestamp = "updateTime"
    }
    
    public init(macAddress: String, ipAddress: String, errors: [ErrorMessage], timestamp: Date) {
        self.macAddress = macAddress
        self.ipAddress = ipAddress
        self.errors = errors
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the other values
        self.macAddress = try values.decode(String.self, forKey: .macAddress)
        self.ipAddress  = try values.decode(String.self, forKey: .ipAddress)
        self.errors     = try values.decode([ErrorMessage].self, forKey: .errors)
    }
}

public struct CellularStatus: Decodable {
    public struct ErrorMessage: Decodable {
        let code: String
        let message: String
    }
    
    public let signalStrength: Int
    public let errors: [ErrorMessage]
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case signalStrength
        case errors
        case timestamp = "updateTime"
    }
    
    public init(signalStrength: Int, errors: [ErrorMessage], timestamp: Date) {
        self.signalStrength = signalStrength
        self.errors = errors
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the other values
        self.signalStrength = try values.decode(Int.self, forKey: .signalStrength)
        self.errors         = try values.decode([ErrorMessage].self, forKey: .errors)
    }
}

public struct ConnectionLatency: Decodable {
    public let avgLatencyMilliseconds: Int
    public let minLatencyMilliseconds: Int
    public let maxLatencyMilliseconds: Int
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case avgLatencyMilliseconds = "avgLatencyMillis"
        case minLatencyMilliseconds = "minLatencyMillis"
        case maxLatencyMilliseconds = "maxLatencyMillis"
        case timestamp = "updateTime"
    }
    
    public init(avgLatencyMilliseconds: Int, minLatencyMilliseconds: Int, maxLatencyMilliseconds: Int, timestamp: Date) {
        self.avgLatencyMilliseconds = avgLatencyMilliseconds
        self.minLatencyMilliseconds = minLatencyMilliseconds
        self.maxLatencyMilliseconds = maxLatencyMilliseconds
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try values.decode(String.self, forKey: .timestamp)
        self.timestamp = try decodeDate(iso8601: timeString)
        
        // Extract the other values
        self.avgLatencyMilliseconds = try values.decode(Int.self, forKey: .avgLatencyMilliseconds)
        self.minLatencyMilliseconds = try values.decode(Int.self, forKey: .minLatencyMilliseconds)
        self.maxLatencyMilliseconds = try values.decode(Int.self, forKey: .maxLatencyMilliseconds)
    }
}



// -------------------------------
// MARK: Events
// -------------------------------

public enum EventType: String, Encodable, CodingKey {
    // Events
    case touch
    case temperature
    case objectPresent
    case humidity
    case objectPresentCount
    case touchCount
    case waterPresent
    
    // Sensor status
    case networkStatus
    case batteryStatus
    case labelsChanged
    
    // Cloud Connector
    case connectionStatus
    case ethernetStatus
    case cellularStatus
    case latencyStatus
}

/// Used to simplify event JSON parsing
internal enum EventContainer: Decodable {
    // Events
    case touch              (deviceID: String, event: TouchEvent)
    case temperature        (deviceID: String, event: TemperatureEvent)
    case objectPresent      (deviceID: String, event: ObjectPresentEvent)
    case humidity           (deviceID: String, event: HumidityEvent)
    case objectPresentCount (deviceID: String, event: ObjectPresentCount)
    case touchCount         (deviceID: String, event: TouchCount)
    case waterPresent       (deviceID: String, event: WaterPresentEvent)
    
    // Sensor Status
    case networkStatus      (deviceID: String, event: NetworkStatus)
    case batteryStatus      (deviceID: String, event: BatteryStatus)
    case labelsChanged      (deviceID: String, event: LabelsChanged)
    
    // Cloud Connector
    case connectionStatus   (deviceID: String, event: ConnectionStatus)
    case ethernetStatus     (deviceID: String, event: EthernetStatus)
    case cellularStatus     (deviceID: String, event: CellularStatus)
    case latencyStatus      (deviceID: String, event: ConnectionLatency)
}

extension EventContainer {
    enum CodingKeys: String, CodingKey {
        case eventType
        case targetName
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let eventTypeString = try container.decode(String.self, forKey: .eventType)
        
        guard let eventType = EventType(rawValue: eventTypeString) else {
            throw ParseError.eventType(type: eventTypeString)
        }
        
        let targetName = try container.decode(String.self, forKey: .targetName)
        let deviceID = targetName.components(separatedBy: "/").last ?? ""

        let eventContainer = try container.nestedContainer(keyedBy: EventType.self, forKey: .data)
        
        switch eventType {
            // Events
            case .touch:
                let event = try eventContainer.decode(TouchEvent.self, forKey: .touch)
                self = .touch(deviceID: deviceID, event: event)
            case .temperature:
                let event = try eventContainer.decode(TemperatureEvent.self, forKey: .temperature)
                self = .temperature(deviceID: deviceID, event: event)
            case .objectPresent:
                let event = try eventContainer.decode(ObjectPresentEvent.self, forKey: .objectPresent)
                self = .objectPresent(deviceID: deviceID, event: event)
            case .humidity:
                let event = try eventContainer.decode(HumidityEvent.self, forKey: .humidity)
                self = .humidity(deviceID: deviceID, event: event)
            case .objectPresentCount:
                let event = try eventContainer.decode(ObjectPresentCount.self, forKey: .objectPresentCount)
                self = .objectPresentCount(deviceID: deviceID, event: event)
            case .touchCount:
                let event = try eventContainer.decode(TouchCount.self, forKey: .touchCount)
                self = .touchCount(deviceID: deviceID, event: event)
            case .waterPresent:
                let event = try eventContainer.decode(WaterPresentEvent.self, forKey: .waterPresent)
                self = .waterPresent(deviceID: deviceID, event: event)
                
            // Sensor Status
            case .networkStatus:
                let event = try eventContainer.decode(NetworkStatus.self, forKey: .networkStatus)
                self = .networkStatus(deviceID: deviceID, event: event)
            case .batteryStatus:
                let event = try eventContainer.decode(BatteryStatus.self, forKey: .batteryStatus)
                self = .batteryStatus(deviceID: deviceID, event: event)
            case .labelsChanged:
                let event = try eventContainer.decode(LabelsChanged.self, forKey: .labelsChanged)
                self = .labelsChanged(deviceID: deviceID, event: event)
                
            // Cloud Connector
            case .connectionStatus:
                let event = try eventContainer.decode(ConnectionStatus.self, forKey: .connectionStatus)
                self = .connectionStatus(deviceID: deviceID, event: event)
            case .ethernetStatus:
                let event = try eventContainer.decode(EthernetStatus.self, forKey: .ethernetStatus)
                self = .ethernetStatus(deviceID: deviceID, event: event)
            case .cellularStatus:
                let event = try eventContainer.decode(CellularStatus.self, forKey: .cellularStatus)
                self = .cellularStatus(deviceID: deviceID, event: event)
            case .latencyStatus:
                let event = try eventContainer.decode(ConnectionLatency.self, forKey: .latencyStatus)
                self = .latencyStatus(deviceID: deviceID, event: event)
        }
    }
}



// -------------------------------
// MARK: Helpers
// -------------------------------

private func decodeDate(iso8601: String) throws -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: iso8601) {
        return date
    } else {
        throw ParseError.dateFormat(date: "Failed to parse ISO 8601 string: \(iso8601)")
    }
}
