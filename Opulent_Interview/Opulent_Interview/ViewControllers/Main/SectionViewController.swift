//
//  SectionViewController.swift
//  Opulent_Interview
//
//  Created by William Judd on 9/23/19.
//  Copyright © 2019 Opulent Apps. All rights reserved.
//

import UIKit
//import RealmSwift
//import Kingfisher
//import LifetimeTracker
//import Ambience

protocol SectionViewControllerDelegate: class {
    func sectionViewControllerDismissed()
}

class SectionViewController: UIViewController, LifetimeTrackable {

    @IBOutlet
    weak var sectionTransitioning : SectionTransitioning!
    
    static var lifetimeConfiguration = LifetimeConfiguration(maxCount: 1,
                                                             groupName: "Section ViewController")

    
    @IBOutlet weak var sectionTableView: UITableView!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backgroundImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var closeVisualEffectView: DesignableVisualEffectView!
    @IBOutlet weak var subheadLabel: UILabel!
    @IBOutlet weak var subheadVisualEffectView: UIVisualEffectView!
    @IBOutlet weak var subheadHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playVisualEffectView: DesignableVisualEffectView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var progressView: GradientView!
    @IBOutlet weak var progressViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var closeButtonContainerView: UIView!

    let visualEffectView = UIVisualEffectView()
    var tableViewHeight: CGFloat = 0
    
    var contents = List<Content>()
    var section: Section! {
        didSet {
            contents = section.contents
        }
    }
    
    var shouldScrollToRow = false
    var hasTableViewReloaded = false
    var scrollContentIndexPath: IndexPath!
    
    var isFromBookmarksVC = false
    
    weak var delegate: SectionViewControllerDelegate?
    weak var cell: SectionCollectionViewCell?
    
    private var bodyAttributedString: (regular : NSAttributedString, invert : NSAttributedString)?
    private var attributedStrings = Dictionary<Int, (regular : NSAttributedString, invert : NSAttributedString)>()
    private var isPresenting = true
    
    private var playerItems = [Int: AVPlayerItem]()
    private var downloadingMedia = [Int: Bool]()
    private var mediaSizes = [Int: CGSize]()

    // Progress
    private var sectionProgress = 0.0
    private var didLayoutSubviews = false
    var statusBarHidden = false
    var onPadDismiss: (() -> Void)?
    
    private var bodyCachedHeight: CGFloat?
    private var cachedCellHeights = [Int: CGFloat]()
    private var bookmarkIds = [Int]()
    private var currentCells = [VideoTableViewCell]()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        trackLifetime()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        trackLifetime()
    }
    
    deinit {
        print("SectionViewController deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let numberOfSections = section.chapter?.sections.count ?? 1
        let sectionNumber = section.chapter?.sections.index(of: section)?.advanced(by: 1)
        let sectionOrder = sectionNumber ?? section.order
        subheadLabel.text = "\(sectionOrder) / \(String(numberOfSections))".uppercased()
        titleLabel.text = section.title
        captionLabel.text = section.caption.stringByDecodingHTMLEntities
        
        if let image = UIImage(named: getBackground(section: section)) {
            backgroundImageView.image = image
        } else {
            backgroundImageView.setImage(fromString: section.image)
        }
        
        if let user = RealmService.getUser() {
            bookmarkIds = user.bookmarks.compactMap { $0.content?.id }
        }
        
        progressView.set(maskedCorners: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner])
        progressViewTrailingConstraint.constant = view.bounds.width
        
        playVisualEffectView.isHidden = section.video.isEmpty

        scrollView.delegate = self
        setProgress()
        updateProgress()
        
//        tableViewHeightConstraint.constant = view.bounds.size.height
        scrollView.contentSize = CGSize.zero
        
        if isFromBookmarksVC && appHasWideScreenForView(view) {
            view.backgroundColor = UIColor(hex: "F5F5F5")
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: self,
                                                   action: #selector(closeButtonTapped(_:)))
        closeButtonContainerView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if appHasWideScreenForView(view) {
            delay(delay: 1, closure: {
                self.visualEffectView.frame = self.view.frame
            })
        }
        
        
        cachedCellHeights.removeAll()
        bodyCachedHeight = nil
        
        guard let visibleRows = sectionTableView.indexPathsForVisibleRows else { return }
        coordinator.animate(alongsideTransition: { context in
            context.viewController(forKey: UITransitionContextViewControllerKey.from)
        }, completion: { context in
            self.calculateCellHeights(viewWidth: size.width, finalHeight: size.height)
            if let first = visibleRows.first {
                self.sectionTableView.reloadRows(at: [first], with: UITableViewRowAnimation.automatic)
                self.sectionTableView.scrollToRow(at: first, at: .top, animated: false)
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        saveProgress()
        delegate?.sectionViewControllerDismissed()
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {

        isPresenting = false

        if let cell = cell {
            cell.updateProgress(percentage: sectionProgress)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ReviewManager.shared.displayReviewControllerIfReady()
            PushNotificationManager.shared.displayPushNotificationPermissionsIfReady()
        }

        onPadDismiss?()

        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func scrollToTopTapped(_ sender: UIButton) {
        sectionTableView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    func prepare(sectionBody: String, contentBodies bodies: [String]) {
        // BodyTextView
        if let regular = sectionBody.wrapInHTML().htmlToAttributedString,
            let invert = sectionBody.wrapInHTML(for: UIScreen.main.bounds, and: .invert).htmlToAttributedString {
            bodyAttributedString = ( regular: regular, invert: invert )
        }

        prepareCells(bodies: bodies)
    }
    
    func prepareCells(bodies: [String]) {
        // Cells
        let waitGroup = DispatchGroup()
        
        for (index, body) in bodies.enumerated() {
            if !isPresenting { return }
            waitGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                
                if let attributedRegular = body.wrapInHTML().htmlToAttributedString, let attributedInvert = body.wrapInHTML(for: UIScreen.main.bounds, and: .invert).htmlToAttributedString {
                    
                    let tuple = (regular: attributedRegular, invert: attributedInvert)
                    
                    self?.attributedStrings.updateValue(tuple, forKey: index)
                }
                
                self?.reloadIfNecessary(row: index)
                waitGroup.leave()
            }
        }
        
        let width = view.bounds.size.width
        let height = view.bounds.size.height
        waitGroup.notify(queue: DispatchQueue.main) { [weak self] in
            self?.sectionTableView.reloadData()
            self?.calculateCellHeights(viewWidth: width, finalHeight: height)
            self?.scrollToRow()
        }
    }
    
    private func setProgress() {
        if let user = RealmService.getUser() {
            if let progress = user.progresses.filter("section = %@", section).first {
                sectionProgress = Double(progress.percentage)
                subheadLabel.text = "\(progress.percentage)%"
            }
        }
    }
    
    private func saveProgress() {
        let percentage = min(Int(sectionProgress), 100)
        RealmService.updateProgress(percentage: percentage, section: section)
    }
    
    @IBAction func progressButtonTapped() {
        let yPoint = sectionTableView.contentSize.height/100 * CGFloat(sectionProgress)
        let point = CGPoint(x: 0, y: yPoint - 1)
        if let indexPath = sectionTableView.indexPathForRow(at: point) {
            sectionTableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
}

// MARK: Scroll to Bookmark
extension SectionViewController {
    func setScrollContent(order: Int) {
        scrollContentIndexPath = IndexPath(row: order - 1, section: 1)
        shouldScrollToRow = true
    }
    
    func scrollToRow() {
        if self.shouldScrollToRow {
            DispatchQueue.main.async {
                self.view.hideLoading()
                self.sectionTableView.scrollToRow(at: self.scrollContentIndexPath,
                                                  at: .top,
                                                  animated: true)
            }
        }
    }
}

// MARK: Table View
extension SectionViewController: UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "bodyCell") as! SectionBodyTableViewCell
            cell.attributedTextTuple = bodyAttributedString
            return cell
        }

        let content = contents[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell") as! VideoTableViewCell
        let contentId = content.id
        DispatchQueue.global(qos: .userInitiated).async {
            let selected = self.bookmarkIds.contains(contentId)
            DispatchQueue.main.async {
                cell.configureBookmarkButton(selected: selected)
            }
        }

        DispatchQueue.main.async {
            
            cell.attributedTextTuple = self.attributedStrings[indexPath.row]
        }
        
        if content.hasMedia {
            cell.avPlayerView.isHidden = false
            if let mediaSize = mediaSizes[content.id] {
                cell.setupPlayerAspectRatio(size: mediaSize)
            } else {
                cell.setupPlayerAspectRatio(size: content.imageSize)
            }
            if content.hasGif || !content.video.isEmpty {
                cell.setupPlayer()
                cell.videoPlayerItem = playerItems[content.id]
                cell.mediaImageView.isHidden = true
            } else {
                cell.mediaImageView.isHidden = false
            }
        } else {
            cell.avPlayerView.isHidden = true
        }
        
        cell.delegate = self
        cell.indexPath = indexPath
        cell.configure(content: content)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 0 { return }
        if let cell = cell as? VideoTableViewCell {
            cell.startVideo()
            currentCells.append(cell)
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? VideoTableViewCell else { return }
        cell.reset()
        if let index = currentCells.index(of: cell) {
            currentCells.remove(at: index)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var width: CGFloat
        width = view.bounds.size.width - 40
        if view.traitCollection.horizontalSizeClass == .regular {
            width = 728 - 40
        }

        if indexPath.section == 0 {
            if let height = bodyCachedHeight {
                return height
            }
            
            if let height = bodyAttributedString?.regular.height(withConstrainedWidth: width) {
                let heightWithMargins = height + 20
                bodyCachedHeight = heightWithMargins
                return heightWithMargins
            }

            return 200.0
        }

        if let height = cachedCellHeights[indexPath.row] {
            return height
        }
        
        if let height = attributedStrings[indexPath.row]?.regular.height(withConstrainedWidth: width) {
            let content = contents[indexPath.row]
            // Spaces in the cell
            var heightWithSpaces = height + 25 + 20 + titleHeightFor(content: content)
            if content.hasMedia {
                if let mediaSize = content.imageSize {
                    heightWithSpaces += 60 + min(300, (mediaSize.height * width / mediaSize.width))
                } else {
                    if let mediaSize = mediaSizes[content.id] {
                        let mediaHeight = (mediaSize.height * width / mediaSize.width)
                        heightWithSpaces += 60 + min(mediaHeight, 300)
                    } else {
                        heightWithSpaces += 60 + 300
                        return heightWithSpaces
                    }
                }
            }
            cachedCellHeights[indexPath.row] = heightWithSpaces
            return heightWithSpaces
        }
        
        return 500.0
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { loadVideo(content: contents[$0.row], forIndexPath: $0) }
    }
    
    func reloadIfNecessary(row: Int) {
        let indexPath = IndexPath(row: row, section: 1)
        DispatchQueue.main.async { [weak self] in
            if self?.sectionTableView.indexPathsForVisibleRows?.contains(indexPath) == true {
                self?.sectionTableView.reloadRows(at: [indexPath],
                                                  with: .automatic)
            }
        }
    }
    
    // TODO: - Fix duplicated code
    func calculateCellHeights(viewWidth: CGFloat, finalHeight: CGFloat) {
        var width: CGFloat
        width = viewWidth - 40
        if view.traitCollection.horizontalSizeClass == .regular {
            width = 728 - 40
        }
        var totalHeight: CGFloat = 0
        for (index, content) in Array(contents).enumerated() {
            if let height = attributedStrings[index]?.regular.height(withConstrainedWidth: width) {
                // Spaces in the cell
                var heightWithSpaces = height + 25 + 20 + titleHeightFor(content: content)
                if content.hasMedia {
                    if let mediaSize = content.imageSize {
                        heightWithSpaces += 60 + min(300, (mediaSize.height * width / mediaSize.width))
                    } else {
                        if let mediaSize = mediaSizes[content.id] {
                            let mediaHeight = (mediaSize.height * width / mediaSize.width)
                            heightWithSpaces += 60 + min(mediaHeight, 300)
                        } else {
                            heightWithSpaces += 60 + 300
                        }
                    }
                }
                cachedCellHeights[index] = heightWithSpaces
                totalHeight += heightWithSpaces
            }
        }
        
        var count = contents.count
        if let bodyHeight = bodyCachedHeight {
            totalHeight += bodyHeight
            count += 1
        } else {
            if let height = bodyAttributedString?.regular.height(withConstrainedWidth: width) {
                let heightWithMargins = height + 20
                bodyCachedHeight = heightWithMargins
                totalHeight += heightWithMargins
                count += 1
            }
        }

        // This will layout the UITableView content inset correctly. Helping us with screen rotation,
        // resuming reading based on percentage, display the vertical scrolling indicator correctly.
        sectionTableView.contentSize = CGSize(width: width + 40.0, height: finalHeight)
        let rowHeight = totalHeight/CGFloat(count)
        sectionTableView.rowHeight = rowHeight
        sectionTableView.bounds.size.height = totalHeight
        sectionTableView.layoutIfNeeded()
     
        sectionTableView.bounds.size.height = finalHeight
        sectionTableView.layoutIfNeeded()
    }
    
    func titleHeightFor(content: Content) -> CGFloat {
        let width = sectionTableView.bounds.size.width - 60
        if content.title.isEmpty {
            return content.subhead.height(withConstrainedWidth: width,
                                          font: UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.semibold))
        }
        return content.title.height(withConstrainedWidth: width,
                                    font: UIFont.boldSystemFont(ofSize: 32))
    }
}

// MARK: ScrollView Progress
extension SectionViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !isPresenting { return }
        let offsetY = scrollView.contentOffset.y
        if offsetY < 0 {
            viewTopConstraint.constant = 0
        } else {
            viewTopConstraint.constant = max(-offsetY, -420.0)
        }
        
        for cell in currentCells {
            let adjustedRect = sectionTableView.convert(cell.frame, to: view)
            let distanceToTop = view.bounds.origin.y.distance(to: adjustedRect.minY)
            cell.update(offset: distanceToTop/(view.bounds.size.height - 40.0))
        }
        
        let percentage = Double(offsetY/(scrollView.contentSize.height - scrollView.frame.size.height)) * 100
        if percentage > sectionProgress {
            let adjustedPercentage = min(percentage, 100)
            sectionProgress = adjustedPercentage
            subheadLabel.text = "\(Int(adjustedPercentage))%"
            updateProgress()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y > 0 {
            let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.7, animations: {
                self.progressView.transform = CGAffineTransform(translationX: 0, y: 0)
                self.closeVisualEffectView.alpha = 0
                self.closeVisualEffectView.transform = CGAffineTransform(translationX: 0, y: -50).concatenating(CGAffineTransform(scaleX: 2, y: 2))
            })
            animator.startAnimation()
        } else {
            let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.7, animations: {
                self.progressView.transform = CGAffineTransform(translationX: 0, y: 6)
                self.closeVisualEffectView.alpha = 1
                self.closeVisualEffectView.transform = CGAffineTransform.identity
            })
            animator.startAnimation()
        }
    }
    
    func updateProgress() {
        let viewWidth = view.bounds.width
        let constant = viewWidth - (viewWidth * CGFloat(sectionProgress) / 100)
        progressViewTrailingConstraint.constant = constant
    }
}

// MARK: Status Bar
extension SectionViewController {
    override var prefersStatusBarHidden: Bool { return statusBarHidden }
}

// MARK: Video
import AVFoundation
import AVKit

extension SectionViewController: VideoCellDelegate {
    
    // MARK: - Cell Media
    func loadVideo(content: Content, forIndexPath indexPath: IndexPath) {
        
        guard playerItems[content.id] == nil else { return }
        
        let contentId = content.id
        let mediaFilename = content.mediaFilename
        let mediaData = ContentMediaData(content: content)
        DispatchQueue.global(qos: .background).async { [weak self] in
            if let url = FileManager.urlForItem(named: "\(mediaFilename)", ofType: "mp4") {
                self?.appendPlayer(contentId: contentId, withUrl: url)
                self?.cachedCellHeights[indexPath.row] = nil
                return
            } else {
                self?.downloadMedia(data: mediaData, atIndexPath: indexPath)
            }
        }
    }
    
    private func downloadMedia(data: ContentMediaData, atIndexPath indexPath: IndexPath) {
        let contentId = data.id
        let mediaFilename = data.filename
        if data.hasGif {
            guard let url = URL(string: data.imageString) else { return }
            
            let documentsUrl = FileManager.documentsDirectoryUrl.appendingPathComponent("\(mediaFilename).mp4")
            
            guard downloadingMedia[contentId] != true else { return }
            downloadingMedia.updateValue(true, forKey: contentId)
            ImageDownloader.default.downloadImage(with: url, completionHandler: { [weak self] _, error, url, data in
                guard error == nil, let data = data else { return }
                DispatchQueue.global(qos: .background).async { [weak self] in
                    GIF2MP4(data: data)?.convertAndExport(to: documentsUrl, completion: { [weak self] in
                        self?.appendPlayer(contentId: contentId, withUrl: documentsUrl)
                        self?.cachedCellHeights[indexPath.row] = nil
                        DispatchQueue.main.async { [weak self] in
                            self?.displayMediaIfNecessaryFor(indexPath: indexPath)
                        }
                    })
                }
            })
            
            return
            
        } else if !data.videoString.isEmpty {
            
            let videoString = data.videoString
            
            guard downloadingMedia[contentId] != true else { return }
            downloadingMedia.updateValue(true, forKey: contentId)
            DispatchQueue.global(qos: .background).async { [weak self] in
                if let url = URL(string: videoString),
                    let urlData = NSData(contentsOf: url)
                {
                    let filePath = FileManager.documentsDirectoryUrl.appendingPathComponent("\(mediaFilename).mp4")
                    urlData.write(toFile: filePath.path, atomically: true)
                    self?.appendPlayer(contentId: contentId, withUrl: filePath)
                    DispatchQueue.main.async { [weak self] in
                        self?.displayMediaIfNecessaryFor(indexPath: indexPath)
                    }
                }
            }
        }
    }
    
    private func displayMediaIfNecessaryFor(indexPath: IndexPath) {
        if sectionTableView.indexPathsForVisibleRows?.contains(indexPath) == true {
            if let cell = sectionTableView.cellForRow(at: indexPath) as? VideoTableViewCell {
                let contentId = contents[indexPath.row].id
                cell.videoPlayerItem = playerItems[contentId]
            }
        }
    }
    
    func appendPlayer(contentId: Int, withUrl url: URL) {
        let playerItem = AVPlayerItem(url: url)
        playerItems.updateValue(playerItem, forKey: contentId)
        // Calculate video size
        guard let track = AVAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return }
        let size = track.naturalSize.applying(track.preferredTransform)
        let videoSize = CGSize(width: fabs(size.width), height: fabs(size.height))
        mediaSizes.updateValue(videoSize, forKey: contentId)
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        guard let url = URL(string: section.video) else {
            showAlert(title: "Unable to play video content",
                      message: "There's been an error with the current video. Please try again later.")
            return
        }
        var videoURL = url
        if url.absoluteString.contains("vimeo") {
            if let filename = url.absoluteString.slice(from: "/external/", to: ".mp4"),
                let fileURL = FileManager.urlForItem(named: filename
                    , ofType: "mp4") {
                videoURL = fileURL
            }
        }

        let player = AVPlayer(url: videoURL)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            try? player.setPlaybackAudio()
            player.play()
        }
        Analytics.videoOpened(chapter: section.chapter?.title ?? "",
                              section: section.title)
    }
    
    func tappedMedia(indexPath: IndexPath, withImageView imageView: UIImageView) {
        guard let image = imageView.image else { return }
        let imageInfo      = GSImageInfo(image: image, imageMode: .aspectFit, imageHD: nil)
        let transitionInfo = GSTransitionInfo(fromView: imageView)
        let imageViewer    = GSImageViewerController(imageInfo: imageInfo, transitionInfo: transitionInfo)
        present(imageViewer, animated: true, completion: nil)
    }
    
    func show(asset: AVAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }
    
    func bookmarkTapped(indexPath: IndexPath) {
        let content = contents[indexPath.row]
        if let index = bookmarkIds.index(of: content.id) {
            bookmarkIds.remove(at: index)
        } else {
            bookmarkIds.append(content.id)
            Analytics.addBookmark(contentId: content.bookmark_id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { 
                ReviewManager.shared.displayReviewControllerIfReady()
            }
        }
    }
}
