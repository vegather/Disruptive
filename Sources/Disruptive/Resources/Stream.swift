//
//  Stream.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 01/06/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

extension Disruptive {
    
    /**
     Sets up a device stream to one or more devices in a specific project using server-sent-events. By default, all events for all the devices in the specified project will be subscribed to. The various arguments are ways to limit which devices and event types gets subscribed to.
     
     Example:
     ```
     let stream = disruptive.subscribeToDevices(projectID: "<PROJECT_ID>")
     stream?.onTemperature = { deviceID, tempEvent in
        print("Got \(tempEvent) from \(deviceID)")
     }
     ```
     
     - Parameter projectID: The identifier of the project that contains the device(s).
     - Parameter deviceIDs: An array of device identifiers to subscribe to. If not specified (or `nil`), all the devices in the project will be subscribed to.
     - Parameter deviceTypes: An array of device types to subscribe to. This is useful if `nil` is specified for the `deviceIDs` argument.
     - Parameter productNumbers: An array of product numbers to subscribe to. This is the same product number that can be found on the support pages for both [Sensors](https://support.disruptive-technologies.com/hc/en-us/sections/360003211399-Products) and [Cloud Connectors](https://support.disruptive-technologies.com/hc/en-us/sections/360003168340-Products).
     - Parameter labelFilters: An array of label filter expressions that filters the set of devices for the results. Each expression takes the form labelKey=labelValue.
     - Parameter eventTypes: An array of event types to subscribe to.
          
     - Returns: A `DeviceEventStream` device stream object with callbacks for each type of event. For example, set a closure on the `onNetworkStatus` property to receive an event each time a device sends out a heart beat.
     */
    public func subscribeToDevices(
        projectID      : String,
        deviceIDs      : [String]?            = nil,
        deviceTypes    : [Device.DeviceType]? = nil,
        productNumbers : [String]?            = nil,
        labelFilters   : [String]?            = nil,
        eventTypes     : [EventType]?         = nil)
        -> DeviceEventStream
    {
        // Construct parameters
        var params: [String: [String]] = [:]
        if let deviceIDs = deviceIDs {
            params["device_ids"] = deviceIDs
        }
        if let labelFilters = labelFilters {
            params["label_filters"] = labelFilters
        }
        if let deviceTypes = deviceTypes {
            params["device_types"] = deviceTypes.compactMap { $0.rawValue }
        }
        if let productNumbers = productNumbers {
            params["product_numbers"] = productNumbers
        }
        if let eventTypes = eventTypes {
            params["event_types"] = eventTypes.map { $0.rawValue }
        }
                
        let request = Request(method: .get, baseURL: Disruptive.baseURL, endpoint: "projects/\(projectID)/devices:stream", params: params)
        
        // Create the stream, and connect to it
        return DeviceEventStream(request: request, authenticator: Disruptive.auth)
    }
    
    /**
     Convenience function to subscribe to just a single device. See `subscribeToDevices` for more details.
     
     - Parameter projectID: The identifier of the project the device is currently in.
     - Parameter deviceID: The identifier of the device to subscribe to.
     - Parameter eventTypes: Optional parameter to specify which event types to subscribe to. If this is omitted, all the available event types for this device will be received.
     */
    public func subscribeToDevice(projectID: String, deviceID: String, eventTypes: [EventType]? = nil) -> DeviceEventStream {
        return subscribeToDevices(
            projectID      : projectID,
            deviceIDs      : [deviceID],
            deviceTypes    : nil,
            productNumbers : nil,
            labelFilters   : nil,
            eventTypes     : eventTypes
        )
    }
}
