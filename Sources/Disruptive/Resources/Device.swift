//
//  Device.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 21/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 Represents a Sensor or Cloud Connector from Disruptive Technologies.
 
 Relevant methods for `Device` can be found on the [Disruptive](../Disruptive) struct.
 */
public struct Device: Decodable, Equatable {
    
    /// The unique identifier of the device. This will be different from the REST API in that it is just the identifier without the `projects/*/devices/` prefix.
    public let identifier: String
    
    /// The display name of the device.
    public var displayName: String
    
    /// The identifier of the project the device is in.
    public let projectID: String
    
    /// The labels that are currently set on the device. This will also include the `displayName` of the device as a label with the key `name`.
    public let labels: [String: String]
    
    /// The type of the device. What type the device is determines which types of events it will receive.
    public let type: DeviceType
    
    /// The last known reported event for each available event type for the device. Which of these are available is dependent on the device `type`.
    public var reportedEvents: ReportedEvents
    
    /// Creates a new `Device`. Creating a new device can be useful for testing purposes.
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
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Device`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
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
     
     - Parameter projectID: The identifier of the project to get devices from.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Device`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Device], DisruptiveError>`
     */
    public func getDevices(
        projectID  : String,
        completion : @escaping (_ result: Result<[Device], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "projects/\(projectID)/devices")
        
        // Send the request
        sendRequest(request, pagingKey: "devices") { completion($0) }
    }
    
    /**
     Updates the display name of a device to a new value (overwrites it if a display name already exists).
     
     This is a convenience function for `batchUpdateDeviceLabels` by setting the `name` label to the new display name.
     
     - Parameter projectID: The identifier of the project the device is in.
     - Parameter deviceID: The identifier of the device to change the display name of.
     - Parameter newDisplayName: The new display name to set for the device.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func updateDeviceDisplayName(
        projectID      : String,
        deviceID       : String,
        newDisplayName : String,
        completion     : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        batchUpdateDeviceLabels(
            projectID      : projectID,
            deviceIDs      : [deviceID],
            labelsToSet    : ["name": newDisplayName],
            labelsToRemove : [],
            completion     : completion
        )
    }
    
    /**
     Removes the specified label for the device. Will return success if the label didn't exist.
     
     This is a convenience function for `batchUpdateDeviceLabels`.
     
     - Parameter projectID: The identifier of the project the device is in.
     - Parameter deviceID: The identifier of the device to remove a label from.
     - Parameter labelKey: The key of the label to remove.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func removeDeviceLabel(
        projectID  : String,
        deviceID   : String,
        labelKey   : String,
        completion : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        batchUpdateDeviceLabels(
            projectID      : projectID,
            deviceIDs      : [deviceID],
            labelsToSet    : [:],
            labelsToRemove : [labelKey],
            completion     : completion
        )
    }
    
    /**
     Assigns a value to a label key for a specific device. If the label key doesn't already exists it will be created, otherwise the value for the key is updated. This is in effect an upsert.
     
     This is a convenience function for `batchUpdateDeviceLabels`.
     
     - Parameter projectID: The identifier of the project the device is in.
     - Parameter deviceID: The identifier of the device to set the label for.
     - Parameter labelKey: The key of the label.
     - Parameter labelValue: The new value of the label.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func setDeviceLabel(
        projectID  : String,
        deviceID   : String,
        labelKey   : String,
        labelValue : String,
        completion : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        batchUpdateDeviceLabels(
            projectID      : projectID,
            deviceIDs      : [deviceID],
            labelsToSet    : [labelKey: labelValue],
            labelsToRemove : [],
            completion     : completion
        )
    }
    
    /**
     Performs a batch update to add or remove one or more labels to one or more devices in a project.
     
     - Parameter projectID: The identifier of the project the devices are in.
     - Parameter deviceIDs: An array of identifiers for the devices to set or remove labels from.
     - Parameter labelsToSet: The key-value pairs to set for the device. If the labels already exists they will be updated, otherwise they will be created, effectively doing an upsert. Any labels that already exists on a device, but are not provided here will be left as-is.
     - Parameter labelsToRemove: An array of label keys to remove from the device.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func batchUpdateDeviceLabels(
        projectID      : String,
        deviceIDs      : [String],
        labelsToSet    : [String: String],
        labelsToRemove : [String],
        completion     : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the body
        struct Body: Codable {
            let devices: [String]
            let addLabels: [String: String]
            let removeLabels: [String]
        }
        let body = Body(
            devices: deviceIDs.map { "projects/\(projectID)/devices/\($0)" },
            addLabels: labelsToSet,
            removeLabels: labelsToRemove
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
     
     - Parameter deviceIDs: A list of the device identifiers to move from one project to another.
     - Parameter fromProjectID: The identifier of the project to move the devices from.
     - Parameter toProjectID: The identifier of the project to move the devices to.
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
        
        // Device resource names are formatted as "projects/b7s3umd0fee000ba5di0/devices/b5rj9ed7rihk942p48og"
        // Setting the identifier to the last component of the resource name
        let projectResourceName = try values.decode(String.self, forKey: .identifier)
        let resourceNameComponents = projectResourceName.components(separatedBy: "/")
        guard resourceNameComponents.count == 4 else {
            throw ParseError.identifier(path: projectResourceName)
        }
        self.projectID  = resourceNameComponents[1]
        self.identifier = resourceNameComponents[3]
        
        // Getting the other properties without any modifications
        self.labels = try values.decode([String: String].self, forKey: .labels)
        self.type   = try values.decode(DeviceType.self,       forKey: .type)
        
        // The name of the device comes in a label (if set)
        self.displayName = self.labels["name", default: ""]
        
        self.reportedEvents = try values.decode(ReportedEvents.self, forKey: .reportedEvents)
    }
}

extension Device {
    
    /**
     Represents the type of a `Device`.
     */
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
        
        /// Returns a `String` representation of the device type that is suited for presenting to a user on screen.
        public func displayName() -> String {
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
    
    /**
     Represents the latest known reported values for a `Device`. Any of the event types that is not available for that particular device type, or that have not yet received an event, will be `nil`.
     */
    public struct ReportedEvents: Decodable, Equatable {
        // Events
        public var touch              : TouchEvent?
        public var touchCount         : TouchCountEvent?
        public var temperature        : TemperatureEvent?
        public var humidity           : HumidityEvent?
        public var objectPresent      : ObjectPresentEvent?
        public var objectPresentCount : ObjectPresentCountEvent?
        public var waterPresent       : WaterPresentEvent?
        
        // Sensor Status
        public var batteryStatus      : BatteryStatusEvent?
        public var networkStatus      : NetworkStatusEvent?
        
        // Cloud Connector
        public var ethernetStatus     : EthernetStatusEvent?
        public var cellularStatus     : CellularStatusEvent?
        public var connectionStatus   : ConnectionStatusEvent?
        
        public init() {}
    }
}
