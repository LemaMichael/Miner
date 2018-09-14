//
//  Client.swift
//  CPJSONRPC
//
//  Created by Nick Lee on 10/9/17.
//

import Foundation
import CocoaAsyncSocket
import ObjectMapper
import NSData_FastHex

protocol ClientDelegate: class {
    func client(_ client: Client, receivedJob: Job)
}

final class Client {
    
    // MARK: Types
    
    fileprivate struct Constants {
        struct Tags {
            static let sendRequest = 1
            static let readJSON = 2
        }
        static let terminator = Data(bytes: [0x0A])
    }
    
    // MARK: Properties
    
    weak var delegate: ClientDelegate?
    let url: URL
    
    // MARK: Private Properties
    
    private var socket: GCDAsyncSocket!
    private let socketDelegate = ClientStreamDelegate()
    
    // MARK: Initialization
    
    init(url u: URL) {
        url = u
        socketDelegate.client = self
        socket = GCDAsyncSocket(delegate: socketDelegate, delegateQueue: .main)
    }
    
    // MARK: Network
    
    func connect() throws {
        guard socket.isDisconnected else {
            return
        }
        try socket.connect(toHost: url.host ?? "", onPort: UInt16(url.port ?? 3333))
    }
    
    func disconnect() {
        guard socket.isConnected else {
            return
        }
        socket.disconnect()
    }
    
    // MARK: Jobs
    
    func submitJob(id: String, jobID: String, result: Data, nonce: Job.Nonce) throws {
        var nonceData = Data(count:  MemoryLayout<Job.Nonce>.size)
        nonceData.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<Job.Nonce>) -> Void in
            ptr.pointee = nonce
        }
        try send(method: "submit", id: 1, params: [
            "id": id,
            "job_id": jobID,
            "result": (result as NSData).hexStringRepresentationUppercase(false),
            "nonce": (nonceData as NSData).hexStringRepresentationUppercase(false)
            ])
    }
    
}

extension Client {
    fileprivate func login() throws {
        try send(method: "login", id: 1, params: [
            "login": url.user ?? "",
            "pass": url.password ?? ""
            ])
    }
    
    private func send(method: String, id: Int, params: Any) throws {
        let message = RPCRequest(method: method, id: id, params: params)
        guard let json = Mapper().toJSONString(message), let jsonData = json.data(using: .utf8) else {
            throw MiningError.commandSerializationFailed
        }
        let terminatedData = jsonData + Constants.terminator
        socket.write(terminatedData, withTimeout: 30, tag: Constants.Tags.sendRequest)
    }
    
    fileprivate func receive() {
        socket.readData(to: Client.Constants.terminator, withTimeout: -1, tag: Client.Constants.Tags.readJSON)
    }
}

extension Client {
    fileprivate func socketConnected() {
        try! login()
    }
    
    fileprivate func didReceive(response: Data) {
        guard let json = (try? JSONSerialization.jsonObject(with: response, options: [])) as? [String : Any] else {
            return
        }
        
        if json.keys.contains("result"), let response = Mapper<RPCResponse>().map(JSON: json) { // JSON-RPC Response
            switch response.result {
            case .success(let result):
                if let resultDict = result as? [String : Any], let jobJson = resultDict["job"], let job = Mapper<Job>().map(JSONObject: jobJson) { // JOB Response
                    delegate?.client(self, receivedJob: job)
                }
            default:
                break
            }
        }
        else if let method = json["method"] as? String, let notification = Mapper<RPCNotification>().map(JSONObject: json) { // JSON-RPC Notification
            if method == "job", let job = Mapper<Job>().map(JSONObject: notification.params) {
                delegate?.client(self, receivedJob: job)
            }
        }
    }
}

@objc private final class ClientStreamDelegate: NSObject, GCDAsyncSocketDelegate {
    weak var client: Client?
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        client?.socketConnected()
        client?.receive()
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        if err != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                do {
                    try self.client?.connect()
                }
                catch {}
            }
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        switch tag {
        case Client.Constants.Tags.readJSON:
            client?.didReceive(response: data)
            client?.receive()
        default:
            break
        }
    }
}
