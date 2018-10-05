//
//  PrefViewController.swift
//  Miner
//
//  Created by Michael Lema on 9/15/18.
//  Copyright © 2018 Michael Lema. All rights reserved.
//

import Cocoa

protocol PreferencesWindowDelegate {
    func toggleStartAtLogin(_ start:Bool)
}

class PrefViewController: NSViewController {
    
    @IBOutlet weak var moneroAddressTF: NSTextField!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var launchAtLoginBtn: NSButton!
    @IBOutlet weak var instructionText: NSTextField!
    var delegate: PreferencesWindowDelegate?


    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSApp.activate(ignoringOtherApps: true)

        textField.delegate = self
        textField.placeholderString = UserDefaults.standard.getAddress()
        
        launchAtLoginBtn.state = NSControl.StateValue(rawValue: 1)
        if let mutableAttributedTitle = launchAtLoginBtn.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: NSColor.white, range: NSRange(location: 0, length: mutableAttributedTitle.length))
            launchAtLoginBtn.attributedTitle = mutableAttributedTitle
        }
        
        if let mutableTitle = moneroAddressTF.attributedStringValue.mutableCopy() as? NSMutableAttributedString {
            mutableTitle.addAttribute(.foregroundColor, value: NSColor.white, range: NSRange(location: 0, length: mutableTitle.length))
            moneroAddressTF.attributedStringValue = mutableTitle
        }
    
    }
    
    @IBAction func launchAtLoginBtnClicked(_ sender: NSButton) {
        var isOn:Bool = false
        if sender.state == .off {
            isOn = false
        } else if sender.state == .on {
            isOn = true
        }
        Foundation.UserDefaults.standard.set(isOn, forKey: UserDefaults.UserDefaultKeys.launchFromStart.rawValue)
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
