//
//  Requests.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

extension Disruptive {    
    /// Creates a URL session with a 10 second timeout
    private static var defaultSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 10
        config.timeoutIntervalForResource = 10
        
        return URLSession(configuration: config)
    }()
    
    
    // -------------------------------
    // MARK: Sending Requests
    // -------------------------------
    
    /**
     Sends a request that doesn't expect any response
     */
    internal func sendRequest(
        request: Request,
        completion: @escaping (Result<Void, DisruptiveError>) -> ())
    {
        guard let auth = authorization else {
            DTLog("Not yet authorized. Call authenticate(serviceAccount: ) to authenticate")
            DispatchQueue.main.async {
                completion(.failure(.unauthorized))
            }
            return
        }
        guard let urlReq = request.urlRequest(authorization: auth) else {
            DTLog("Failed to create URLRequest from request: \(request)", isError: true)
            DispatchQueue.main.async {
                completion(.failure(.unknownError))
            }
            return
        }
        
        var diagnostics = RequestDiagnostics(request: request)
        diagnostics.setNetworkStart()
        
        let task = Disruptive.defaultSession.dataTask(with: urlReq) { data, response, error in
            
            diagnostics.setNetworkEnd()
            
            let urlString = urlReq.url!.absoluteString
            
            // Check the response for any errors
            if let internalError = Disruptive.checkResponseForErrors(
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
                        self.sendRequest(request: request, completion: completion)
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
            
            diagnostics.logDiagnostics(responseData: nil)
            
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
        task.resume()
    }
    
    /**
     Sends a requests that expects a single (non-paginated) response.
     */
    internal func sendRequest<T: Decodable>(
        request: Request,
        completion: @escaping (Result<T, DisruptiveError>) -> ())
    {
        guard let auth = authorization else {
            DTLog("Not yet authorized. Call authenticate(serviceAccount: ) to authenticate")
            DispatchQueue.main.async {
                completion(.failure(.unauthorized))
            }
            return
        }
        guard let urlReq = request.urlRequest(authorization: auth) else {
            DTLog("Failed to create URLRequest from request: \(request)", isError: true)
            DispatchQueue.main.async {
                completion(.failure(.unknownError))
            }
            return
        }
        
        var diagnostics = RequestDiagnostics(request: request)
        diagnostics.setNetworkStart()
        
        let task = Disruptive.defaultSession.dataTask(with: urlReq) { data, response, error in
            diagnostics.setNetworkEnd()
            
            let urlString = urlReq.url!.absoluteString
            
            // Check the response for any errors
            if let internalError = Disruptive.checkResponseForErrors(
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
                        self.sendRequest(request: request, completion: completion)
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
            
            // Prepare a decoder for decoding paginated results
            let decoder = JSONDecoder()
            
            diagnostics.setParseStart()
            
            // Parse the returned data
            guard let result: T = Disruptive.parsePayload(data, decoder: decoder) else {
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
    
    /**
     Sends a requests that expects a paginated response. This pagination
     will be handled automatically, and an array of the response type (T)
     will be returned.
     */
    internal func sendRequest<T: Decodable>(
        request: Request,
        cumulativeResults: [T] = [],
        pageingKey: String,
        completion: @escaping (Result<[T], DisruptiveError>) -> ())
    {
        guard let auth = authorization else {
            DTLog("Not yet authorized. Call authenticate(serviceAccount: ) to authenticate")
            DispatchQueue.main.async {
                completion(.failure(.unauthorized))
            }
            return
        }
        guard let urlReq = request.urlRequest(authorization: auth) else {
            DTLog("Failed to create URLRequest from request: \(request)", isError: true)
            DispatchQueue.main.async {
                completion(.failure(.unknownError))
            }
            return
        }
        
        var diagnostics = RequestDiagnostics(request: request)
        diagnostics.setNetworkStart()
        
        let task = Disruptive.defaultSession.dataTask(with: urlReq) { data, response, error in
            diagnostics.setNetworkEnd()
            
            let urlString = urlReq.url!.absoluteString
            
            // Check the response for any errors
            if let internalError = Disruptive.checkResponseForErrors(
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
                        self.sendRequest(
                            request: request,
                            cumulativeResults: cumulativeResults,
                            pageingKey: pageingKey,
                            completion: completion
                        )
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
                        
            // Prepare a decoder for decoding paginated results
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .custom { keys in
                if keys.last!.stringValue == pageingKey {
                    return PagedKey(stringValue: "results")!
                } else {
                    return keys.last!
                }
            }
            
            diagnostics.setParseStart()
            
            // Parse the returned data
            guard let pagedResult: PagedResult<T> = Disruptive.parsePayload(data, decoder: decoder) else {
                DispatchQueue.main.async {
                    DTLog("Failed to parse the response JSON from \(urlString)")
                    completion(.failure(.unknownError))
                }
                return
            }
            
            diagnostics.setParseEnd()
            diagnostics.logDiagnostics(responseData: data)
            
            // Concatinate all the results so far
            let updateResultArray = cumulativeResults + pagedResult.results
            
            // Check if there are any more pages
            if pagedResult.nextPageToken.count == 0 {
                // This was the last page
                DispatchQueue.main.async {
                    completion(.success(updateResultArray))
                }
            } else {
                // This was not the last page, send request for the next page
                var nextRequest = request
                nextRequest.params["pageToken"] = [pagedResult.nextPageToken]
                
                DTLog("Still more pages to load for \(urlString)")
                
                DispatchQueue.global().async() {
                    self.sendRequest(
                        request: nextRequest,
                        cumulativeResults: updateResultArray,
                        pageingKey: pageingKey,
                        completion: completion
                    )
                }
                
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
                DTLog("Failed to parse payload data: \(payload.hexString())", isError: true)
            }
            
            return nil
        }
    }
    
    
}
