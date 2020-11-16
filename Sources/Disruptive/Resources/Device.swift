//
//  Device.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 21/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 Represents a Cloud Connector or Sensor from Disruptive Technologies
 
 ### Relevant methods in [Disruptive](../Disruptive):
 * [`getDevice`](../Disruptive/#disruptive.getdevice(projectid:deviceid:completion:))
 * [`getDevices`](../Disruptive/#disruptive.getdevices(projectid:completion:))
 
 */
public struct Device: Decodable {
    public let identifier: String
    public var displayName: String
    public let projectID: String
    public let labels: [String: String]
    public let type: DeviceType
    public var reportedEvents: ReportedEvents
    
    public init(identifier: String, displayName: String, projectID: String, labels: [String: String], type: DeviceType, reportedEvents: ReportedEvents)
    {
        self.identifier = identifier
        self.displayName = displayName
        self.projectID = projectID
        self.labels = labels
        self.type = type
        self.reportedEvents = reportedEvents
    }
}


extension Disruptive {
    /**
     Gets details for a specific device. This device could be found within a specific project, or if the `projectID` argument is not specified (or nil), throughout all the project available to the authenticated account.
     
     - Parameter projectID: The identifier of the project to find the device in. If default value (nil) is used, a wildcard character will be used for the projectID that searches through all the project the authenticated account has access to.
     - Parameter deviceID: The identifier of the device to get details on.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Device`. If a failure occured, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Device, DisruptiveError>`
     */
    public func getDevice(
        projectID  : String? = nil,
        deviceID   : String,
        completion : @escaping (_ result: Result<Device, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID ?? "-")/devices/\(deviceID)"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Gets a list of devices in a specific project.
     
     - Parameter projectID: The identifier for the project to get devices from
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Device`s. If a failure occured, the `.failure` case will contain a `DisruptiveError`
     - Parameter result: `Result<[Device], DisruptiveError>`
     */
    public func getDevices(
        projectID  : String,
        completion : @escaping (_ result: Result<[Device], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "projects/\(projectID)/devices")
        
        // Send the request
        sendRequest(request, pageingKey: "devices") { completion($0) }
    }
    
    /**
     Updates the display name of a device to a new value (overwrites it if a display name already exists).
     
     This is a convenience function that uses the `setDeviceLabel` function with the `name` key.
     
     - Parameter projectID: The identifier for the project the device is in
     - Parameter deviceID: The identifier of the device to change the display name of
     - Parameter newDisplayName: The new display name to set for the device
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func updateDeviceDisplayName(
        projectID      : String,
        deviceID       : String,
        newDisplayName : String,
        completion     : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        setDeviceLabel(
            projectID  : projectID,
            deviceID   : deviceID,
            key        : "name",
            value      : newDisplayName,
            completion : completion
        )
    }
    
    /**
     Assigns a value to a label key for a specific device. If the label key doesn't already exists it will be created. Otherwise the value for the key is updated. This is in effect an upsert.
     
     - Parameter projectID: The identifier for the project the device is in
     - Parameter deviceID: The identifier of the device to set the label for
     - Parameter key: The key of the label
     - Parameter value: The new value of the label
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func setDeviceLabel(
        projectID  : String,
        deviceID   : String,
        key        : String,
        value      : String,
        completion : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the body
        struct Body: Codable {
            let devices: [String]
            let addLabels: [String: String]
            let removeLabels: [String]
        }
        let body = Body(
            devices: ["projects/\(projectID)/devices/\(deviceID)"],
            addLabels: [key: value],
            removeLabels: []
        )
        
        do {
            // Create the request
            let endpoint = "projects/\(projectID)/devices:batchUpdate"
            let request = try Request(method: .post, baseURL: baseURL, endpoint: endpoint, body: body)
            
            // Send the request
            sendRequest(request) { completion($0) }
        } catch (let error) {
            DTLog("Failed to init setLabel request with payload: \(body). Error: \(error)", isError: true)
            completion(.failure(.unknownError))
        }
    }
    
    /**
     Moves a list of devices from one project to another. The authenticated account must be an admin
     in the `toProjectID`, or an organization admin in which the `toProjectID` resides.
     
     - Parameter deviceIDs: A list of the device identifiers to move from one project to another
     - Parameter fromProjectID: The identifier of the project to move the devices from
     - Parameter toProjectID: The identifier of the project to move the devices to
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func moveDevices(
        deviceIDs     : [String],
        fromProjectID : String,
        toProjectID   : String,
        completion    : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the body
        struct Body: Codable {
            let devices: [String]
        }
        let body = Body(devices: deviceIDs.map { "projects/\(fromProjectID)/devices/\($0)" })
        
        do {
            // Create the request
            let endpoint = "projects/\(toProjectID)/devices:transfer"
            let request = try Request(method: .post, baseURL: baseURL, endpoint: endpoint, body: body)
            
            // Send the request
            sendRequest(request) { completion($0) }
        } catch (let error) {
            DTLog("Failed to initialize move devices request with payload: \(body). Error: \(error)", isError: true)
            completion(.failure(.unknownError))
        }
    }
    
    /**
     Moves a list of devices from one project to another. The authenticated account must be an admin
     in the `toProject`, or an organization admin in which the `toProject` resides.
     
     - Parameter devices: A list of the devices to move from one project to another
     - Parameter fromProject: The project to move the devices from
     - Parameter toProject: The project to move the devices to
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func moveDevices(
        _ devices   : [Device],
        fromProject : Project,
        toProject   : Project,
        completion  : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        moveDevices(
            deviceIDs     : devices.map { $0.identifier },
            fromProjectID : fromProject.identifier,
            toProjectID   : toProject.identifier,
            completion    : completion
        )
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
        self.displayName = self.labels["name", default: ""]
        
        self.reportedEvents = try values.decode(ReportedEvents.self, forKey: .reportedEvents)
    }
}

extension Device {
    public enum DeviceType: String, Codable, CaseIterable {
        case temperature      = "temperature"
        case touch            = "touch"
        case proximity        = "proximity"
        case humidity         = "humidity"
        case touchCounter     = "touchCounter"
        case proximityCounter = "proximityCounter"
        case waterDetector    = "waterDetector"
        case cloudConnector   = "ccon"
        case unknown
        
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
                case .unknown          : return "Unknown"
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
