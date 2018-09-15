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
    
    var currentVal: UInt = 0
    let miner = Miner(destinationAddress: "45ZvUbU9EYnKiJMUJ4DfkkEe3iVjUNgxUAtoJ1ENgA27LCcuMwYjcvb4daZhfQXctHJfmoAcJXwP16cjvHAuDVfv54Wtzbz")
    var isMining = false
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var hashRate: NSMenuItem!
    @IBOutlet weak var submittedHashes: NSMenuItem!
    @IBOutlet weak var totalSubmittedHeading: NSMenuItem!
    @IBOutlet weak var totalSubmitted: NSMenuItem!
    
    @IBAction func miningClicked(_ sender: NSMenuItem) {
        if isMining {
            miner.stop()
            isMining = false
            sender.title = "Start Mining"
        } else {
            startMining()
            sender.title = "Stop Mining"
        }
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        miner.stop()
        NSApplication.shared.terminate(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupMiner()
        
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        totalSubmittedHeading.title = "Total Hashes since: \(UserDefaults.standard.getLaunchDate())"
    }
    
    fileprivate func setupMiner() {
        miner.delegate = self
        startMining()
    }
    
    fileprivate func startMining() {
        do {
            try miner.start()
            isMining = true
        }
        catch {
            isMining = false
            print("something bad happened")
        }
    }
}

extension StatusMenuController: MinerDelegate {
    func miner(updatedStats stats: MinerStats) {
        print(stats.hashRate)
        print(stats.submittedHashes)
        
        let currentHashed = UserDefaults.standard.getTotalHashes()
        if currentVal != stats.submittedHashes {
            UserDefaults.standard.setTotalHashes(value: currentHashed + 1)
            currentVal = stats.submittedHashes
        }
        
        hashRate.title = String(format: "Hash Rate: %.2f H/s", stats.hashRate)
        submittedHashes.title = "Submitted Hashes: \(stats.submittedHashes) H/s"
        totalSubmitted.title = "\(currentHashed) H/s"
    }
}

