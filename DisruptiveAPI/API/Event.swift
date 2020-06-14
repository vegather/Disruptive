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
    public var labelsChanged      : [LabelsChanged]?
    
    // Cloud Connector
    public var connectionStatus   : [ConnectionStatus]?
    public var ethernetStatus     : [EthernetStatus]?
    public var cellularStatus     : [CellularStatus]?
    public var latencyStatus      : [ConnectionLatency]?
    
    public init() {}
    
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
                case .labelsChanged     (_, let event): Events.addToList(list: &labelsChanged,      newItem: event)
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
}

extension Disruptive {
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
        
        // Create the request
        let request = Request(method: .get, endpoint: "projects/\(projectID)/devices/\(deviceID)/events", params: params)
        
        // Send the request
        sendRequest(request: request, pageingKey: "events") { (response: Result<[EventContainer], DisruptiveError>) in
            switch response {
                case .success(let eventContainers):
                    completion(.success(Events(events: eventContainers)))
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
}
