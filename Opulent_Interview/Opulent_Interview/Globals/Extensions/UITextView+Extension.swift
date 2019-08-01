//
//  UITextView+Extension.swift
//  Opulent_Interview
//
//  Created by William Judd on 8/1/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit

extension UITextView {
    func heightForAttributedText(_ text: NSAttributedString, width: CGFloat) -> CGFloat{
        self.attributedText = text
        return self.sizeThatFits(CGSize(width: width, height: 20000)).height
    }
    
    func getHeight(width: CGFloat) -> CGFloat {
        return self.sizeThatFits(CGSize(width: width, height: 20000)).height
    }
}
