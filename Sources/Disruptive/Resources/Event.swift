//
//  Event.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 28/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

public struct Events {
    // Events
    public var touch              : [TouchEvent]?
    public var temperature        : [TemperatureEvent]?
    public var objectPresent      : [ObjectPresentEvent]?
    public var humidity           : [HumidityEvent]?
    public var objectPresentCount : [ObjectPresentCount]?
    public var touchCount         : [TouchCount]?
    public var waterPresent       : [WaterPresentEvent]?

    // Sensor Status
    public var networkStatus      : [NetworkStatus]?
    public var batteryStatus      : [BatteryStatus]?
//    public var labelsChanged      : [LabelsChanged]?
    
    // Cloud Connector
    public var connectionStatus   : [ConnectionStatus]?
    public var ethernetStatus     : [EthernetStatus]?
    public var cellularStatus     : [CellularStatus]?
    public var latencyStatus      : [ConnectionLatency]?
    
    public init() {}
}


extension Disruptive {
    /**
     Fetches historical data for a specific device from the server. The events are
     returned with the oldest event at the beginning of the array, and the newest
     event at the end.
     
     If one or more `eventTypes` are specified, only those events will be fetched.
     Otherwise, all the events available for the specified device will be fetched.
     Note that not all event types are available for all devices.
     
     If `startDate` or `endDate` is not specified, it defaults to the last 24 hours.
     
     - Parameter projectID: The identifier of the project where the device is
     - Parameter deviceID: The identifier of the device to get events from
     - Parameter startDate: The timestamp of the first event to fetch. Defaults to 24 hours ago
     - Parameter endDate: The timestamp of the last event to fetch. Defaults to now
     - Parameter eventTypes: A list of event types to fetch. Defaults to fetching all events for specified device
     - Parameter completion: The completion handler that is called when data is returned from the server. This is a `Result` type where the success case is a list of `Events`, and the failure case is a `DisruptiveError`.
     - Parameter result: `Result<Events, DisruptiveError>`
     */
    public func getEvents(
        projectID  : String,
        deviceID   : String,
        startDate  : Date? = nil,
        endDate    : Date? = nil,
        eventTypes : [EventType]? = nil,
        completion : @escaping (_ result: Result<Events, DisruptiveError>) -> ())
    {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        // Set up the query parameters
        var params: [String: [String]] = [:]
        if let startDate = startDate {
            params["start_time"] = [dateFormatter.string(from: startDate)]
        }
        if let endDate = endDate {
            params["end_time"] = [dateFormatter.string(from: endDate)]
        }
        if let eventTypes = eventTypes {
            params["event_types"] = eventTypes.map { $0.rawValue }
        }
        
        params["page_size"] = ["1000"]
        
        // Create the request
        let request = Request(method: .get, baseURL: baseURL, endpoint: "projects/\(projectID)/devices/\(deviceID)/events", params: params)
        
        // Send the request
        sendRequest(request, pageingKey: "events") { (response: Result<[EventContainer], DisruptiveError>) in
            switch response {
                case .success(let eventContainers):
                    // The events are returned from the server with the newest event at the beginning.
                    // We want to flip this around to make the data easier to work with (draw as
                    // graphs, etc). The `reversed()` call should be doing most of the heavy lifting
                    // here, and we're sorting at the end to guarantee the order. This is way faster
                    // than just sorting without reversing first.
                    var events = Events(events: eventContainers.reversed())
                    events.sort()
                    
                    completion(.success(events))
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
}


extension Events {
    
    fileprivate init(events: [EventContainer]) {
        for event in events {
            switch event {
                case .touch             (_, let event): Events.addToList(list: &touch,              newItem: event)
                case .temperature       (_, let event): Events.addToList(list: &temperature,        newItem: event)
                case .objectPresent     (_, let event): Events.addToList(list: &objectPresent,      newItem: event)
                case .humidity          (_, let event): Events.addToList(list: &humidity,           newItem: event)
                case .objectPresentCount(_, let event): Events.addToList(list: &objectPresentCount, newItem: event)
                case .touchCount        (_, let event): Events.addToList(list: &touchCount,         newItem: event)
                case .waterPresent      (_, let event): Events.addToList(list: &waterPresent,       newItem: event)
                case .networkStatus     (_, let event): Events.addToList(list: &networkStatus,      newItem: event)
                case .batteryStatus     (_, let event): Events.addToList(list: &batteryStatus,      newItem: event)
//                case .labelsChanged     (_, let event): Events.addToList(list: &labelsChanged,      newItem: event)
                case .connectionStatus  (_, let event): Events.addToList(list: &connectionStatus,   newItem: event)
                case .ethernetStatus    (_, let event): Events.addToList(list: &ethernetStatus,     newItem: event)
                case .cellularStatus    (_, let event): Events.addToList(list: &cellularStatus,     newItem: event)
                case .latencyStatus     (_, let event): Events.addToList(list: &latencyStatus,      newItem: event)
            }
        }
    }
    
    // Helper to append to optional array. Creates the array if it's nil,
    // and appends to the array if it already exists
    private static func addToList<T>(list: inout [T]?, newItem: T) {
        if list == nil {
            list = [newItem]
        } else {
            list?.append(newItem)
        }
    }
    
    fileprivate mutating func sort() {
        touch?             .sort { $0.timestamp < $1.timestamp }
        temperature?       .sort { $0.timestamp < $1.timestamp }
        objectPresent?     .sort { $0.timestamp < $1.timestamp }
        humidity?          .sort { $0.timestamp < $1.timestamp }
        objectPresentCount?.sort { $0.timestamp < $1.timestamp }
        touchCount?        .sort { $0.timestamp < $1.timestamp }
        waterPresent?      .sort { $0.timestamp < $1.timestamp }
        networkStatus?     .sort { $0.timestamp < $1.timestamp }
        batteryStatus?     .sort { $0.timestamp < $1.timestamp }
        connectionStatus?  .sort { $0.timestamp < $1.timestamp }
        ethernetStatus?    .sort { $0.timestamp < $1.timestamp }
        cellularStatus?    .sort { $0.timestamp < $1.timestamp }
        latencyStatus?     .sort { $0.timestamp < $1.timestamp }
    }
    
    public mutating func merge(with other: Events) {
        if let e = other.touch              { self.touch              = e }
        if let e = other.temperature        { self.temperature        = e }
        if let e = other.objectPresent      { self.objectPresent      = e }
        if let e = other.humidity           { self.humidity           = e }
        if let e = other.objectPresentCount { self.objectPresentCount = e }
        if let e = other.touchCount         { self.touchCount         = e }
        if let e = other.waterPresent       { self.waterPresent       = e }
        if let e = other.networkStatus      { self.networkStatus      = e }
        if let e = other.batteryStatus      { self.batteryStatus      = e }
//        if let e = other.labelsChanged      { self.labelsChanged      = e }
        if let e = other.connectionStatus   { self.connectionStatus   = e }
        if let e = other.ethernetStatus     { self.ethernetStatus     = e }
        if let e = other.cellularStatus     { self.cellularStatus     = e }
        if let e = other.latencyStatus      { self.latencyStatus      = e }
    }
}
