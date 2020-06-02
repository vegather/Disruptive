//
//  Utils.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 24/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

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
