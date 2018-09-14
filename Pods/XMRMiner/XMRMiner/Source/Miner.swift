//
//  Miner.swift
//  CocoaAsyncSocket
//
//  Created by Nick Lee on 10/9/17.
//

import Foundation
import NSData_FastHex

public protocol MinerDelegate: class {
    func miner(updatedStats stats: MinerStats)
}

public final class Miner {
    
    // MARK: Public Properties
    
    public weak var delegate: MinerDelegate?
    
    // MARK: Internal Properties
    
    let client: Client
    
    let jobSemaphore = DispatchSemaphore(value: 1)
    var job: Job?
    
    var threads: [Thread] = []
    
    let statsSemaphore = DispatchSemaphore(value: 1)
    var stats = MinerStats()
    
    public init(host: String = "pool.supportxmr.com", port: Int = 3333, destinationAddress: String, clientIdentifier: String = "\(arc4random())") {
        let url: URL = {
            var components = URLComponents()
            components.scheme = "stratum+tcp"
            components.user = destinationAddress
            components.password = clientIdentifier
            components.host = host
            components.port = port
            return components.url!
        }()
        client = Client(url: url)
        client.delegate = self
    }
    
    deinit {
        stop()
    }
    
    public func start(threadLimit: Int = ProcessInfo.processInfo.activeProcessorCount) throws {
        try client.connect()
        let threadCount = max(min(ProcessInfo.processInfo.activeProcessorCount, threadLimit), 1)
        for i in 0 ..< threadCount {
            let t = Thread(block: mine)
            t.name = "Mining Thread \(i+1)"
            t.qualityOfService = .userInitiated
            t.start()
        }
    }
    
    public func stop() {
        threads.forEach { $0.cancel() }
        threads = []
        client.disconnect()
    }
}

extension Miner: ClientDelegate {
    func client(_ client: Client, receivedJob: Job) {
        jobSemaphore.wait()
        job = receivedJob
        jobSemaphore.signal()
    }
}

extension Miner {
    
    fileprivate func mine() {
        
        let hasher = HashContext()
        
        while !Thread.current.isCancelled {
            autoreleasepool {
                hash(with: hasher)
            }
        }
        
    }
    
    private func hash(with hasher: HashContext) {
        jobSemaphore.wait()
        guard let job = job else {
            jobSemaphore.signal()
            return
        }
        job.nonce += 1
        let blob = job.blob
        let currentNonce = job.nonce
        jobSemaphore.signal()
        
        let result = hasher.hashData(blob)
        
        statsSemaphore.wait()
        stats.hashes += 1
        let now = Date()
        if (now.timeIntervalSince(stats.lastDate) >= 0.1) {
            let s = self.stats
            DispatchQueue.main.async {
                self.delegate?.miner(updatedStats: s)
            }
            stats.lastDate = now
            stats.hashes = 0
        }
        statsSemaphore.signal()
        
        if job.evaluate(hash: result) {
            DispatchQueue.main.async {
                do {
                    try self.client.submitJob(id: job.id, jobID: job.jobID, result: result, nonce: currentNonce)
                }
                catch {}
            }
            statsSemaphore.wait()
            stats.submittedHashes += 1
            DispatchQueue.main.async {
                self.delegate?.miner(updatedStats: self.stats)
            }
            statsSemaphore.signal()
        }
    }
}

