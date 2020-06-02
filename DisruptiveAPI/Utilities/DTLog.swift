//
//  DTLog.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

internal func DTLog(
    _ message   : Any      = "",
    isError     : Bool     = false,
    filePath    : String   = #file,
    functionName: String   = #function,
    lineNumber  : Int      = #line)
{
    if Disruptive.loggingEnabled {
        print("Disruptive API -- \(message)")
    }
}
