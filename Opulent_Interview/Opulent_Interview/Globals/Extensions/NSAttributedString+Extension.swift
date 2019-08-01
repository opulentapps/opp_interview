//
//  NSAttributedString+Extension.swift
//  Opulent_Interview
//
//  Created by William Judd on 8/1/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import Foundation
import UIKit
import CoreFoundation

extension NSAttributedString {
    // MARK: - calculate size
    func heightWith(width: CGFloat, font: UIFont) -> CGFloat {
//        let bound = self.boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil)
//        return bound.size.height
        
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        return boundingBox.height
    }
}
