//
//  AppDelegate.swift
//  Helper
//
//  Created by Michael Lema on 10/4/18.
//  Copyright © 2018 Michael Lema. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainAppIdentifier = "com.lema.Miner.Monero"
        let running = NSWorkspace.shared.runningApplications
        var alreadyRunning = false
        
        for app in running {
            if app.bundleIdentifier == mainAppIdentifier {
                alreadyRunning = true
                break
            }
        }
        
        if alreadyRunning == false {
            DistributedNotificationCenter.default().addObserver(self,
                                                                selector: #selector(AppDelegate.terminate),
                                                                name: NSNotification.Name(rawValue: "killme"),
                                                                object: mainAppIdentifier,
                                                                suspensionBehavior: .drop)
            
            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("Miner") //main app name
            
            let newPath = NSString.path(withComponents: components)
            
            NSWorkspace.shared.launchApplication(newPath)
        }
        else {
            self.terminate()
        }
    }
    
    @objc func terminate() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

