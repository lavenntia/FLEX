//
//  FeedDetailHeaderComponentView.swift
//  Tokopedia
//
//  Created by Kenneth Vincent on 4/17/17.
//  Copyright © 2017 TOKOPEDIA. All rights reserved.
//

import UIKit
import Render
import RxSwift
import RxCocoa

class FeedDetailHeaderComponentView: ComponentView<FeedDetailState> {
    
    override func construct(state: FeedDetailState?, size _: CGSize) -> NodeType {
        guard let state = state else { return NilNode() }
        
        let mainContent = Node<UIView>(identifier: "main-content") { view, layout, _ in
            layout.flexDirection = .row
            layout.alignItems = .center
            
            view.bk_(whenTapped: {
                TPRoutes.routeURL(URL(string: state.source.shopState.shopURL)!)
            })
        }.add(children: [
            Node<UIImageView>(identifier: "author-image") { imageView, layout, _ in
                layout.width = 52
                layout.height = 52
                
                imageView.borderWidth = 1.0
                imageView.borderColor = UIColor.fromHexString("#e0e0e0")
                imageView.cornerRadius = 3.0
                imageView.setImageWith(URL(string: state.source.shopState.shopImage), placeholderImage: #imageLiteral(resourceName: "grey-bg"))
                
            },
            Node<UIView>(identifier: "author-info") { _, layout, _ in
                layout.flexDirection = .column
                layout.flexShrink = 1
                layout.marginLeft = state.oniPad ? 10.0 : 8.0
            }.add(children: [
                Node<UIView>(identifier: "author-name") { _, layout, _ in
                    layout.flexDirection = .row
                    layout.alignItems = .center
                    layout.marginBottom = 3
                }.add(child: Node<UILabel>(identifier: "title") { label, layout, _ in
                    layout.flexShrink = 1
                    
                    label.numberOfLines = 0
                    label.attributedText = self.attributedStringHeader(withActivity: state.content.activity, state: state.source.shopState)
                }),
                Node<UILabel>(identifier: "create-time") { label, layout, _ in
                    layout.marginBottom = 3
                    
                    label.text = FeedService.feedCreateTimeFormatted(withCreatedTime: state.createTime)
                    label.font = .microTheme()
                    label.textColor = UIColor.tpDisabledBlackText()
                }
            ])
        ])
        
        let shareButton = Node<UIButton>(identifier: "share-button-ipad") { button, layout, _ in
            button.setTitle(" Bagikan", for: .normal)
            button.setImage(#imageLiteral(resourceName: "icon_button_share"), for: .normal)
            button.backgroundColor = .white
            button.cornerRadius = 3.0
            button.titleLabel?.font = .smallThemeSemibold()
            button.setTitleColor(UIColor.tpDisabledBlackText(), for: .normal)
            button.borderWidth = 1
            button.borderColor = UIColor.fromHexString("#e0e0e0")
            
            button.rx.tap
                .subscribe(onNext: {
                    if let viewController = UIApplication.topViewController() {
                        ReferralManager().share(object: state.source.shopState, from: viewController, anchor: button)
                    }
                })
                .disposed(by: self.rx_disposeBag)
            
            layout.height = 40.0
            layout.width = 203.0
        }
        
        let buttonContent = state.oniPad ? Node<UIView>(identifier: "button-content-ipad") { _, layout, _ in
            layout.flexDirection = .row
            layout.alignItems = .center
            layout.justifyContent = .center
        }.add(children: [
            shareButton,
            Node<UIButton>(identifier: "visit-shop-ipad") { button, layout, _ in
                button.setTitle("Kunjungi Toko", for: .normal)
                button.backgroundColor = .tpGreen()
                button.cornerRadius = 3.0
                button.titleLabel?.font = .smallThemeSemibold()
                button.setTitleColor(.white, for: .normal)
                
                button.rx.tap
                    .subscribe(onNext: { [weak self] in
                        AnalyticsManager.trackEventName("clickFeed", category: GA_EVENT_CATEGORY_FEED, action: GA_EVENT_ACTION_VIEW, label: "Product List - Shop")
                        TPRoutes.routeURL(URL(string: state.source.shopState.shopURL)!)
                    })
                    .disposed(by: self.rx_disposeBag)
                
                layout.height = 40.0
                layout.width = 203.0
                layout.left = 10.0
            }
        ]) : NilNode()
        
        return Node<UIView>() { view, layout, _ in
            layout.flexDirection = .column
            layout.width = state.oniPad ? 560.0 : UIScreen.main.bounds.width
            
            view.backgroundColor = .white
        }.add(children: [
            Node<UIView>() { view, layout, _ in
                layout.flexDirection = .column
                layout.padding = 10.0
                layout.width = state.oniPad ? 560.0 : UIScreen.main.bounds.width
                layout.flexGrow = 1
                
                view.backgroundColor = .white
            }.add(children: [
                mainContent,
                buttonContent
            ]),
            Node<UIView>(identifier: "horizontal-line") { view, layout, _ in
                layout.height = 1
                layout.width = state.oniPad ? 560.0 : UIScreen.main.bounds.width
                layout.flexGrow = 1
                
                view.backgroundColor = .tpBackground()
            }
        ])
    }
    
    private func attributedStringHeader(withActivity activity: FeedDetailActivityState, state: FeedDetailShopState) -> NSAttributedString {
        let attString: NSMutableAttributedString = NSMutableAttributedString()
        
        let bold: [String: Any] = [
            NSFontAttributeName: UIFont.largeThemeSemibold(),
            NSForegroundColorAttributeName: UIColor.tpPrimaryBlackText()
        ]
        let normal: [String: Any] = [
            NSFontAttributeName: UIFont.largeTheme(),
            NSForegroundColorAttributeName: UIColor.tpPrimaryBlackText()
        ]
        
        var attachmentString: NSAttributedString?
        
        if state.shopIsGold || state.shopIsOfficial {
            let attachment = NSTextAttachment()
            
            if state.shopIsGold {
                attachment.image = UIImage(named: "icon_gold_merchant")
            }
            
            if state.shopIsOfficial {
                attachment.image = UIImage(named: "icon_official_store")
            }
            
            attachment.bounds = CGRect(x: 0, y: -3, width: (attachment.image?.size.width)!, height: (attachment.image?.size.height)!)
            
            attachmentString = NSAttributedString(attachment: attachment)
        }
        
        if attachmentString != nil {
            attString.append(attachmentString!)
            attString.append(NSAttributedString(string: " ", attributes: bold))
        }
        
        attString.append(NSAttributedString(string: "\(activity.source) ", attributes: bold))
        attString.append(NSAttributedString(string: "\(activity.activity) ", attributes: normal))
        attString.append(NSAttributedString(string: "\(activity.amount) produk", attributes: normal))
        
        return attString
    }
}
