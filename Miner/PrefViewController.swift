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
    
    
    @IBOutlet weak var moneroAddressTF: NSTextField!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var launchAtLoginBtn: NSButton!
    @IBOutlet weak var instructionText: NSTextField!
    
    var prefs = Preferences()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSApp.activate(ignoringOtherApps: true)

        textField.delegate = self
        textField.placeholderString = UserDefaults.standard.getAddress()
        
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

extension PrefViewController: NSTextFieldDelegate {
    
    //:https://getmonero.org/resources/moneropedia/address.html
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            instructionText.isHidden = true

            let wrongFirstInput = "A Monero address begins with '4'"
            let defaultOutput = "Monero Address"
            
            let input = textField.stringValue
            
            if input.first == "4" {
                moneroAddressTF.stringValue = defaultOutput
            } else {
                moneroAddressTF.stringValue = wrongFirstInput
                return
            }
            
            if input.count == 95 {
                moneroAddressTF.stringValue = "Successfully changed address!"
                instructionText.isHidden = false
                UserDefaults.standard.setAddress(value: input)
            } else if input.count > 95 {
                moneroAddressTF.stringValue = "Address is too long."
            }
            
        }
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
