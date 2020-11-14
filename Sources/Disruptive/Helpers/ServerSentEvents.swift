//
//  ServerSentEvents.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

// Reference: https://www.w3.org/TR/eventsource/

public class ServerSentEvents: NSObject {
    private static var sseConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = .greatestFiniteMagnitude
        config.timeoutIntervalForResource = .greatestFiniteMagnitude
        
        let headers = [
            "Accept"        : "text/event-stream",
            "Cache-Control" : "no-cache"
        ]
        config.httpAdditionalHeaders = headers
        
        return config
    }()
    
    private var session: URLSession!
    private var task: URLSessionTask?
    private let request: Request
    private let authProvider: AuthProvider
    
    private var retryScheme = RetryScheme()
    
    private var hasBeenClosed = false
    
    // Error
    public var onError              : ((DisruptiveError)            -> ())?
    
    // Event callbacks
    public var onTouch              : ((String, TouchEvent)         -> ())?
    public var onTemperature        : ((String, TemperatureEvent)   -> ())?
    public var onObjectPresent      : ((String, ObjectPresentEvent) -> ())?
    public var onHumidity           : ((String, HumidityEvent)      -> ())?
    public var onObjectPresentCount : ((String, ObjectPresentCount) -> ())?
    public var onTouchCount         : ((String, TouchCount)         -> ())?
    public var onWaterPresent       : ((String, WaterPresentEvent)  -> ())?
    
    // Sensor status callbacks
    public var onNetworkStatus      : ((String, NetworkStatus) -> ())?
    public var onBatteryStatus      : ((String, BatteryStatus) -> ())?
//    public var onLabelsChanged      : ((String, LabelsChanged) -> ())?
    
    // Cloud connector callbacks
    public var onConnectionStatus   : ((String, ConnectionStatus)  -> ())?
    public var onEthernetStatus     : ((String, EthernetStatus)    -> ())?
    public var onCellularStatus     : ((String, CellularStatus)    -> ())?
    public var onLatencyStatus      : ((String, ConnectionLatency) -> ())?
    
    // Preventing init without parameters
    private override init() { fatalError() }
    
    internal init(request: Request, authProvider: AuthProvider) {
        self.request = request
        self.authProvider = authProvider
        
        super.init()
        
        setupSession()
        restartStream()
    }
    
    public func close() {
        guard hasBeenClosed == false else { return }
        
        hasBeenClosed = true
        task?.cancel()
        session.invalidateAndCancel()
    }
    
    deinit {
        close()
    }
    
    
    
    // -------------------------------
    // MARK: Private Helpers
    // -------------------------------
    
    private func setupSession() {
        session = URLSession(
            configuration: ServerSentEvents.sseConfig,
            delegate: self,
            delegateQueue: .main
        )
    }
    
    private func restartStream() {
        guard hasBeenClosed == false else { return }
        
        authProvider.getNonExpiredAuthToken { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let token):
                
                // Add the "Authorization" header to the Request
                var req = self.request
                req.setHeader(field: "Authorization", value: token)
                
                // Convert to URLRequest
                guard let urlRequest = req.urlRequest() else {
                    DTLog("Failed to create URLRequest to restart the ServerSentEvents stream", isError: true)
                    self.onError?(.unknownError)
                    return
                }
                
                // Send the request (connect to stream)
                self.task = self.session.dataTask(with: urlRequest)
                self.task?.resume()
            case .failure(let e):
                DTLog("Failed to authenticate the ServerSentEvents stream. Error: \(e)", isError: true)
                self.onError?(e)
            }
        }
    }
}

extension ServerSentEvents: URLSessionDataDelegate {
    // Packet format for payloads from the ServerSentEvent
    private struct StreamPacket: Decodable {
        let result: StreamEvent
        
        struct StreamEvent: Decodable {
            let event: EventContainer
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data)
    {
        // We got data, so reset the retry scheme
        retryScheme.reset()
        
        // Somewhat clunky way to parse this data:
        // - Convert to String
        // - Split on "\n\n"
        // - Remove empty strings
        // - Remove the "data: " prefix
        // - Convert back to Data
        // - JSON decode the Data
        
        guard let payloadStr = String(data: data, encoding: .utf8) else {
            return
        }
        
        let eventJSONs: [Data] = payloadStr.components(separatedBy: "\n\n").compactMap {
            // Return nil it it's an empty string. compactMap(...) will remove it
            if $0.count == 0 { return nil }
            
            // Remove the "data: " prefix, leaving just the event JSON
            let jsonStr = $0.replacingOccurrences(of: "data: ", with: "")
            
            // Convert the JSON String to Data
            return jsonStr.data(using: .utf8)
        }
        
        let decoder = JSONDecoder()
        for eventData in eventJSONs {
            do {
                let streamPacket = try decoder.decode(StreamPacket.self, from: eventData)
                
                // Reading out the device ID and the event of each stream packet,
                // and calling the appropriate callback closure
                switch streamPacket.result.event {
                    // Events
                    case .touch              (let d, let e): onTouch?(d, e)
                    case .temperature        (let d, let e): onTemperature?(d, e)
                    case .objectPresent      (let d, let e): onObjectPresent?(d, e)
                    case .humidity           (let d, let e): onHumidity?(d, e)
                    case .objectPresentCount (let d, let e): onObjectPresentCount?(d, e)
                    case .touchCount         (let d, let e): onTouchCount?(d, e)
                    case .waterPresent       (let d, let e): onWaterPresent?(d, e)
                    
                    // Sensor status
                    case .networkStatus      (let d, let e): onNetworkStatus?(d, e)
                    case .batteryStatus      (let d, let e): onBatteryStatus?(d, e)
//                    case .labelsChanged      (let d, let e): onLabelsChanged?(d, e)
                    
                    // Cloud connector
                    case .connectionStatus   (let d, let e): onConnectionStatus?(d, e)
                    case .ethernetStatus     (let d, let e): onEthernetStatus?(d, e)
                    case .cellularStatus     (let d, let e): onCellularStatus?(d, e)
                    case .latencyStatus      (let d, let e): onLatencyStatus?(d, e)
                }
            } catch {
                DTLog("Failed to decode: \(String(describing: String(data: data, encoding: .utf8))). Error: \(error)", isError: true)
            }
        }
        
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?)
    {
        // Primitive error handling for now. Just logs the error,
        // and closes the connection.
        // TODO: Figure out an appropriate reconnect scheme
        
        let statusCode = (task.response as? HTTPURLResponse)?.statusCode
        let errorMessage = error?.localizedDescription ?? ""
        
        DTLog("The event stream closed with message: \"\(errorMessage)\". Status code: \(String(describing: statusCode))")
        
        if hasBeenClosed {
            DTLog("Not reconnecting to stream since it has been closed")
            return
        }
        
        let backoff = retryScheme.nextBackoff()
        DTLog("Reconnecting to the event stream in \(backoff)s...")
        DispatchQueue.global().asyncAfter(deadline: .now() + backoff) { [weak self] in
            self?.restartStream()
        }
    }
}
