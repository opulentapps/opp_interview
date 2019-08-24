//
//  HomeViewController+SectionViewControllerDelegate.swift
//  Opulent_Interview
//
//  Created by William Judd on 9/23/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit

extension HomeViewController : SectionViewControllerDelegate {

    func sectionViewControllerDismissed () {

        isStatusBarHidden = false

        UIView.animate(withDuration: 0.5) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
}
