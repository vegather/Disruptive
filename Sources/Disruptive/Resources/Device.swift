//
//  Device.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 21/05/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 Represents a Sensor or Cloud Connector from Disruptive Technologies.
 */
public struct Device: Decodable, Equatable {
    
    /// The unique identifier of the device. This will be different from the `name` field in the REST API
    /// in that it is just the identifier without the `projects/*/devices/` prefix.
    public let identifier: String
    
    /// The display name of the device.
    public var displayName: String
    
    /// The identifier of the project the device is in.
    public let projectID: String
    
    /// The labels that are currently set on the device. This will also include the `displayName` of the device as a label with the key `name`.
    public let labels: [String: String]
    
    /// The type of the device. What type the device is determines which types of events it will receive.
    public let type: DeviceType
    
    /// The product number of the device. This is the same product number that can be found on the support pages for both
    /// [Sensors](https://support.disruptive-technologies.com/hc/en-us/sections/360003211399-Products) and
    /// [Cloud Connectors](https://support.disruptive-technologies.com/hc/en-us/sections/360003168340-Products).
    public let productNumber: String?
    
    /// The last known reported event for each available event type for the device. Which of these are available is dependent on the device `type`.
    public var reportedEvents: ReportedEvents
    
    /// Indicates whether the device is a real physical device or an emulated one.
    public let isEmulatedDevice: Bool
    
    /// Creates a new `Device`. Creating a new device can be useful for testing purposes.
    public init(identifier: String, displayName: String, projectID: String, labels: [String: String], type: DeviceType, productNumber: String?, reportedEvents: ReportedEvents, isEmulatedDevice: Bool)
    {
        self.identifier = identifier
        self.displayName = displayName
        self.projectID = projectID
        self.labels = labels
        self.type = type
        self.productNumber = productNumber
        self.reportedEvents = reportedEvents
        self.isEmulatedDevice = isEmulatedDevice
    }
}


extension Device {
    
    /**
     Gets all the devices in a specific project (including emulated devices).
     
     This will handle pagination automatically and send multiple network requests in
     the background if necessary. If a lot of devices are expected to be in the project,
     it might be better to load pages of devices as they're needed using the
     `getDevicesPage` function instead.
     
     Examples:
     ```swift
     // Get all the devices in the project
     Disruptive.getDevices(projectID: "<PROJECT_ID>") { result in
         ...
     }
     
     // Get all the temperature devices in the project ordered by
     // the temperature (highest temperatures first)
     Disruptive.getDevices(
         projectID   : "<PROJECT_ID>",
         deviceTypes : [.temperature],
         orderBy     : (field: "reported.temperature.value", ascending: false))
     { result in
        ...
     }
     ```
     
     - Parameter projectID: The identifier of the project to get devices from.
     - Parameter query: Simple keyword based search. Will be ignored if not set (or `nil`), which is the default.
     - Parameter deviceIDs: Filters on a list of device identifiers. Will be ignored if not set (or `nil`), which is the default.
     - Parameter deviceTypes: Filters on a list of device types. Will be ignored if not set (or `nil`), which is the default.
     - Parameter productNumbers: Filters on a list of product numbers. This is the same product number that can be found on the support pages for both [Sensors](https://support.disruptive-technologies.com/hc/en-us/sections/360003211399-Products) and [Cloud Connectors](https://support.disruptive-technologies.com/hc/en-us/sections/360003168340-Products).
     - Parameter labelFilters: Filters on a set of labels. Will be ignored if not set (or `nil`), which is the default.
     - Parameter orderBy: Specifies the field to order the retrieved devices by. Uses a dot notation format (eg. `reported.temperature.value` or `labels.name`). The fields are defined by the JSON structure of a Device. See the [REST API](https://developer.disruptive-technologies.com/api#/Devices%20%26%20Labels/get_projects__project__devices) documentation for the `GET Devices` endpoint to get hints for which fields are available. Also provides option to specify ascending or descending order.  Will be ignored if not set (or `nil`), which is the default.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Device`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Device], DisruptiveError>`
     */
    public static func getDevices(
        projectID      : String,
        query          : String?                           = nil,
        deviceIDs      : [String]?                         = nil,
        deviceTypes    : [Device.DeviceType]?              = nil,
        productNumbers : [String]?                         = nil,
        labelFilters   : [String: String]?                 = nil,
        orderBy        : (field: String, ascending: Bool)? = nil,
        completion     : @escaping (_ result: Result<[Device], DisruptiveError>) -> ())
    {
        // Set up the query parameters
        let params = createDevicesParams(
            query:          query,
            deviceIDs:      deviceIDs,
            deviceTypes:    deviceTypes,
            productNumbers: productNumbers,
            labelFilters:   labelFilters,
            orderBy:        orderBy
        )
        
        // Create the request
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: "projects/\(projectID)/devices", params: params)
        
        // Send the request
        request.send(pagingKey: "devices") { completion($0) }
    }
    
    /**
     Gets one page of devices (including emulated devices).
     
     Useful if a lot of devices are expected in the specified project. This function
     provides better control for when to get devices and how many to get at a time so
     that devices are only fetch when they are needed. This can also improve performance,
     at a cost of convenience compared to the `getDevices` function.
     
     - Parameter projectID: The identifier of the project to get devices from.
     - Parameter query: Simple keyword based search. Will be ignored if not set (or `nil`), which is the default.
     - Parameter deviceIDs: Filters on a list of device identifiers. Will be ignored if not set (or `nil`), which is the default.
     - Parameter deviceTypes: Filters on a list of device types. Will be ignored if not set (or `nil`), which is the default.
     - Parameter productNumbers: Filters on a list of product numbers. This is the same product number that can be found on the support pages for both [Sensors](https://support.disruptive-technologies.com/hc/en-us/sections/360003211399-Products) and [Cloud Connectors](https://support.disruptive-technologies.com/hc/en-us/sections/360003168340-Products).
     - Parameter labelFilters: Filters on a set of labels. Will be ignored if not set (or `nil`), which is the default.
     - Parameter orderBy: Specifies the field to order the retrieved devices by. Uses a dot notation format (eg. `reported.temperature.value` or `labels.name`). The fields are defined by the JSON structure of a Device. See the [REST API](https://developer.disruptive-technologies.com/api#/Devices%20%26%20Labels/get_projects__project__devices) documentation for the `GET Devices` request to get hints for which fields are available. Also provides option to specify ascending or descending order.  Will be ignored if not set (or `nil`), which is the default.
     - Parameter pageSize: The maximum number of devices to get for this page. The maximum page size is 100, which is also the default
     - Parameter pageToken: The token of the page to get. For the first page, set this to `nil`. For subsequent pages, use the `nextPageToken` received when getting the previous page.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain a tuple with both an array of `Device`s, as well as the token for the next page. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<(nextPageToken: String?, devices: [Device]), DisruptiveError>`
     */
    public static func getDevicesPage(
        projectID      : String,
        query          : String?                           = nil,
        deviceIDs      : [String]?                         = nil,
        deviceTypes    : [Device.DeviceType]?              = nil,
        productNumbers : [String]?                         = nil,
        labelFilters   : [String: String]?                 = nil,
        orderBy        : (field: String, ascending: Bool)? = nil,
        pageSize       : Int = 100,
        pageToken      : String?,
        completion     : @escaping (_ result: Result<(nextPageToken: String?, devices: [Device]), DisruptiveError>) -> ())
    {
        // Set up the query parameters
        let params = createDevicesParams(
            query:          query,
            deviceIDs:      deviceIDs,
            deviceTypes:    deviceTypes,
            productNumbers: productNumbers,
            labelFilters:   labelFilters,
            orderBy:        orderBy
        )
        
        // Create the request
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: "projects/\(projectID)/devices", params: params)
        
        // Send the request
        request.send(pageSize: pageSize, pageToken: pageToken, pagingKey: "devices") { (result: Result<PagedResult<Device>, DisruptiveError>) in
            switch result {
                case .success(let page) : completion(.success((nextPageToken: page.nextPageToken, devices: page.results)))
                case .failure(let err)  : completion(.failure(err))
            }
        }
    }
    
    // Private helper function to create parameters for the getDevices... requests
    private static func createDevicesParams(
        query          : String?                           = nil,
        deviceIDs      : [String]?                         = nil,
        deviceTypes    : [Device.DeviceType]?              = nil,
        productNumbers : [String]?                         = nil,
        labelFilters   : [String: String]?                 = nil,
        orderBy        : (field: String, ascending: Bool)? = nil
        ) -> [String: [String]]
    {
        var params = [String: [String]]()
        
        if let query = query {
            params["query"] = [query]
        }
        if let deviceIDs = deviceIDs {
            params["device_ids"] = deviceIDs
        }
        if let deviceTypes = deviceTypes {
            params["device_types"] = deviceTypes.compactMap { $0.rawValue }
        }
        if let productNumbers = productNumbers {
            params["product_numbers"] = productNumbers
        }
        if let labelFilters = labelFilters {
            params["label_filters"] = labelFilters.keys.map { "\($0)=\(labelFilters[$0]!)"}
        }
        if let orderBy = orderBy {
            params["order_by"] = [(orderBy.ascending ? "" : "-") + orderBy.field]
        }
        
        return params
    }
    
    /**
     Gets details for a specific device. This device could be found within a specific project, or if the `projectID` argument is not specified (or nil), throughout all the project available to the authenticated account.
     
     - Parameter projectID: The identifier of the project to find the device in. If default value (nil) is used, a wildcard character will be used for the projectID that searches through all the project the authenticated account has access to.
     - Parameter deviceID: The identifier of the device to get details for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Device`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Device, DisruptiveError>`
     */
    public static func getDevice(
        projectID  : String? = nil,
        deviceID   : String,
        completion : @escaping (_ result: Result<Device, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID ?? "-")/devices/\(deviceID)"
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: endpoint)
        
        // Send the request
        request.send() { completion($0) }
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
    public static func updateDeviceDisplayName(
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
     Deletes the specified label for the device. Will return success if the label didn't exist.
     
     This is a convenience function for `batchUpdateDeviceLabels`.
     
     - Parameter projectID: The identifier of the project the device is in.
     - Parameter deviceID: The identifier of the device to delete a label from.
     - Parameter labelKey: The key of the label to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public static func deleteDeviceLabel(
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
    public static func setDeviceLabel(
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
    public static func batchUpdateDeviceLabels(
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
            let request = try Request(method: .post, baseURL: Disruptive.baseURL, endpoint: endpoint, body: body)
            
            // Send the request
            request.send() { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to init setLabel request with payload: \(body). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? DisruptiveError(type: .unknownError, message: "", helpLink: nil)))
        }
    }
    
    /**
     Transfers a list of devices from one project to another. The authenticated account must be a project admin
     in the `toProjectID`, or an organization admin in the organization that owns the `toProjectID` project.
     
     - Parameter deviceIDs: A list of the device identifiers to transfer from one project to another.
     - Parameter fromProjectID: The identifier of the project to transfer the devices from.
     - Parameter toProjectID: The identifier of the project to transfer the devices to.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public static func transferDevices(
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
            let request = try Request(method: .post, baseURL: Disruptive.baseURL, endpoint: endpoint, body: body)
            
            // Send the request
            request.send() { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to initialize transfer devices request with payload: \(body). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? DisruptiveError(type: .unknownError, message: "", helpLink: nil)))
        }
    }
}


extension Device {
    private enum CodingKeys: String, CodingKey {
        case resourceName = "name"
        case labels
        case type
        case reported
        case productNumber
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Device resource names are formatted as "projects/b7s3umd0fee000ba5di0/devices/b5rj9ed7rihk942p48og"
        // Setting the identifier to the last component of the resource name
        let projectResourceName = try container.decode(String.self, forKey: .resourceName)
        let resourceNameComponents = projectResourceName.components(separatedBy: "/")
        guard resourceNameComponents.count == 4 else {
            throw ParseError.identifier(resourceName: projectResourceName)
        }
        self.projectID  = resourceNameComponents[1]
        let id = resourceNameComponents[3]
        self.identifier = id
        self.isEmulatedDevice = id.count == 23 && id.hasPrefix("emu")
        
        // Decode product number. Will not be present for emulators,
        // and should be nil if empty string.
        var productNumber = try container.decodeIfPresent(String.self,  forKey: .productNumber)
        if productNumber == "" {
            productNumber = nil
        }
        self.productNumber = productNumber
        
        // Getting the other properties without any modifications
        self.labels        = try container.decode([String: String].self, forKey: .labels)
        self.type          = try container.decode(DeviceType.self,       forKey: .type)
        
        // The name of the device comes in a label (if set)
        self.displayName = self.labels["name", default: ""]
        
        // An emulated device will initially not have any reported events
        if let reported = try container.decodeIfPresent(ReportedEvents.self, forKey: .reported) {
            self.reportedEvents = reported
        } else {
            self.reportedEvents = ReportedEvents()
        }
    }
}

extension Device {
    
    /**
     Represents the type of a `Device`.
     
     For more details about the various sensors, see the [DT product page](https://www.disruptive-technologies.com/products/wireless-sensors).
     */
    public enum DeviceType: Decodable, Equatable {
        case temperature
        case touch
        case proximity
        case humidity
        case touchCounter
        case proximityCounter
        case waterDetector
        case cloudConnector
        
        /// The type received for the device was unknown.
        /// Added for backwards compatibility in case a new device type
        /// is added on the backend, and not yet added to this client library.
        case unknown(value: String)
        
        // This is a slightly clunky setup to let the `DeviceType` be
        // backwards compatible in case new device types gets added
        // to the backend.
        public init(from decoder: Decoder) throws {
            let str = try decoder.singleValueContainer().decode(String.self)
            
            switch str {
                case "temperature"      : self = .temperature
                case "touch"            : self = .touch
                case "proximity"        : self = .proximity
                case "humidity"         : self = .humidity
                case "touchCounter"     : self = .touchCounter
                case "proximityCounter" : self = .proximityCounter
                case "waterDetector"    : self = .waterDetector
                case "ccon"             : self = .cloudConnector
                default                 : self = .unknown(value: str)
            }
        }
        
        /// Used internally to create requests and for testing.
        /// Returns `nil` for the `.unknown` device type.
        internal var rawValue: String? {
            switch self {
                case .temperature      : return "temperature"
                case .touch            : return "touch"
                case .proximity        : return "proximity"
                case .humidity         : return "humidity"
                case .touchCounter     : return "touchCounter"
                case .proximityCounter : return "proximityCounter"
                case .waterDetector    : return "waterDetector"
                case .cloudConnector   : return "ccon"
                case .unknown          : return nil
            }
        }
        
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
                case .unknown(let s)   : return "Unknown (\(s))"
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
