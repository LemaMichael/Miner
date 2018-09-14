//
//  RPCObject.swift
//  CocoaAsyncSocket
//
//  Created by Nick Lee on 10/9/17.
//

import Foundation
import ObjectMapper

class RPCObject: Mappable {
    
    // MARK: Properties
    
    private var jsonrpc = "2.0"
    
    // MARK: Initialization
    
    init() {}
    required init?(map: Map) {}
    
    // MARK: Mapping
    
    func mapping(map: Map) {
        jsonrpc <- map["jsonrpc"]
    }
    
}
