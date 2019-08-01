//
//  UserDefaultKey.swift
//  Opulent_Interview
//
//  Created by William Judd on 8/1/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit

struct UserDefaultKey {
    // Favorite
    static let favoritedList : ((String) -> String) = {key in
        return "FavoritedList" + key
    }
    
    // Time use app
    static let timesOpenApp = "timesOpenApp"
    
    
}

