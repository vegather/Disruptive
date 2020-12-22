import XCTest
@testable import Disruptive

class DisruptiveTests: XCTestCase {
    var disruptive: Disruptive!
    var expectation: XCTestExpectation!
    
    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        Request.defaultSession = URLSession(configuration: configuration)
        
        let creds = ServiceAccountCredentials(email: "", key: "", secret: "")
        let auth = BasicAuthAuthenticator(credentials: creds)
        disruptive = Disruptive(authProvider: auth)
        Disruptive.loggingEnabled = true
    }
}
