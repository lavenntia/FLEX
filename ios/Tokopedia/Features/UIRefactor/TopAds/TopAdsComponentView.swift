//
//  TopAdsComponentView.swift
//  Tokopedia
//
//  Created by Dhio Etanasti on 3/27/17.
//  Copyright © 2017 TOKOPEDIA. All rights reserved.
//

import Foundation
import UIKit
import Render
import RxSwift

struct TopAdsState: StateType {
    var topAds: [PromoResult]?
}

class TopAdsNode: NSObject, NodeType {
    
    private var rootNode: NodeType
    private let disposeBag = DisposeBag()
    fileprivate var isSimple = false
    
    override init() {
        rootNode = NilNode()
    }
    
    convenience init(ads: [PromoResult]) {
        self.init()
        guard ads.count > 0 else {
            rootNode = NilNode()
            return
        }
        
        construct(ads: ads)
    }
    
    fileprivate func construct(ads: [PromoResult]) {
        let theTopAds = ads
        let divider: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2)
        
        let mainWrapper = Node<UIView>(identifier: "topads") {
            view, layout, size in
            view.backgroundColor = .clear
            layout.width = size.width
        }
        
        func promotedInfoView() -> NodeType {
            let promotedInfoView = Node<UIView> {
                view, layout, size in
                view.backgroundColor = .clear
                layout.alignItems = .center
                layout.flexDirection = .row
                layout.width = size.width
                layout.height = 35
            }
            
            let promotedLabel = Node<UILabel> {
                view, layout, _ in
                view.text = "Promoted"
                view.font = .largeTheme()
                layout.marginLeft = 8
            }
            
            let infoButtonImageView = Node<UIImageView>(create: {
                let tapGesture = UITapGestureRecognizer()
                tapGesture.rx.event
                    .subscribe(onNext: { _ in
                        let alertController = TopAdsInfoActionSheet()
                        alertController.show()
                    }).addDisposableTo(self.disposeBag)
                
                let imageView = UIImageView()
                imageView.isUserInteractionEnabled = true
                imageView.contentMode = .scaleAspectFit
                imageView.image = UIImage(named: "icon_information")
                imageView.backgroundColor = .clear
                imageView.addGestureRecognizer(tapGesture)
                
                return imageView
            }) {
                _, layout, _ in
                
                layout.width = 16
                layout.marginLeft = 4
            }
            
            return promotedInfoView.add(children: [
                promotedLabel,
                infoButtonImageView
            ])
        }
        
        let adsWrapper = Node<UIView> {
            view, layout, size in
            view.backgroundColor = .tpLine()
            layout.width = size.width
            layout.flexDirection = .row
            layout.flexWrap = .wrap
        }
        
        func adView(topAdsResult: PromoResult, index: Int) -> NodeType {
            
            let product = topAdsResult.viewModel!
            
            let adView = Node<UIView>{
                view, layout, size in
                
                let tapGesture = UITapGestureRecognizer()
                tapGesture.rx.event
                    .subscribe(onNext: { _ in
                        if let url = URL(string: topAdsResult.applinks) {
                            TopAdsService.sendClickImpression(clickURLString: topAdsResult.product_click_url)
                            TPRoutes.routeURL(url)
                        }
                    }).addDisposableTo(self.disposeBag)
                
                view.backgroundColor = UIColor.white
                view.gestureRecognizers?.removeAll()
                view.addGestureRecognizer(tapGesture)
                
                layout.flexDirection = .column
                layout.width = (size.width - (divider - 1)) / divider
                
                if (index + 1) != Int(divider) {
                    layout.marginRight = 1
                }
            }
            
            let productImageView = Node<TopAdsCustomImageView> {
                view, layout, _ in
                view.ad = topAdsResult
                view.setImageWith(URL(string: product.productThumbEcs), placeholderImage: UIImage(named: "grey-bg.png"))
                layout.aspectRatio = 1
                layout.marginHorizontal = 7
                layout.marginTop = 7
                layout.marginBottom = 8
                
            }
            
            let productNameWrapper = Node<UIView> {
                _, layout, _ in
                layout.height = 31.5
                layout.marginHorizontal = 8
                layout.paddingTop = 0
            }
            
            let productNameLabel = Node<UILabel> {
                view, _, _ in
                view.text = product.productName
                view.textColor = UIColor.tpPrimaryBlackText().withAlphaComponent(0.70)
                view.font = .smallThemeMedium()
                view.numberOfLines = 2
                
            }
            
            productNameWrapper.add(child: productNameLabel)
            
            let productPriceLabel = Node<UILabel> {
                view, layout, _ in
                view.textColor = UIColor.tpOrange()
                view.font = .largeThemeMedium()
                
                view.text = product.productPrice
                layout.marginHorizontal = 8
                layout.marginBottom = self.isSimple ? 9 : 0
                layout.height = 17
            }
            
            let ratingWrapper = Node<UIView> {
                _, layout, _ in
                layout.height = 15
                layout.marginHorizontal = 8
                layout.marginBottom = 7
            }
            
            func statusWrapper() -> NodeType {
                let statusWrapper = Node<UIView> {
                    _, layout, _ in
                    layout.height = 18
                    layout.marginTop = 5
                    layout.marginBottom = 5
                    layout.marginHorizontal = 8
                    layout.flexDirection = .row
                }
                
                func statusLabel(label: ProductLabel) -> NodeType {
                    let statusLabel = Node<UILabel> {
                        view, layout, _ in
                        view.layer.borderWidth = 1
                        view.layer.cornerRadius = 3
                        view.layer.backgroundColor = UIColor.fromHexString(label.color).cgColor
                        view.layer.borderColor = label.color == "#ffffff" ? UIColor.lightGray.cgColor : UIColor.fromHexString(label.color).cgColor
                        view.textColor = label.color == "#ffffff" ? UIColor.lightGray : UIColor.white
                        view.text = label.title
                        view.textAlignment = .center
                        view.font = .microThemeMedium()
                        layout.paddingHorizontal = 1
                        layout.marginRight = 2
                    }
                    
                    return statusLabel
                }
                
                if let labels = product.labels {
                    statusWrapper.add(children: (0..<labels.count).map { index in
                        statusLabel(label: labels[index] as! ProductLabel)
                    })
                }
                
                return statusWrapper
            }
            
            let productShopLabel = Node<UILabel> {
                view, layout, _ in
                view.textColor = UIColor.black.withAlphaComponent(0.54)
                view.font = .microTheme()
                view.text = product.productShop
                layout.marginHorizontal = 8
                layout.marginBottom = 3
            }
            
            func bottomWrapper() -> NodeType {
                let bottomWrapper = Node<UIView> {
                    _, layout, _ in
                    layout.height = 14
                    layout.marginHorizontal = 8
                    layout.marginBottom = 8
                    layout.flexDirection = .row
                    layout.alignItems = .center
                }
                
                let pinIcon = Node<UIImageView> {
                    view, layout, _ in
                    view.image = UIImage(named: "icon_location.png")
                    view.contentMode = .scaleAspectFill
                    layout.width = 11
                    layout.height = 14
                    layout.marginRight = 3
                }
                
                let locationLabel = Node<UILabel> {
                    view, layout, _ in
                    view.textColor = UIColor.fromHexString("9E9E9E")
                    view.text = product.shopLocation
                    view.textAlignment = .left
                    view.font = .microTheme()
                    layout.flexGrow = 1
                    layout.flexShrink = 1
                }
                
                let badgesWrapper = Node<UIView> {
                    _, layout, _ in
                    layout.flexDirection = .row
                    layout.justifyContent = .flexEnd
                    layout.height = 14
                }
                
                func badgeView(badge: ProductBadge) -> NodeType {
                    let badgeView = Node<UIImageView> {
                        view, layout, _ in
                        view.setImageWith(URL(string: badge.image_url))
                        layout.marginLeft = 2
                        layout.height = 14
                        layout.width = layout.height
                    }
                    return badgeView
                }
                
                if let badges = product.badges {
                    badgesWrapper.add(children: (0..<badges.count).map { index in
                        badgeView(badge: badges[index] as! ProductBadge)
                    })
                }
                
                return bottomWrapper.add(children: [
                    pinIcon,
                    locationLabel,
                    badgesWrapper
                ])
            }
            
            if isSimple {
                return adView.add(children: [
                    productImageView,
                    productNameWrapper,
                    productPriceLabel
                ])
            } else {
                return adView.add(children: [
                    productImageView,
                    productNameWrapper,
                    productPriceLabel,
                    ratingWrapper,
                    statusWrapper(),
                    productShopLabel,
                    bottomWrapper()
                ])
            }
        }
        
        adsWrapper.add(children: (0..<theTopAds.count).map { index in
            adView(topAdsResult: theTopAds[index], index: index)
        })
        mainWrapper.add(children: [
            promotedInfoView(),
            adsWrapper
        ])
        
        rootNode = mainWrapper
    }
    
    var renderedView: UIView? {
        return rootNode.renderedView
    }
    
    var identifier: String {
        return rootNode.identifier
    }
    
    var children: [NodeType] {
        set {}
        get {
            return rootNode.children
        }
    }
    
    func add(children: [NodeType]) -> NodeType {
        return self
    }
    
    var index: Int = 0
    
    func render(in bounds: CGSize) {
        rootNode.render(in: bounds)
    }
    
    func internalConfigure(in bounds: CGSize) {
        rootNode.internalConfigure(in: bounds)
    }
    
    func willRender() {
        rootNode.willRender()
    }
    
    func didRender() {
        rootNode.didRender()
    }
    
    func build(with reusable: UIView?) {
        rootNode.build(with: reusable)
    }
}

class TopAdsView: UIView {
    
    func setPromo(ads: [PromoResult]) {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
        let topAdsComponent = TopAdsFeedPlusComponentView(ads: ads)
        self.addSubview(topAdsComponent)
        topAdsComponent.render(in: self.frame.size)
        
        self.frame.size = CGSize(width: topAdsComponent.frame.size.width, height: topAdsComponent.frame.size.height)
    }
    
}

class TopAdsCustomImageView: UIImageView, UIGestureRecognizerDelegate {
    
    var panRecognizer: UIPanGestureRecognizer?
    var ad = PromoResult() {
        didSet {
            isImpressionAlreadySent = false
            weak var weakSelf = self
            let when = DispatchTime.now() + 0.5
            DispatchQueue.main.asyncAfter(deadline: when) {
                weakSelf?.userPanned()
            }
        }
    }
    var isImpressionAlreadySent = false
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow == nil {
            for recognizer in self.window?.gestureRecognizers ?? [] {
                if recognizer == panRecognizer {
                    self.window?.removeGestureRecognizer(recognizer)
                    panRecognizer = nil
                }
            }
        } else {
            if panRecognizer == nil {
                panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userPanned))
                panRecognizer?.minimumNumberOfTouches = 1
                panRecognizer?.cancelsTouchesInView = false
                panRecognizer?.delegate = self
                
                newWindow?.addGestureRecognizer(panRecognizer!)
            }
        }
    }
    
    override func didMoveToWindow() {
        userPanned()
    }
    
    @objc private func userPanned() {
        if let _ = ad.shop?.image_shop {
            if isVisible(view: self) && !isImpressionAlreadySent && ad.shop.image_shop.s_url != ad.shop.image_shop.s_ecs && !ad.isImpressionSent {
                TopAdsService.sendClickImpression(clickURLString: ad.shop.image_shop.s_url)
                isImpressionAlreadySent = true
                ad.isImpressionSent = true
            }
        } else {
            if isVisible(view: self) && !isImpressionAlreadySent && ad.viewModel.productThumbEcs != ad.viewModel.productThumbUrl && !ad.isImpressionSent {
                TopAdsService.sendClickImpression(clickURLString: ad.viewModel.productThumbUrl)
                isImpressionAlreadySent = true
                ad.isImpressionSent = true
            }
        }
    }
    
    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    private func isVisible(view: UIView) -> Bool {
        if view.window == nil {
            return false
        }
        
        func rectVisibleInView(rect: CGRect, inRect: CGRect) -> CGPoint {
            var offset = CGPoint()
            
            if inRect.contains(rect) {
                return CGPoint(x: 0, y: 0)
            }
            
            if rect.origin.x < inRect.origin.x {
                // It's out to the left
                offset.x = inRect.origin.x - rect.origin.x
            } else if (rect.origin.x + rect.width) > (inRect.origin.x + inRect.width) {
                // It's out to the right
                offset.x = (rect.origin.x + rect.width) - (inRect.origin.x + inRect.width)
            }
            
            if rect.origin.y < inRect.origin.y {
                // It's out to the top
                offset.y = inRect.origin.y - rect.origin.y
            } else if rect.origin.y + rect.height > inRect.origin.y + inRect.height {
                // It's out to the bottom
                offset.y = (rect.origin.y + rect.height) - inRect.origin.y + inRect.height
            }
            
            return offset
        }
        
        func owningViewController(_ responder: UIResponder) -> UIViewController? {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            
            guard let next = responder.next else { return nil }
            return owningViewController(next)
        }
        
        let convertedViewRect = view.convert(view.bounds, to: view.window!)
        if let owningViewControllerView = owningViewController(view)?.view {
            let visibleScreenRect = owningViewControllerView.convert(owningViewControllerView.bounds, to: view.window!)
            return rectVisibleInView(rect: convertedViewRect, inRect: visibleScreenRect) == CGPoint(x: 0, y: 0)
        }
        
        return false
    }
}

class TopAdsComponentView: ComponentView<TopAdsState>, TKPDAlertViewDelegate {
    
    fileprivate var isSimple = false
    
    override init() {
        super.init()
    }
    
    convenience init(ads: [PromoResult]) {
        self.init()
        let theState = TopAdsState(topAds: ads)
        self.state = theState
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func construct(state: TopAdsState?, size: CGSize) -> NodeType {
        guard let theTopAds = state?.topAds, theTopAds.count > 0 else {
            return Node<UIView> {
                _, _, _ in
            }
        }
        
        let topAdsNode = TopAdsNode()
        topAdsNode.isSimple = self.isSimple
        topAdsNode.construct(ads: theTopAds)
        return topAdsNode
    }
    
}
