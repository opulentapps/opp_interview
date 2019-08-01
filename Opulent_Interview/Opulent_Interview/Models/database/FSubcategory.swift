//
//  FSubcategory.swift
//  Opulent_Interview
//
//  Created by William Judd on 8/1/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit
import Firebase

class FSubcategory: FObject {
    
    // HARD CODE
    static let TipUser = "-Kdjnh1gwHPXYRRTQuIg" // Dev: "-KdjpEvGoGrCg0_ejxHc"
    static let TipAdmin = "-KdjniTnpvjaBGV3h9KR" // 
    
    // KEY -----------------------------------------------------
    static let name = "name"
    // KEY -----------------------------------------------------
    
    // variables
    // for filter
    var resultCount = 0
    var selected = false
    
    func getName() -> String? {
        return dictionary[FSubcategory.name] as? String
    }
}
