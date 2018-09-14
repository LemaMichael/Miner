//
//  RPCNotification.swift
//  XMRMiner
//
//  Created by Nick Lee on 10/12/17.
//

import Foundation
import ObjectMapper

final class RPCNotification: RPCObject {
    
    // MARK: Properties
    
    var method: String = ""
    var params: Any = [:]
    
    // MARK: Initialization
    
    init(method: String, id: Int, params: Any) {
        self.method = method
        self.params = params
        super.init()
    }
    
    required init?(map: Map) {
        super.init(map: map)
    }
    
    // MARK: Mapping
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        method <- map["method"]
        params <- map["params"]
    }

}
