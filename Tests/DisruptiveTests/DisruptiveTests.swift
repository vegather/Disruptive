import XCTest
@testable import Disruptive

struct TestAuthenticator: Authenticator {
    var auth: AuthToken? {
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
        let auth = TestAuthenticator()
        disruptive = Disruptive(authenticator: auth)
        Disruptive.loggingEnabled = true
    }
}
