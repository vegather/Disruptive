//
//  ServiceAccount.swift
//  
//
//  Created by Vegard Solheim Theriault on 22/12/2020.
//

import Foundation

/**
 All programmatic interaction with the Disruptive Technologies API is done via a logged-in Service Account.
 
 To learn more about Service Accounts, see the [Service Account page on the developer website](https://developer.disruptive-technologies.com/docs/service-accounts/introduction-to-service-accounts).
 
 Functions relevant for `ServiceAccount`s are implemented on the [`Disruptive`](https://vegather.github.io/Disruptive/Disruptive/) struct:
 * [`getServiceAccounts`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getserviceaccounts(projectid:completion:))
 * [`getServiceAccountsPage`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getserviceaccountspage(projectid:pagesize:pagetoken:completion:))
 * [`getServiceAccount`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getserviceaccount(projectid:serviceaccountid:completion:))
 * [`createServiceAccount`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.createserviceaccount(projectid:displayname:basicauthenabled:completion:))
 * [`updateServiceAccount`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.updateserviceaccount(projectid:serviceaccountid:displayname:basicauthenabled:completion:))
 * [`deleteServiceAccount`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.deleteserviceaccount(projectid:serviceaccountid:completion:))
 * [`getServiceAccountKeys`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getserviceaccountkeys(projectid:serviceaccountid:completion:))
 * [`getServiceAccountKeysPage`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getserviceaccountkeyspage(projectid:serviceaccountid:pagesize:pagetoken:completion:))
 * [`getServiceAccountKey`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.getserviceaccountkey(projectid:serviceaccountid:keyid:completion:))
 * [`createServiceAccountKey`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.createserviceaccountkey(projectid:serviceaccountid:completion:))
 * [`deleteServiceAccountKey`](https://vegather.github.io/Disruptive/Disruptive/#disruptive.deleteserviceaccountkey(projectid:serviceaccountid:keyid:completion:))
 */
public struct ServiceAccount: Decodable, Equatable {
    
    /// The unique identifier of the Service Account. This will be different from the `name` field in the REST API
    /// in that it is just the identifier without the `projects/*/serviceaccounts/` prefix.
    public let identifier: String
    
    /// The identifier of the project the Service Account is in.
    public let projectID: String
    
    /// The email of the Service Accounts. Used for authenticating the Service Account.
    /// Has the format: `<identifier>@<projectID>.serviceaccount.d21s.com`.
    public let email: String
    
    /// The display name of the Service Account.
    public let displayName: String
    
    /// Indicates whether or not the Service Account can be authenticated using HTTP basic auth.
    /// It is *not* recommended to have this enabled in a production environment.
    public let basicAuthEnabled: Bool
    
    /// The timestamp for when the Service Account was created.
    public let createTime: Date
    
    /// The timestamp for when the Service Account was last updated.
    public let updateTime: Date
}

extension Disruptive {
    
    /**
     Gets all the Service Accounts that are available in a specific project.
     
     This will handle pagination automatically and send multiple network requests in
     the background if necessary. If a lot of Service Accounts are expected to be in the project,
     it might be better to load pages of Service Accounts as they're needed using the
     `getServiceAccountsPage` function instead.
     
     - Parameter projectID: The identifier of the project to get Service Accounts from.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `ServiceAccount`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[ServiceAccount], DisruptiveError>`
     */
    public func getServiceAccounts(
        projectID  : String,
        completion : @escaping (_ result: Result<[ServiceAccount], DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/serviceaccounts"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request, pagingKey: "serviceAccounts") { completion($0) }
    }
    
    /**
     Gets one page of Service Accounts.
     
     Useful if a lot of Service Accounts are expected in the specified project. This function
     provides better control for when to get Service Accounts and how many to get at a time so
     that Service Accounts are only fetch when they are needed. This can also improve performance,
     at a cost of convenience compared to the `getServiceAccounts` function.
     
     - Parameter projectID: The identifier of the project to get Service Accounts from.
     - Parameter pageSize: The maximum number of Service Accounts to get for this page. The maximum page size is 100, which is also the default
     - Parameter pageToken: The token of the page to get. For the first page, set this to `nil`. For subsequent pages, use the `nextPageToken` received when getting the previous page.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain a tuple with both an array of `ServiceAccount`s, as well as the token for the next page. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<(nextPageToken: String?, serviceAccounts: [ServiceAccount]), DisruptiveError>`
     */
    public func getServiceAccountsPage(
        projectID  : String,
        pageSize   : Int = 100,
        pageToken  : String?,
        completion : @escaping (_ result: Result<(nextPageToken: String?, serviceAccounts: [ServiceAccount]), DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/serviceaccounts"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request, pageSize: pageSize, pageToken: pageToken, pagingKey: "serviceAccounts") { (result: Result<PagedResult<ServiceAccount>, DisruptiveError>) in
            switch result {
                case .success(let page) : completion(.success((nextPageToken: page.nextPageToken, serviceAccounts: page.results)))
                case .failure(let err)  : completion(.failure(err))
            }
        }
    }
    
    /**
     Gets a specific Service Account within a project by its identifier.
     
     - Parameter projectID: The identifier of the project to get the Service Account from.
     - Parameter serviceAccountID: The identifier of the Service Account to get within the specified project.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `ServiceAccount`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<ServiceAccount, DisruptiveError>`
     */
    public func getServiceAccount(
        projectID        : String,
        serviceAccountID : String,
        completion       : @escaping (_ result: Result<ServiceAccount, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/serviceaccounts/\(serviceAccountID)"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Creates a new Service Account within a specific project.
     
     __NOTE__: This Service Account will by default not have access to any resources.
     In order to allow the Service Account to send API requests, add it as a `Member` to a project
     or an organization.
     
     - Parameter projectID: The identifier of the project to create the Service Account in.
     - Parameter displayName: The display name to give the Service Account.
     - Parameter basicAuthEnabled: Whether or not the Service Account should be able to be authenticated
     using HTTP basic auth. This is not recommended in a production environment. The default value is `false`.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `ServiceAccount` (along with its generated identifier). If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<ServiceAccount, DisruptiveError>`
     */
    public func createServiceAccount(
        projectID        : String,
        displayName      : String,
        basicAuthEnabled : Bool = false,
        completion       : @escaping (_ result: Result<ServiceAccount, DisruptiveError>) -> ())
    {
        struct ServiceAccountPayload: Encodable {
            let displayName     : String
            let enableBasicAuth : Bool
        }
        let payload = ServiceAccountPayload(
            displayName     : displayName,
            enableBasicAuth : basicAuthEnabled
        )
        
        do {
            // Create the request
            let endpoint = "projects/\(projectID)/serviceaccounts"
            let request = try Request(method: .post, baseURL: baseURL, endpoint: endpoint, body: payload)
            
            // Send the request
            sendRequest(request) { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to init create service account request with payload \(payload). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? .unknownError))
        }
    }
    
    /**
     Updates parameters of a specific Service Account. Only the parameters that are set will be updated, and the remaining will be left unchanged.
     
     Examples:
     
     ```
     // Enable basic auth
     disruptive.updateServiceAccount(
         projectID        : "<PROJECT_ID>",
         serviceAccountID : "<SERVICE_ACCOUNT_ID>",
         basicAuthEnabled : true)
     { result in
         ...
     }
     
     // Change the display name
     disruptive.updateServiceAccount(
         projectID        : "<PROJECT_ID>",
         serviceAccountID : "<SERVICE_ACCOUNT_ID>",
         displayName      : "New Display Name")
     { result in
         ...
     }
     ```
     
     - Parameter projectID: The identifier of the project the Service Account to update is in.
     - Parameter serviceAccountID: The identifier of the Service Account to update.
     - Parameter displayName: The new display name to use for the Service Account. Will be ignored if not set (or `nil`). Defaults to `nil`.
     - Parameter basicAuthEnabled: Enables or disables HTTP basic auth for a Service Account. It is recommended to set this to false in a production environment. Will be ignored if not set (or `nil`). Defaults to `nil`.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the updated `ServiceAccount`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<ServiceAccount, DisruptiveError>`
     */
    public func updateServiceAccount(
        projectID        : String,
        serviceAccountID : String,
        displayName      : String? = nil,
        basicAuthEnabled : Bool?   = nil,
        completion       : @escaping (_ result: Result<ServiceAccount, DisruptiveError>) -> ())
    {
        struct ServiceAccountPatch: Encodable {
            var displayName: String?
            var enableBasicAuth: Bool?
        }
        
        // Prepare the payload
        var patch = ServiceAccountPatch()
        var updateMask = [String]()
        
        if let displayName = displayName {
            patch.displayName = displayName
            updateMask.append("displayName")
        }
        if let basicAuthEnabled = basicAuthEnabled {
            patch.enableBasicAuth = basicAuthEnabled
            updateMask.append("enableBasicAuth")
        }
        
        do {
            // Create the request
            let endpoint = "projects/\(projectID)/serviceaccounts/\(serviceAccountID)"
            let params = ["update_mask": [updateMask.joined(separator: ",")]]
            let request = try Request(method: .patch, baseURL: baseURL, endpoint: endpoint, params: params, body: patch)
            
            // Send the request
            sendRequest(request) { completion($0) }
        } catch (let error) {
            Disruptive.log("Failed to init updateServiceAccount request with payload: \(patch). Error: \(error)", level: .error)
            completion(.failure((error as? DisruptiveError) ?? .unknownError))
        }
    }
    
    /**
     Deletes a Service Account.
     
     - Parameter projectID: The identifier of the project to delete the Service Account from.
     - Parameter serviceAccountID: The identifier of the Service Account to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`
     */
    public func deleteServiceAccount(
        projectID        : String,
        serviceAccountID : String,
        completion       : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/serviceaccounts/\(serviceAccountID)"
        let request = Request(method: .delete, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Gets all the keys for a specific Service Account.
     
     This will handle pagination automatically and send multiple network requests in
     the background if necessary. If a lot of keys are expected to be available for the Service Account,
     it might be better to load pages of keys as they're needed using the
     `getServiceAccountKeysPage` function instead.
     
     - Parameter projectID: The identifier of the project the Service Account is in.
     - Parameter serviceAccountID: The identifier of the Service Account to get keys for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain an array of `ServiceAccount.Key`s. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<[ServiceAccount.Key], DisruptiveError>`
     */
    public func getServiceAccountKeys(
        projectID        : String,
        serviceAccountID : String,
        completion       : @escaping (_ result: Result<[ServiceAccount.Key], DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/serviceaccounts/\(serviceAccountID)/keys"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request, pagingKey: "keys") { completion($0) }
    }
    
    /**
     Gets one page of keys for a specific Service Account.
     
     Useful if a lot of keys are expected to be available for this Service Account. This function
     provides better control for when to get keys and how many to get at a time so
     that keys are only fetch when they are needed. This can also improve performance,
     at a cost of convenience compared to the `getServiceAccountKeys` function.
     
     - Parameter projectID: The identifier of the project the Service Account is in.
     - Parameter serviceAccountID: The identifier of the Service Account to get keys for.
     - Parameter pageSize: The maximum number of keys to get for this page. The maximum page size is 100, which is also the default
     - Parameter pageToken: The token of the page to get. For the first page, set this to `nil`. For subsequent pages, use the `nextPageToken` received when getting the previous page.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain a tuple with both an array of `ServiceAccount.Key`s, as well as the token for the next page. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<(nextPageToken: String?, keys: [ServiceAccount.Key]), DisruptiveError>`
     */
    public func getServiceAccountKeysPage(
        projectID        : String,
        serviceAccountID : String,
        pageSize         : Int = 100,
        pageToken        : String?,
        completion       : @escaping (_ result: Result<(nextPageToken: String?, keys: [ServiceAccount.Key]), DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/serviceaccounts/\(serviceAccountID)/keys"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request, pageSize: pageSize, pageToken: pageToken, pagingKey: "keys") { (result: Result<PagedResult<ServiceAccount.Key>, DisruptiveError>) in
            switch result {
                case .success(let page) : completion(.success((nextPageToken: page.nextPageToken, keys: page.results)))
                case .failure(let err)  : completion(.failure(err))
            }
        }
    }
    
    /**
     Gets a single key for a specific Service Account.
     
     - Parameter projectID: The identifier of the project the Service Account is in.
     - Parameter serviceAccountID: The identifier of the Service Account to get a key for.
     - Parameter keyID: The identifier of the key to get.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `ServiceAccount.Key`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<ServiceAccount.Key, DisruptiveError>`
     */
    public func getServiceAccountKey(
        projectID        : String,
        serviceAccountID : String,
        keyID            : String,
        completion       : @escaping (_ result: Result<ServiceAccount.Key, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/serviceaccounts/\(serviceAccountID)/keys/\(keyID)"
        let request = Request(method: .get, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Creates a new key for a Service Account, and gets both the key and the corresponding secret in return.
     
     Note a couple of things:
     * The secret that is returned can not be retrieved later, so make sure to take a note of it.
     * A Service Account can have a maximum of 10 keys.
     
     - Parameter projectID: The identifier of the project the Service Account is in.
     - Parameter serviceAccountID: The identifier of the Service Account to create a new key for.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` case of the result will contain the `ServiceAccount.KeySecret`. If a failure occurred, the `.failure` case will contain a `DisruptiveError`.
     - Parameter result: `Result<ServiceAccount.KeySecret, DisruptiveError>`
     */
    public func createServiceAccountKey(
        projectID        : String,
        serviceAccountID : String,
        completion       : @escaping (_ result: Result<ServiceAccount.KeySecret, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/serviceaccounts/\(serviceAccountID)/keys"
        let request = Request(method: .post, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
    
    /**
     Deletes a key for a Service Account.
     
     This will prevent the Service Account from being able to authenticate using the deleted key.
     
     - Parameter projectID: The identifier of the project the Service Account is in.
     - Parameter serviceAccountID: The identifier of the Service Account to delete a key for.
     - Parameter keyID: The identifier of the key to delete.
     - Parameter completion: The completion handler to be called when a response is received from the server. If successful, the `.success` result case is returned, otherwise a `DisruptiveError` is returned in the `.failure` case.
     - Parameter result: `Result<Void, DisruptiveError>`

     */
    public func deleteServiceAccountKey(
        projectID        : String,
        serviceAccountID : String,
        keyID            : String,
        completion       : @escaping (_ result: Result<Void, DisruptiveError>) -> ())
    {
        // Create the request
        let endpoint = "projects/\(projectID)/serviceaccounts/\(serviceAccountID)/keys/\(keyID)"
        let request = Request(method: .delete, baseURL: baseURL, endpoint: endpoint)
        
        // Send the request
        sendRequest(request) { completion($0) }
    }
}


extension ServiceAccount {
    
    /// A key that can be used to authenticate a Service Account.
    public struct Key: Decodable, Equatable {
        /// The identifier of the Service Account key.
        public let identifier: String
        
        /// The identifier of the Service Account the key belongs to.
        public let serviceAccountID: String
        
        /// The identifier of the project the Service Account belongs to.
        public let projectID: String
        
        /// The timestamp for when the Service Account key was created.
        public let createTime: Date
    }
    
    /// A secret along with the corresponding key used to authenticate a Service Account.
    /// This is the response value for when a new key is created for a Service Account.
    public struct KeySecret: Decodable, Equatable {
        /// The key the `secret` corresponds to.
        public let key: Key
        
        /// The secret used to authenticate a Service Account.
        public let secret: String
    }
}

extension ServiceAccount.Key {
    private enum CodingKeys: String, CodingKey {
        case name
        case createTime
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Service Account key resource names are formatted as
        // "projects/b7s3umd0fee000ba5di0/serviceaccounts/b5rj9ed7rihk942p48og/keys/bvh86mj24tgg00b2515g"
        // Setting the identifier to the last component of the resource name
        let keyResourceName = try container.decode(String.self, forKey: .name)
        let resourceNameComponents = keyResourceName.components(separatedBy: "/")
        guard resourceNameComponents.count == 6 else {
            throw ParseError.identifier(path: keyResourceName)
        }
        self.identifier       = resourceNameComponents[5]
        self.serviceAccountID = resourceNameComponents[3]
        self.projectID        = resourceNameComponents[1]
        
        let timeString = try container.decode(String.self, forKey: .createTime)
        self.createTime = try Date(iso8601String: timeString)
    }
}

extension ServiceAccount {
    private enum CodingKeys: String, CodingKey {
        case resourceName = "name"
        case email
        case displayName
        case enableBasicAuth
        case createTime
        case updateTime
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Service Account resource names are formatted as
        // "projects/b7s3umd0fee000ba5di0/serviceaccounts/b5rj9ed7rihk942p48og"
        // Setting the identifier to the last component of the resource name
        let saResourceName = try container.decode(String.self, forKey: .resourceName)
        let resourceNameComponents = saResourceName.components(separatedBy: "/")
        guard resourceNameComponents.count == 4 else {
            throw ParseError.identifier(path: saResourceName)
        }
        self.projectID  = resourceNameComponents[1]
        self.identifier = resourceNameComponents[3]
        
        self.email            = try container.decode(String.self, forKey: .email)
        self.displayName      = try container.decode(String.self, forKey: .displayName)
        self.basicAuthEnabled = try container.decode(Bool.self,   forKey: .enableBasicAuth)
        
        let createTimestamp = try container.decode(String.self, forKey: .createTime)
        let updateTimestamp = try container.decode(String.self, forKey: .updateTime)
        self.createTime = try Date(iso8601String: createTimestamp)
        self.updateTime = try Date(iso8601String: updateTimestamp)
    }
}
