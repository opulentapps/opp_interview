//
//  UtilNumber.swift
//  Opulent_Interview
//
//  Created by William Judd on 8/1/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit

class UtilNumber: NSObject {
    static let formatter = NumberFormatter()
    
    static func formatTemperature(_ temp: Float) -> String? {
        UtilNumber.formatter.positiveFormat = "0.##"
        return UtilNumber.formatter.string(from: NSNumber(value: temp))
    }
    
    static func formatDistance(_ dis: Double) -> String? {
        UtilNumber.formatter.positiveFormat = "0.#"
        return UtilNumber.formatter.string(from: NSNumber(value: dis))
    }
}

