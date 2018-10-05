//
//  StatusMenuController.swift
//  Miner
//
//  Created by Michael Lema on 9/14/18.
//  Copyright © 2018 Michael Lema. All rights reserved.
//

import Cocoa
import XMRMiner
import ServiceManagement
import AppKit


class StatusMenuController: NSObject, PreferencesWindowDelegate {
    
    var currentVal: UInt = 0
    let miner = Miner(destinationAddress: UserDefaults.standard.getAddress())
    var isMining = false
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let defaults = Foundation.UserDefaults.standard
    var preferencesControl: PrefViewController!


    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var hashRate: NSMenuItem!
    @IBOutlet weak var submittedHashes: NSMenuItem!
    @IBOutlet weak var totalSubmittedHeading: NSMenuItem!
    @IBOutlet weak var totalSubmitted: NSMenuItem!
    
    @IBAction func preferencesClicked(_ sender: Any) {
        
        if NSApplication.shared.windows.count > 1 {
            return
        }

        let prefController = NSStoryboard(name: "Preferences",bundle: nil).instantiateController(withIdentifier: "PreferencesController")  as! NSWindowController
        prefController.showWindow(self)
    }
    
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
        
        totalSubmittedHeading.title = "Since \(UserDefaults.standard.getLaunchDate())"
        totalSubmitted.title = "\(UserDefaults.standard.getTotalHashes()) H/s"
        preferencesControl = PrefViewController()
        preferencesControl.delegate = self
    }
    
    fileprivate func setupMiner() {
        miner.delegate = self
        startMining()
        
        var startAtLogin = false
        if defaults.object(forKey: UserDefaults.UserDefaultKeys.launchFromStart.rawValue) == nil {
            startAtLogin = true
            defaults.set(true, forKey: UserDefaults.UserDefaultKeys.launchFromStart.rawValue)
        } else {
            startAtLogin = defaults.bool(forKey: UserDefaults.UserDefaultKeys.launchFromStart.rawValue)
        }
        toggleStartAtLogin(startAtLogin)
    }
    
    //MARK: Login
    func toggleStartAtLogin(_ start:Bool) {
        let launcherAppIdentifier = "com.lema.Miner.Monero"
        SMLoginItemSetEnabled(launcherAppIdentifier as CFString, start)
        var startedAtLogin = false
        for app in NSWorkspace.shared.runningApplications {
            if app.bundleIdentifier == launcherAppIdentifier {
                startedAtLogin = true
            }
        }
        if startedAtLogin == true {
            DistributedNotificationCenter.default().postNotificationName(NSNotification.Name(rawValue: "killme"),
                                                                         object: Bundle.main.bundleIdentifier!,
                                                                         userInfo: nil,
                                                                         deliverImmediately: true)
        }
        
        defaults.set(start, forKey: UserDefaults.UserDefaultKeys.launchFromStart.rawValue)
        defaults.synchronize()
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

