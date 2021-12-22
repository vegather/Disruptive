//
//  ServiceAccountTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 24/12/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class ServiceAccountTests: DisruptiveTests {
    
    func testDecodeServiceAccount() {
        let saIn = createDummyServiceAccount()
        let saOut = try! JSONDecoder().decode(ServiceAccount.self, from: createServiceAccountJSON(from: saIn))
        
        XCTAssertEqual(saIn, saOut)
    }
    
    func testDecodeServiceAccountKey() {
        let keyIn = createDummyServiceAccountKey()
        let keyOut = try! JSONDecoder().decode(ServiceAccount.Key.self, from: createServiceAccountKeyJSON(from: keyIn))
        
        XCTAssertEqual(keyIn, keyOut)
    }
    
    func testDecodeServiceAccountKeySecret() {
        let keySecretIn = createDummyServiceAccountKeySecret()
        let keySecretOut = try! JSONDecoder().decode(ServiceAccount.KeySecret.self, from: createServiceAccountKeySecretJSON(from: keySecretIn))
        
        XCTAssertEqual(keySecretIn, keySecretOut)
    }
    
    func testGetServiceAccounts() async throws {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts")
        
        let respServiceAccounts = [createDummyServiceAccount(), createDummyServiceAccount()]
        let respData = createServiceAccountsJSON(from: respServiceAccounts)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let accounts = try await ServiceAccount.getAll(projectID: reqProjectID)
        XCTAssertEqual(accounts, respServiceAccounts)
    }
    
    func testGetServiceAccountsPage() async throws {
        let reqProjectID = "proj1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts")
        
        let respServiceAccounts = [createDummyServiceAccount(), createDummyServiceAccount()]
        let respData = createServiceAccountsJSON(from: respServiceAccounts, nextPageToken: "nextToken")
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : ["page_size": ["2"], "page_token": ["token"]],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let page = try await ServiceAccount.getPage(projectID: reqProjectID, pageSize: 2, pageToken: "token")
        XCTAssertEqual(page.nextPageToken, "nextToken")
        XCTAssertEqual(page.serviceAccounts, respServiceAccounts)
    }
    
    func testGetServiceAccount() async throws {
        let reqProjectID = "proj1"
        let reqSAID = "sa1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts/\(reqSAID)")
        
        let respSA = createDummyServiceAccount()
        let respData = createServiceAccountJSON(from: respSA)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let sa = try await ServiceAccount.get(projectID: reqProjectID, serviceAccountID: reqSAID)
        XCTAssertEqual(respSA, sa)
    }
    
    func testCreateServiceAccount() async throws {
        let reqProjectID = "abc"
        let reqDisplayName = "dummy"
        let reqBasicAuthEnabled = true
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts")
        let reqBody = """
        {
            "displayName": "\(reqDisplayName)",
            "enableBasicAuth": \(reqBasicAuthEnabled)
        }
        """.data(using: .utf8)!
        
        let respSA = createDummyServiceAccount()
        let respData = createServiceAccountJSON(from: respSA)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "POST",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let sa = try await ServiceAccount.create(projectID: reqProjectID, displayName: reqDisplayName, basicAuthEnabled: reqBasicAuthEnabled)
        XCTAssertEqual(sa, respSA)
    }
    
    func testUpdateServiceAccountAllParametersSet() async throws {
        let reqProjectID = "proj1"
        let reqSaID = "sa1"
        let reqDisplayName = "disp_name"
        let reqBasicAuthEnabled = true
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts/\(reqSaID)")
        let reqBody = """
        {
          "displayName": "\(reqDisplayName)",
          "enableBasicAuth": \(reqBasicAuthEnabled)
        }
        """.data(using: .utf8)!
        
        
        let respSA = createDummyServiceAccount()
        let respData = createServiceAccountJSON(from: respSA)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "PATCH",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let sa = try await ServiceAccount.update(
            projectID        : reqProjectID,
            serviceAccountID : reqSaID,
            displayName      : reqDisplayName,
            basicAuthEnabled : reqBasicAuthEnabled
        )
        XCTAssertEqual(sa, respSA)
    }
    
    func testUpdateServiceAccountNoParametersSet() async throws {
        let reqProjectID = "proj1"
        let reqSaID = "sa1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts/\(reqSaID)")
        let reqBody = """
        { }
        """.data(using: .utf8)!
        
        
        let respSA = createDummyServiceAccount()
        let respData = createServiceAccountJSON(from: respSA)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "PATCH",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : reqBody
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
                
        let sa = try await ServiceAccount.update(projectID: reqProjectID, serviceAccountID: reqSaID)
        XCTAssertEqual(sa, respSA)
    }
    
    func testDeleteServiceAccount() async throws {
        let reqSaID = "sa1"
        let reqProjectID = "proj1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts/\(reqSaID)")
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "DELETE",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        try await ServiceAccount.delete(projectID: reqProjectID, serviceAccountID: reqSaID)
    }
    
    func testGetServiceAccountKeys() async throws {
        let reqProjectID = "proj1"
        let reqSaID = "sa1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts/\(reqSaID)/keys")
        
        let respSaKeys = [createDummyServiceAccountKey(), createDummyServiceAccountKey()]
        let respData = createServiceAccountKeysJSON(from: respSaKeys)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let keys = try await ServiceAccount.getAllKeys(projectID: reqProjectID, serviceAccountID: reqSaID)
        XCTAssertEqual(keys, respSaKeys)
    }
    
    func testGetServiceAccountKeysPage() async throws {
        let reqProjectID = "proj1"
        let reqSaID = "sa1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts/\(reqSaID)/keys")
        
        let respSaKeys = [createDummyServiceAccountKey(), createDummyServiceAccountKey()]
        let respData = createServiceAccountKeysJSON(from: respSaKeys, nextPageToken: "nextToken")
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : ["page_size": ["2"], "page_token": ["token"]],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let page = try await ServiceAccount.getKeysPage(projectID: reqProjectID, serviceAccountID: reqSaID, pageSize: 2, pageToken: "token")
        XCTAssertEqual(page.nextPageToken, "nextToken")
        XCTAssertEqual(page.keys, respSaKeys)
    }
    
    func testGetServiceAccountKey() async throws {
        let reqProjectID = "proj1"
        let reqSaID = "sa1"
        let reqKeyID = "key1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts/\(reqSaID)/keys/\(reqKeyID)")
        
        let respSaKey = createDummyServiceAccountKey()
        let respData = createServiceAccountKeyJSON(from: respSaKey)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "GET",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let keys = try await ServiceAccount.getKey(projectID: reqProjectID, serviceAccountID: reqSaID, keyID: reqKeyID)
        XCTAssertEqual(respSaKey, keys)
    }
    
    func testCreateServiceAccountKey() async throws {
        let reqProjectID = "abc"
        let reqSaId = "sa1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts/\(reqSaId)/keys")
        
        let respSaKs = createDummyServiceAccountKeySecret()
        let respData = createServiceAccountKeySecretJSON(from: respSaKs)
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "POST",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (respData, resp, nil)
        }
        
        let ks = try await ServiceAccount.createKey(projectID: reqProjectID, serviceAccountID: reqSaId)
        XCTAssertEqual(ks, respSaKs)
    }
    
    func testDeleteServiceAccountKey() async throws {
        let reqProjectID = "proj1"
        let reqSaID = "sa1"
        let reqKeyID = "key1"
        let reqURL = URL(string: Config.DefaultURLs.baseURL)!
            .appendingPathComponent("projects/\(reqProjectID)/serviceaccounts/\(reqSaID)/keys/\(reqKeyID)")
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : true,
                method        : "DELETE",
                queryParams   : [:],
                headers       : [:],
                url           : reqURL,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: reqURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (nil, resp, nil)
        }
        
        try await ServiceAccount.deleteKey(projectID: reqProjectID, serviceAccountID: reqSaID, keyID: reqKeyID)
    }
}



// -------------------------------
// MARK: ServiceAccount Helpers
// -------------------------------

extension ServiceAccountTests {
    private func createServiceAccountJSONString(from sa: ServiceAccount) -> String {
        return """
            {
                "name": "projects/\(sa.projectID)/serviceaccounts/\(sa.identifier)",
                "email": "\(sa.email)",
                "displayName": "\(sa.displayName)",
                "enableBasicAuth": \(sa.basicAuthEnabled ? "true" : "false"),
                "createTime": "\(sa.createTime.iso8601String())",
                "updateTime": "\(sa.updateTime.iso8601String())"
            }
            
        """
    }
    
    fileprivate func createServiceAccountJSON(from sa: ServiceAccount) -> Data {
        return createServiceAccountJSONString(from: sa).data(using: .utf8)!
    }
    
    fileprivate func createServiceAccountsJSON(from sas: [ServiceAccount], nextPageToken: String = "") -> Data {
        return """
        {
            "serviceAccounts": [
                \(sas.map({ createServiceAccountJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": "\(nextPageToken)"
        }
        """.data(using: .utf8)!
    }
    
    fileprivate func createDummyServiceAccount() -> ServiceAccount {
        return ServiceAccount(
            identifier       : "bpoubfs24sg000b24vd0",
            projectID        : "bpotd75ufmde03ajo8fa",
            email            : "bpotd75ufmde03ajo8fa@bpoubfs24sg000b24vd0.serviceaccounts.d21s.com",
            displayName      : "Test account",
            basicAuthEnabled : true,
            createTime       : Date(timeIntervalSince1970: 1608768915),
            updateTime       : Date(timeIntervalSince1970: 1608768915)
        )
    }
}




// -------------------------------
// MARK: ServiceAccount.Key Helpers
// -------------------------------

extension ServiceAccountTests {
    private func createServiceAccountKeyJSONString(from key: ServiceAccount.Key) -> String {
        return """
        {
            "name": "projects/\(key.projectID)/serviceaccounts/\(key.serviceAccountID)/keys/\(key.identifier)",
            "id": "\(key.identifier)",
            "createTime": "\(key.createTime.iso8601String())"
        }
        """
    }
    
    fileprivate func createServiceAccountKeyJSON(from key: ServiceAccount.Key) -> Data {
        return createServiceAccountKeyJSONString(from: key).data(using: .utf8)!
    }
    
    fileprivate func createServiceAccountKeysJSON(from keys: [ServiceAccount.Key], nextPageToken: String = "") -> Data {
        return """
        {
            "keys": [
                \(keys.map({ createServiceAccountKeyJSONString(from: $0) }).joined(separator: ","))
            ],
            "nextPageToken": "\(nextPageToken)"
        }
        """.data(using: .utf8)!
    }
    
    fileprivate func createDummyServiceAccountKey() -> ServiceAccount.Key {
        return ServiceAccount.Key(
            identifier       : "b5rj9ed7rihk942p48og",
            serviceAccountID : "bpoubfs24sg000b24vd0",
            projectID        : "bpotd75ufmde03ajo8fa",
            createTime       : Date(timeIntervalSince1970: 1608768915)
        )
    }
}



// -------------------------------
// MARK: ServiceAccount.KeySecret Helpers
// -------------------------------

extension ServiceAccountTests {
    private func createServiceAccountKeySecretJSONString(from keySecret: ServiceAccount.KeySecret) -> String {
        return """
        {
            "key": {
                "name": "projects/\(keySecret.key.projectID)/serviceaccounts/\(keySecret.key.serviceAccountID)/keys/\(keySecret.key.identifier)",
                "id": "\(keySecret.key.identifier)",
                "createTime": "\(keySecret.key.createTime.iso8601String())"
            },
            "secret": "\(keySecret.secret)"
        }
        """
    }
    
    fileprivate func createServiceAccountKeySecretJSON(from keySecret: ServiceAccount.KeySecret) -> Data {
        return createServiceAccountKeySecretJSONString(from: keySecret).data(using: .utf8)!
    }
    
    fileprivate func createDummyServiceAccountKeySecret() -> ServiceAccount.KeySecret {
        return ServiceAccount.KeySecret(
            key: ServiceAccount.Key(
                identifier       : "b5rj9ed7rihk942p48og",
                serviceAccountID : "bpoubfs24sg000b24vd0",
                projectID        : "bpotd75ufmde03ajo8fa",
                createTime       : Date(timeIntervalSince1970: 1608768915)
            ),
            secret: "the_secret_goes_here"
        )
    }
    
}
