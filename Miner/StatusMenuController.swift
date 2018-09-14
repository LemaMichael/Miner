//
//  StatusMenuController.swift
//  Miner
//
//  Created by Michael Lema on 9/14/18.
//  Copyright © 2018 Michael Lema. All rights reserved.
//

import Cocoa
import XMRMiner

class StatusMenuController: NSObject {
    
    let miner = Miner(destinationAddress: "45ZvUbU9EYnKiJMUJ4DfkkEe3iVjUNgxUAtoJ1ENgA27LCcuMwYjcvb4daZhfQXctHJfmoAcJXwP16cjvHAuDVfv54Wtzbz")

    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        extractedFunc()
        
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
    }
    
    fileprivate func extractedFunc() {
        miner.delegate = self
        do {
            try miner.start()
        }
        catch {
            print("something bad happened")
        }
    }
}

extension StatusMenuController: MinerDelegate {
    func miner(updatedStats stats: MinerStats) {
        print("\(stats.hashRate) H/s")
        print("\(stats.submittedHashes)")
    }
}

