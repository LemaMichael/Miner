//
//  PrefViewController.swift
//  Miner
//
//  Created by Michael Lema on 9/15/18.
//  Copyright © 2018 Michael Lema. All rights reserved.
//

import Cocoa
import LaunchAtLogin

class PrefViewController: NSViewController {
    
    @IBOutlet weak var launchAtLoginBtn: NSButton!
    var prefs = Preferences()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSApp.activate(ignoringOtherApps: true)
        launchAtLoginBtn.state = NSControl.StateValue(rawValue: prefs.launchAtLogin.intValue)
        if let mutableAttributedTitle = launchAtLoginBtn.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: NSColor.white, range: NSRange(location: 0, length: mutableAttributedTitle.length))
            launchAtLoginBtn.attributedTitle = mutableAttributedTitle
        }

    }
    
    @IBAction func launchAtLoginBtnClicked(_ sender: Any) {
        let state = launchAtLoginBtn.state.rawValue.boolValue
        LaunchAtLogin.isEnabled = state
        prefs.launchAtLogin = state
    }
}

extension Int {
    var boolValue: Bool { return self != 0 }
}

extension Bool {
    var intValue: Int { return self == false ? 0 : 1 }
}

struct Preferences {
    let defaults = UserDefaults.standard
    var launchAtLogin: Bool {
        get {
            return defaults.bool(forKey: "launchAtLogin")
        }
        set {
            defaults.set(newValue, forKey: "launchAtLogin")
        }
    }
}
