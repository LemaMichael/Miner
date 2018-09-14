//
//  StatusMenuController.swift
//  Miner
//
//  Created by Michael Lema on 9/14/18.
//  Copyright © 2018 Michael Lema. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
    }
}
