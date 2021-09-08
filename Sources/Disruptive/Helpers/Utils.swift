//
//  Utils.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 24/05/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation


// -------------------------------
// MARK: Date <-> String
// -------------------------------

internal extension Date {
    func iso8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
    
    init(iso8601String: String) throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso8601String) {
            self = date
        } else {
            throw ParseError.dateFormat(date: "Failed to parse ISO 8601 string: \(iso8601String)")
        }
    }
}




// -------------------------------
// MARK: Celsius <-> Fahrenheit
// -------------------------------

internal func celsiusToFahrenheit(celsius: Float) -> Float {
    return (celsius * 9/5) + 32
}

internal func fahrenheitToCelsius(fahrenheit: Float) -> Float {
    return (fahrenheit - 32) * 5/9
}
