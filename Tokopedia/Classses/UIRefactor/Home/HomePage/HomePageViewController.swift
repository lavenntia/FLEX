//
//  HomePageViewController.swift
//  Tokopedia
//
//  Created by Kenneth Vincent on 7/26/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit
import Foundation

@IBDesignable
@objc

class HomePageViewController: UIViewController, iCarouselDelegate, LoginViewDelegate {
    
    var slider: iCarousel!
    var carouselDataSource: CarouselDataSource!
    var categoryDataSource: CategoryDataSource!
    
    var banner: [Slide!]!
    var tickerRequest: AnnouncementTickerRequest!
    var tickerView: AnnouncementTickerView!
    
    var pulsaView = PulsaView!()
    var prefixes = Dictionary<String, Dictionary<String, String>>()
    var requestManager = PulsaRequest!()
    var navigator = PulsaNavigator!()
    
    var carouselView: UIView!
    var pulsaPlaceholder: UIView!
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var flow: UICollectionViewFlowLayout!
   
    private let sliderHeight: CGFloat = (UI_USER_INTERFACE_IDIOM() == .Pad) ? 225.0 : 175.0
    private let screenWidth = UIScreen.mainScreen().bounds.size.width
    
    init() {
        super.init(nibName: "HomePageViewController", bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.categoryDataSource = CategoryDataSource()
        self.categoryDataSource.delegate = self
        
        flow.headerReferenceSize = CGSizeMake(self.view.frame.width, 292)
        
        self.collectionView.dataSource = self.categoryDataSource
        self.collectionView.delegate = self.categoryDataSource
        self.collectionView.backgroundColor = UIColor.whiteColor()
        self.collectionView.collectionViewLayout = flow
        
        let cellNib = UINib(nibName: "CategoryViewCell", bundle: nil)
        self.collectionView.registerNib(cellNib, forCellWithReuseIdentifier: "CategoryViewCellIdentifier")

        self.carouselView = UIView(frame: CGRectZero)
        self.pulsaPlaceholder = UIView(frame: CGRectZero)
        self.pulsaPlaceholder.backgroundColor = UIColor.whiteColor()

        tickerRequest = AnnouncementTickerRequest()
        self.loadBanners()
        self.requestTicker()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Bordered, target: self, action: nil)
        
        let timer = NSTimer(timeInterval: 5.0, target: self, selector: #selector(moveToNextSlider), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        TPAnalytics.trackScreenName("Top Category")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        let bannersStore = HomePageViewController.self.TKP_rootController().storeManager().homeBannerStore
        bannersStore.stopBannerRequest()
    }
    
    // MARK: - Request Banner
    func loadBanners() {
        let bannersStore = HomePageViewController.self.TKP_rootController().storeManager().homeBannerStore
        
        let backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1.0)
        bannersStore.fetchBannerWithCompletion({[weak self] (banner, error) in
            self!.banner = banner
            self!.slider = iCarousel(frame: CGRectMake(0, 0, self!.screenWidth, self!.sliderHeight))
            self!.slider.backgroundColor = backgroundColor
            
            self!.carouselDataSource = CarouselDataSource(banner: banner)
            self!.carouselDataSource.delegate = self
            
            self!.slider.type = .Linear
            self!.slider.dataSource = self!.carouselDataSource
            self!.slider.delegate = self!.carouselDataSource
            self!.slider.decelerationRate = 0.5
            
            self?.carouselView .addSubview(self!.slider)
            self?.collectionView.addSubview((self?.carouselView)!)
            self?.collectionView.bringSubviewToFront((self?.carouselView)!)
            
            self?.carouselView.mas_makeConstraints { make in
                make.top.equalTo()(self!.collectionView.mas_top)
                make.left.equalTo()(self!.view.mas_left)
                make.right.equalTo()(self!.view.mas_right)
            }
            
            self?.collectionView.addSubview((self?.pulsaPlaceholder)!)
            
            self?.slider.mas_makeConstraints { make in
                make.height.equalTo()(self!.sliderHeight)
                make.top.equalTo()(self?.carouselView.mas_top)
                make.left.equalTo()(self?.carouselView.mas_left)
                make.right.equalTo()(self?.carouselView.mas_right)
                make.bottom.equalTo()(self?.carouselView.mas_bottom)
            }
            
            self?.pulsaPlaceholder.mas_makeConstraints { make in
                make.left.equalTo()(self?.carouselView.mas_left)
                make.right.equalTo()(self?.carouselView.mas_right)
                make.top.equalTo()(self!.carouselView?.mas_bottom)
            }

        })
        
        self.requestManager = PulsaRequest()
        self.requestManager.requestCategory()
        self.requestManager.didReceiveCategory = { [unowned self] categories in
            var activeCategories: [PulsaCategory] = []
            categories.enumerate().forEach { id, category in
                if(category.attributes.status == 1) {
                    activeCategories.append(category)
                }
            }
            
            var sortedCategories = activeCategories
            sortedCategories.sortInPlace({
                $0.attributes.weight < $1.attributes.weight
            })

            
            let container = UIView(frame: CGRectZero)
            self.pulsaView = PulsaView(categories: sortedCategories)
            self.pulsaView.attachToView(self.pulsaPlaceholder)
            
            self.navigator = PulsaNavigator()
            self.navigator.pulsaView = self.pulsaView
            self.navigator.controller = self
            
            self.pulsaView.didAskedForLogin = {
                self.navigator.loginDelegate = self
                self.navigator.navigateToLoginIfRequired()
            }
            
            self.pulsaView.didSuccessPressBuy = { url in
                self.navigator.navigateToSuccess(url)
            }
            
            self.requestManager.requestOperator()
            self.requestManager.didReceiveOperator = { operators in
                var sortedOperators = operators
                
                sortedOperators.sortInPlace({
                    $0.attributes.weight < $1.attributes.weight
                })
                
                self.didReceiveOperator(sortedOperators)
            }
            
        }
    }
    
    func mappingPrefixFromOperators(operators: [PulsaOperator]) {
        //mapping operator by prefix
        // {0812 : {"image" : "simpati.png", "id" : "1"}}
        operators.enumerate().forEach { id, op in
            op.attributes.prefix.map { prefix in
                var prefixDictionary = Dictionary<String, String>()
                prefixDictionary["image"] = op.attributes.image
                prefixDictionary["id"] = op.id
                
                //BOLT only had 3 chars prefix
                if(prefix.characters.count == 3) {
                    let range = 0...9
                    range.enumerate().forEach { index, element in
                        prefixes[prefix.stringByAppendingString(String(element))] = prefixDictionary
                    }
                } else {
                    prefixes[prefix] = prefixDictionary
                }
            }
            
        }
        
        if(prefixes.count > 0) {
            self.pulsaView.prefixes = self.prefixes
        }
    }
    
    func didReceiveOperator(operators: [PulsaOperator]) {
        self.mappingPrefixFromOperators(operators)
        
        self.pulsaView.addActionNumberField();
        self.pulsaView.invalidateViewHeight = {
            let debounced = Debouncer(delay: 0.1) {
                self.flow.headerReferenceSize = CGSizeMake(self.view.frame.width, self.pulsaPlaceholder.frame.origin.y + self.pulsaPlaceholder.frame.size.height)
            }
            
            debounced.call()
        }
        
        self.pulsaView.didPrefixEntered = { operatorId, categoryId in
            self.pulsaView.selectedOperator = self.findOperatorById(operatorId, operators: operators)
            
            self.requestManager.requestProduct(operatorId, categoryId: categoryId)
            self.pulsaView.showBuyButton([])
            
            self.requestManager.didReceiveProduct = { products in
                self.didReceiveProduct(products)
            }

        }
        
        self.pulsaView.didTapAddressbook = { [unowned self] contacts in
            self.navigator.navigateToAddressBook(contacts)
        }
    }
    
    func didReceiveProduct(products: [PulsaProduct]) {
        if(products.count > 0) {
            self.pulsaView.showBuyButton(products)
            self.pulsaView.didTapProduct = { [unowned self] products in
                self.navigator.navigateToPulsaProduct(products)
            }
        }
    }
    
    func findOperatorById(id: String, operators: [PulsaOperator]) -> PulsaOperator{
        var foundOperator = PulsaOperator()
        operators.enumerate().forEach { index, op in
            if(op.id == id) {
                foundOperator = operators[index]
            }
        }
        
        return foundOperator
    }
    
    func redirectViewController(viewController: AnyObject!) {
        
    }
    
    func requestTicker() {
        tickerRequest.fetchTicker({[weak self] (ticker) in
            if (ticker.tickers.count > 0) {
                let randomIndex = Int(arc4random_uniform(UInt32(ticker.tickers.count)))
                let tick = ticker.tickers[randomIndex]
                self!.tickerView = AnnouncementTickerView.newView()
                self!.tickerView.setTitle(tick.title)
                self!.tickerView.setMessage(tick.message)
                self!.tickerView.onTapMessageWithUrl = {[weak self] (url) in
                    self!.navigator.navigateToWebTicker(url)
                }
                
            }
            
        }) { (error) in
            
        }
    }
    
    func moveToNextSlider() {
        slider.scrollToItemAtIndex(slider.currentItemIndex + 1, duration: 1.0)
    }
}
