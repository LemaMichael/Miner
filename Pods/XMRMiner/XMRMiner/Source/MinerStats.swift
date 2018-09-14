//
//  HashStats.swift
//  XMRMiner
//
//  Created by Nick Lee on 10/16/17.
//

import Foundation

public struct MinerStats {
    
    // MARK: Public Properties
    
    public internal(set) var hashes: UInt = 0
    public internal(set) var submittedHashes: UInt = 0
    
    public var hashRate: Double {
        let interval = Date().timeIntervalSince(lastDate)
        return TimeInterval(hashes) / interval
    }
    
    // MARK: Internal Properties
    
    var lastDate = Date()
    
    // MARK Initialization
    
    init() {}
    
}
