//
//  Stream.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 01/06/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

extension Disruptive {
    public static func subscribeToDevices(
        in projectID : String,
        deviceIDs    : [String]? = nil,
        deviceTypes  : [Device.DeviceType]? = nil,
        labelFilters : [String]? = nil,
        eventTypes   : [EventType]? = nil)
        -> ServerSentEvents?
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
            params["device_types"] = deviceTypes.map { $0.rawValue }
        }
        if let eventTypes = eventTypes {
            params["event_types"] = eventTypes.map { $0.rawValue }
        }
        
        // Get the URL request
        let request = Request(method: .get, endpoint: "projects/\(projectID)/devices:stream", params: params)
        guard let urlRequest = request.urlRequest() else {
            return nil
        }
        
        // Create the stream, and connect to it
        return ServerSentEvents(request: urlRequest)
    }
}
