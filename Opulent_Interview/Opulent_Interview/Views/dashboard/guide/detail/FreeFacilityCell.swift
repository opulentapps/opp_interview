//
//  FreeFacilityCell.swift
//  Opulent_Interview
//
//  Created by William Judd on 8/1/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit

class FreeFacilityCell: UICollectionViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    public func make(facility: FFacility){
        icon.image = UIImage(named: facility.getIcon())
        labelName.text = facility.getName()
    }

}
