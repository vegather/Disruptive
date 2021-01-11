import XCTest
@testable import Disruptive

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
        let creds = ServiceAccountCredentials(email: "", key: "", secret: "")
        let auth = BasicAuthAuthenticator(credentials: creds)
        disruptive = Disruptive(authenticator: auth)
        Disruptive.loggingEnabled = true
    }
}
