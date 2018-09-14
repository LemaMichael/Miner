//
//  RPCRequest.swift
//  CocoaAsyncSocket
//
//  Created by Nick Lee on 10/9/17.
//

import Foundation
import ObjectMapper

final class RPCRequest: RPCObject {

    // MARK: Properties
    
    var method: String = ""
    var id: Int = 0
    var params: Any = [:]
    
    // MARK: Initialization
    
    init(method: String, id: Int, params: Any) {
        self.method = method
        self.id = id
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
        id <- map["id"]
        params <- map["params"]
    }

}
