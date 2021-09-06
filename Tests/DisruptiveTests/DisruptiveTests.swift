import XCTest
@testable import Disruptive

struct TestAuthenticator: Authenticator {
    var authToken: AuthToken? {
        return AuthToken(token: "foobar", expirationDate: .distantFuture)
    }
    
    var shouldAutoRefreshAccessToken: Bool {
        return true
    }
    
    func login(completion: @escaping AuthHandler) {
        completion(.success(()))
    }
    
    func logout(completion: @escaping AuthHandler) {
        completion(.success(()))
    }
    
    func refreshAccessToken(completion: @escaping AuthHandler) {
        completion(.success(()))
    }
    
    
}

class DisruptiveTests: XCTestCase {
    var disruptive: Disruptive!
    var expectation: XCTestExpectation!
    
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
        Disruptive.auth = TestAuthenticator()
        Disruptive.loggingEnabled = true
        disruptive = Disruptive()
    }
    
    private func tearDownAuth() {
        Disruptive.auth = nil
        Disruptive.loggingEnabled = false
        disruptive = nil
    }
}
