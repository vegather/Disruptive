//
//  DeviceEventStream.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation


/**
 Represent an event stream for a device
 
 Has callbacks that can be set for each type of event. Note that which event type is available for a device depends on the device type.
 
 Example:
 ```
 let stream = Device.subscribeToDevices(
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
    
    /// Called with the device identifier and the event when a new `LabelsChangedEvent` is received
    public var onLabelsChanged      : ((DeviceID, LabelsChangedEvent) -> ())?
    
    
    
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
    
    /// Called when an error was received on the stream. The connection to the stream will automatically
    /// be re-established.
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
            "Accept"        : "application/json",
            "Cache-Control" : "no-cache"
        ]
        config.httpAdditionalHeaders = headers
        
        return config
    }()
    
    private var session: URLSession!
    private var task: URLSessionTask?
    private let request: Request
    private let authenticator: Authenticator?
    
    private var retryScheme = RetryScheme()
    
    private var hasBeenClosed = false
    
    
    
    // Preventing init without parameters
    private override init() { fatalError() }
    
    internal init(request: Request, authenticator: Authenticator?) {
        self.request = request
        self.authenticator = authenticator
        
        super.init()
        
        setupSession()
        
        // Starting the stream in the next runloop cycle in case no authenticator
        // has been, and we want to call `onError?()` immediately.
        Task {
            await restartStream()
        }
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
    
    private func restartStream() async {
        guard hasBeenClosed == false else { return }
        guard let auth = authenticator else {
            let error = DisruptiveError(
                type: .loggedOut,
                message: "Not authenticated",
                helpLink: nil
            )
            Logger.error("No authentication has been set. Set it with `Disruptive.authenticator = ...`")
            onError?(error)
            return
        }
        
        // Add the "Authorization" header to the Request
        var req = self.request
        do {
            let token = try await auth.getActiveAccessToken()
            req.setHeader(field: "Authorization", value: token)
        } catch {
            Logger.error("Failed to authenticate the DeviceEventStream stream. Error: \(error)")
            self.onError?((error as? DisruptiveError) ?? DisruptiveError(type: .unknownError, message: "", helpLink: nil))
            return
        }
        
        // Convert to URLRequest
        guard let urlRequest = req.urlRequest() else {
            let error = DisruptiveError(
                type: .unknownError,
                message: "Unknown error",
                helpLink: nil
            )
            Logger.error("Failed to create URLRequest to restart the DeviceEventStream stream")
            self.onError?(error)
            return
        }
        
        // Send the request (connect to stream)
        self.task = self.session.dataTask(with: urlRequest)
        self.task?.resume()
    }
}

extension DeviceEventStream: URLSessionDataDelegate {
    // Packet format for payloads from the ServerSentEvent
    private struct StreamResult: Decodable {
        let result: Event
        
        struct Event: Decodable {
            let event: EventContainer
        }
    }
    
    private struct StreamError: Decodable {
        let error: Error
        
        struct Error: Decodable {
            let code: Int
            let message: String
            let details: [[String: String]]
            
            func toError() -> DisruptiveError? {
                // Checking both HTTP codes and gRPC codes
                switch code {
                    case 3, 9, 11, 400:  return DisruptiveError(type: .badRequest,              message: message, helpLink: nil)
                    case 16, 401:        return DisruptiveError(type: .unauthorized,            message: message, helpLink: nil)
                    case 7, 403:         return DisruptiveError(type: .insufficientPermissions, message: message, helpLink: nil)
                    case 5, 404:         return DisruptiveError(type: .notFound,                message: message, helpLink: nil)
                    case 2, 13, 15, 500: return DisruptiveError(type: .serverError,             message: message, helpLink: nil)
                    case 14, 503:        return DisruptiveError(type: .serverError,             message: message, helpLink: nil)
                    case 1,4, 504:       return nil // The stream session timed out, and will be restarted. Not considered an error
                    default :            return DisruptiveError(type: .unknownError,            message: message, helpLink: nil)
                }
            }
        }
    }
    
    // Reads out the device ID and the event of each stream packet,
    // and calling the appropriate callback closure
    private func handleResult(with payload: StreamResult) {
        
        switch payload.result.event {
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
            case .labelsChanged      (let d, let e): onLabelsChanged?(d, e)
                
            // Cloud connector
            case .connectionStatus   (let d, let e): onConnectionStatus?(d, e)
            case .ethernetStatus     (let d, let e): onEthernetStatus?(d, e)
            case .cellularStatus     (let d, let e): onCellularStatus?(d, e)
                
            case .unknown(let eventType): Logger.warning("Unknown event type: \(eventType)")
        }
    }
    
    private func handleError(with payload: StreamError) {
        guard let dtErr = payload.error.toError() else { return }
        
        var helpStr = ""
        if let help = payload.error.details.first?["help"] {
            helpStr = ". Help URL: \(help)"
        }
        
        Logger.warning("Got an error from the stream. Message: \"\(payload.error.message)\". Error: \(dtErr)\(helpStr)")
        onError?(dtErr)
    }
    
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data)
    {
        // We might receive multiple messages per payload, so the data needs to be split
        // on linebreak (0x0A)
        data.split(separator: 0x0A).forEach { message in
            if let result = try? JSONDecoder().decode(StreamResult.self, from: message) {
                // We got a result, so reset the retry scheme
                retryScheme.reset()
                
                handleResult(with: result)
            } else if let error = try? JSONDecoder().decode(StreamError.self, from: message) {
                handleError(with: error)
            } else {
                Logger.error("Failed to decode stream data: \(String(data: message, encoding: .utf8) as Any)")
            }
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?)
    {
        if hasBeenClosed {
            Logger.info("Stream closed")
            return
        }
        
        // Log the error, if present
        if let error = error {
            var statusCodeStr = ""
            if let statusCode = (task.response as? HTTPURLResponse)?.statusCode {
                statusCodeStr = ". Status code: \(String(describing: statusCode))"
            }
            
            let err = DisruptiveError(
                type: .serverUnavailable,
                message: "Stream error",
                helpLink: nil
            )
            Logger.error("The event stream closed with message: \"\(error.localizedDescription)\"\(statusCodeStr)")
            onError?(err)
        }
        
        let backoff = retryScheme.nextBackoff()
        Logger.info("Disconnected from event stream. Reconnecting in \(backoff)s...")
        
        // Restart the stream after a backoff
        Task {
            try await Task.sleep(nanoseconds: UInt64(backoff) * 1_000_000_000)
            await restartStream()
        }
    }
}
