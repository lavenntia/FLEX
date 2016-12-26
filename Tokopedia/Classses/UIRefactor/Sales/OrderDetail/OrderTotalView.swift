//
//  OrderTotalView.swift
//  Tokopedia
//
//  Created by Renny Runiawati on 11/22/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit

class OrderTotalView: UIView {
    
    @IBOutlet private var totalProduct: UILabel!
    @IBOutlet private var subtotal: UILabel!
    @IBOutlet private var additionalFee: UILabel!
    @IBOutlet private var shipmentFee: UILabel!
    @IBOutlet private var totalPayment: UILabel!
    @IBOutlet private var additionalFeeTitleLabel: UILabel!
    @IBOutlet private var infoButton: UIButton!
    @IBOutlet private var courierAgentGesture: UITapGestureRecognizer!
    
    var onTapInfoButton:(() -> Void)?
    
    private var order = OrderTransaction(){
        didSet{
            totalProduct.text = "\(order.order_detail.detail_quantity) Barang (\(order.order_detail.detail_total_weight) kg)"
            subtotal.text = order.order_detail.detail_product_price_idr
            additionalFee.text = order.order_detail.additionalFee
            additionalFeeTitleLabel.text = order.order_detail.additionalFeeTitle
            shipmentFee.text = order.order_detail.detail_shipping_price_idr
            infoButton.hidden = (Int(order.order_detail.detail_additional_fee)==0)
            totalPayment.text = order.order_detail.detail_open_amount_idr;
        }
    }
    
    static func newView(order: OrderTransaction)-> UIView {
        
        let views:Array = NSBundle.mainBundle().loadNibNamed("OrderTotalView", owner: nil, options: nil)!
        let view = views.first as! OrderTotalView
        
        view.order = order
        
        return view
    }
    
    @IBAction func tapInfoButton(sender: AnyObject) {
        onTapInfoButton?()
    }
}
