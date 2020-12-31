//
//  Diagnostics.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 30/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

internal struct RequestDiagnostics {
    private let request      : Request
    private var networkStart : CFAbsoluteTime?
    private var networkEnd   : CFAbsoluteTime?
    private var parseStart   : CFAbsoluteTime?
    private var parseEnd     : CFAbsoluteTime?
    
    init(request: Request) {
        self.request = request
    }
    
    mutating func setNetworkStart() {
        networkStart = CFAbsoluteTimeGetCurrent()
    }
    
    mutating func setNetworkEnd() {
        networkEnd = CFAbsoluteTimeGetCurrent()
    }
    
    mutating func setParseStart() {
        parseStart = CFAbsoluteTimeGetCurrent()
    }
    
    mutating func setParseEnd() {
        parseEnd = CFAbsoluteTimeGetCurrent()
    }
    
    func logDiagnostics(responseData: Data?) {
        guard let networkStart = networkStart else { return }
        guard let networkEnd   = networkEnd   else { return }
        
        let networkDuration = String(format: "%.2f ms", (networkEnd - networkStart) * 1000)
        var str = "Finished request to \(request.endpoint) in \(networkDuration). "
        
        if let parseStart = parseStart, let parseEnd = parseEnd {
            var byteCount = 0
            if let data = responseData {
                byteCount = data.count
            }
            let parseDuration = String(format: "%.2f ms", (parseEnd - parseStart) * 1000)
            
            str += "Parsed \(byteCount) bytes in \(parseDuration)"
        }
        
        Disruptive.log(str, level: .debug)
    }
}
