//
//  Event.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 27/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation


/// An enumeration of all the possible types of events that a device can emit.
public enum EventType: String, Decodable, CodingKey, CaseIterable {
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
    //    case labelsChanged
    
    // Cloud Connector
    case connectionStatus
    case ethernetStatus
    case cellularStatus
}




// -------------------------------
// MARK: Events
// -------------------------------

/// An event that is sent whenever a device is touched. This event is sent for almost all the
/// available device types (except a few like the counting sensors).
///
/// See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#h_e9491be1-b53d-447b-9c21-de436175a0e1) for more details.
public struct TouchEvent: Decodable, Equatable {
    /// The timestamp of when the device was touched
    public let timestamp: Date
    
    
    /// Creates a new `TouchEvent`. Creating a new touch event can be useful for testing purposes.
    public init(timestamp: Date) {
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
    }
    
    private enum CodingKeys: String, CodingKey {
        case timestamp = "updateTime"
    }
}

/// A temperature event that is sent for temperature sensors every heartbeat, and whenever the sensor is touched.
///
/// See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#temperatureevent) for more details.
public struct TemperatureEvent: Decodable, Equatable {
    
    /// The temperature value in celsius
    public let value: Float
    
    /// The timestamp the temperature event was generated
    public let timestamp: Date
    
    
    /// Creates a new `TemperatureEvent`. Creating a new temperature can be useful for testing purposes.
    public init(value: Float, timestamp: Date) {
        self.value     = value
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the value
        self.value = try container.decode(Float.self, forKey: .value)
    }
    
    private enum CodingKeys: String, CodingKey {
        case value
        case timestamp = "updateTime"
    }
}

/// An event that is sent whenever an object is close to a proximity sensor or not.
///
///  See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#objectpresentevent) for more details.
public struct ObjectPresentEvent: Decodable, Equatable {
    
    /// Whether or not an object is close to the proximity sensor
    public let objectPresent: Bool
    
    /// The timestamp of when the presence of an object switched state
    public let timestamp: Date
    
    
    /// Creates a new `ObjectPresentEvent`. Creating a new object present event can be useful for testing purposes.
    public init(objectPresent: Bool, timestamp: Date) {
        self.objectPresent = objectPresent
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the state
        let stateString = try values.decode(String.self, forKey: .objectPresent)
        switch stateString {
            case "NOT_PRESENT": self.objectPresent = false
            case "PRESENT"    : self.objectPresent = true
            
            // Likely "UNKNOWN"
            default: throw ParseError.stateValue(eventType: .objectPresent, state: stateString)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case objectPresent = "state"
        case timestamp = "updateTime"
    }
}

/// A humidity event that is sent for humidity sensors every heartbeat, and whenever the
/// sensor is touched. This event contains both the measured temperature as well as the relative humidity.
///
/// See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#humidityevent) for more details.
public struct HumidityEvent: Decodable, Equatable {
    
    /// The temperature value in celsius
    public let temperature: Float
    
    /// The relative humidity as a percentage
    public let relativeHumidity: Float
    
    /// The timestamp the humidity event was generated
    public let timestamp: Date
    
    
    /// Creates a new `HumidityEvent`. Creating a new humidity event can be useful for testing purposes.
    public init(temperature: Float, relativeHumidity: Float, timestamp: Date) {
        self.temperature      = temperature
        self.relativeHumidity = relativeHumidity
        self.timestamp        = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the values
        self.temperature      = try container.decode(Float.self, forKey: .temperature)
        self.relativeHumidity = try container.decode(Float.self, forKey: .relativeHumidity)
    }
    
    private enum CodingKeys: String, CodingKey {
        case temperature
        case relativeHumidity
        case timestamp = "updateTime"
    }
}

/// An event that includes the accumulated count of proximity state changes for a
/// Counting Proximity sensor. These events are sent every heartbeat, and *not* when
/// the sensor is touched or when the state is switched (to save battery life).
///
/// See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#h_cc5229d5-adb4-46fb-9293-2f4178494e6d) for more details.
public struct ObjectPresentCountEvent: Decodable, Equatable {
    
    /// The total accumulated state switches for this sensor
    public let total: Int
    
    /// The timestamp the event was generated
    public let timestamp: Date
    
    
    /// Creates a new `ObjectPresentCountEvent`. Creating a new object present count event can be useful for testing purposes.
    public init(total: Int, timestamp: Date) {
        self.total     = total
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the total
        self.total = try container.decode(Int.self, forKey: .total)
    }
    
    private enum CodingKeys: String, CodingKey {
        case total
        case timestamp = "updateTime"
    }
}

/// An event that includes the accumulated count of touches for a Counting Touch sensor.
/// These events are sent every heartbeat, and *not* when the sensor is touched (to save battery life).
///
/// See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#h_942dab91-0826-458a-a0bb-2c28ab92d21b) for more details.
public struct TouchCountEvent: Decodable, Equatable {
    
    /// The total accumulated number of touches for this sensor
    public let total: Int
    
    /// The timestamp the event was generated
    public let timestamp: Date
    
    
    /// Creates a new `TouchCountEvent`. Creating a new touch count event can be useful for testing purposes.
    public init(total: Int, timestamp: Date) {
        self.total     = total
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the total
        self.total = try container.decode(Int.self, forKey: .total)
    }
    
    private enum CodingKeys: String, CodingKey {
        case total
        case timestamp = "updateTime"
    }
}

/// An event that indicates whether or not water is present to a Water Detector sensor.
/// This event is sent every heartbeat, and when the sensor is touched.
///
/// See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#h_fbe6f0b1-a42c-4072-aaa1-46d117c0be99) for more details.
public struct WaterPresentEvent: Decodable, Equatable {
    
    /// Whether or not water was detected close to the sensor
    public let waterPresent: Bool
    
    /// The timestamp of when the state of water presence was changed
    public let timestamp: Date
    
    
    /// Creates a new `WaterPresentEvent`. Creating a new water present event can be useful for testing purposes
    public init(waterPresent: Bool, timestamp: Date) {
        self.waterPresent = waterPresent
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the state
        let stateString = try values.decode(String.self, forKey: .waterPresent)
        switch stateString {
            case "NOT_PRESENT": self.waterPresent = false
            case "PRESENT"    : self.waterPresent = true
            
            // Likely "UNKNOWN"
            default: throw ParseError.stateValue(eventType: .waterPresent, state: stateString)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case waterPresent = "state"
        case timestamp = "updateTime"
    }
}



// -------------------------------
// MARK: Sensor Status
// -------------------------------

/**
 A network status event describes which Cloud Connectors a sensor is connected to, and how strong
 that connection is. A network status event is sent on every heartbeat, as well as when a sensor is touched.
 
 See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#h_231c54ad-8586-4d45-a3f6-b169edbe3fae) for more details.
 */
public struct NetworkStatusEvent: Decodable, Equatable {
    
    /// The signal strength of the sensor as a percentage.
    /// This is a convenience value that is determined directly from the `rssi`.
    /// This will be the strongest signal strength received by all the Cloud Connector(s)
    /// in the `cloudConnectors` array.
    public let signalStrength: Int
    
    /// The raw signal strength of the sensor. This will be the strongest RSSI
    /// received by all the Cloud Connector(s) in the `cloudConnectors` array.
    /// See [Wikipedia](https://en.wikipedia.org/wiki/Received_signal_strength_indication) for more details.
    public let rssi: Int
    
    /// The timestamp the event was generated.
    public let timestamp: Date
    
    /// The Cloud Connector(s) that picked up this event.
    ///
    /// **NOTE**: When this event is received through a `DeviceEventStream`, the historical
    /// events, or a Data Connector, this event will only contain one Cloud Connector even if multiple
    /// Cloud Connectors were in range. You should expect to see one of these events per Cloud Connector
    /// in range. However, when looking in the `reportedEvents` field for a device, the last known
    /// network status events will be grouped together, meaning this `cloudConnectors` array will
    /// list all the Cloud Connectors that were in range.
    public let cloudConnectors: [CloudConnector]
    
    /// Which transmission mode the sensor was in when sending this network status event.
    public let transmissionMode: TransmissionMode
    
    
    
    
    /// A Cloud Connector that picked a network status event for a sensor.
    public struct CloudConnector: Decodable, Equatable {
        
        /// The identifier of the Cloud Connector that picked up the network status event.
        public let identifier: String
        
        /// The signal strength received by this Cloud Connector as a percentage.
        public let signalStrength: Int
        
        /// The raw signal strength received by this Cloud Connector.
        public let rssi: Int
        
        
        /// Creates a new `CloudConnector`. Creating a new cloud connector can be useful for testing purposes.
        public init(identifier: String, signalStrength: Int, rssi: Int) {
            self.identifier     = identifier
            self.signalStrength = signalStrength
            self.rssi           = rssi
        }
        
        private enum CodingKeys: String, CodingKey {
            case identifier = "id"
            case signalStrength
            case rssi
        }
    }
    
    /// The transmission mode the sensor is currently in. The sensor will automatically switch
    /// transmission modes when the sensor has low connectivity to a Cloud Connector.
    /// See the [Help Center](https://support.disruptive-technologies.com/hc/en-us/articles/360003182914-What-is-Boost-high-power-usage-) for more details.
    public enum TransmissionMode: String, Decodable, Equatable {
        /// The normal transmission mode for a sensor. This consumes less energy, but has a lower range.
        case standard = "LOW_POWER_STANDARD_MODE"
        
        /// Boost mode is used when a sensor has low connectivity to a Cloud Connector. It uses more energy, but has better range.
        case boost    = "HIGH_POWER_BOOST_MODE"
    }
    
    /// Creates a new `NetworkStatusEvent`. Creating a new network status can be useful for testing purposes.
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
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the other values
        self.signalStrength   = try container.decode(Int.self,              forKey: .signalStrength)
        self.rssi             = try container.decode(Int.self,              forKey: .rssi)
        self.cloudConnectors  = try container.decode([CloudConnector].self, forKey: .cloudConnectors)
        self.transmissionMode = try container.decode(TransmissionMode.self, forKey: .transmissionMode)
    }
    
    private enum CodingKeys: String, CodingKey {
        case signalStrength
        case rssi
        case timestamp = "updateTime"
        case cloudConnectors
        case transmissionMode
    }
}

/**
 A battery status event is sent quite rarely since the battery life of the sensors lasts up to 15 years. It indicates how much battery life is left in the sensor.
 
 See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#h_ecc3b3d4-36d0-46b7-82c0-564cd42013bc) for more details.
 */
public struct BatteryStatusEvent: Decodable, Equatable {
    
    /// The amount of battery life left in the sensor as a percentage.
    public let percentage: Int
    
    /// The timestamp the battery status event was generated.
    public let timestamp: Date
    
    
    
    /// Creates a new `BatteryStatusEvent`. Creating a new battery status event can be useful for testing purposes.
    public init(percentage: Int, timestamp: Date) {
        self.percentage = percentage
        self.timestamp  = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the percentage
        self.percentage = try container.decode(Int.self, forKey: .percentage)
    }
    
    private enum CodingKeys: String, CodingKey {
        case percentage
        case timestamp = "updateTime"
    }
}

// This will only be available when subscribing to an event stream on a sensor, or through a data connector
// TODO: This does not work! `labelsChanged` is not a key in the `data` field as expected
//public struct LabelsChangedEvent: Decodable {
//    public let added    : [String: String]
//    public let modified : [String: String]
//    public let removed  : [String]
//
//    public init(added: [String: String], modified: [String: String], removed: [String]) {
//        self.added = added
//        self.modified = modified
//        self.removed = removed
//    }
//}



// -------------------------------
// MARK: Cloud Connector
// -------------------------------

/**
 Indicates the current connectivity of a Cloud Connector. This is sent when there is a
 change in the connectivity of a Cloud Connector.
 
 See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#h_54fc31ee-d707-4227-b968-fc596a86b434) for more details.
 */
public struct ConnectionStatusEvent: Decodable, Equatable {
    
    /// The current connection of the Cloud Connector. If both `ethernet` and
    /// `cellular` is available, the Cloud Connector will prefer `ethernet`.
    public let connection: Connection
    
    /// An array of the available `Connection`s for the Cloud Connector.
    public let available: [Available]
    
    /// The timestamp the event was generated.
    public let timestamp: Date
    
    /// Indicates the current connectivity of a Cloud Connector.
    public enum Connection: String, Decodable, Equatable {
        
        /// Indicates that the Cloud Connector is currently offline.
        case offline  = "OFFLINE"
        
        /// Indicates that the Cloud Connector will send its data over Ethernet.
        case ethernet = "ETHERNET"
        
        /// Indicates that the Cloud Connector will send its data over Cellular.
        case cellular = "CELLULAR"
        
        /// Return a `String` representation of the `Connection` that is suited for presenting to a user on screen.
        public func displayName() -> String {
            switch self {
                case .offline        : return "Offline"
                case .ethernet       : return "Ethernet"
                case .cellular       : return "Cellular"
            }
        }
    }
    
    /// Indicates a connectivity that is available for a Cloud Connector.
    public enum Available: String, Decodable, Equatable {
        
        /// Indicates that ethernet connectivity is available for a Cloud Connector.
        case ethernet = "ETHERNET"
        
        /// Indicates that cellular connectivity is available for a Cloud Connector.
        case cellular = "CELLULAR"
        
        /// Return a `String` representation of the `Available` that is suited for presenting to a user on screen.
        public func displayName() -> String {
            switch self {
                case .ethernet       : return "Ethernet"
                case .cellular       : return "Cellular"
            }
        }
    }
    
    /// Creates a new `ConnectionStatusEvent`. Creating a new connection status event can be useful for testing purposes.
    public init(connection: Connection, available: [Available], timestamp: Date) {
        self.connection = connection
        self.available  = available
        self.timestamp  = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the other values
        self.connection = try container.decode(Connection.self,  forKey: .connection)
        
        // Extracting the list of `available` network interfaces as the REST API
        // might occasionally return "OFFLINE" in the `available` array, even
        // though this is not a valid value. This can happen when sending a
        // `ConnectionStatusEvent` on an emulated Cloud Connector in Studio.
        let availableStrings = try values.decode([String].self, forKey: .available)
        self.available = availableStrings.compactMap { Available(rawValue: $0) }
    }
    
    private enum CodingKeys: String, CodingKey {
        case connection
        case available
        case timestamp = "updateTime"
    }
}

/**
 Details about the current ethernet connection status of a Cloud Connector.
 
 See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#ethernetstatusevent) for more details.
 */
public struct EthernetStatusEvent: Decodable, Equatable {
    
    /// The MAC address of the Cloud Connector.
    public let macAddress: String
    
    /// The current IP address of the Cloud Connector.
    public let ipAddress: String
    
    /// Any errors related to connecting to the local network.
    public let errors: [ErrorMessage]
    
    /// The timestamp the event was generated.
    public let timestamp: Date
    
    
    /// Indicates an error related to connecting to the local network.
    public struct ErrorMessage: Decodable, Equatable {
        /// The error code.
        public let code: String
        
        /// The error message.
        public let message: String
    }
    
    /// Creates a new `EthernetStatusEvent`. Creating a new ethernet status event can be useful for testing purposes.
    public init(macAddress: String, ipAddress: String, errors: [ErrorMessage], timestamp: Date) {
        self.macAddress = macAddress
        self.ipAddress  = ipAddress
        self.errors     = errors
        self.timestamp  = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the other values
        self.macAddress = try container.decode(String.self,         forKey: .macAddress)
        self.ipAddress  = try container.decode(String.self,         forKey: .ipAddress)
        self.errors     = try container.decode([ErrorMessage].self, forKey: .errors)
    }
    
    private enum CodingKeys: String, CodingKey {
        case macAddress
        case ipAddress
        case errors
        case timestamp = "updateTime"
    }
}

/**
 Details about the current cellular connection status of a Cloud Connector.
 
 See the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events#cellularstatusevent) for more details.
 */
public struct CellularStatusEvent: Decodable, Equatable {
    
    /// The current signal strength of the Cloud Connector to the cellular network as a percentage.
    public let signalStrength: Int
    
    /// Any errors related to connecting to the cellular network.
    public let errors: [ErrorMessage]
    
    /// The timestamp the event was generated.
    public let timestamp: Date
    
    
    /// Indicates an error related to connecting to the cellular network.
    public struct ErrorMessage: Decodable, Equatable {
        /// The error code
        public let code: String
        
        /// The error message
        public let message: String
    }
    
    
    /// Creates a new `CellularStatusEvent`. Creating a new cellular status event can be useful for testing purposes.
    public init(signalStrength: Int, errors: [ErrorMessage], timestamp: Date) {
        self.signalStrength = signalStrength
        self.errors         = errors
        self.timestamp      = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the other values
        self.signalStrength = try container.decode(Int.self,            forKey: .signalStrength)
        self.errors         = try container.decode([ErrorMessage].self, forKey: .errors)
    }
    
    private enum CodingKeys: String, CodingKey {
        case signalStrength
        case errors
        case timestamp = "updateTime"
    }
}



// -------------------------------
// MARK: Events
// -------------------------------

/// Used to simplify event JSON parsing.
internal enum EventContainer: Decodable, Equatable {
    // Events
    case touch              (deviceID: String, event: TouchEvent)
    case temperature        (deviceID: String, event: TemperatureEvent)
    case objectPresent      (deviceID: String, event: ObjectPresentEvent)
    case humidity           (deviceID: String, event: HumidityEvent)
    case objectPresentCount (deviceID: String, event: ObjectPresentCountEvent)
    case touchCount         (deviceID: String, event: TouchCountEvent)
    case waterPresent       (deviceID: String, event: WaterPresentEvent)
    
    // Sensor Status
    case networkStatus      (deviceID: String, event: NetworkStatusEvent)
    case batteryStatus      (deviceID: String, event: BatteryStatusEvent)
//    case labelsChanged      (deviceID: String, event: LabelsChanged)
    
    // Cloud Connector
    case connectionStatus   (deviceID: String, event: ConnectionStatusEvent)
    case ethernetStatus     (deviceID: String, event: EthernetStatusEvent)
    case cellularStatus     (deviceID: String, event: CellularStatusEvent)
    
    /// Used for backward compatibility in case a new event
    /// is added on the backend before being added to this
    /// client library.
    case unknown(value: String)
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
            self = .unknown(value: "\(eventTypeString)")
            return
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
                let event = try eventContainer.decode(ObjectPresentCountEvent.self, forKey: .objectPresentCount)
                self = .objectPresentCount(deviceID: deviceID, event: event)
            case .touchCount:
                let event = try eventContainer.decode(TouchCountEvent.self, forKey: .touchCount)
                self = .touchCount(deviceID: deviceID, event: event)
            case .waterPresent:
                let event = try eventContainer.decode(WaterPresentEvent.self, forKey: .waterPresent)
                self = .waterPresent(deviceID: deviceID, event: event)
                
            // Sensor Status
            case .networkStatus:
                let event = try eventContainer.decode(NetworkStatusEvent.self, forKey: .networkStatus)
                self = .networkStatus(deviceID: deviceID, event: event)
            case .batteryStatus:
                let event = try eventContainer.decode(BatteryStatusEvent.self, forKey: .batteryStatus)
                self = .batteryStatus(deviceID: deviceID, event: event)
//            case .labelsChanged:
//                let event = try eventContainer.decode(LabelsChanged.self, forKey: .labelsChanged)
//                self = .labelsChanged(deviceID: deviceID, event: event)
                
            // Cloud Connector
            case .connectionStatus:
                let event = try eventContainer.decode(ConnectionStatusEvent.self, forKey: .connectionStatus)
                self = .connectionStatus(deviceID: deviceID, event: event)
            case .ethernetStatus:
                let event = try eventContainer.decode(EthernetStatusEvent.self, forKey: .ethernetStatus)
                self = .ethernetStatus(deviceID: deviceID, event: event)
            case .cellularStatus:
                let event = try eventContainer.decode(CellularStatusEvent.self, forKey: .cellularStatus)
                self = .cellularStatus(deviceID: deviceID, event: event)
        }
    }
}
