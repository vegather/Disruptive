//
//  Logger.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 23/05/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

/**
 Provides a nicely formatted log output with the file, function, and line number the
 log statement came from. Also includes a timestamp with millisecond accuracy.
 
 Here are some examples of the output format:
 ```txt
 2021-01-11 02:01:28.084    l:122   Authentication.swift   getActiveAccessToken(comple...   Authentication successful
 2021-01-11 02:04:32.512    l:94    main.swift             main()                           Fetched 28 devices
 2021-01-11 02:04:31.506    l:108   main.swift             main()                           🐛 This is a debug log
 2021-01-11 02:04:31.507    l:109   main.swift             main()                           ⚠️ This is a warning
 2021-01-11 02:04:31.507    l:110   main.swift             main()                           ❌ This is an error
 ```
 
 - Parameter message: The thing that should be log. This will be converted to a `String` like this: `String(describing: message)`
 - Parameter level: The severity of the log. Will be used as a prefix before `message`. The default is `.info` (no prefix).
 - Parameter filePath: Should be left as-is to get the correct file path.
 - Parameter functionName: Should be left as-is to get the correct function name.
 - Parameter lineNumber: Should be left as-is to get the correct line number.
 */
public func log(
    _ message   : Any      = "",
    prefix      : String,
    filePath    : String   = #file,
    functionName: String   = #function,
    lineNumber  : Int      = #line)
{
    let fileNameWidth = 20
    let functionNameWidth = 30
    let lineNumberWidth = 7
    
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


internal struct Logger {
    
    /// Used for debug logging. Will only print if `Disruptive.loggingLevel`
    /// is set to `.debug`.
    static func debug(
        _ message   : Any      = "",
        filePath    : String   = #file,
        functionName: String   = #function,
        lineNumber  : Int      = #line)
    {
        guard shouldLog(level: .debug) else { return }
        
        log(
            message,
            prefix       : "🐛 ",
            filePath     : filePath,
            functionName : functionName,
            lineNumber   : lineNumber
        )
    }
    
    /// Used for informational logging. Will only print if `Disruptive.loggingLevel`
    /// is set to `.info` or `.debug`.
    static func info(
        _ message   : Any      = "",
        filePath    : String   = #file,
        functionName: String   = #function,
        lineNumber  : Int      = #line)
    {
        guard shouldLog(level: .info) else { return }
        
        log(
            message,
            prefix       : "",
            filePath     : filePath,
            functionName : functionName,
            lineNumber   : lineNumber
        )
    }
    
    /// Used for warning logging. Will only print if `Disruptive.loggingLevel`
    /// is set to `.warning`, `.info`, or `.debug`.
    static func warning(
        _ message   : Any      = "",
        filePath    : String   = #file,
        functionName: String   = #function,
        lineNumber  : Int      = #line)
    {
        guard shouldLog(level: .warning) else { return }
        
        log(
            message,
            prefix       : "⚠️ ",
            filePath     : filePath,
            functionName : functionName,
            lineNumber   : lineNumber
        )
    }
    
    /// Used for error logging. Will only print if `Disruptive.loggingLevel`
    /// is set to `.error`, `.warning`, `.info`, or `.debug`.
    static func error(
        _ message   : Any      = "",
        filePath    : String   = #file,
        functionName: String   = #function,
        lineNumber  : Int      = #line)
    {
        guard shouldLog(level: .error) else { return }
        
        log(
            message,
            prefix       : "❌ ",
            filePath     : filePath,
            functionName : functionName,
            lineNumber   : lineNumber
        )
    }
    
    private static func shouldLog(level: Config.LoggingLevel) -> Bool {
        return Config.loggingLevel.rawValue >= level.rawValue
    }
}
