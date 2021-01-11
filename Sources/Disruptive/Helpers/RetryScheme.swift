//
//  RetryScheme.swift
//  DisruptiveAPI
//
//  Created by Vegard Solheim Theriault on 02/07/2020.
//  Copyright © 2020 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

internal struct RetryScheme {
    
    private var index: Int?
    private let timeIntervals = [TimeInterval(0.1), 1, 3, 5, 7, 11, 15]
    
    var backoffInterval: TimeInterval {
        return timeIntervals[index ?? 0]
    }
    
    mutating func nextBackoff() -> TimeInterval {
        if let index = index {
            if index < timeIntervals.count - 1 {
                self.index = index + 1
            }
        } else {
            index = 0
        }
        
        return backoffInterval
    }
    
    mutating func reset() {
        index = nil
    }
}
