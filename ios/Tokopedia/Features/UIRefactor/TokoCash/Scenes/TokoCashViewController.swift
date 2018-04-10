//
//  TokoCashViewController.swift
//  Tokopedia
//
//  Created by Tiara Freddy Andika on 08/02/18.
//  Copyright © 2018 TOKOPEDIA. All rights reserved.
//

import CFAlertViewController
import RxCocoa
import RxSwift
import UIKit

public class TokoCashViewController: UIViewController {
    
    // outlet
    @IBOutlet weak private var scrollView: UIScrollView!
    @IBOutlet weak private var stackView: UIStackView!
    @IBOutlet weak private var balanceActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak private var totalActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak private var thresholdActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak private var topUpView: UIView!
    @IBOutlet weak private var balanceLabel: UILabel!
    @IBOutlet weak private var holdBalanceView: UIView!
    @IBOutlet weak private var holdBalanceDescView: UIView!
    @IBOutlet weak private var holdBalanceInfoButton: UIButton!
    @IBOutlet weak private var holdBalanceLabel: UILabel!
    @IBOutlet weak private var totalBalanceLabel: UILabel!
    @IBOutlet weak private var thresholdLabel: UILabel!
    @IBOutlet weak private var walletProgressView: UIProgressView!
    @IBOutlet weak private var nominalLabel: UILabel!
    @IBOutlet weak private var nominalButton: UIButton!
    @IBOutlet weak private var topUpButton: UIButton!
    @IBOutlet weak private var topUpActivityIndicator: UIActivityIndicatorView!
    
    private let optionBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icon_option_grey"), style: .plain, target: self, action: nil)
    private let refreshControl = UIRefreshControl()
    
    // view model
    public var viewModel: TokoCashViewModel!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = "TokoCash"
        navigationItem.rightBarButtonItem = optionBarButtonItem
        
        configureRefreshControl()
        bindViewModel()
        configureTapHoldBalanceInfo()
        configureTapOptionButton()
    }
    
    private func bindViewModel() {
        assert(viewModel != nil)
        
        let viewWillAppear = rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        
        let pull = refreshControl.rx
            .controlEvent(.valueChanged)
            .asDriver()
        
        let input = TokoCashViewModel.Input(didLoadTrigger: Driver.just(),
                                            refreshTrigger: Driver.merge(viewWillAppear, pull),
                                            nominalTrigger: nominalButton.rx.tap.asDriver(),
                                            topUpTrigger: topUpButton.rx.tap.asDriver())
        let output = viewModel.transform(input: input)
        
        // fetching
        output.fetching.drive(refreshControl.rx.isRefreshing).disposed(by: rx_disposeBag)
        output.fetching.drive(balanceActivityIndicatorView.rx.isAnimating).disposed(by: rx_disposeBag)
        output.fetching.drive(totalActivityIndicatorView.rx.isAnimating).disposed(by: rx_disposeBag)
        output.fetching.drive(thresholdActivityIndicatorView.rx.isAnimating).disposed(by: rx_disposeBag)
        output.fetching
            .drive(onNext: { isHidden in
                self.balanceLabel.isHidden = isHidden
                self.totalBalanceLabel.isHidden = isHidden
                self.thresholdLabel.isHidden = isHidden
            })
            .disposed(by: rx_disposeBag)
        
        // balance info
        output.balance.drive(balanceLabel.rx.text).disposed(by: rx_disposeBag)
        output.holdBalance.drive(holdBalanceLabel.rx.text).disposed(by: rx_disposeBag)
        output.totalBalance.drive(totalBalanceLabel.rx.text).disposed(by: rx_disposeBag)
        output.threshold.drive(thresholdLabel.rx.text).disposed(by: rx_disposeBag)
        output.holdBalanceView
            .drive(onNext: { isHidden in
                UIView.animate(withDuration: 0.3) {
                    self.holdBalanceDescView.isHidden = isHidden
                    self.holdBalanceLabel.isHidden = isHidden
                    self.holdBalanceView.isHidden = isHidden
                    self.holdBalanceView.backgroundColor = isHidden ? .clear : .white
                    self.stackView.layoutIfNeeded()
                }
            })
            .disposed(by: rx_disposeBag)
        output.spendingProgress
            .drive(onNext: { progress in
                self.walletProgressView.setProgress(progress, animated: true)
            })
            .disposed(by: rx_disposeBag)
        
        // Top Up
        output.isTopUpVisible
            .debug()
            .drive(topUpView.rx.isHidden)
            .dispose()
        output.selectedNominalString.drive(nominalLabel.rx.text).disposed(by: rx_disposeBag)
        output.nominal
            .drive()
            .disposed(by: rx_disposeBag)
        output.topUp
            .drive()
            .disposed(by: rx_disposeBag)
        output.topUpActivityIndicator
            .drive(topUpActivityIndicator.rx.isAnimating)
            .disposed(by: rx_disposeBag)
        
        // button
        output.disableTopUpButton.drive(topUpButton.rx.isEnabled).disposed(by: rx_disposeBag)
        output.backgroundButtonColor
            .drive(onNext: { color in
                self.topUpButton.backgroundColor = color
            }).addDisposableTo(rx_disposeBag)
        
    }
    
    private func configureRefreshControl() {
        if #available(iOS 10.0, *) {
            scrollView.refreshControl = refreshControl
        } else {
            scrollView.addSubview(refreshControl)
        }
    }
    
    private func configureTapHoldBalanceInfo() {
        holdBalanceInfoButton.rx.tap
            .subscribe(onNext: { _ in
                let closeButton = CFAlertAction.action(title: "Tutup",
                                                       style: .Default,
                                                       alignment: .justified,
                                                       backgroundColor: #colorLiteral(red: 0.3051282465, green: 0.7462322116, blue: 0.356926471, alpha: 1),
                                                       textColor: .white,
                                                       handler: nil)
                let actionSheet = TooltipAlert.createAlert(title: "Dana Tertahan",
                                                           subtitle: "Dana Anda tertahan, untuk Transaksi yang Belum Lunas. Dana akan dikembalikan bila transaksi batal.",
                                                           image: #imageLiteral(resourceName: "icon_tokocash_lock"),
                                                           buttons: [closeButton])
                self.present(actionSheet, animated: true, completion: nil)
            })
            .disposed(by: rx_disposeBag)
    }
    
    private func configureTapOptionButton() {
        optionBarButtonItem.rx.tap
            .subscribe(onNext: { _ in
                
                let navigator = TokoCashNavigator(navigationController: self.navigationController!)
                
                let alertController = UIAlertController(title: nil, message: "Lainnya", preferredStyle: .actionSheet)
                let openWalletHistoryAction = UIAlertAction(title: "Riwayat Transaksi", style: .default) { _ in
                    navigator.toWalletHistory()
                }
                let settingAction = UIAlertAction(title: "Pengaturan Akun", style: .default) { _ in
                    navigator.toAccountSetting()
                }
                let helpAction = UIAlertAction(title: "Bantuan", style: .default) { _ in
                    navigator.toHelpWebView()
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
                
                alertController.addAction(openWalletHistoryAction)
                alertController.addAction(settingAction)
                alertController.addAction(helpAction)
                alertController.addAction(cancelAction)
                alertController.popoverPresentationController?.barButtonItem = self.optionBarButtonItem
                self.present(alertController, animated: true)
            })
            .disposed(by: rx_disposeBag)
    }
}
