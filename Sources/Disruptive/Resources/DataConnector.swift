//
//  DataConnector.swift
//  
//
//  Created by Vegard Solheim Theriault on 01/12/2020.
//

import Foundation

/**
 A Data Connector is a mechanism to send device events in real-time from Disruptive Technologies' backend
 to an external service. It can be set up to send specific types of events to a configurable endpoint through an
 HTTP POST request.
 
 Functions relevant for `DataConnector`s are implemented on the [`Disruptive`](https://vegather.github.io/Disruptive/Disruptive/) struct:
 
 * [`getDataConnectors`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getdataconnectors(projectid:completion:))
 * [`getDataConnectorsPage`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getdataconnectorspage(projectid:pagesize:pagetoken:completion:))
 * [`getDataConnector`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getdataconnector(projectid:dataconnectorid:completion:))
 * [`createDataConnector`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.createdataconnector(projectid:displayname:pushtype:eventtypes:labels:isactive:completion:))
 * [`updateDataConnector`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.updatedataconnector(projectid:dataconnectorid:displayname:httppush:isactive:eventtypes:labels:completion:))
 * [`deleteDataConnector`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.deletedataconnector(projectid:dataconnectorid:completion:))
 * [`getDataConnectorMetrics`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getdataconnectormetrics(projectid:dataconnectorid:completion:))
 * [`syncDataConnector`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.syncdataconnector(projectid:dataconnectorid:completion:))
 
 To learn more about Data Connectors, see the following article on the developer website:
 * [Data Connectors](https://developer.disruptive-technologies.com/docs/data-connectors/introduction-to-data-connector)
 */
public struct DataConnector: Decodable, Equatable {
    
    /// The unique identifier of the Data Connector. This will be different from the`name` field in the REST API
    /// in that it is just the identifier without the `projects/*/dataconnectors/` prefix.
    public let identifier: String
    
    /// The identifier of the project the Data Connector is in.
    public let projectID: String
    
    /// Describes the mechanism for how to push events to an external service, with
    /// configurable parameters. See more in the documentation for the type itself.
    public let pushType: PushType

    /// The display name of the Data Connector.
    public let displayName: String
    
    /// The current status of the Data Connector. This will indicate whether or
    /// not the Data Connector is currently sending out events.
    public let status: Status
    
    /// The event types that the Data Connector can send.
    public let events: [EventType]
    
    /// The labels that could be included along with an event (if the label is present
    /// on the device the event comes from).
    public let labels: [String]
    
}

extension Disruptive {
    
    /**
     Gets all the Data Connectors that are available in a specific project.
     
     This will handle pagination automatically and send multiple network requests in
     the background if necessary. If a lot of Data Connectors are expected to be in the project,
     it might be better to load pages of Data Connectors as they're needed using the
     `getDataConnectorsPage` function instead.
     
     - Parameter projectID: The identifier of the project to get Data Connectors from.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `DataConnector`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[DataConnector], DisruptiveError>`
     */
    public func getDataConnectors(
        projectID  : String,
        completion : @escaping (_ result: Result<[DataConnector], DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/dataconnectors"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request, pagingKey: "dataConnectors") { completion($0) }
    }
    
    /**
     Gets one page of Data Connectors.
     
     Useful if a lot of Data Connectors are expected in the specified project. This function
     provides better control for when to get Data Connectors and how many to get at a time so
     that Data Connectors are only fetch when they are needed. This can also improve performance,
     at a cost of convenience compared to the `getDataConnectors` function.
     
     - Parameter projectID: The identifier of the project to get Data Connectors from.
     - Parameter pageSize: The maximum number of Data Connectors to get for this page. The maximum page size is 100, which is also the default
     - Parameter pageToken: The token of the page to get. For the first page, set this to `nil`. For subsequent pages, use the `nextPageToken` received when getting the previous page.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain a tuple with both an array of `DataConnector`s, as well as the token for the next page. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<(nextPageToken: String?, dataConnectors: [DataConnector]), DisruptiveError>`
     */
    public func getDataConnectorsPage(
        projectID  : String,
        pageSize   : Int = 100,
        pageToken  : String?,
        completion : @escaping (_ result: Result<(nextPageToken: String?, dataConnectors: [DataConnector]), DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/dataconnectors"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request, pageSize: pageSize, pageToken: pageToken, pagingKey: "dataConnectors") { (result: Result<PagedResult<DataConnector>, DisruptiveError>) in
            switch result {
                case .success(let page) : completion(.success((nextPageToken: page.nextPageToken, dataConnectors: page.results)))
                case .failure(let err)  : completion(.failure(err))
            }
        }
    }
    
    /**
     Gets a specific Data Connector within a project by its identifier.
     
     - Parameter projectID: The identifier of the project to get the Data Connector from.
     - Parameter dataConnectorID: The identifier of the Data Connector to get within the specified project.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `DataConnector`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<DataConnector, DisruptiveError>`
     */
    public func getDataConnector(
        projectID       : String,
        dataConnectorID : String,
        completion      : @escaping (_ result: Result<DataConnector, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/dataconnectors/\(dataConnectorID)"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Creates a new Data Connector. See the [Data Connectors](https://developer.disruptive-technologies.com/docs/data-connectors/introduction-to-data-connector)
     guide on the developer website to learn more about how Data Connectors work, and how to
     set up an external service to receive the events that are sent out by a Data Connector.
     
     - Parameter projectID: The identifier of the project to create the Data Connector in.
     - Parameter displayName: The display name to give the Data Connector.
     - Parameter pushType: The mechanism to use to push events to an external service. This will also include the parameters to configure the push mechanism.
     - Parameter eventTypes: The event types that the Data Connector will send to the external service.
     - Parameter labels: The labels to be included along with the events. If a device that an event originates from has a label that is not included in this list, it will not be included in the event from the Data Connector. **Note** that if you want the display name of the device to be included in the events to the external service, you need to include the `name` label in this list. The default value of this parameter is an empty list, meaning no labels will be included.
     - Parameter isActive: Whether or not the Data Connector should start in the active state. This can be changed later by calling the `updateDataConnector` function.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `DataConnector` (along with its generated identifier). If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<DataConnector, DisruptiveError>`
     */
    public func createDataConnector(
        projectID     : String,
        displayName   : String,
        pushType      : DataConnector.PushType,
        eventTypes    : [EventType],
        labels        : [String] = [],
        isActive      : Bool = true,
        completion    : @escaping (_ result: Result<DataConnector, DisruptiveError>) -> ())
    {
        guard case let .httpPush(url, secret, headers) = pushType else {
            fatalError("PushType \(pushType) is currently not supported")
        }
        
        // Since the initial status can only be active or user disabled, the argument is
        // a Bool instead of a Status. This just converts that back to a Status.
        let initialStatus = isActive ? DataConnector.Status.active : .userDisabled
        
        struct DataConnectorPayload: Encodable {
            let displayName: String
            let events: [String]
            let labels: [String]
            let type: String
            let status: DataConnector.Status
            let httpConfig: HTTPConfig
            
            struct HTTPConfig: Encodable {
                let url: String
                let signatureSecret: String
                let headers: [String: String]
            }
        }
        let payload = DataConnectorPayload(
            displayName : displayName,
            events      : eventTypes.map { $0.rawValue },
            labels      : labels,
            type        : "HTTP_PUSH", // Update this if new push types are added
            status      : initialStatus,
            httpConfig  : DataConnectorPayload.HTTPConfig(
                url             : url,
                signatureSecret : secret,
                headers         : headers
            )
        )
        
        do {
            // Create the request
            let endpoint = "projects/\(projectID)/dataconnectors"
            let request = try Request(method: .post, baseURL: baseURL, endpoint: endpoint, body: payload)
            
            // Send the request
            sendRequest(request) { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to init create data connector request with payload \(payload). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? .unknownError))
        }
    }
    
    /**
     Updates the configuration of a Data Connector. Only the parameters that are set will be updated, and the remaining will be left unchanged.
     
     Examples:
     
     ```
     // Deactivates a Data Connector by only using the `active` parameter
     disruptive.updateDataConnector(
         projectID       : "<PROJECT_ID>",
         dataConnectorID : "<DC_ID>",
         active          : false)
     { result in
         ...
     }
  
     // Updates the signature secret of a Data Connector, and nothing else
     disruptive.updateDataConnector(
         projectID       : "<PROJECT_ID>",
         dataConnectorID : "<DC_ID>",
         httpPush        : (url: nil, signatureSecret: "NEW_SECRET", headers: nil))
     { result in
         ...
     }
     ```
     
     - Parameter projectID: The identifier of the project the Data Connector to update is in.
     - Parameter dataConnectorID: The identifier of the Data Connector to update.
     - Parameter displayName: The new display name to use for the Data Connector. Will be ignored if not set (or `nil`). Defaults to `nil`.
     - Parameter httpPush: The new configuration of the `httpPush` `pushType`. Only the non-`nil` tuple values will actually be set. Will be ignored the whole `httpPush` argument is not set (or `nil`). Defaults to `nil`.
     - Parameter isActive: The new active status of the Data Connector. Will be ignored if not set (or `nil`). Defaults to `nil`.
     - Parameter eventTypes: The new list of event types the Data Connector will send out. Will be ignored if not set (or `nil`). Defaults to `nil`.
     - Parameter labels: The new labels that will be included for every event pushed to an external service by the Data Connector. Will be ignored if not set (or `nil`). **Note:** if you want the display name of the device to be included in the events to the external service, you need to include the `name` label in this list. The default value of this parameter is `nil`.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the updated `DataConnector`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<DataConnector, DisruptiveError>`
     */
    public func updateDataConnector(
        projectID       : String,
        dataConnectorID : String,
        displayName     : String? = nil,
        httpPush        : (url: String?, signatureSecret: String?, headers: [String: String]?)? = nil,
        isActive        : Bool? = nil,
        eventTypes      : [EventType]? = nil,
        labels          : [String]? = nil,
        completion      : @escaping (_ result: Result<DataConnector, DisruptiveError>) -> ())
    {
        struct DataConnectorPatch: Encodable {
            var displayName: String?
            var status: String?
            var events: [String]?
            var labels: [String]?
            var httpConfig: HTTPConfig?
            
            struct HTTPConfig: Encodable {
                var url: String?
                var signatureSecret: String?
                var headers: [String: String]?
            }
        }
        
        // Prepare the payload
        var patch = DataConnectorPatch()
        var updateMask = [String]()
        
        if let displayName = displayName {
            patch.displayName = displayName
            updateMask.append("displayName")
        }
        if let httpPush = httpPush {
            var httpConfig = DataConnectorPatch.HTTPConfig()

            if let url = httpPush.url {
                httpConfig.url = url
                updateMask.append("httpConfig.url")
            }
            if let secret = httpPush.signatureSecret {
                httpConfig.signatureSecret = secret
                updateMask.append("httpConfig.signatureSecret")
            }
            if let headers = httpPush.headers {
                httpConfig.headers = headers
                updateMask.append("httpConfig.headers")
            }
            
            patch.httpConfig = httpConfig
        }
        if let isActive = isActive {
            patch.status = (isActive ? DataConnector.Status.active : .userDisabled).rawValue
            updateMask.append("status")
        }
        if let eventTypes = eventTypes {
            patch.events = eventTypes.map { $0.rawValue }
            updateMask.append("events")
        }
        if let labels = labels {
            patch.labels = labels
            updateMask.append("labels")
        }
        
        do {
            // Create the request
            let endpoint = "projects/\(projectID)/dataconnectors/\(dataConnectorID)"
            let params = ["update_mask": [updateMask.joined(separator: ",")]]
            let request = try Request(method: .patch, baseURL: baseURL, endpoint: endpoint, params: params, body: patch)
            
            // Send the request
            sendRequest(request) { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to init updateDataConnector request with payload: \(patch). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? .unknownError))
        }
    }
    
    /**
     Deletes a Data Connector.
     
     - Parameter projectID: The identifier of the project to delete the Data Connector from.
     - Parameter dataConnectorID: The identifier of the Data Connector to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func deleteDataConnector(
        projectID       : String,
        dataConnectorID : String,
        completion      : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/dataconnectors/\(dataConnectorID)"
        let request = Request(method: .delete, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Retrieves the metrics for the past 3 hours for a Data Connector.
     
     - Parameter projectID: The identifier of the project to delete the Data Connector from.
     - Parameter dataConnectorID: The identifier of the Data Connector to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `DataConnector.Metrics`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<DataConnector.Metrics, DisruptiveError>`
     */
    public func getDataConnectorMetrics(
        projectID       : String,
        dataConnectorID : String,
        completion      : @escaping (_ result: Result<DataConnector.Metrics, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/dataconnectors/\(dataConnectorID):metrics"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Synchronizes a Data Connector with the external service. When this is called, the last known event for each event type of every device in the project will be re-pushed to the external service.
     
     - Parameter projectID: The identifier of the project the Data Connector to synchronize is in.
     - Parameter dataConnectorID: The identifier of the Data Connector to synchronize.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func syncDataConnector(
        projectID       : String,
        dataConnectorID : String,
        completion      : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/dataconnectors/\(dataConnectorID):sync"
        let request = Request(method: .post, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
}

extension DataConnector {
    
    /// Represents the metrics such as success-rate and latency for the past 3 hours of a Data Connector.
    public struct Metrics: Decodable, Equatable {
        
        /// How many events have been successfully pushed for the Data Connector in the past 3 hours.
        let successCount: Int
        
        /// How many events have failed to push for the Data Connector in the past 3 hours.
        let errorCount: Int
        
        /// The latency (in number of seconds) of the fastest 99% of pushes in the past 3 hours for the Data Connector.
        let latency99p: TimeInterval
        
        private enum OuterCodingKeys: String, CodingKey {
            case metrics
        }

        private enum InnerCodingKeys: String, CodingKey {
            case successCount
            case errorCount
            case latency99p
        }
        
        public init(from decoder: Decoder) throws {
            let outer = try decoder.container(keyedBy: OuterCodingKeys.self)
            let inner = try outer.nestedContainer(keyedBy: InnerCodingKeys.self, forKey: .metrics)
            
            self.successCount = try inner.decode(Int.self, forKey: .successCount)
            self.errorCount   = try inner.decode(Int.self, forKey: .errorCount)
            
            let latencyString = try inner.decode(String.self, forKey: .latency99p)
            guard latencyString.hasSuffix("s"), let latency = TimeInterval(latencyString.dropLast()) else {
                throw ParseError.durationFormat(format: latencyString)
            }
            self.latency99p = latency
        }
    }
    
    /// The current status of a Data Connector. This will indicate whether or
    /// not the Data Connector is currently sending out events.
    public enum Status: Codable, Equatable {
        
        /// The Data Connector is currently active, and will push out events for the devices in the project
        /// to an external service.
        case active
        
        /// The Data Connector is deactivated. It can be reactivated by calling the `updateDataConnector` function.
        case userDisabled
        
        /// The Data Connector will be set to this state by the system if it has received
        /// too many errors recently, or if it keeps seeing errors for a prolonged period of time.
        /// It can be reactivated by calling the `updateDataConnector` function.
        case systemDisabled
        
        /// The status received for the Data Connector was unknown.
        /// Added for backwards compatibility in case a new status
        /// is added on the backend, and not yet added to this client library.
        case unknown(value: String)
        
        
        // Used for testing, and internally for creating requests
        internal var rawValue: String? {
            switch self {
                case .active         : return "ACTIVE"
                case .userDisabled   : return "USER_DISABLED"
                case .systemDisabled : return "SYSTEM_DISABLED"
                case .unknown        : return nil
            }
        }
        
        public init(from decoder: Decoder) throws {
            let container    = try decoder.singleValueContainer()
            let statusString = try container.decode(String.self)
            
            switch statusString {
                case "ACTIVE"          : self = .active
                case "USER_DISABLED"   : self = .userDisabled
                case "SYSTEM_DISABLED" : self = .systemDisabled
                default                : self = .unknown(value: statusString)
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            if let rawValue = rawValue {
                var container = encoder.singleValueContainer()
                try container.encode(rawValue)
            } else {
                Disruptive.log("Can't encode DataConnector.Status with case .unknown", level: .error)
                throw DisruptiveError.badRequest
            }
        }
    }
    
    /// The mechanism used by a Data Connector to push device events to an external service.
    public enum PushType: Equatable {
        /**
         This mechanism pushes device events to an external service using an HTTP POST request, and is
         effectively a webhook.
         
         An HTTP push Data Connector allows you to specify a signature secret that will be used to sign
         each every event sent from the Data Connector. The signature will be included as a JWT in a header.
         Read more about it in the [Signing events section](https://developer.disruptive-technologies.com/docs/data-connectors/advanced-configurations#signing-events)
         of the Data Connectors article on the developer website.
         
         Parameters:
         
         * `url`: The URL of the external service that the HTTP POST requests will be pushed to.
         * `signatureSecret`: Used to sign each event pushed from the Data Connector. See details above.
         * `headers`: Any additional headers that should be included with every event pushed from the Data Connector.
         */
        case httpPush(url: String, signatureSecret: String, headers: [String: String])
        
        /// The push type received for the Data Connector was unknown.
        /// Added for backwards compatibility in case a new push type
        /// is added on the backend, and not yet added to this client library.
        case unknown(value: String)
    }
    
    
    private enum CodingKeys: String, CodingKey {
        case resourceName = "name"
        case type
        case displayName
        case status
        case events
        case labels
        case httpConfig
    }
    
    private enum HTTPConfigCodingKeys: String, CodingKey {
        case url
        case signatureSecret
        case headers
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        
        // Data Connector resource names are formatted as "projects/b7s3umd0fee000ba5di0/dataconnectors/b5rj9ed7rihk942p48og"
        // Setting the identifier to the last component of the resource name
        let dcResourceName = try values.decode(String.self, forKey: .resourceName)
        let resourceNameComponents = dcResourceName.components(separatedBy: "/")
        guard resourceNameComponents.count == 4 else {
            throw ParseError.identifier(path: dcResourceName)
        }
        self.projectID  = resourceNameComponents[1]
        self.identifier = resourceNameComponents[3]
        
        
        // Extract the push type of the data connector. This will be a nested object that
        // is present or not based on the value of the "type" field (a string). At the time
        // of this writing, only "HTTP_PUSH" exists (along with the `.httpConfig` coding key),
        // but more could be added in the future (at which point different nested objects
        // will be present).
        let typeString = try values.decode(String.self, forKey: .type)
        switch typeString {
            case "HTTP_PUSH":
                let httpConfig = try values.nestedContainer(keyedBy: HTTPConfigCodingKeys.self, forKey: .httpConfig)
                
                self.pushType = .httpPush(
                    url             : try httpConfig.decode(String.self, forKey: .url),
                    signatureSecret : try httpConfig.decode(String.self, forKey: .signatureSecret),
                    headers         : try httpConfig.decode([String: String].self, forKey: .headers)
                )
            default:
                self.pushType = .unknown(value: typeString)
        }
        
        // Only include the known event types
        let eventStrings = try values.decode([String].self, forKey: .events)
        self.events = eventStrings.compactMap { EventType(rawValue: $0) }
        
        // Getting the other properties without any modifications
        self.displayName = try values.decode(String.self, forKey: .displayName)
        self.status      = try values.decode(Status.self, forKey: .status)
        self.labels      = try values.decode([String].self, forKey: .labels)
    }

}
