//
//  DeviceEmulator.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 31/12/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

struct DeviceEmulator {
    
    /**
     Creates a new emulated device in a specific project.
     
     Emulated devices will be listed in the standard `Device.getAll` method along with the
     physical devices. The `isEmulatedDevice` property will differentiate them.
     
     - Parameter projectID: The identifier of the project to create the emulated device in.
     - Parameter deviceType: The type of device the emulated device should emulate.
     - Parameter displayName: The display name of the new emulated device. This will be added as a label with the key `name`.
     - Parameter labels: A set of keys and values to use as labels for the emulated device.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the newly created `Device`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<Device, DisruptiveError>`
     */
    public static func create(
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
            completion(.failure(DisruptiveError(
                type: .badRequest,
                message: "Device type \(deviceType) can't be used as an emulated device",
                helpLink: nil
            )))
            return
        }
        
        // Prepare the payload
        var payload = EmulatedPayload(type: typeStr, labels: labels)
        payload.labels["name"] = displayName
        
        do {
            // Create the request
            let endpoint = "projects/\(projectID)/devices"
            let request = try Request(method: .post, baseURL: Disruptive.emulatorBaseURL, endpoint: endpoint, body: payload)
            
            // Create the new project
            request.send() { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to init request with payload: \(payload). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? DisruptiveError(type: .unknownError, message: "", helpLink: nil)))
        }
    }
    
    /**
     Deletes an emulated device.
     
     - Parameter projectID: The identifier of the project to delete the emulated device from.
     - Parameter deviceID: The identifier of the emulated device to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public static func delete(
        projectID   : String,
        deviceID    : String,
        completion  : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/devices/\(deviceID)"
        let request = Request(method: .delete, baseURL: Disruptive.emulatorBaseURL, endpoint: endpoint)
        
        // Send the request
        request.send() { completion($0) }
    }
    
    /**
     Publishes a new event to an emulated device.
     
     Any of the event types in `Sources/Disruptive/Helpers/EventTypes.swift` can be published,
     although not all event types can be published for every device type. For example, an emulated temperature sensor
     cannot publish an `EthernetStatusEvent`.
     For more details about the different event types, see the [Developer Website](https://developer.disruptive-technologies.com/docs/concepts/events).
     
     Example:
     ```
     // Publish a temperature event
     DeviceEmulator.publishEvent(
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
    public static func publishEvent<Event: PublishableEvent>(
        projectID          : String,
        deviceID           : String,
        event              : Event,
        completion         : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        do {
            // Create request
            let endpoint = "projects/\(projectID)/devices/\(deviceID):publish"
            let body = try PublishBody(event: event)
            let request = try Request(method: .post, baseURL: Disruptive.emulatorBaseURL, endpoint: endpoint, body: body)

            // Send the request
            request.send() { completion($0) }
        } catch (let err) {
            completion(.failure((err as? DisruptiveError) ?? DisruptiveError(type: .unknownError, message: "", helpLink: nil)))
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
                let error = DisruptiveError(
                    type: .badRequest,
                    message: "LabelsChangedEvent cannot be published",
                    helpLink: nil
                )
                DTLog(error.message, level: .error)
                throw error
        }
    }
}
