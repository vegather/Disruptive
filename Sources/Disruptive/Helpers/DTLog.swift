//
//  DTLog.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

public enum LogLevel {
    case debug
    case info
    case warning
    case error
}

public func DTLog(
    _ message   : Any      = "",
    level       : LogLevel = .info,
    filePath    : String   = #file,
    functionName: String   = #function,
    lineNumber  : Int      = #line)
{
    let fileNameWidth = 20
    let functionNameWidth = 30
    let lineNumberWidth = 7
    
    let prefix: String
    switch level {
        case .debug   : prefix = "🐛 "
        case .info    : prefix = ""
        case .warning : prefix = "⚠️ "
        case .error   : prefix = "❌ "
    }
    
    var printString = ""
    
    // Going with this ANSI C solution here because it's about 1.5x
    // faster than the standard NSDateFormatter alternative.
    let bufferSize = 32
    var buffer = [Int8](repeating: 0, count: bufferSize)
    var timeValue = time(nil)
    let tmValue = localtime(&timeValue)
    
    strftime(&buffer, bufferSize, "%Y-%m-%d %H:%M:%S", tmValue)
    if let dateFormat = String(cString: buffer, encoding: .utf8) {
        var timeForMilliseconds = timeval()
        gettimeofday(&timeForMilliseconds, nil)
        let timeSince1970 = Date().timeIntervalSince1970
        let seconds = floor(timeSince1970)
        let thousands = UInt(floor((timeSince1970 - seconds) * 1000.0))
        let milliseconds = String(format: "%03u", arguments: [thousands])
        printString = dateFormat + "." + milliseconds + "    "
    }
    
    let lineNumberStr = String("l:\(lineNumber)").padding(toLength: lineNumberWidth,
                                                          withPad: " ",
                                                          startingAt: 0)
    
    // Limiting file name string length
    var fileNameStr = (filePath as NSString).lastPathComponent
    if fileNameStr.count <= fileNameWidth {
        fileNameStr = fileNameStr.padding(toLength: fileNameWidth, withPad: " ", startingAt: 0)
    } else {
        let upperIndex = fileNameStr.index(fileNameStr.startIndex, offsetBy: fileNameWidth - 3)
        fileNameStr = String(fileNameStr[..<upperIndex]) + "..."
    }
    
    // Limiting method name string length
    var functionNameStr = functionName
    if functionNameStr.count <= functionNameWidth {
        functionNameStr = functionName.padding(toLength: functionNameWidth, withPad: " ", startingAt: 0)
    } else {
        let upperIndex = functionNameStr.index(functionNameStr.startIndex, offsetBy: functionNameWidth - 3)
        functionNameStr = String(functionNameStr[..<upperIndex]) + "..."
    }
    
    // Construct the message to be printed
    printString += lineNumberStr   + " "
    printString += fileNameStr     + "   "
    printString += functionNameStr + "   "
    printString += prefix
    printString += String(describing: message)
    
    print(printString)
}


internal extension Disruptive {
    
    /// Used for internal logging. Lets the `DTLog` global function be public while
    /// respecting the `Disruptive.loggingEnabled` flag only for internal logging.
    static func log(
        _ message   : Any      = "",
        level       : LogLevel = .info,
        filePath    : String   = #file,
        functionName: String   = #function,
        lineNumber  : Int      = #line)
    {
        guard Disruptive.loggingEnabled else { return }
        
        DTLog(
            message,
            level        : level,
            filePath     : filePath,
            functionName : functionName,
            lineNumber   : lineNumber
        )
    }
}
