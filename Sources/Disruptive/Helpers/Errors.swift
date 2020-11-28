//
//  Errors.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 24/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 An enumeration of all the possible errors that could occur by calling one of the endpoints.
 */
public enum DisruptiveError: Error {
    /// Could not reach the server. Either the client is not connected
    /// to the internet, or the server is currently offline.
    case serverUnavailable
    
    /// Something went wrong on the server. This error comes from
    /// a 500, 503, or 504 status code.
    case serverError
    
    /// Something went wrong with parsing the request on the
    /// server. This error comes from a 400 status code.
    case badRequest
    
    /// Either the client is not properly authorized, or the access
    /// token has expired. This error comes from a 401 status code.
    case unauthorized
    
    /// You attempted to access a resource that you don't
    /// have access to. This error comes from either a 403
    /// status code.
    case insufficientPermissions
    
    /// You attempted to access a resource that you either don't
    /// have access to, or doesn't exist. This error comes from
    /// either a 403 or a 404 status code.
    case notFound
    
    /// You likely tried to create a resource that already exists.
    /// This error comes from a 409 status code.
    case resourceAlreadyExists
    
    /// Something unexpected happened that could not be recovered from.
    /// Check the logs for more information
    case unknownError
    
    /// Returned when the `authProvider` is currently logged out. Call
    /// `login()` on the `authProvider` to log it back in.
    case loggedOut
}

internal enum InternalError: Error {
    /// Could be client is not on network, or server is down
    case serverUnavailable
    
    /// Something unexpected, unrecoverable happened
    case unknownError
    
    /**
     # Error Code: 400 - Bad Request
     
        Most likely due to an invalid argument as a part of a path, query parameter, or in the body of the request. Please see the error message for more information.
     */
    case badRequest
    
    /**
     # Error Code: 401 - Unauthorized
     
        Your user, or the service account that you are using, cannot be authenticated towards our API.
     
     # Access Tokens
     
        If you are using an Access Token received from our OAuth2 endpoint, please note that these are only valid for one hour. For uninterrupted operation using Access Tokens, make sure to get a new one before the previous one expires. See our Authentication Article for more details.
     
        If you copy-pasted the curl command from the Interactive API Reference, you will have gotten an Access Token which will only be valid for one hour. See the cURL Article to learn how to use it with a service account.
     */
    case unauthorized
    
    
    /**
     # Error Code: 403 - Forbidden
        Your user, or the service account that you are using, does not have access to this resource.
     
        Make sure that you have access to the Studio project or organization, that you are trying to access.
     
     # Roles

        If you are trying to modify a sensor, such as changing or adding a label, make sure that you or the Service Account used to make the request, have at least project developer access.

        If you are trying to modify a project, such as inviting a new user or transferring a sensor to another project, make sure that you, or the Service Account used to make the request, are a project administrator.

        If you are trying to transfer a sensor to another project, make sure that you, or the Service Account used to make the request, are project administrator in both the project you are transferring the sensor out of, and the one you are targeting to transfer it to.
     */
    case forbidden
    
    /**
     # Error Code: 404 - Not Found
     
        The resource that you are looking for doesn’t exist.

        Double-check any path parameters, that they are correct and that they exist. When executing a “:” method, such as /projects/{PROJECT_ID}/devices:transfer, this error indicates that the Project with  PROJECT_ID cannot be found, not that the devices slated for transfer was not found.

        Please note that it might take a few moments from a resource is created until the change has propagated. So if you are trying to fetch a very recently created resource, please try again with exponential backoff and minimum 1s delay.
     */
    case notFound
    
   
    /**
     # Error Code: 409 - Conflict
     
        The resource that you are trying to create most likely already exists. You will get this error if you are trying to create a new label with the same name as an existing one, or if you invite a member to an organization or project who is already invited.

        It is also possible to get this error if you are trying to change a resource rapidly from different clients at once. If you suspect this, then read out the related resources again, apply any changes and try to do the operation again.
     */
    case conflict
    
    /**
     # Error Code: 429 - Too Many Requests
     
        You are sending too many requests to the API in a too short of a time frame.

        When you exceed your rate-limit of 25 requests per 5 seconds you will see this error. This represents a steady state of 5 requests per second, but we also allow for shorter bursts, up to the limit of 25 requests per 5 seconds.
     
     # Retry-After Header
     
        When you exceed this limit, this error response will have an attached Retry-After header. This header can be used to schedule a retry no earlier than the provided Retry-After value in seconds.

        For example, let us say that you are trying to read-modify-write a specific label on a lot of devices as quickly as possible. After having run 25 requests in 1 second, you will get a “429 - Too many requests” error response. In response, you will get a Retry-After which will tell you to wait 4 seconds before retrying again.

        Please note that while this burst-wait-burst is possible, spreading out requests over time is preferred.
     */
    case tooManyRequests(retryAfter: Int)
    
    /**
     # Error Code: 500 - Internal Server Error
     
        There has been an internal error in our services.

        This type of error is often intermittent and we recommend you retry the request with an exponential backoff with minimum 1s delay.

        If the error persists, please check our Status Page. If there is no announced downtime, please contact Support.
     */
    case internalServerError
    
    /**
     # Error Code: 501 - Service Unavailable
     
        See 500 - Internal Server Error.
     */
    case serviceUnavailale
    
    /**
     # Error Code: 503 - Gateway Timeout
     
        See 500 - Internal Server Error, but retry with minimum 10s delay.
     */
    case gatewayTimeout
    
    func disruptiveError() -> DisruptiveError? {
        switch self {
            case .serverUnavailable     : return .serverUnavailable
            case .unknownError          : return .unknownError
            case .badRequest            : return .badRequest
            case .unauthorized          : return .unauthorized
            case .forbidden             : return .insufficientPermissions
            case .notFound              : return .notFound
            case .conflict              : return .resourceAlreadyExists
            case .tooManyRequests       : return nil
            
            // TODO: Retry scheme with exponential backoff
            case .internalServerError   : return .serverError
            case .serviceUnavailale     : return .serverError
            case .gatewayTimeout        : return .serverError
        }
    }
}

internal enum ParseError: Error {
    case identifier(path: String)
    case dateFormat(date: String)
    case eventType(type: String)
}
