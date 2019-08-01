//
//  PaidFacilityCell.swift
//  Opulent_Interview
//
//  Created by William Judd on 8/1/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit

class PaidFacilityCell: UICollectionViewCell {
    
    // constant
    static let className : String = "PaidFacilityCell"
    
    // outlet
    @IBOutlet weak var labelName: UILabel!
    
    // value
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public func makeName(_ name : String, color: UIColor = UIColor(netHex: AppSetting.Color.gray), size: CGFloat = AppSetting.FontSize.normal){
        labelName.text = name.trimmingCharacters(in: CharacterSet(charactersIn: "\n @"))
        labelName.textColor = color
        labelName.font = UIFont(name: AppSetting.Font.roboto, size: size)
    }
}
