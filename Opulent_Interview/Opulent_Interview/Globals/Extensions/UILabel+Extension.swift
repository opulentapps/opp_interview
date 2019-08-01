//
//  UILabel+Extension.swift
//  Opulent_Interview
//
//  Created by William Judd on 8/1/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit

extension UILabel {
    func heightForText(_ text: String, width: CGFloat) -> CGFloat{
        self.text = text
        return self.sizeThatFits(CGSize(width: width, height: CGFloat(MAXFLOAT))).height
    }
    
    func heightForAttributedText(_ text: NSAttributedString, width: CGFloat) -> CGFloat{
        self.attributedText = text
        return self.sizeThatFits(CGSize(width: width, height: CGFloat(MAXFLOAT))).height
    }
    
    func getHeight(width: CGFloat) -> CGFloat {
        return self.sizeThatFits(CGSize(width: width, height: CGFloat(MAXFLOAT))).height
    }
}


