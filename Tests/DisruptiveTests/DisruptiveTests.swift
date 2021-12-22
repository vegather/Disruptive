//
//  DisruptiveTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 27/12/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

struct TestAuthenticator: Authenticator {
    var authToken: AuthToken? {
        return AuthToken(token: "foobar", expirationDate: .distantFuture)
    }
    
    var shouldAutoRefreshAccessToken: Bool {
        return true
    }
    
    func login() async throws {}
    
    func logout() async throws {}
    
    func refreshAccessToken() async throws {}
}

class DisruptiveTests: XCTestCase {
    var disruptive: Disruptive!
    
    override func setUp() {
        setupRequest()
        setupStream()
        setupAuth()
    }
    
    override func tearDown() {
        tearDownAuth()
    }
    
    private func setupRequest() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        Request.defaultSession = URLSession(configuration: config)
    }
    
    private func setupStream() {
        DeviceEventStream.sseConfig.protocolClasses = [MockStreamURLProtocol.self]
        DeviceEventStream.sseConfig.timeoutIntervalForRequest  = 1
        DeviceEventStream.sseConfig.timeoutIntervalForResource = 1
    }
    
    private func setupAuth() {
        Disruptive.authenticator = TestAuthenticator()
        Disruptive.loggingEnabled = true
        disruptive = Disruptive()
    }
    
    private func tearDownAuth() {
        Disruptive.authenticator = nil
        Disruptive.loggingEnabled = false
        disruptive = nil
    }
}
