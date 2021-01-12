//
//  Emulator.swift
//  
//
//  Created by Vegard Solheim Theriault on 31/12/2020.
//

import Foundation

extension Disruptive {
    
    /**
     Gets details for a specific emulated device within a project.
     
     - Parameter projectID: The identifier of the project to find the device in.
     - Parameter deviceID: The identifier of the emulated device to get details for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `Device`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Device, DisruptiveError>`
     */
    public func getEmulatedDevice(
        projectID  : String,
        deviceID   : String,
        completion : @escaping (_ result: Result<Device, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/devices/\(deviceID)"
        let request = Request(method: .get, baseURL: emulatorBaseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Gets all the emulated devices in a specific project (without any physical devices).
     
     This will handle pagination automatically and send multiple network requests in
     the background if necessary. If a lot of emulated devices are expected to be in the project,
     it might be better to load pages of emulated devices as they're needed using the
     `getEmulatedDevicesPage` function instead.
     
     - Parameter projectID: The identifier of the project to get emulated devices from.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `Device`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[Device], DisruptiveError>`
     */
    public func getAllEmulatedDevices(
        projectID  : String,
        completion : @escaping (_ result: Result<[Device], DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: emulatorBaseURL, endpoint: "projects/\(projectID)/devices")
        
        // Send the request
        sendRequest(request, pagingKey: "devices") { completion($0) }
    }
    
    /**
     Gets one page of emulated devices.
     
     Useful if a lot of emulated devices are expected in the specified project. This function
     provides better control for when to get emulated devices and how many to get at a time so
     that emulated devices are only fetch when they are needed. This can also improve performance,
     at a cost of convenience compared to the `getAllEmulatedDevices` function.
     
     - Parameter projectID: The identifier of the project to get emulated devices from.
     - Parameter pageSize: The maximum number of emulated devices to get for this page. The maximum page size is 100, which is also the default
     - Parameter pageToken: The token of the page to get. For the first page, set this to `nil`. For subsequent pages, use the `nextPageToken` received when getting the previous page.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain a tuple with both an array of `Device`s, as well as the token for the next page. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<(nextPageToken: String?, devices: [Device]), DisruptiveError>`
     */
    public func getEmulatedDevicesPage(
        projectID  : String,
        pageSize   : Int = 100,
        pageToken  : String?,
        completion : @escaping (_ result: Result<(nextPageToken: String?, devices: [Device]), DisruptiveError>) -> ())
    {
        // Create the request
        let request = Request(method: .get, baseURL: emulatorBaseURL, endpoint: "projects/\(projectID)/devices")
        
        // Send the request
        sendRequest(request, pageSize: pageSize, pageToken: pageToken, pagingKey: "devices") { (result: Result<PagedResult<Device>, DisruptiveError>) in
            switch result {
                case .success(let page) : completion(.success((nextPageToken: page.nextPageToken, devices: page.results)))
                case .failure(let err)  : completion(.failure(err))
            }
        }
    }
    
    /**
     Creates a new emulated device in a specific project.
     
     - Parameter projectID: The identifier of the project to create the emulated device in.
     - Parameter deviceType: The type of device the emulated device should emulate.
     - Parameter displayName: The display name of the new emulated device. This will be added as a label with the key `name`.
     - Parameter labels: A set of keys and values to use as labels for the emulated device.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the newly created `Device`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Device, DisruptiveError>`
     */
    public func createEmulatedDevice(
        projectID   : String,
        deviceType  : Device.DeviceType,
        displayName : String,
        labels      : [String: String] = [:],
        completion  : @escaping (_ result: Result<Device, DisruptiveError>) -> ())
    {
        struct EmulatedPayload: Encodable {
            let type: String
            var labels: [String: String]
        }
        
        // If the device type is `.unknown`, return an error
        guard let typeStr = deviceType.rawValue else {
            Disruptive.log("Unable to use device type \(deviceType) for an emulated device", level: .error)
            completion(.failure(.badRequest))
            return
        }
        
        // Prepare the payload
        var payload = EmulatedPayload(type: typeStr, labels: labels)
        payload.labels["name"] = displayName
        
        do {
            // Create the request
            let endpoint = "projects/\(projectID)/devices"
            let request = try Request(method: .post, baseURL: emulatorBaseURL, endpoint: endpoint, body: payload)
            
            // Create the new project
            sendRequest(request) { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to init request with payload: \(payload). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? .unknownError))
        }
    }
    
    /**
     Deletes an emulated device.
     
     - Parameter projectID: The identifier of the project to delete the emulated device from.
     - Parameter deviceID: The identifier of the emulated device to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func deleteEmulatedDevice(
        projectID   : String,
        deviceID    : String,
        completion  : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/devices/\(deviceID)"
        let request = Request(method: .delete, baseURL: emulatorBaseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Publishes a new event to an emulated device.
     
     Any of the event types in `Sources/Disruptive/Helpers/EventTypes.swift` can be published,
     although not all event types can be published for every device type. For example, an emulated temperature sensor
     cannot publish an `EthernetStatusEvent`.
     For more details about the different event types, see the [Developer Website](https://support.disruptive-technologies.com/hc/en-us/articles/360012510839-Events).
     
     Example:
     ```
     // Publish a temperature event
     publishEmulatedEvent(
         projectID : "<PROJECT_ID>",
         deviceID  : "<DEVICE_ID>",
         event     : TemperatureEvent(value: 10, timestamp: Date())
     { result in
         ...
     }
     ```
     
     - Parameter projectID: The identifier of the project the emulated device is in.
     - Parameter deviceID: The identifier of the emulated device to publish the event to.
     - Parameter event: The event to publish to the emulated device. This can be any event type such as `TemperatureEvent`,
     `TouchEvent`, `NetworkStatusEvent`, `ObjectPresentEvent`, etc, as long as it conforms to the `PublishableEvent` protocol.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func publishEmulatedEvent<Event: PublishableEvent>(
        projectID          : String,
        deviceID           : String,
        event              : Event,
        completion         : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        do {
            // Create request
            let endpoint = "projects/\(projectID)/devices/\(deviceID):publish"
            let body = try PublishBody(event: event)
            let request = try Request(method: .post, baseURL: emulatorBaseURL, endpoint: endpoint, body: body)

            // Send the request
            sendRequest(request) { completion($0) }
        } catch (let err) {
            completion(.failure((err as? DisruptiveError) ?? .unknownError))
        }
    }
}

/// Used by event types (such as `TouchEvent`) to indicate that
/// they can be published to the device emulator.
public protocol PublishableEvent: Encodable {
    var eventType: EventType { get }
}

extension TouchEvent              : PublishableEvent { public var eventType: EventType { .touch } }
extension TemperatureEvent        : PublishableEvent { public var eventType: EventType { .temperature } }
extension ObjectPresentEvent      : PublishableEvent { public var eventType: EventType { .objectPresent } }
extension HumidityEvent           : PublishableEvent { public var eventType: EventType { .humidity } }
extension ObjectPresentCountEvent : PublishableEvent { public var eventType: EventType { .objectPresentCount } }
extension TouchCountEvent         : PublishableEvent { public var eventType: EventType { .touchCount } }
extension WaterPresentEvent       : PublishableEvent { public var eventType: EventType { .waterPresent } }
extension NetworkStatusEvent      : PublishableEvent { public var eventType: EventType { .networkStatus } }
extension BatteryStatusEvent      : PublishableEvent { public var eventType: EventType { .batteryStatus } }
extension ConnectionStatusEvent   : PublishableEvent { public var eventType: EventType { .connectionStatus } }
extension EthernetStatusEvent     : PublishableEvent { public var eventType: EventType { .ethernetStatus } }
extension CellularStatusEvent     : PublishableEvent { public var eventType: EventType { .cellularStatus } }

private struct PublishBody: Encodable {
    var touch              : TouchEvent?              = nil
    var temperature        : TemperatureEvent?        = nil
    var objectPresent      : ObjectPresentEvent?      = nil
    var humidity           : HumidityEvent?           = nil
    var objectPresentCount : ObjectPresentCountEvent? = nil
    var touchCount         : TouchCountEvent?         = nil
    var waterPresent       : WaterPresentEvent?       = nil
    var networkStatus      : NetworkStatusEvent?      = nil
    var batteryStatus      : BatteryStatusEvent?      = nil
    var connectionStatus   : ConnectionStatusEvent?   = nil
    var ethernetStatus     : EthernetStatusEvent?     = nil
    var cellularStatus     : CellularStatusEvent?     = nil
    
    init<Event: PublishableEvent>(event: Event) throws {
        switch event.eventType {
            case .touch              : touch              = event as? TouchEvent
            case .temperature        : temperature        = event as? TemperatureEvent
            case .objectPresent      : objectPresent      = event as? ObjectPresentEvent
            case .humidity           : humidity           = event as? HumidityEvent
            case .objectPresentCount : objectPresentCount = event as? ObjectPresentCountEvent
            case .touchCount         : touchCount         = event as? TouchCountEvent
            case .waterPresent       : waterPresent       = event as? WaterPresentEvent
            case .networkStatus      : networkStatus      = event as? NetworkStatusEvent
            case .batteryStatus      : batteryStatus      = event as? BatteryStatusEvent
            case .connectionStatus   : connectionStatus   = event as? ConnectionStatusEvent
            case .ethernetStatus     : ethernetStatus     = event as? EthernetStatusEvent
            case .cellularStatus     : cellularStatus     = event as? CellularStatusEvent
            case .labelsChanged:
                // LabelsChangedEvent is not a `PublishableEvent` so this shouldn't happen.
                DTLog("LabelsChangedEvent cannot be published", level: .error)
                throw DisruptiveError.badRequest
        }
    }
}
