//
//  Requests.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

internal struct Request {
    let method: HTTPMethod
    let baseURL: String
    let endpoint: String
    private(set) var headers: [HTTPHeader]
    var params: [String: [String]]
    let body: Data?
    
    init(
        method: HTTPMethod,
        baseURL: String,
        endpoint: String,
        headers: [HTTPHeader] = [],
        params: [String: [String]] = [:])
    {
        self.method = method
        self.baseURL = baseURL
        self.endpoint = endpoint
        self.headers = headers
        self.params = params
        self.body = nil
    }
    
    init<Body: Encodable>(
        method: HTTPMethod,
        baseURL: String,
        endpoint: String,
        headers: [HTTPHeader] = [],
        params: [String: [String]] = [:],
        body: Body) throws
    {
        self.headers = headers
        
        // If the body is already of type `Data`, just set it directly.
        // Otherwise, JSON encode it.
        if let body = body as? Data {
            self.body = body
        } else {
            self.body = try JSONEncoder().encode(body)
            self.headers.append(HTTPHeader(field: "Content-Type", value: "application/json"))
        }
        
        self.baseURL = baseURL
        self.method = method
        self.endpoint = endpoint
        self.params = params
    }
    
    /// Overrides an existing header if it already exists, otherwise creates a new header
    mutating func setHeader(field: String, value: String) {
        let newHeader = HTTPHeader(field: field, value: value)
        
        // Update the existing header if it already exists
        for (index, header) in headers.enumerated() {
            if header.field == field {
                headers[index] = newHeader
                return
            }
        }
        
        // Create a new header
        headers.append(newHeader)
    }
    
    /**
     Creates a `URLRequest` object from the `Request` properties. Sets the HTTP method,
     query parameters, headers, and body of the `URLRequest`.
     */
    func urlRequest() -> URLRequest? {
        
        // Construct the URL
        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            return nil
        }
        if params.count > 0 {
            urlComponents.queryItems = params.flatMap { paramName, paramValues in
                return paramValues.map { URLQueryItem(name: paramName, value: $0) }
            }
        }
        guard let url = urlComponents.url(relativeTo: nil) else {
            return nil
        }
        
        // Create the request
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.httpBody = body
        
        // Add the headers
        headers.forEach { req.addValue($0.value, forHTTPHeaderField: $0.field) }

        return req
    }
}

extension Request {
    /// Creates a URL session with a 20 second timeout
    static var defaultSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 20
        config.timeoutIntervalForResource = 20
        
        return URLSession(configuration: config)
    }()
    
    
    // -------------------------------
    // MARK: Sending Requests
    // -------------------------------
    
    /// Use this instead of `Void` as a generic parameter (the `T`) for the `send` function since `Void` cannot be `Decodable`.
    internal struct EmptyResponse: Decodable {}
    
    /**
     Sends the request to the Disruptive backend. This function does not handle authentications, so it's expected
     that the `Authorization` header is already populated (if necessary). If a "429 Too Many Requests" error is
     received, the request will be re-sent after waiting the appropriate amount of time. If an empty response is expected
     (eg. `Void`), use the `EmptyResponse` type as the generic success type, and just replace it with `Void` if the
     request was successful.
     
     - Parameter decoder: If some custom decoding is required (eg. pagination), this default decoder can be replaced with a custom one
     */
    internal func send<T: Decodable>(decoder: JSONDecoder = JSONDecoder(), completion: @escaping (Result<T, DisruptiveError>) -> ()) {
        
        guard let urlReq = urlRequest() else {
            DTLog("Failed to create URLRequest from request: \(self)", isError: true)
            DispatchQueue.main.async {
                completion(.failure(.unknownError))
            }
            return
        }
        
        var diagnostics = RequestDiagnostics(request: self)
        diagnostics.setNetworkStart()
        
        let task = Request.defaultSession.dataTask(with: urlReq) { data, response, error in
            diagnostics.setNetworkEnd()
            
            let urlString = urlReq.url!.absoluteString
            
            // Check the response for any errors
            if let internalError = Request.checkResponseForErrors(
                forRequestURL: urlString,
                response: response,
                error: error)
            {
                // If this error can be converted to a disruptive error
                if let dtErr = internalError.disruptiveError() {
                    DTLog("Request to \(urlString) resulted in error: \(dtErr)")
                    DispatchQueue.main.async {
                        completion(.failure(dtErr))
                    }
                    return
                }
                
                // Check if we've been rate limited
                if case .tooManyRequests(let retryAfter) = internalError {
                    DTLog("Request got rate limited, waiting \(retryAfter) seconds before retrying")
                    
                    // Dispatch the same request again after waiting
                    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(retryAfter)) {
                        self.send(decoder: decoder, completion: completion)
                    }
                    
                    return
                }
                
                // Unhandled error
                DTLog("The internal error \(internalError) was not handled for \(urlString)")
                DispatchQueue.main.async {
                    completion(.failure(.unknownError))
                }
                return
            }
            
            // If the caller has requested a success type of `EmptyResponse`, just response
            // with an `EmptyResponse` value without doing any parsing of the received payload.
            // This is done instead of responding with `Void` because `Void` does not conform
            // to the `Decodable` protocol
            if T.self == EmptyResponse.self {
                diagnostics.logDiagnostics(responseData: nil)
                DispatchQueue.main.async {
                    completion(.success(EmptyResponse() as! T))
                }
                return
            }
            
            diagnostics.setParseStart()
            
            // Parse the returned data
            guard let result: T = Request.parsePayload(data, decoder: decoder) else {
                DispatchQueue.main.async {
                    DTLog("Failed to parse the response JSON from \(urlString)")
                    completion(.failure(.unknownError))
                }
                return
            }
            
            diagnostics.setParseEnd()
            diagnostics.logDiagnostics(responseData: data)
            
            DispatchQueue.main.async {
                completion(.success(result))
            }
        }
        task.resume()
    }
    
    
    
    // -------------------------------
    // MARK: Error Checking
    // -------------------------------
    
    private static func checkResponseForErrors(
        forRequestURL url: String,
        response: URLResponse?,
        error: Error?)
    -> InternalError?
    {
        // Check if there is an error (server probably not accessible)
        if let error = error {
            DTLog("Request: \(url) resulted in error: \(error) (code: \(String(describing: (error as? URLError)?.code))), response: \(String(describing: response))", isError: true)
            return .serverUnavailable
        }
        
        // Cast response to HTTPURLResponse
        guard let httpResponse = response as? HTTPURLResponse else {
            DTLog("Request: \(url) resulted in HTTP Error: \(String(describing: error))", isError: true)
            return .unknownError
        }
        
        // Check if the status code is outside the 2XX range
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            DTLog("Request: \(url) resulted in status code: \(httpResponse.statusCode)", isError: true)
            
            switch httpResponse.statusCode {
            case 400: return .badRequest
            case 401: return .unauthorized
            case 403: return .forbidden
            case 404: return .notFound
            case 409: return .conflict
            case 500: return .internalServerError
            case 501: return .serviceUnavailale
            case 503: return .gatewayTimeout
            case 429:
                // Read "Retry-After" header for how long we need to wait
                // Default to 5 seconds if not present
                let retryAfterStr = httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "5"
                let retryAfter = Int(retryAfterStr) ?? 5
                return .tooManyRequests(retryAfter: retryAfter)
            default:
                DTLog("Unexpected status code: \(httpResponse.statusCode)", isError: true)
                return .unknownError
            }
        }
        
        return nil
    }
    
    
    // -------------------------------
    // MARK: Parsing Payload
    // -------------------------------
    
    private static func parsePayload<T: Decodable>(_ payload: Data?, decoder: JSONDecoder) -> T? {
        // Unwrap payload
        guard let payload = payload else {
            DTLog("Didn't get a body in the response as expected", isError: true)
            return nil
        }
        
        // Decode the payload
        do {
            return try decoder.decode(T.self, from: payload)
        } catch {
            // Failed to decode payload
            if let str = String(data: payload, encoding: .utf8) {
                DTLog("Failed to parse JSON: \(str)", isError: true)
                DTLog("Error: \(error)", isError: true)
            } else {
                DTLog("Failed to parse payload data: \(payload)", isError: true)
            }
            
            return nil
        }
    }
    
}



// -------------------------------
// MARK: Disruptive Extension (Send Requests)
//
// Adds three convenience functions to `Disruptive` to both ensure that
// the request gets authenticated before being sent, as well as properly
// handling the three types of requests: no response payload, single response
// payload, and paginated response payload.
// -------------------------------

extension Disruptive {
    
    /// If the auth provider is already authenticated, and the expiration date is far enough
    /// away, this will succeed with the `Authorization` header set to the auth token.
    /// If the auth provider is not authenticated,
    private func authenticateRequest(
        _ request: Request,
        completion: @escaping (Result<Request, DisruptiveError>) -> ())
    {
        authProvider.getActiveAccessToken { result in
            switch result {
            case .success(let token):
                var req = request
                req.setHeader(field: "Authorization", value: token)
                completion(.success(req))
            case .failure(let e):
                completion(.failure(e))
            }
        }
    }
    
    /// Makes sure the `authProvider` is authenticated, and adds the `Authorization` header to
    /// the request before sending it. This will not return anything if successful, but it will return a
    /// `DisruptiveError` on failure.
    internal func sendRequest(
        _ request: Request,
        completion: @escaping (Result<Void, DisruptiveError>) -> ())
    {
        // Create a new request with a non-expired access token
        // in the `Authorization` header.
        authenticateRequest(request) { authResult in
            switch authResult {
            case .success(let req):
                // Send the request to the Disruptive endpoint
                // Switch out the `EmptyResponse` payload with `Void` (aka "()")
                req.send { (response: Result<Request.EmptyResponse, DisruptiveError>) in
                    switch response {
                    case .success: completion(.success(()))
                    case .failure(let err): completion(.failure(err))
                    }
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    /// Makes sure the `authProvider` is authenticated, and adds the `Authorization` header to
    /// the request before sending it. This will return a single value if successful, and a
    /// `DisruptiveError` on failure.
    internal func sendRequest<T: Decodable>(
        _ request: Request,
        completion: @escaping (Result<T, DisruptiveError>) -> ())
    {
        // Create a new request with a non-expired access token
        // in the `Authorization` header.
        authenticateRequest(request) { authResult in
            switch authResult {
            case .success(let req):
                // Send the request to the Disruptive endpoint
                req.send { completion($0) }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    /// Makes sure the `authProvider` is authenticated, and adds the `Authorization` header to
    /// the request before sending it. This expects a list of paginated items to be returned, and fetches
    /// all the available pages before returning.
    internal func sendRequest<T: Decodable>(
        _ request: Request,
        pageingKey: String,
        completion: @escaping (Result<[T], DisruptiveError>) -> ())
    {
        // Prepare a decoder for decoding paginated results
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .custom { keys in
            if keys.last!.stringValue == pageingKey {
                return PagedKey(stringValue: "results")!
            } else {
                return keys.last!
            }
        }
        
        // Recursive function to fetch all the pages as long as `nextPageToken` is set.
        // The structure of this is a bit unfortunate due to having multiple nested
        // function calls that takes a completion closure. This can be improved once
        // Swift gains support for async/await.
        // More details here: https://gist.github.com/lattner/429b9070918248274f25b714dcfc7619
        func fetchPages(
            request: Request,
            cumulativeResults: [T],
            pageingKey: String,
            completion: @escaping (Result<[T], DisruptiveError>) -> ())
        {
            // Create a new request with a non-expired access token
            // in the `Authorization` header.
            authenticateRequest(request) { authResult in
                switch authResult {
                case .success(let req):
                    // We now have an authenticated request to fetch the next page
                    req.send(decoder: decoder) { (result: Result<PagedResult<T>, DisruptiveError>) in
                        switch result {
                        case .success(let pagedResult):
                            
                            // Create a new array of all the items received so far
                            let updatedResultsArray = cumulativeResults + pagedResult.results
                            
                            // Check if there are any more pages
                            if pagedResult.nextPageToken.count == 0 {
                                // This was the last page
                                DispatchQueue.main.async {
                                    completion(.success(updatedResultsArray))
                                }
                            } else {
                                // This was not the last page, send request for the next page
                                var nextRequest = req
                                nextRequest.params["pageToken"] = [pagedResult.nextPageToken]
                                
                                DTLog("Still more pages to load for \(String(describing: nextRequest.urlRequest()?.url))")
                                
                                // Fetch the next page
                                fetchPages(
                                    request           : nextRequest,
                                    cumulativeResults : updatedResultsArray,
                                    pageingKey        : pageingKey,
                                    completion        : completion
                                )
                            }
                            
                        // The request failed
                        case .failure(let err):
                            completion(.failure(err))
                        }
                    }
                    
                // Authentication failed
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }
        
        fetchPages(request: request, cumulativeResults: [], pageingKey: pageingKey) { completion($0) }
    }
}
