//
//  File.swift
//  
//
//  Created by Vegard Solheim Theriault on 25/11/2020.
//

import XCTest
@testable import Disruptive

class AuthenticationTests: DisruptiveTests {
    
    func testBasicAuth() {
        let serviceAccount = ServiceAccount(email: "email", key: "key", secret: "secret")
        let provider = BasicAuthAuthenticator(account: serviceAccount)
        
        XCTAssertNotNil(provider.auth)
        XCTAssertTrue(provider.auth!.token.hasPrefix("Basic "))
        XCTAssertGreaterThan(provider.auth!.expirationDate.timeIntervalSince1970, Date().timeIntervalSince1970)
        XCTAssertTrue(provider.shouldBeLoggedIn)
        
        let canGetTokenExp = expectation(description: "")
        provider.getNonExpiredAuthToken { result in
            switch result {
                case .success(let token):
                    XCTAssertEqual(token, provider.auth!.token)
                case .failure(_):
                    XCTFail()
            }
            canGetTokenExp.fulfill()
        }
        
        let canReauthenticateExp = expectation(description: "")
        provider.reauthenticate { result in
            if case .failure = result { XCTFail() }
            canReauthenticateExp.fulfill()
        }
        
        let canLoginExp = expectation(description: "")
        provider.login { result in
            if case .failure = result { XCTFail() }
            canLoginExp.fulfill()
        }
        
        let canLogoutExp = expectation(description: "")
        provider.logout { result in
            if case .failure = result { XCTFail() }
            canLogoutExp.fulfill()
        }
        
        wait(for: [canGetTokenExp, canReauthenticateExp, canLoginExp, canLogoutExp], timeout: 1)
    }
    
    func testOAuth2() {
        
    }
}
