//
//  JWT.swift
//  DisruptiveAPI
//
//  Created by Geir Botterli on 30/08/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import CryptoKit
import Foundation

internal struct JWT {
    /// Produces a JWT token that is suitable for a Disruptive service account.
    /// Docs: https://support.disruptive-technologies.com/hc/en-us/articles/360011534099-Authentication
    internal static func serviceAccount(authURL: String, account: ServiceAccount) -> String? {
        let headers = [
            "alg": "HS256",
            "kid": account.key
        ]
        
        let now = Int(Date().timeIntervalSince1970)
        let claims: [String: Any] = [
            "iat": now,
            "exp": now + 3600,
            "aud": authURL,
            "iss": account.email
        ]
        
        return jwt(headers: headers, claims: claims, secret: account.secret)
    }
    
    /// Produces a JWT token for a given set of `headers`, `claims`, and a `secret`. No default
    /// values will be set, so all headers and claims must be present.
    /// Only supports the HMACSHA256 algorithm.
    private static func jwt(headers: [String: String], claims: [String: Any], secret: String) -> String? {
        guard let header  = jsonEncode(headers) else { return nil }
        guard let payload = jsonEncode(claims)  else { return nil }
    
        let signatureInput = header + "." + payload
        let key = SymmetricKey(data: secret.data(using: .utf8)!)
        let code = HMAC<SHA256>.authenticationCode(for: signatureInput.data(using: .utf8)!, using: key)
        
        return signatureInput + "." + base64Encode(Data(code))
    }
    
    /// Base64 encodes some `Data` to a JWT compatible `String`
    private static func base64Encode(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// JSON encodes and base64 encodes a `Dictionary` to a JWT compatible `String`
    private static func jsonEncode(_ input: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: input) else { return nil }
        return base64Encode(data)
    }
}
