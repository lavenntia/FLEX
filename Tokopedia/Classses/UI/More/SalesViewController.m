//
//  PaymentViewController.m
//  Tokopedia
//
//  Created by Tokopedia PT on 12/16/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import "SalesViewController.h"
#import "SalesNewOrderViewController.h"
#import "ShipmentConfirmationViewController.h"

@interface SalesViewController ()

@property (weak, nonatomic) IBOutlet UILabel *orderCountValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *shipmentConfirmationValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *shipmentStatusValueLabel;

@property (weak, nonatomic) IBOutlet UILabel *orderLabel;
@property (weak, nonatomic) IBOutlet UILabel *shipmentConfirmationLabel;
@property (weak, nonatomic) IBOutlet UILabel *shipmentStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *transactionListLabel;

@property (weak, nonatomic) IBOutlet UIView *orderView;
@property (weak, nonatomic) IBOutlet UIView *shipmentConfirmationView;
@property (weak, nonatomic) IBOutlet UIView *shipmentStatusView;
@property (weak, nonatomic) IBOutlet UIView *transactionListView;

@end

@implementation SalesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _orderCountValueLabel.text = _notification.result.sales.sales_new_order?:@"0";
    _shipmentStatusValueLabel.text = _notification.result.sales.sales_shipping_status?:@"0";
    _shipmentConfirmationValueLabel.text = _notification.result.sales.sales_shipping_confirm?:@"0";
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 4.0;
    style.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName            : [UIFont fontWithName:@"GothamBook" size:14],
                                 NSParagraphStyleAttributeName  : style,
                                 NSForegroundColorAttributeName : [UIColor colorWithRed:10.0/255.0 green:126.0/255.0 blue:7.0/255.0 alpha:1],
                                 };

    _orderLabel.attributedText = [[NSAttributedString alloc] initWithString:_orderLabel.text
                                                                 attributes:attributes];
    
    _shipmentConfirmationLabel.attributedText = [[NSAttributedString alloc] initWithString:_shipmentConfirmationLabel.text
                                                                                attributes:attributes];
    
    _shipmentStatusLabel.attributedText = [[NSAttributedString alloc] initWithString:_shipmentStatusLabel.text
                                                                          attributes:attributes];
    
    _transactionListLabel.attributedText = [[NSAttributedString alloc] initWithString:_transactionListLabel.text
                                                                           attributes:attributes];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.hidesBottomBarWhenPushed = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)newOrderDidTap:(id)sender {
    SalesNewOrderViewController *controller = [[SalesNewOrderViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)shipmentConfirmationDidTap:(id)sender {
    ShipmentConfirmationViewController *controller = [[ShipmentConfirmationViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)shipmentStatusDidTap:(id)sender {
}

- (IBAction)listTransactionDidTap:(id)sender {
}


@end
