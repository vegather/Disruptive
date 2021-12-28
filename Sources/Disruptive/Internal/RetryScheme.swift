//
//  RetryScheme.swift
//  Disruptive
//
//  Created by Vegard Solheim Theriault on 02/07/2020.
//  Copyright © 2021 Disruptive Technologies Research AS. All rights reserved.
//

import Foundation

internal protocol RetryScheme {
    /// Returns how many seconds to wait until the next retry.
    /// Returns `nil` if no more retries should be attempted.
    mutating func nextBackoff() -> TimeInterval?
    
    /// Resets the the retry-scheme to its initial state.
    mutating func reset()
}

internal struct ExponentialBackoffScheme: RetryScheme {
    
    private var retries = 0
    private let maxRetries: Int?
    private let initialBackoff: TimeInterval
    private let timeIntervals: [TimeInterval] = [0, 0.3, 1, 3, 5, 7, 11, 15]
    
    init(initialBackoff: TimeInterval = 0, maxRetries: Int? = nil) {
        self.initialBackoff = initialBackoff
        self.maxRetries = maxRetries
    }
    
    mutating func nextBackoff() -> TimeInterval? {
        if let maxRetries = maxRetries, retries >= maxRetries {
            return nil
        }
        
        defer {
            retries += 1
        }
        
        let index = min(retries, timeIntervals.count - 1)
        return initialBackoff + timeIntervals[index]
    }
    
    mutating func reset() {
        retries = 0
    }
}
