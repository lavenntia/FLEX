//
//  FreeReturnsConfirmationAlertView.swift
//  Tokopedia
//
//  Created by Billion Goenawan on 9/1/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit

class OrderDeliveredConfirmationAlertView: TKPDAlertView {
    
    var didComplain: (() -> Void)?
    
    var didOK: (() -> Void)?
    
    var didCancel: (() -> Void)?
    
    @IBOutlet var alertTitleLabel: UILabel!
    @IBOutlet var alertMessageLabel: UILabel!
    @IBOutlet var freeReturnsInfoView: UIView!
    @IBOutlet var freeReturnsInfoHeightConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.frame.size.width = 300
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @IBAction func didTapOKButton(sender: UIButton) {
        if let didOK = didOK {
            didOK()
        }
    }
    
    @IBAction func didTapComplainButton(sender: UIButton) {
        if let didComplain = didComplain {
            didComplain()
        }
    }
    
    @IBAction func didCancel(sender: UIButton) {
        if let didCancel = didCancel {
            didCancel()
        }
    }
    
    func dismiss() {
        self.dismissWithClickedButtonIndex(0, animated: true)
    }
    
    func setHeight(height: CGFloat) {
        self.frame.size.height = height
    }
}
