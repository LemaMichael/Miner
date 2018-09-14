//
//  Job.swift
//  XMRMiner
//
//  Created by Nick Lee on 10/9/17.
//

import Foundation
import ObjectMapper
import NSData_FastHex

class Job: Mappable {
    
    // MARK: Types
    
    typealias Nonce = UInt32
    
    // MARK: Properties
    
    private(set) var id = ""
    private(set) var jobID = ""
    private(set) var blob = Data()
    private(set) var target: UInt64 = 0
    
    var nonce: Nonce {
        get {
            let start = 39
            let sd = blob.subdata(in: start ..< start + MemoryLayout<Nonce>.size)
            let v = sd.withUnsafeBytes { (a: UnsafePointer<Nonce>) -> Nonce in a.pointee }
            return v.littleEndian
        }
        set {
            let start = 39
            let range: Range<Data.Index> = start ..< start + MemoryLayout<Nonce>.size
            var newBytes = blob.subdata(in: range)
            newBytes.withUnsafeMutableBytes { (a: UnsafeMutablePointer<Nonce>) -> Void in
                a.pointee = newValue.littleEndian
            }
            blob.replaceSubrange(range, with: newBytes)
        }
    }
    
    // MARK: Initialization
    
    required init?(map: Map) {}
    
    // MARK: Mapping
    
    func mapping(map: Map) {
        var blobStr = ""
        blobStr <- map["blob"]
        blob = NSData(hexString: blobStr) as Data
        
        var targetStr = ""
        targetStr <- map["target"]
        let targetLength = targetStr.characters.count
        let targetData = NSData(hexString: targetStr) as Data
        if targetLength <= 8 {
            target = targetData.withUnsafeBytes { (ptr: UnsafePointer<UInt32>) -> UInt64 in
               return 0xFFFFFFFFFFFFFFFF / (0xFFFFFFFF / UInt64(ptr.pointee))
            }
        }
        else if targetLength <= 16 {
            target = targetData.withUnsafeBytes { (ptr: UnsafePointer<UInt64>) -> UInt64 in
                return ptr.pointee
            }
        }
        
        id <- map["id"]
        jobID <- map["job_id"]
    }
    
    // MARK: Target Test
    
    func evaluate(hash result: Data) -> Bool {
        let start = 24
        let sd = result.subdata(in: start ..< start + MemoryLayout<UInt64>.size)
        let v = sd.withUnsafeBytes { (a: UnsafePointer<UInt64>) -> UInt64 in a.pointee }
        return v < target
    }
    
}
