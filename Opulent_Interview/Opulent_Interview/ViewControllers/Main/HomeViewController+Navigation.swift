//
//  HomeViewController+Navigation.swift
//  Opulent_Interview
//
//  Created by William Judd on 9/23/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit

extension HomeViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier?.range(of: "Embed Chapter ") != nil {

            configureChapterContainer(for: segue)
            chapterCollectionViewControllers.append(segue.destination as! ChapterViewController)

            return
        }

        if segue.identifier == "HomeToLogin" {
            let toView = segue.destination as! LoginViewController
            toView.delegate = self
        }

        if segue.identifier == "HomeToBenefit" {
            let toView = segue.destination as! BenefitViewController
            toView.delegate = self
        }

        if segue.identifier == "HomeToPurchase" {
            let toView = segue.destination as! PurchaseViewController
            toView.delegate = self
            toView.modalPresentationCapturesStatusBarAppearance = true
            Analytics.openedPurchaseScreen(planStatus: RealmService.userPlanStatus())
        }

        if segue.identifier == "HomeToDiscount" {
            let toView = segue.destination as! DiscountViewController
            toView.modalPresentationCapturesStatusBarAppearance = true
            Analytics.openedDiscountScreen()
        }
    }
}
