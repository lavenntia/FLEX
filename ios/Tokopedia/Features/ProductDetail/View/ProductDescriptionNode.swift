//
//  ProductDescriptionNode.swift
//  Tokopedia
//
//  Created by Setiady Wiguna on 7/5/17.
//  Copyright © 2017 TOKOPEDIA. All rights reserved.
//

import Render
import TTTAttributedLabel
import UIKit

internal class ProductDescriptionNode: ContainerNode {
    fileprivate let didTapDescription: ((ProductInfo) -> Void)
    fileprivate let didLongPressDescription: (UILabel) -> Void
    fileprivate let didTapVideo: (ProductVideo) -> Void
    fileprivate var state: ProductDetailState
    fileprivate var scrollView: UIScrollView?
    fileprivate var viewController: ProductDetailViewController
    
    internal init(identifier: String, viewController: ProductDetailViewController, state: ProductDetailState, didTapDescription: @escaping ((ProductInfo) -> Void), didTapVideo: @escaping (ProductVideo) -> Void, didLongPressDescription: @escaping (UILabel) -> Void) {
        self.didTapDescription = didTapDescription
        self.didTapVideo = didTapVideo
        self.didLongPressDescription = didLongPressDescription
        self.state = state
        self.viewController = viewController
        
        super.init(identifier: identifier)
        
        node.add(children: [
            container().add(children: [
                GlobalRenderComponent.horizontalLine(identifier: "Description-Line-1", marginLeft: 0),
                titleLabel(),
                videoListView(),
                productDescriptionView(),
                productBottomView(),
                GlobalRenderComponent.horizontalLine(identifier: "Description-Line-2", marginLeft: 0)
            ])
        ])
    }
    
    private func container() -> NodeType {
        return Node<UIView> { view, layout, size in
            layout.width = size.width
            layout.flexDirection = .column
            layout.marginTop = 10
            view.backgroundColor = .white
            view.isUserInteractionEnabled = true
        }
    }
    
    private func titleLabel() -> NodeType {
        return Node<UILabel>() { view, layout, _ in
            layout.marginLeft = 15
            layout.marginTop = 22
            layout.marginBottom = 22
            view.text = "Deskripsi Produk"
            view.textColor = .tpPrimaryBlackText()
            view.font = .largeThemeMedium()
        }
    }
    
    private func videoPlaceholderView(videoUrl: String) -> NodeType {
        if let nowPlayingVideo = self.state.nowPlayingVideo,
            nowPlayingVideo.url == videoUrl {
            return Node<UIActivityIndicatorView>(identifier: "ActivityIndicator-\(videoUrl)") { view, layout, _ in
                layout.alignSelf = .center
                view.activityIndicatorViewStyle = .whiteLarge
                view.isUserInteractionEnabled = true
                view.startAnimating()
            }
        }
        
        return Node<UIImageView>(identifier: "IconPlay-\(videoUrl)") { view, layout, _ in
            layout.alignSelf = .center
            layout.width = 55
            layout.height = 40
            view.backgroundColor = .clear
            view.contentMode = .scaleAspectFill
            view.clipsToBounds = true
            view.isUserInteractionEnabled = true
            view.image = #imageLiteral(resourceName: "icon_play_black")
        }
    }
    
    private func videoActivityView(videoUrl: String) -> NodeType {
        return Node<UIActivityIndicatorView>(identifier: "ActivityIndicator-\(videoUrl)") { view, layout, _ in
            layout.alignSelf = .center
            view.activityIndicatorViewStyle = .whiteLarge
            view.startAnimating()
        }
    }
    
    private func videoView(video: ProductVideo) -> NodeType {
        let imageUrl = "https://img.youtube.com/vi/\(video.url)/0.jpg"
        
        return Node<UIImageView>(identifier: video.url) { view, layout, _ in
            layout.width = 140
            layout.height = 80
            layout.marginLeft = 10
            layout.marginRight = 10
            layout.justifyContent = .center
            view.backgroundColor = .tpBackground()
            view.contentMode = .scaleAspectFill
            view.clipsToBounds = true
            view.layer.cornerRadius = 4
            view.layer.masksToBounds = true
            view.setImageWith(URL(string: imageUrl)!)
            view.isUserInteractionEnabled = true
            
            let tapGestureRecognizer = UITapGestureRecognizer()
            _ = tapGestureRecognizer.rx.event.subscribe(onNext: { [unowned self] _ in
                self.didTapVideo(video)
            })
            view.addGestureRecognizer(tapGestureRecognizer)
            
        }.add(children: [
            self.videoPlaceholderView(videoUrl: video.url)
        ])
    }
    
    private func videoListView() -> NodeType {
        guard let videos = state.productDetail?.videos.map({ (video) -> NodeType in
            videoView(video: video)
        }) else {
            return NilNode()
        }
        
        if let videos = state.productDetail?.videos, videos.isEmpty {
            return NilNode()
        }
        
        return Node<UIScrollView>(identifier: "Product-Scroll-View") { view, layout, size in
            layout.width = size.width
            layout.height = 80
            layout.flexDirection = .row
            layout.alignItems = .stretch
            layout.marginBottom = 22
            view.showsHorizontalScrollIndicator = false
            view.isPagingEnabled = false
            view.bounces = true
            view.contentSize.width = 160.0 * CGFloat(videos.count)
            view.backgroundColor = .clear
        }.add(children: videos)
    }
    
    private func productDescriptionView() -> NodeType {
        guard var description = state.productDetail?.info.descriptionHtml() else { return NilNode() }
        
        return Node<TTTAttributedLabel>() { view, layout, size in
            layout.width = size.width - 30
            layout.marginLeft = 15
            layout.marginRight = 15
            layout.marginTop = 0
            layout.marginBottom = 4
            view.numberOfLines = 0
            view.font = .title1Theme()
            view.textColor = .tpSecondaryBlackText()
            view.isUserInteractionEnabled = true
            view.delegate = self.viewController
            
            description = description.kv_decodeHTMLCharacterEntities()
            var fullString = NSString.extracTKPMEUrl(description) as String
            var fullAttributedString = NSMutableAttributedString(string: fullString,
                                                                 attributes: [
                                                                     NSFontAttributeName: UIFont.title1Theme(),
                                                                     NSForegroundColorAttributeName: UIColor.tpSecondaryBlackText()
            ])
            if fullString.characters.count > 300 {
                let range = fullString.startIndex..<fullString.index(description.startIndex, offsetBy: 300)
                let subtringDesc = fullString[range]
                
                fullString = "\(subtringDesc)..."
                fullAttributedString = NSMutableAttributedString(string: fullString,
                                                                 attributes: [
                                                                     NSFontAttributeName: UIFont.title1Theme(),
                                                                     NSForegroundColorAttributeName: UIColor.tpSecondaryBlackText()
                ])
            }
            
            if description.isEmpty {
                view.text = "Tidak Ada Deskripsi"
            } else {
                view.attributedText = fullAttributedString
            }
            
            let descriptionSize = view.font.sizeOfString(string: fullString, constrainedToWidth: Double(size.width - 30))
            layout.height = descriptionSize.height + 12
            
            view.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
            if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
                let matches = detector.matches(in: fullString, options: [], range: NSRange(location: 0, length: fullString.utf16.count))
                
                for match in matches {
                    view.addLink(to: match.url, with: match.range)
                }
            }
        
            let longPressGestureRecognizer = UILongPressGestureRecognizer()
            longPressGestureRecognizer.minimumPressDuration = 1.0
            _ = longPressGestureRecognizer.rx.event
                .filter { event in
                    event.state == .began
                }
                .subscribe(onNext: { [unowned self] _ in
                    self.didLongPressDescription(view)
                })
            view.addGestureRecognizer(longPressGestureRecognizer)
        }
    }
    
    private func productBottomView() -> NodeType {
        guard let productInfo = state.productDetail?.info else { return NilNode() }
        
        var fullString = NSString.extracTKPMEUrl(productInfo.descriptionHtml()) as String
        if fullString.characters.count > 300 {
            return Node<UIView>(identifier: "Bottom-View") { _, layout, _ in
                layout.flexDirection = .column
            }.add(children: [
                GlobalRenderComponent.horizontalLine(identifier: "Description-Line-1", marginLeft: 0),
                productMoreView()
            ])
        }
        
        return Node { _, layout, _ in
            layout.height = 12
        }
    }
    
    private func productMoreView() -> NodeType {
        guard let productInfo = state.productDetail?.info else { return NilNode() }
        
        return Node<UIView>(identifier: "Product-More") { view, layout, _ in
            layout.height = 64
            layout.flexDirection = .row
            layout.alignContent = .center
            layout.justifyContent = .flexEnd
            
            let tapGestureRecognizer = UITapGestureRecognizer()
            _ = tapGestureRecognizer.rx.event.subscribe(onNext: { [unowned self] _ in
                self.didTapDescription(productInfo)
            })
            view.addGestureRecognizer(tapGestureRecognizer)
        }.add(children: [
            Node<UILabel>() { view, _, _ in
                view.font = .title1Theme()
                view.textColor = .tpGreen()
                view.text = "Baca Selengkapnya"
                view.numberOfLines = 4
            },
            Node<UIImageView>(identifier: "more-icon", create: {
                let view = UIImageView(image: #imageLiteral(resourceName: "icon_carret_green"))
                view.transform = view.transform.rotated(by: CGFloat(Double.pi))
                return view
                
            }, configure: { _, layout, _ in
                layout.height = 18
                layout.width = 18
                layout.marginRight = 15
                layout.alignSelf = .center
            })
        ])
    }
}
