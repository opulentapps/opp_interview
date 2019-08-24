//
//  ViewController.swift
//  Opulent_Interview
//
//  Created by William Judd on 9/23/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import AVKit
import UIKit
//import RealmSwift

class HomeViewController: UIViewController, Scrollable, ChapterCollectionViewDelegate {

    var isStatusBarHidden = false
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var benefitContainerView: UIView!
    @IBOutlet weak var benefitContainerViewHeightConstraint: NSLayoutConstraint!
    
    // Scroll parallax
    @IBOutlet weak var phoneImageView: UIImageView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var titleLabel: DesignableLabel!
    @IBOutlet weak var contentView: DesignableView!
    @IBOutlet weak var bodyView: UIView!
    
    @IBOutlet weak var buyBookButton: DesignableButton!
    // Login
    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var readyToStartViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var readyToStartActionButton: UIButton!
    @IBOutlet weak var textView: UITextView!

    var chapterCollectionViewControllers : Array<ChapterViewController> = []
    
    override func viewDidLoad() {

        super.viewDidLoad()

        chapterCollectionViewControllers.forEach({ $0.reloadData() })

        if appHasWideScreenForView(view) {
            backgroundImageView.contentMode = .scaleAspectFill
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkLogin),
            name: .UserStatusChanged,
            object: nil)

        checkLogin()
        validateUserSubscription()
        
        if let attributedText = textView.attributedText {
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            mutableAttributedString.setAsLink(textToFind: "Terms of Service",
                                              linkURL: "http://designcode.io/terms")
            mutableAttributedString.setAsLink(textToFind: "Privacy Policy",
                                              linkURL: "http://designcode.io/privacy")
            textView.attributedText = mutableAttributedString
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)

        checkLogin()
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {

        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        print("screen changed")
    }
    
    // MARK: Action
    @IBAction func purchaseButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "HomeToPurchase", sender: nil)
    }
    
    @IBAction func discountButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "HomeToDiscount", sender: nil)
    }
    
    @IBAction func logoButtonTapped(_ sender: Any) {
        self.tabBarController?.selectedIndex = 4
    }
}

extension HomeViewController : UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let offsetY = scrollView.contentOffset.y

        if offsetY < 0 {

            contentView.transform = CGAffineTransform(translationX: 0, y: offsetY)
            phoneImageView.transform = CGAffineTransform(translationX: 0, y: -offsetY/2)
            backgroundImageView.transform = CGAffineTransform(translationX: 0, y: -offsetY/3)
            titleLabel.transform = CGAffineTransform(translationX: 0, y: -offsetY/4)
            bodyView.transform = CGAffineTransform(translationX: 0, y: -offsetY/5)
        }

        let hideNavigationBar = offsetY <= 0

        UIView.animate(withDuration: 2) {
            self.navigationController?.setNavigationBarHidden(hideNavigationBar, animated: true)
        }
    }
}

// MARK: Benefit Container View
extension HomeViewController: BenefitViewControllerDelegate {

    func benefitViewControllerAdjustHeight(height: CGFloat) {

        benefitContainerViewHeightConstraint.constant = height
    }
}

// MARK: LoginViewControllerDelegate
extension HomeViewController: LoginViewControllerDelegate {

    func loginSucceed() {
        checkLogin()
        if RealmService.isUserPlanExpired {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.showPlanExpiredAlert()
            })
        }
    }
    
    @objc func checkLogin() {
        var loginTitle = ""
        var buttonText = ""
        var actionTitle = ""
        let planStatus = RealmService.userPlanStatus()
        switch planStatus {
        case .active:
            loginTitle = "Logout"
            hideReadyToStartView()
        case .expired:
            loginTitle = "Logout"
            hideReadyToStartView()
            buttonText = "Renew subscription"
            actionTitle = "Renew subscription"
        case .inactive:
            loginTitle = "Login"
            buttonText = "Get full access"
            actionTitle = "Start 7-day free trial"
            let previousConstant = readyToStartViewHeightConstraint.constant
            if previousConstant != 440 {
                DispatchQueue.main.async {
                    self.readyToStartViewHeightConstraint.constant = 440
                }
            }
        }

        DispatchQueue.main.async {
            self.buyBookButton.isHidden = planStatus == .active
            self.loginButton.title = loginTitle
            self.buyBookButton.setTitle(buttonText, for: .normal)
            self.readyToStartActionButton.setTitle(actionTitle, for: .normal)
        }
        
        // Guest
        if !RealmService.isUser() {
            let guest = DataUser(id: "0", email: "", password: "", date: "", plan: "", endDate: nil, customerId: nil)
            RealmService.addUser(sender: guest, completion: {
                print("Guest.")
            })
        }
    }
    
    private func hideReadyToStartView() {
        let previousConstant = readyToStartViewHeightConstraint.constant
        if previousConstant != 0 {
            DispatchQueue.main.async {
                self.readyToStartViewHeightConstraint.constant = 0
            }
        }
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        if RealmService.userPlanStatus() != .inactive {
            RealmService.logout {
                self.checkLogin()
            }
        } else {
            performSegue(withIdentifier: "HomeToLogin", sender: nil)
        }
    }
}

extension HomeViewController: PurchaseViewControllerDelegate {

    func purchaseViewControllerFinished() {
        checkLogin()
    }
    
    func purchaseViewControllerBenefitButtonTapped(tag: Int) {
        let frame = benefitContainerView.frame
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        var navigationBarHeight: CGFloat = 0
        if let nav = navigationController {
            navigationBarHeight = nav.navigationBar.frame.height
        }
        UIView.animate(withDuration: 0.5) {
            self.scrollView.contentOffset.y = frame.origin.y - statusBarHeight - navigationBarHeight + 460
        }
    }
}

extension HomeViewController {
    
    @IBAction func videoButtonTapped() {
        let promoVideoString = RemoteConfig.shared.promoVideo
        guard let url = URL(string: promoVideoString) else {
            showAlert(title: "Unable to play video content",
                      message: "There's been an error with the current video. Please try again later.")
            return
        }
        
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
        Analytics.videoOpened(chapter: "Home", section: "Main Video")
    }
}

// MARK: Status Bar
extension HomeViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .slide }
    
    override var prefersStatusBarHidden: Bool { return isStatusBarHidden }
    
    /// Hides status bar.
    func hideStatusBar(animated : Bool = false) {

        isStatusBarHidden = true

        guard animated else {
            setNeedsStatusBarAppearanceUpdate()
            return
        }

        // Adds a UIView with the size of the status bar and animates its movement vertically.

        if scrollView.contentOffset.y > 0 {
            let underlayView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            underlayView.frame = UIApplication.shared.statusBarFrame
            underlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(underlayView)
            let statusBarHeight = UIApplication.shared.statusBarFrame.size.height

            UIView.animate(withDuration: 0.35) {
                self.setNeedsStatusBarAppearanceUpdate()
                underlayView.frame.origin.y -= statusBarHeight
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                underlayView.removeFromSuperview()
            }
        } else {
            UIView.animate(withDuration: 0.35) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

// MARK: - Subscription request
extension HomeViewController {

    /// Validates the current user subscription status.
    func validateUserSubscription() {
        guard let user = RealmService.getUser() else { return }
        if user.email.isEmpty {
            validateRevenueCat(userCustomerId: user.customerId)
        } else {
            validate(user: user)
        }
    }
    
    /// Validates the current user subscription status against our own backend.
    ///
    /// - Parameter user: current user.
    func validate(user: User) {
        let endpoint = DCEndpoint.user(email: user.email)
        let service = WebService.shared
        service.request(endpoint: endpoint) { (result: ServiceResult<UserResponse>) in
            switch result {
            case .success(let response):
                let user = response.user
                self.handle(expirationDate: user.formattedEndDate as Date?)
            case .error(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    /// Validates the current user subscription status against RevenueCat service
    ///
    /// - Parameter userCustomerId: RevenueCat customerId (unique UUID)
    func validateRevenueCat(userCustomerId: String?) {
        var checkedCustomerId = userCustomerId
        if checkedCustomerId == nil {
            let defaults = UserDefaults.standard
            checkedCustomerId = defaults.string(forKey: "customerId")
        }
        
        guard let customerId = checkedCustomerId, !customerId.isEmpty else { return }
        let baseURL = URL(string: Constants.URLs.revenueCat)
        let service = WebService(baseURL: baseURL)
        let endpoint = RCEndpoint.subscribers(customerId: customerId)
        service.request(endpoint: endpoint) { (result: ServiceResult<RCResponseData>) in
            switch result {
            case .success(let data):
                self.handle(expirationDate: data.subscriber.subscriptions.lastDate)
            case .error(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    /// Updates the current user subscription expiration date.
    ///
    /// - Parameter expirationDate: latest user subscription expiration date.
    func handle(expirationDate: Date?) {
        guard let date = expirationDate else { return }
        RealmService.getUser()?.update(endDate: date)
        checkLogin()
    }
}
