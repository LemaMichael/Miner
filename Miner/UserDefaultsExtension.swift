//
//  UserDefaultsExtension.swift
//  Miner
//
//  Created by Michael Lema on 9/14/18.
//  Copyright © 2018 Michael Lema. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum UserDefaultKeys: String {
        case launchDate
        case hasLaunchedBefore
        case hashesSubmitted
    }
    
    func setTotalHashes(value: Int) {
        set(value, forKey: UserDefaultKeys.hashesSubmitted.rawValue)
        synchronize()
    }
    func getTotalHashes() -> Int {
        return integer(forKey: UserDefaultKeys.hashesSubmitted.rawValue)
    }
    
    func setLaunchedBefore(value: Bool) {
        set(Date(), forKey: UserDefaultKeys.launchDate.rawValue)
        set(value, forKey: UserDefaultKeys.hasLaunchedBefore.rawValue)
        synchronize()
    }
    func hasLaunchedBefore() -> Bool {
        return bool(forKey: UserDefaultKeys.hasLaunchedBefore.rawValue)
    }
    func getLaunchDate() -> String {
        guard let validDate = object(forKey: UserDefaultKeys.launchDate.rawValue) as? Date else {return ""}
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM. d, h:mm a"
        return dateFormatter.string(from: validDate)
    }
    
    
}
