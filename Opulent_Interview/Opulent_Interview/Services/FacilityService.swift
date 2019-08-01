//
//  FacilityService.swift
//  Opulent_Interview
//
//  Created by William Judd on 8/1/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit
import Firebase

class FacilityService: NSObject {
    // Path to table
    static let path = "facility"
    // Singleton
    static let shared = FacilityService()
    
    // ref
    var ref : DatabaseReference!
    // data
    var facilities : [FFacility] = []
    
    // init
    override init() {
        super.init()
    }
    
    public func configureDatabase(finish: @escaping () -> Void) {
        facilities.removeAll()
        // ref
        ref = Database.database().reference(withPath: FacilityService.path)
        ref.keepSynced(true)
        // remove all observe
        ref.removeAllObservers()
        // query data
        ref.observe(.childAdded, with: { (snapshot) -> Void in
            //print("The \(snapshot.key) - value is \(snapshot.value)")
            let facility = FFacility(path: FacilityService.path, snapshot: snapshot)
            self.facilities.append(facility)
        })
        ref.observeSingleEvent(of: .value, with: {(snapshot) -> Void in
            print("DONE2 Facility")
            finish()
        })
    }
    
    static func facilitiesFor(keys : [String]) -> [FFacility] {
        return shared.facilities.filter({keys.contains($0.objectId!)})
    }
    
}

