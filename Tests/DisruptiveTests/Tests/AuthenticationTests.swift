//
//  AuthenticationTests.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 25/11/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import XCTest
@testable import Disruptive

class AuthenticationTests: DisruptiveTests {
    func testOAuth2() {
        let reqKey = "key"
        let reqEmail = "email"
        let reqURL = Disruptive.DefaultURLs.oauthTokenEndpoint
        
        let respAccessToken = "dummy_token"
        let respPayload = """
        {
            "access_token": "\(respAccessToken)",
            "token_type": "bearer",
            "expires_in": 3600
        }
        """.data(using: .utf8)!
        
        let creds = OAuth2Authenticator.Credentials(keyID: reqKey, issuer: reqEmail, secret: "secret")
        let auth = OAuth2Authenticator(credentials: creds, authURL: reqURL)
        Disruptive.auth = auth
        
        MockURLProtocol.requestHandler = { request in
            self.assertRequestParams(
                for           : request,
                authenticated : false,
                method        : "POST",
                queryParams   : [:],
                headers       : ["Content-Type": "application/x-www-form-urlencoded"],
                url           : URL(string: reqURL)!,
                body          : nil
            )
            
            let resp = HTTPURLResponse(url: URL(string: reqURL)!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            
            guard let body = request.httpBodyStream?.readData(), let bodyStr = String(data: body, encoding: .utf8) else {
                XCTFail()
                return (respPayload, resp, nil)
            }

            let parts = bodyStr.components(separatedBy: "&")
            XCTAssertEqual(parts.count, 2)

            for part in parts {
                let subParts = part.components(separatedBy: "=")
                XCTAssertEqual(subParts.count, 2)

                switch subParts[0] {
                    case "grant_type":
                        XCTAssertEqual(subParts[1], "urn:ietf:params:oauth:grant-type:jwt-bearer")

                    case "assertion":
                        // JWT
                        let jwtParts = subParts[1].components(separatedBy: ".")
                        XCTAssertEqual(jwtParts.count, 3)

                        let headerData = """
                        { "alg":"HS256", "kid":"\(reqKey)" }
                        """.data(using: .utf8)!
                        self.assertJSONDatasAreEqual(
                            a: headerData,
                            b: jwtParts[0].base64Decoded()!.data(using: .utf8)!
                        )
                        
                        struct JWTPayload: Decodable {
                            let iat: Int
                            let exp: Int
                            let aud: String
                            let iss: String
                        }
                        guard
                            let base64Decoded = (jwtParts[1] + "=").base64Decoded(), // Extra "=" was determined empirically
                            let payloadData = base64Decoded.data(using: .utf8),
                            let jwtPayload = try? JSONDecoder().decode(JWTPayload.self, from: payloadData)
                        else {
                            XCTFail()
                            return (respPayload, resp, nil)
                        }
                        XCTAssertEqual(jwtPayload.aud, reqURL)
                        XCTAssertEqual(jwtPayload.iss, reqEmail)
                        XCTAssertEqual(jwtPayload.exp - jwtPayload.iat, 3600)

                    default:
                        XCTFail("Unexpected part: \(subParts[0]), value: \(subParts[1])")
                }
            }
                        
            return (respPayload, resp, nil)
        }
        
        // Should not be authenticated to begin with
        XCTAssertNil(auth.authToken)
        XCTAssertTrue(auth.shouldAutoRefreshAccessToken)
        
        
        // Should successfully authenticate
        var exp = expectation(description: "testOAuth2.login")
        auth.refreshAccessToken { result in
            guard case .success = result else { XCTFail(); return }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(auth.shouldAutoRefreshAccessToken)
        XCTAssertNotNil(auth.authToken)
        XCTAssertGreaterThan(
            auth.authToken!.expirationDate.timeIntervalSince1970,
            Date().timeIntervalSince1970
        )
        XCTAssertEqual(auth.authToken?.token, "Bearer \(respAccessToken)")
        
        
        // Log out
        exp = expectation(description: "testOAuth2.logout")
        auth.logout { result in
            guard case .success = result else { XCTFail(); return }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        XCTAssertFalse(auth.shouldAutoRefreshAccessToken)
        XCTAssertNil(auth.authToken)
        
        // getActiveAccessToken should return .loggedOut
        exp = expectation(description: "testOAuth2.shouldBeLoggedOut")
        auth.getActiveAccessToken { result in
            guard case .failure(let err) = result, err.type == .loggedOut else { XCTFail(); return }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)


        // Log back in
        exp = expectation(description: "testOAuth2.logBackIn")
        auth.login { result in
            guard case .success = result else { XCTFail(); return }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(auth.shouldAutoRefreshAccessToken)
        XCTAssertNotNil(auth.authToken)
        XCTAssertGreaterThan(
            auth.authToken!.expirationDate.timeIntervalSince1970,
            Date().timeIntervalSince1970
        )
        XCTAssertEqual(auth.authToken?.token, "Bearer \(respAccessToken)")
    }
}

private extension String {
    func base64Decoded() -> String? {
        guard let decodedData = Data(base64Encoded: self) else { return nil }
        return String(data: decodedData, encoding: .utf8)
    }
}
