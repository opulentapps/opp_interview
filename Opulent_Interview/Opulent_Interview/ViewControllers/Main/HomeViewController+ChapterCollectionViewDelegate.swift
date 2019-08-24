//
//  HomeViewController+ChapterCollectionViewDelegate.swift
//  Opulent_Interview
//
//  Created by William Judd on 9/23/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit

extension HomeViewController {

    var stageView : UIView { return self.view }

    func chapterCollectionView(chapterController: ChapterViewController, willPresent sectionController : SectionViewController) {

        hideStatusBar(animated: true)
    }
}
