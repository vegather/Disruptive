//
//  DeviceEventStream.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation


/**
 Represent an event stream for a device, and is implemented using [Server-Sent Events](https://html.spec.whatwg.org/multipage/server-sent-events.html).
 
 Has callbacks that can be set for each type of event. Note that which event type is available for a device depends on the device type.
 
 Example:
 ```
 let stream = disruptive.subscribeToDevices(
    projectID: "<PROJECT_ID>"
 )
 stream?.onTemperature = { deviceID, temperatureEvent in
    print("Got temperature \(temperatureEvent) for device with id \(deviceID)")
 }
 ```
 */
public class DeviceEventStream: NSObject {
    
    /// Used to specify that the `String` argument in the callbacks is the identifier of a device
    public typealias DeviceID = String
    
    
    // Sensor data callbacks
    // -------------------------
    
    /// Called with the device identifier and the event when a new `TouchEvent` is received
    public var onTouch              : ((DeviceID, TouchEvent) -> ())?
    
    /// Called with the device identifier and the event when a new `TemperatureEvent` is received
    public var onTemperature        : ((DeviceID, TemperatureEvent) -> ())?
    
    /// Called with the device identifier and the event when a new `ObjectPresentEvent` is received
    public var onObjectPresent      : ((DeviceID, ObjectPresentEvent) -> ())?
    
    /// Called with the device identifier and the event when a new `HumidityEvent` is received
    public var onHumidity           : ((DeviceID, HumidityEvent) -> ())?
    
    /// Called with the device identifier and the event when a new `ObjectPresentCountEvent` is received
    public var onObjectPresentCount : ((DeviceID, ObjectPresentCountEvent) -> ())?
    
    /// Called with the device identifier and the event when a new `TouchCountEvent` is received
    public var onTouchCount         : ((DeviceID, TouchCountEvent) -> ())?
    
    /// Called with the device identifier and the event when a new `WaterPresentEvent` is received
    public var onWaterPresent       : ((DeviceID, WaterPresentEvent) -> ())?
    
    
    
    // Sensor status callbacks
    // -------------------------
    
    /// Called with the device identifier and the event when a new `NetworkStatusEvent` is received
    public var onNetworkStatus      : ((DeviceID, NetworkStatusEvent) -> ())?
    
    /// Called with the device identifier and the event when a new `BatteryStatusEvent` is received
    public var onBatteryStatus      : ((DeviceID, BatteryStatusEvent) -> ())?
    
//    public var onLabelsChanged      : ((DeviceID, LabelsChanged) -> ())?
    
    
    
    // Cloud connector callbacks
    // -------------------------
    
    /// Called with the device identifier and the event when a new `ConnectionStatusEvent` is received
    public var onConnectionStatus   : ((DeviceID, ConnectionStatusEvent) -> ())?
    
    /// Called with the device identifier and the event when a new `EthernetStatusEvent` is received
    public var onEthernetStatus     : ((DeviceID, EthernetStatusEvent) -> ())?
    
    /// Called with the device identifier and the event when a new `CellularStatusEvent` is received
    public var onCellularStatus     : ((DeviceID, CellularStatusEvent) -> ())?
    
    
    
    // Error
    // -------------------------
    
    /// Called with an error if the device stream couldn't open
    public var onError: ((DisruptiveError)-> ())?

    
    
    
    internal static var sseConfig: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        
        // Setting the timeout to `.greatestFiniteMagnitude` caused unexpected
        // "The request timed out." errors. Seems like any value above 9223372037
        // will cause that error. Setting the timeout to 3600 (1 hour) which means
        // if we don't receive a single byte within an hour, the connection will
        // be dropped and a new connection will be set up by the retry scheme mechanism.
        config.timeoutIntervalForRequest  = 3600
        config.timeoutIntervalForResource = 3600
        
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
    
    
    
    // Preventing init without parameters
    private override init() { fatalError() }
    
    internal init(request: Request, authProvider: AuthProvider) {
        self.request = request
        self.authProvider = authProvider
        
        super.init()
        
        setupSession()
        restartStream()
    }
    
    /**
     Closes the open connection to the device stream. If the stream had already been closed, nothing will happen. Once a stream has been closed, it can not be re-opened. Create a new stream instead.
     */
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
            configuration: DeviceEventStream.sseConfig,
            delegate: self,
            delegateQueue: .main
        )
    }
    
    private func restartStream() {
        guard hasBeenClosed == false else { return }
        
        authProvider.getActiveAccessToken { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let token):
                
                // Add the "Authorization" header to the Request
                var req = self.request
                req.setHeader(field: "Authorization", value: token)
                
                // Convert to URLRequest
                guard let urlRequest = req.urlRequest() else {
                    Disruptive.log("Failed to create URLRequest to restart the ServerSentEvents stream", level: .error)
                    self.onError?(.unknownError)
                    return
                }
                
                // Send the request (connect to stream)
                self.task = self.session.dataTask(with: urlRequest)
                self.task?.resume()
            case .failure(let e):
                Disruptive.log("Failed to authenticate the ServerSentEvents stream. Error: \(e)", level: .error)
                self.onError?(e)
            }
        }
    }
}

extension DeviceEventStream: URLSessionDataDelegate {
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
        guard let response = dataTask.response as? HTTPURLResponse,
              let contentType = response.allHeaderFields["Content-Type"] as? String,
              contentType == "text/event-stream",
              response.statusCode == 200
        else {
            Disruptive.log("Unexpected response: \(String(describing: dataTask.response))", level: .error)
            return
        }
        
        // We got data, so reset the retry scheme
        retryScheme.reset()
                
        guard let payloadStr = String(data: data, encoding: .utf8) else {
            return
        }
                
        // Decoding using scheme from:
        // https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
        // Assumes all fields will be "data", and ignores event IDs. Only supports
        // one event per block (data buffer), An event can be spread across
        // multiple data fields, as long as it's all within the same block.
        var dataBuffer = ""
        for line in payloadStr.components(separatedBy: "\n") {
            if line.count == 0 {
                if dataBuffer.count > 0 {
                    // Dispatching the data buffer
                    handleNewDataBuffer(dataBuffer)
                    dataBuffer = ""
                }
                continue
            }
            if line.hasPrefix(":") {
                continue // Comment
            }
            if line.contains(":") == false {
                // Ignoring lines that doesn't contain ":", even though it's
                // allowed by the spec.
                continue
            }
            let field = line.components(separatedBy: ":")[0]
            let value = line.dropFirst((field+":").count).trimmingCharacters(in: .whitespaces)
            
            // Only handling "data" fields
            guard field == "data" else {
                Disruptive.log("Not handling unexpected field: \(field)", level: .warning)
                continue
            }
            
            dataBuffer += value
        }
    }
    
    private func handleNewDataBuffer(_ dataBuffer: String) {
        guard dataBuffer.count > 0, let data = dataBuffer.data(using: .utf8) else {
            Disruptive.log("Couldn't convert: \"\(dataBuffer)\" to Data", level: .warning)
            return
        }
        do {
            let streamPacket = try JSONDecoder().decode(StreamPacket.self, from: data)
            
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
                    
                case .unknown(let eventType): Disruptive.log("Unknown event type: \(eventType)", level: .warning)
            }
        } catch {
            Disruptive.log("Failed to decode: \(dataBuffer). Error: \(error)", level: .error)
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?)
    {
        let statusCode = (task.response as? HTTPURLResponse)?.statusCode
        let errorMessage = error?.localizedDescription ?? ""
        
        if hasBeenClosed {
            Disruptive.log("Stream closed")
            return
        }
        
        Disruptive.log("The event stream closed with message: \"\(errorMessage)\". Status code: \(String(describing: statusCode))", level: .warning)
        
        let backoff = retryScheme.nextBackoff()
        Disruptive.log("Reconnecting to the event stream in \(backoff)s...")
        DispatchQueue.global().asyncAfter(deadline: .now() + backoff) { [weak self] in
            self?.restartStream()
        }
    }
}
