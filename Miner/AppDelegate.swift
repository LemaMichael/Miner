//
//  AppDelegate.swift
//  Miner
//
//  Created by Michael Lema on 9/14/18.
//  Copyright © 2018 Michael Lema. All rights reserved.
//

import Cocoa
import XMRMiner

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MinerDelegate {
    
    let miner = Miner(destinationAddress: "45ZvUbU9EYnKiJMUJ4DfkkEe3iVjUNgxUAtoJ1ENgA27LCcuMwYjcvb4daZhfQXctHJfmoAcJXwP16cjvHAuDVfv54Wtzbz")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        miner.delegate = self
        do {
            try miner.start()
        }
        catch {
            print("something bad happened")
        }
    }
    
    func miner(updatedStats stats: MinerStats) {
       print("\(stats.hashRate) H/s")
        print("\(stats.submittedHashes)")
    }
    

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        miner.stop()
    }
    
}

