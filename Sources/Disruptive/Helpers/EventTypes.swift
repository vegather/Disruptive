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
    case labelsChanged
    
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
/// See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#touch-event) for more details.
public struct TouchEvent: Codable, Equatable {
    /// The timestamp of when the touch event was received by a Cloud Connector.
    public let timestamp: Date
    
    
    /// Creates a new `TouchEvent`.
    public init(timestamp: Date) {
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
    }
    
    private enum CodingKeys: String, CodingKey {
        case timestamp = "updateTime"
    }
}

/// A temperature event that is sent for temperature sensors every heartbeat, and whenever the sensor is touched.
///
/// See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#temperature-event) for more details.
public struct TemperatureEvent: Codable, Equatable {
    
    /// The temperature value in celsius.
    public let celsius: Float
    
    /// The temperature value in fahrenheit.
    public let fahrenheit: Float
    
    /// The timestamp of when the temperature event was received by a Cloud Connector.
    public let timestamp: Date
    
    /// An array of temperature values sampled within a single heartbeat.
    /// The order is the same as the order of events, meaning newest is first.
    public let samples: [TemperatureSample]
    
    
    /// Represents a temperature value sampled within a single heartbeat.
    public struct TemperatureSample: Codable, Equatable {
        /// The temperature value in celsius.
        public let celsius: Float
        
        /// The temperature value in fahrenheit.
        public let fahrenheit: Float
        
        /// The timestamp the temperature value was sample.
        /// This timestamp is estimated by DT Cloud, and may not
        /// be as accurate as the timestamp of the event itself.
        public let timestamp: Date
        
        /// Creates a new `TemperatureSample` using celsius.
        public init(celsius: Float, timestamp: Date) {
            self.celsius    = celsius
            self.fahrenheit = celsiusToFahrenheit(celsius: celsius)
            self.timestamp  = timestamp
        }
        
        /// Creates a new `TemperatureSample` using fahrenheit.
        public init(fahrenheit: Float, timestamp: Date) {
            self.celsius    = fahrenheitToCelsius(fahrenheit: fahrenheit)
            self.fahrenheit = fahrenheit
            self.timestamp  = timestamp
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Extract the timestamp
            let timeString = try container.decode(String.self, forKey: .timestamp)
            self.timestamp = try Date(iso8601String: timeString)
            
            // Extract the value
            self.celsius = try container.decode(Float.self, forKey: .value)
            self.fahrenheit = celsiusToFahrenheit(celsius: self.celsius)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(celsius,                   forKey: .value)
            try container.encode(timestamp.iso8601String(), forKey: .timestamp)
        }
        
        private enum CodingKeys: String, CodingKey {
            case value
            case timestamp = "sampleTime"
        }
    }
    
    
    /// Creates a new `TemperatureEvent` using celsius.
    public init(celsius: Float, timestamp: Date, samples: [TemperatureSample]? = nil) {
        self.celsius    = celsius
        self.fahrenheit = celsiusToFahrenheit(celsius: celsius)
        self.timestamp  = timestamp
        self.samples    = samples ?? [TemperatureSample(celsius: celsius, timestamp: timestamp)]
    }
    
    /// Creates a new `TemperatureEvent` using fahrenheit.
    public init(fahrenheit: Float, timestamp: Date, samples: [TemperatureSample]? = nil) {
        self.celsius    = fahrenheitToCelsius(fahrenheit: fahrenheit)
        self.fahrenheit = fahrenheit
        self.timestamp  = timestamp
        self.samples    = samples ?? [TemperatureSample(fahrenheit: fahrenheit, timestamp: timestamp)]
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the value
        self.celsius = try container.decode(Float.self, forKey: .value)
        self.fahrenheit = celsiusToFahrenheit(celsius: self.celsius)
        
        // Extract samples
        var samples = try container.decode([TemperatureSample].self, forKey: .samples)
        samples.sort(by: { $0.timestamp > $1.timestamp })
        self.samples = samples
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(celsius,                   forKey: .value)
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
        try container.encode(samples,                   forKey: .samples)
    }
    
    private enum CodingKeys: String, CodingKey {
        case value
        case timestamp = "updateTime"
        case samples
    }
}

/// An event that is sent whenever an object is close to a proximity sensor or not.
///
///  See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#object-present-event) for more details.
public struct ObjectPresentEvent: Codable, Equatable {
    
    /// Whether or not an object is close to the proximity sensor.
    public let state: State
    
    /// The timestamp of when the object present event was received by a Cloud Connector.
    public let timestamp: Date
    
    /// The proximity state of a sensor.
    public enum State: Codable, Equatable {
        /// An object is close to the sensor.
        case objectPresent
        
        /// No objects are close to the sensor.
        case objectNotPresent
        
        /// Used for backward compatibility in case a new state
        /// is added on the backend before being added to this
        /// client library.
        case unknown(value: String)
        
        public init(from decoder: Decoder) throws {
            let str = try decoder.singleValueContainer().decode(String.self)
            switch str {
                case "PRESENT"     : self = .objectPresent
                case "NOT_PRESENT" : self = .objectNotPresent
                default            : self = .unknown(value: str)
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
                case .objectPresent    : try container.encode("PRESENT")
                case .objectNotPresent : try container.encode("NOT_PRESENT")
                case .unknown(let s):
                    throw ParseError.encodingUnknownCase(value: "NetworkStatusEvent.TransmissionMode.unknown(\(s))")
            }
        }
    }
    
    /// Creates a new `ObjectPresentEvent`.
    public init(state: State, timestamp: Date) {
        self.state     = state
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the state
        self.state = try container.decode(State.self, forKey: .state)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(state,                     forKey: .state)
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
    }
    
    private enum CodingKeys: String, CodingKey {
        case state
        case timestamp = "updateTime"
    }
}

/// A humidity event that is sent for humidity sensors every heartbeat, and whenever the
/// sensor is touched. This event contains both the measured temperature as well as the relative humidity.
///
/// See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#humidity-event) for more details.
public struct HumidityEvent: Codable, Equatable {
    
    /// The temperature value in celsius.
    public let celsius: Float
    
    /// The temperature value in fahrenheit.
    public let fahrenheit: Float
    
    /// The relative humidity as a percentage.
    public let relativeHumidity: Float
    
    /// The timestamp of when the humidity event was received by a Cloud Connector.
    public let timestamp: Date
    
    
    /// Creates a new `HumidityEvent` using celsius.
    public init(celsius: Float, relativeHumidity: Float, timestamp: Date) {
        self.celsius          = celsius
        self.fahrenheit       = celsiusToFahrenheit(celsius: celsius)
        self.relativeHumidity = relativeHumidity
        self.timestamp        = timestamp
    }
    
    /// Creates a new `HumidityEvent` using fahrenheit.
    public init(fahrenheit: Float, relativeHumidity: Float, timestamp: Date) {
        self.celsius          = fahrenheitToCelsius(fahrenheit: fahrenheit)
        self.fahrenheit       = fahrenheit
        self.relativeHumidity = relativeHumidity
        self.timestamp        = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the values
        self.relativeHumidity = try container.decode(Float.self, forKey: .relativeHumidity)
        self.celsius          = try container.decode(Float.self, forKey: .temperature)
        self.fahrenheit = celsiusToFahrenheit(celsius: self.celsius)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(celsius,                   forKey: .temperature)
        try container.encode(relativeHumidity,          forKey: .relativeHumidity)
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
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
/// See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#object-present-count-event) for more details.
public struct ObjectPresentCountEvent: Codable, Equatable {
    
    /// The total accumulated state switches for this sensor.
    public let total: Int
    
    /// The timestamp of when the object present count event was received by a Cloud Connector.
    public let timestamp: Date
    
    
    /// Creates a new `ObjectPresentCountEvent`.
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(total,                     forKey: .total)
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
    }
    
    private enum CodingKeys: String, CodingKey {
        case total
        case timestamp = "updateTime"
    }
}

/// An event that includes the accumulated count of touches for a Counting Touch sensor.
/// These events are sent every heartbeat, and *not* when the sensor is touched (to save battery life).
///
/// See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#touch-count-event) for more details.
public struct TouchCountEvent: Codable, Equatable {
    
    /// The total accumulated number of touches for this sensor.
    public let total: Int
    
    /// The timestamp of when the touch count event was received by a Cloud Connector.
    public let timestamp: Date
    
    
    /// Creates a new `TouchCountEvent`.
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(total,                     forKey: .total)
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
    }
    
    private enum CodingKeys: String, CodingKey {
        case total
        case timestamp = "updateTime"
    }
}

/// An event that indicates whether or not water is present to a Water Detector sensor.
/// This event is sent every heartbeat, and when the sensor is touched.
///
/// See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#water-present-event) for more details.
public struct WaterPresentEvent: Codable, Equatable {
    
    /// Whether or not water was detected close to the sensor.
    public let state: State
    
    /// The timestamp of when the water present event event was received by a Cloud Connector.
    public let timestamp: Date
    
    
    /// The water presence state of a sensor.
    public enum State: Codable, Equatable {
        
        /// The sensor has detected the presence of water.
        case waterPresent
        
        /// The sensor has not detected the presence of water.
        case waterNotPresent
        
        /// Used for backward compatibility in case a new state
        /// is added on the backend before being added to this
        /// client library.
        case unknown(value: String)
        
        public init(from decoder: Decoder) throws {
            let str = try decoder.singleValueContainer().decode(String.self)
            switch str {
                case "PRESENT"     : self = .waterPresent
                case "NOT_PRESENT" : self = .waterNotPresent
                default            : self = .unknown(value: str)
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
                case .waterPresent    : try container.encode("PRESENT")
                case .waterNotPresent : try container.encode("NOT_PRESENT")
                case .unknown(let s):
                    throw ParseError.encodingUnknownCase(value: "NetworkStatusEvent.TransmissionMode.unknown(\(s))")
            }
        }
    }
    
    
    /// Creates a new `WaterPresentEvent`.
    public init(state: State, timestamp: Date) {
        self.state     = state
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract the timestamp
        let timeString = try container.decode(String.self, forKey: .timestamp)
        self.timestamp = try Date(iso8601String: timeString)
        
        // Extract the state
        self.state = try container.decode(State.self, forKey: .state)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(state,                     forKey: .state)
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
    }
    
    private enum CodingKeys: String, CodingKey {
        case state
        case timestamp = "updateTime"
    }
}



// -------------------------------
// MARK: Sensor Status
// -------------------------------

/**
 A network status event describes which Cloud Connectors a sensor is connected to, and how strong
 that connection is. A network status event is sent on every heartbeat, as well as when a sensor is touched.
 
 See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#network-status-event) for more details.
 */
public struct NetworkStatusEvent: Codable, Equatable {
    
    /// The signal strength of the sensor as a percentage.
    /// This is a convenience value that is determined directly from the `rssi`.
    /// This will be the strongest signal strength received by all the Cloud Connector(s)
    /// in the `cloudConnectors` array.
    public let signalStrength: Int
    
    /// The raw signal strength of the sensor. This will be the strongest RSSI
    /// received by all the Cloud Connector(s) in the `cloudConnectors` array.
    /// See [Wikipedia](https://en.wikipedia.org/wiki/Received_signal_strength_indication) for more details.
    public let rssi: Int
    
    /// The timestamp of when the network status event was received by a Cloud Connector.
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
    public struct CloudConnector: Codable, Equatable {
        
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
    /// See the [Help Center](https://support.disruptive-technologies.com/hc/en-us/articles/360003182914-What-is-Boost-high-power-boost-mode-) for more details.
    public enum TransmissionMode: Codable, Equatable {
        /// The normal transmission mode for a sensor. This consumes less energy, but has a lower range.
        case standard
        
        /// Boost mode is used when a sensor has low connectivity to a Cloud Connector. It uses more energy, but has better range.
        case boost
        
        /// Used for backward compatibility in case a new transmission mode
        /// is added on the backend before being added to this client library.
        case unknown(value: String)
        
        public init(from decoder: Decoder) throws {
            let str = try decoder.singleValueContainer().decode(String.self)
            
            switch str {
                case "LOW_POWER_STANDARD_MODE": self = .standard
                case "HIGH_POWER_BOOST_MODE"  : self = .boost
                default                       : self = .unknown(value: str)
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
                case .standard : try container.encode("LOW_POWER_STANDARD_MODE")
                case .boost    : try container.encode("HIGH_POWER_BOOST_MODE")
                case .unknown(let s):
                    throw ParseError.encodingUnknownCase(value: "NetworkStatusEvent.TransmissionMode.unknown(\(s))")
            }
        }
    }
    
    /// Creates a new `NetworkStatusEvent`.
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
        try container.encode(signalStrength,            forKey: .signalStrength)
        try container.encode(rssi,                      forKey: .rssi)
        try container.encode(cloudConnectors,           forKey: .cloudConnectors)
        try container.encode(transmissionMode,          forKey: .transmissionMode)
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
 
 See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#battery-status-event) for more details.
 */
public struct BatteryStatusEvent: Codable, Equatable {
    
    /// The amount of battery life left in the sensor as a percentage.
    public let percentage: Int
    
    /// The timestamp of when the battery status event was received by a Cloud Connector.
    public let timestamp: Date
    
    
    
    /// Creates a new `BatteryStatusEvent`.
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(percentage,                forKey: .percentage)
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
    }
    
    private enum CodingKeys: String, CodingKey {
        case percentage
        case timestamp = "updateTime"
    }
}

/**
 Labels changed events are sent when the labels for a device are changed (added, deleted, or modified).
 
 Since the display name of a device is a label with the key "name" behind the scene, this event will also
 be sent when the display name changes.
 
 Note that this event will only be sent to a device stream (see `subscribeToDevices`), or a Data Connector.
 It will not be available as historical events for a device (the current labels for a device can be found on
 the `Device` itself).
 
 Seed the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#labels-changed-event) for more details.
 */
public struct LabelsChangedEvent: Decodable, Equatable {
    public let added    : [String: String]
    public let modified : [String: String]
    public let removed  : [String]

    // Used for testing
    internal init(added: [String: String], modified: [String: String], removed: [String]) {
        self.added = added
        self.modified = modified
        self.removed = removed
    }
}



// -------------------------------
// MARK: Cloud Connector
// -------------------------------

/**
 Indicates the current connectivity of a Cloud Connector. This is sent when there is a
 change in the connectivity of a Cloud Connector.
 
 See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#connection-status-event) for more details.
 */
public struct ConnectionStatusEvent: Codable, Equatable {
    
    /// The current connection of the Cloud Connector. If both `ethernet` and
    /// `cellular` is available, the Cloud Connector will prefer `ethernet`.
    public let connection: Connection
    
    /// An array of the available `Connection`s for the Cloud Connector.
    public let available: [Available]
    
    /// The timestamp of when the connection status event was received by a Cloud Connector.
    public let timestamp: Date
    
    /// Indicates the current connectivity of a Cloud Connector.
    public enum Connection: Codable, Equatable {
        
        /// Indicates that the Cloud Connector is currently offline.
        case offline
        
        /// Indicates that the Cloud Connector will send its data over Ethernet.
        case ethernet
        
        /// Indicates that the Cloud Connector will send its data over Cellular.
        case cellular
        
        /// Used for backward compatibility in case a new connection type
        /// is added on the backend before being added to this client library.
        case unknown(value: String)
        
        /// Return a `String` representation of the `Connection` that is suited for presenting to a user on screen.
        public func displayName() -> String {
            switch self {
                case .offline        : return "Offline"
                case .ethernet       : return "Ethernet"
                case .cellular       : return "Cellular"
                case .unknown(let s) : return "Unknown (\(s))"
            }
        }
        
        public init(from decoder: Decoder) throws {
            let str = try decoder.singleValueContainer().decode(String.self)
            
            switch str {
                case "OFFLINE"  : self = .offline
                case "ETHERNET" : self = .ethernet
                case "CELLULAR" : self = .cellular
                default         : self = .unknown(value: str)
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
                case .offline  : try container.encode("OFFLINE")
                case .ethernet : try container.encode("ETHERNET")
                case .cellular : try container.encode("CELLULAR")
                case .unknown(let s):
                    throw ParseError.encodingUnknownCase(value: "NetworkStatusEvent.TransmissionMode.unknown(\(s))")
            }
        }
    }
    
    /// Indicates a connectivity that is available for a Cloud Connector.
    public enum Available: Codable, Equatable {
        
        /// Indicates that ethernet connectivity is available for a Cloud Connector.
        case ethernet
        
        /// Indicates that cellular connectivity is available for a Cloud Connector.
        case cellular
        
        /// Used for backward compatibility in case a new available connectivity type
        /// is added on the backend before being added to this client library.
        case unknown(value: String)
        
        /// Return a `String` representation of the `Available` that is suited for presenting to a user on screen.
        public func displayName() -> String {
            switch self {
                case .ethernet       : return "Ethernet"
                case .cellular       : return "Cellular"
                case .unknown(let s) : return "Unknown (\(s))"
            }
        }
        
        public init(from decoder: Decoder) throws {
            let str = try decoder.singleValueContainer().decode(String.self)
            
            switch str {
                case "ETHERNET" : self = .ethernet
                case "CELLULAR" : self = .cellular
                default         : self = .unknown(value: str)
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            
            switch self {
                case .ethernet : try container.encode("ETHERNET")
                case .cellular : try container.encode("CELLULAR")
                case .unknown(let s):
                    throw ParseError.encodingUnknownCase(value: "NetworkStatusEvent.Available.unknown(\(s))")
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
        self.available  = try container.decode([Available].self, forKey: .available)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(connection,                forKey: .connection)
        try container.encode(available,                 forKey: .available)
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
    }
    
    private enum CodingKeys: String, CodingKey {
        case connection
        case available
        case timestamp = "updateTime"
    }
}

/**
 Details about the current ethernet connection status of a Cloud Connector.
 
 See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#ethernet-status-event) for more details.
 */
public struct EthernetStatusEvent: Codable, Equatable {
    
    /// The MAC address of the Cloud Connector.
    public let macAddress: String
    
    /// The current IP address of the Cloud Connector.
    public let ipAddress: String
    
    /// Any errors related to connecting to the local network.
    public let errors: [ErrorMessage]
    
    /// The timestamp of when the ethernet status event was generated by a Cloud Connector.
    public let timestamp: Date
    
    
    /// Indicates an error related to connecting to the local network.
    public struct ErrorMessage: Codable, Equatable {
        /// The error code.
        public let code: String
        
        /// The error message.
        public let message: String
    }
    
    /// Creates a new `EthernetStatusEvent`.
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(macAddress,                forKey: .macAddress)
        try container.encode(ipAddress,                 forKey: .ipAddress)
        try container.encode(errors,                    forKey: .errors)
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
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
 
 See the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events#cellular-status-event) for more details.
 */
public struct CellularStatusEvent: Codable, Equatable {
    
    /// The current signal strength of the Cloud Connector to the cellular network as a percentage.
    public let signalStrength: Int
    
    /// Any errors related to connecting to the cellular network.
    public let errors: [ErrorMessage]
    
    /// The timestamp of when the cellular status event was generated by a Cloud Connector.
    public let timestamp: Date
    
    
    /// Indicates an error related to connecting to the cellular network.
    public struct ErrorMessage: Codable, Equatable {
        /// The error code.
        public let code: String
        
        /// The error message.
        public let message: String
    }
    
    
    /// Creates a new `CellularStatusEvent`.
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
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(signalStrength,            forKey: .signalStrength)
        try container.encode(errors,                    forKey: .errors)
        try container.encode(timestamp.iso8601String(), forKey: .timestamp)
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
    case labelsChanged      (deviceID: String, event: LabelsChangedEvent)
    
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
            case .labelsChanged:
                // Labels changed events are nested one layer shallower than the other events,
                // so getting it straight out of the root container keyed by "data".
                let event = try container.decode(LabelsChangedEvent.self, forKey: .data)
                self = .labelsChanged(deviceID: deviceID, event: event)
                
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
