//
//  Utils.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 24/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation
import Accelerate

// -------------------------------
// MARK: Data -> String
// -------------------------------

public extension Data {
    enum HexFormat {
        /// <0x00, 0x01, 0x02, 0x03, 0x04, 0x05>
        case byteByByte
        /// <00010203 0405>
        case fourBytesAtATime
    }
    
    func hexString(format: HexFormat = .fourBytesAtATime) -> String {
        switch format {
        case .byteByByte:
            let byteStrings = map { "0x" + String(format: "%02x", $0).uppercased() }
            return "<" + byteStrings.joined(separator: ", ") + ">"
        case .fourBytesAtATime:
            var bytes = map { String(format: "%02x", $0).uppercased() }
            stride(from: 4, to: count, by: 4).reversed().forEach {
                bytes.insert(" ", at: $0)
            }
            return "<" + bytes.joined() + ">"
        }
    }
    
    func binaryString() -> String {
        return map({ byte in
            (0...7).reduce("", { String((byte & (1 << $1)) >> $1) + $0})
        }).joined(separator: " ")
    }
}



// -------------------------------
// MARK: DSP
// -------------------------------

/// Adds hardware accelerated functions to Array when the element is Float
extension Array where Element == Float {

    /// Calculates the mean of an array of Floats using Accelerate
    func mean() -> Float {
        var value: Float = 0
        vDSP_meanv(self, vDSP_Stride(1), &value, vDSP_Length(count))
        return value.isNaN ? 0 : value
    }

    /// Calculates the median of an array of Floats using Accelerate
    func median() -> Float {
        guard count > 0 else { return 0 }
        guard count > 1 else { return first! }
        
        var input = self
        vDSP_vsort(&input, vDSP_Length(count), 1)
        
        let midIndex = Int(floor(Double(count)/2))
        if count % 2 == 0 {
            return (input[midIndex-1] + input[midIndex]) / 2
        } else {
            return input[midIndex]
        }
    }

}

