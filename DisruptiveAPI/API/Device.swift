//
//  Device.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 21/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

public struct Device: Decodable {
    public let identifier: String
    public let name: String
    public let projectID: String
    public let labels: [String: String]
    public let type: DeviceType
    public var reportedEvents: ReportedEvents
    
    public init(identifier: String, name: String, projectID: String, labels: [String: String], type: DeviceType, reportedEvents: ReportedEvents)
    {
        self.identifier = identifier
        self.name = name
        self.projectID = projectID
        self.labels = labels
        self.type = type
        self.reportedEvents = reportedEvents
    }
}

extension Device {
    private enum CodingKeys: String, CodingKey {
        case identifier = "name"
        case labels
        case type
        case reportedEvents = "reported"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Device identifiers are formatted as "projects/b7s3umd0fee000ba5di0/devices/b5rj9ed7rihk942p48og"
        // Setting the identifier to the last component of the path
        let projectPath = try values.decode(String.self, forKey: .identifier)
        let pathComponents = projectPath.components(separatedBy: "/")
        guard pathComponents.count == 4 else {
            throw ParseError.identifier(path: projectPath)
        }
        self.projectID  = pathComponents[1]
        self.identifier = pathComponents[3]
        
        // Getting the other properties without any modifications
        self.labels = try values.decode([String: String].self, forKey: .labels)
        self.type   = try values.decode(DeviceType.self,       forKey: .type)
        
        // The name of the device comes in a label (if set)
        self.name = self.labels["name", default: ""]
        
        self.reportedEvents = try values.decode(ReportedEvents.self, forKey: .reportedEvents)
    }
}

extension Device {
    public enum DeviceType: String, Codable {
        case temperature      = "temperature"
        case touch            = "touch"
        case proximity        = "proximity"
        case humidity         = "humidity"
        case touchCounter     = "touchCounter"
        case proximityCounter = "proximityCounter"
        case waterDetector    = "waterDetector"
        case cloudConnector   = "ccon"
        
        public func humanPresentable() -> String {
            switch self {
                case .temperature      : return "Temperature"
                case .touch            : return "Touch"
                case .proximity        : return "Proximity"
                case .humidity         : return "Humidity"
                case .touchCounter     : return "Touch Counter"
                case .proximityCounter : return "Proximity Counter"
                case .waterDetector    : return "Water Detector"
                case .cloudConnector   : return "Cloud Connector"
            }
        }
    }
        
    public struct ReportedEvents: Decodable {
        // Events
        public var touch              : TouchEvent?
        public var touchCount         : TouchCount?
        public var temperature        : TemperatureEvent?
        public var humidity           : HumidityEvent?
        public var objectPresent      : ObjectPresentEvent?
        public var objectPresentCount : ObjectPresentCount?
        public var waterPresent       : WaterPresentEvent?
        
        // Sensor Status
        public var batteryStatus      : BatteryStatus?
        public var networkStatus      : NetworkStatus?
        
        // Cloud Connector
        public var ethernetStatus     : EthernetStatus?
        public var cellularStatus     : CellularStatus?
        public var connectionStatus   : ConnectionStatus?
        public var connectionLatency  : ConnectionLatency?
        
        public init() {}
    }
}

extension Disruptive {
    public func getDevices(projectID: String, completion: @escaping (Result<[Device], DisruptiveError>) -> ()) {
        // Create the request
        let request = Request(method: .get, endpoint: "projects/\(projectID)/devices")
        
        // Send the request
        sendRequest(request: request, pageingKey: "devices") { response in
            completion(response)
        }
    }
}
