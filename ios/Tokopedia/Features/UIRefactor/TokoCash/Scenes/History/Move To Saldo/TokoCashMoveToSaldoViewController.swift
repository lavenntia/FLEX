//
//  TokoCashMoveToSaldoViewController.swift
//  Tokopedia
//
//  Created by Tiara Freddy Andika on 10/11/17.
//  Copyright © 2017 TOKOPEDIA. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class TokoCashMoveToSaldoViewController: UIViewController {
    
    @IBOutlet weak var nominalLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var moveToSaldoButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // view model
    var viewModel: TokoCashMoveToSaldoViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    private func bindViewModel() {
        assert(viewModel != nil)
        let viewWillAppear = rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        let input = TokoCashMoveToSaldoViewModel.Input(trigger: viewWillAppear,
                                                       cancelTrigger: cancelButton.rx.tap.asDriver(),
                                                       moveToSaldoTrigger: moveToSaldoButton.rx.tap.asDriver())
        let output = viewModel.transform(input: input)
        
        output.nominal
            .drive(nominalLabel.rx.text)
            .disposed(by: rx_disposeBag)
        
        output.disableButton
            .drive(moveToSaldoButton.rx.isEnabled)
            .addDisposableTo(rx_disposeBag)
        
        output.backgroundButtonColor
            .drive(onNext: { color in
                self.moveToSaldoButton.backgroundColor = color
            }).addDisposableTo(rx_disposeBag)
        
        output.cancel
            .drive()
            .disposed(by: rx_disposeBag)
        
        output.requestActivity
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: rx_disposeBag)
        
        output.moveToSaldoSuccess
            .drive()
            .disposed(by: rx_disposeBag)
        
        output.moveToSaldoFailed
            .drive()
            .disposed(by: rx_disposeBag)
    }
}
