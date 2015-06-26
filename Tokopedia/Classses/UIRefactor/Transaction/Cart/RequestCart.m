//
//  RequestCart.m
//  Tokopedia
//
//  Created by Renny Runiawati on 6/25/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "RequestCart.h"

#import "TransactionAction.h"
#import "TransactionSummary.h"
#import "TransactionBuy.h"
#import "TransactionVoucher.h"

#import "TransactionObjectManager.h"
#import "string_transaction.h"

@interface RequestCart()<TokopediaNetworkManagerDelegate>
{
    TokopediaNetworkManager *_networkManager;
    TokopediaNetworkManager *_networkManagerCancelCart;
    TokopediaNetworkManager *_networkManagerCheckout;
    TokopediaNetworkManager *_networkManagerBuy;
    TokopediaNetworkManager *_networkManagerVoucher;
    TokopediaNetworkManager *_networkManagerEditProduct;
    TokopediaNetworkManager *_networkManagerEMoney;
    TokopediaNetworkManager *_networkManagerBCAClickPay;
    
    TransactionObjectManager *_objectManager;
}

@end

@implementation RequestCart

-(TransactionObjectManager*)objectManager
{
    if (!_objectManager) {
        _objectManager = [TransactionObjectManager new];
    }
    NSNumber *gatewayID  = [_param objectForKey:@"gateway"];
    _objectManager.gatewayID = [gatewayID integerValue];
    return _objectManager;
}

-(TokopediaNetworkManager*)networkManager
{
    if (!_networkManager) {
        _networkManager = [TokopediaNetworkManager new];
        _networkManager.tagRequest = TAG_REQUEST_CART;
        _networkManager.delegate = self;
    }
    return _networkManager;
}

-(TokopediaNetworkManager*)networkManagerCancelCart
{
    if (!_networkManagerCancelCart) {
        _networkManagerCancelCart = [TokopediaNetworkManager new];
        _networkManagerCancelCart.tagRequest = TAG_REQUEST_CANCEL_CART;
        _networkManagerCancelCart.delegate = self;
    }
    return _networkManagerCancelCart;
}

-(TokopediaNetworkManager *)networkManagerCheckout
{
    if (!_networkManagerCheckout) {
        _networkManagerCheckout = [TokopediaNetworkManager new];
        _networkManagerCheckout.tagRequest = TAG_REQUEST_CHECKOUT;
        _networkManagerCheckout.delegate = self;
    }
    return _networkManagerCheckout;
}

-(TokopediaNetworkManager*)networkManagerBuy
{
    if (!_networkManagerBuy) {
        _networkManagerBuy = [TokopediaNetworkManager new];
        _networkManagerBuy.tagRequest = TAG_REQUEST_BUY;
        _networkManagerBuy.delegate = self;
    }
    return _networkManagerBuy;
}

-(TokopediaNetworkManager*)networkManagerVoucher
{
    if (!_networkManagerVoucher) {
        _networkManagerVoucher = [TokopediaNetworkManager new];
        _networkManagerVoucher.tagRequest = TAG_REQUEST_VOUCHER;
        _networkManagerVoucher.delegate = self;
    }
    return _networkManagerVoucher;
}

-(TokopediaNetworkManager*)networkManagerEditProduct
{
    if (!_networkManagerEditProduct) {
        _networkManagerEditProduct = [TokopediaNetworkManager new];
        _networkManagerEditProduct.tagRequest = TAG_REQUEST_EDIT_PRODUCT;
        _networkManagerEditProduct.delegate = self;
    }
    return _networkManagerEditProduct;
}

-(TokopediaNetworkManager*)networkManagerEMoney
{
    if (!_networkManagerEMoney) {
        _networkManagerEMoney = [TokopediaNetworkManager new];
        _networkManagerEMoney.tagRequest = TAG_REQUEST_EMONEY;
        _networkManagerEMoney.delegate = self;
    }
    return _networkManagerEMoney;
}

-(TokopediaNetworkManager*)networkManagerBCAClickPay
{
    if (!_networkManagerBCAClickPay) {
        _networkManagerBCAClickPay = [TokopediaNetworkManager new];
        _networkManagerBCAClickPay.tagRequest = TAG_REQUEST_BCA_CLICK_PAY;
        _networkManagerBCAClickPay.delegate = self;
    }
    
    return _networkManagerBCAClickPay;
}

-(void)doRequestCart
{
    [[self networkManager] doRequest];
}

-(void)doRequestCheckout
{
    [[self networkManagerCheckout] doRequest];
}

-(void)doRequestCancelCart
{
    [[self networkManagerCancelCart]doRequest];
}

-(void)dorequestBuy
{
    [[self networkManagerBuy]doRequest];
}

-(void)doRequestVoucher
{
    [[self networkManagerVoucher]doRequest];
}

-(void)doRequestEditProduct
{
    [[self networkManagerEditProduct]doRequest];
}

-(void)doRequestEMoney;
{
    [[self networkManagerEMoney]doRequest];
}

-(void)doRequestBCAClickPay
{
    [[self networkManagerBCAClickPay]doRequest];
}

#pragma mark - Network Manager Delegate
-(id)getObjectManager:(int)tag
{
    if (tag == TAG_REQUEST_CART) {
        return [[self objectManager] objectManagerCart];
    }
    if (tag == TAG_REQUEST_CANCEL_CART) {
        return [[self objectManager] objectManagerCancelCart];
    }
    if (tag == TAG_REQUEST_CHECKOUT) {
        return [[self objectManager] objectManagerCheckout];
    }
    if (tag == TAG_REQUEST_BUY) {
        return [[self objectManager] objectManagerBuy];
    }
    if (tag == TAG_REQUEST_VOUCHER) {
        return  [[self objectManager] objectManagerVoucher];
    }
    if (tag == TAG_REQUEST_EDIT_PRODUCT) {
        return [[self objectManager] objectMangerEditProduct];
    }

    return nil;
}

-(NSDictionary *)getParameter:(int)tag
{
    return _param?:@{};
}

-(NSString *)getPath:(int)tag
{
    if (tag == TAG_REQUEST_CART) {
        return API_TRANSACTION_PATH;
    }
    if (tag == TAG_REQUEST_CANCEL_CART) {
        return API_ACTION_TRANSACTION_PATH;
    }
    if (tag == TAG_REQUEST_CHECKOUT) {
        return API_TRANSACTION_PATH;
    }
    if (tag == TAG_REQUEST_BUY) {
        return API_TRANSACTION_PATH;
    }
    if (tag == TAG_REQUEST_VOUCHER) {
        return API_CHECK_VOUCHER_PATH;
    }
    if (tag == TAG_REQUEST_EDIT_PRODUCT) {
        return API_ACTION_TRANSACTION_PATH;
    }
    if (tag == TAG_REQUEST_EMONEY) {
        return API_EMONEY_PATH;
    }
    if (tag == TAG_REQUEST_BCA_CLICK_PAY) {
        return API_BCA_KLICK_PAY_PATH;
    }
    return nil;
}

-(void)actionBeforeRequest:(int)tag
{
    [_delegate actionBeforeRequest:tag];
}

-(NSString *)getRequestStatus:(id)result withTag:(int)tag
{
    NSDictionary *resultDict = ((RKMappingResult*)result).dictionary;
    id stat = [resultDict objectForKey:@""];
    
    if (tag == TAG_REQUEST_CART) {
        TransactionCart *cart = stat;
        return cart.status;
    }
    if (tag == TAG_REQUEST_CANCEL_CART) {
        TransactionAction *action = stat;
        return action.status;
    }
    if (tag == TAG_REQUEST_CHECKOUT) {
        TransactionSummary *cart = stat;
        return cart.status;
    }
    if (tag == TAG_REQUEST_BUY) {
        TransactionBuy *cart = stat;
        return cart.status;
    }
    
    if (tag == TAG_REQUEST_VOUCHER) {
        TransactionVoucher *dataVoucher = stat;
        return dataVoucher.status;
    }
    if (tag == TAG_REQUEST_EDIT_PRODUCT) {
        TransactionAction *action = stat;
        return action.status;
    }
    if (tag == TAG_REQUEST_EMONEY) {
        TxEmoney *emoney = stat;
        return emoney.status;
    }
    if (tag == TAG_REQUEST_BCA_CLICK_PAY) {
        TransactionBuy *BCAClickPay = stat;
        return BCAClickPay.status;
    }
    return nil;
}

-(void)actionAfterRequest:(id)successResult withOperation:(RKObjectRequestOperation *)operation withTag:(int)tag
{
    if (tag == TAG_REQUEST_CART) {
        [_delegate requestSuccessCart:successResult withOperation:operation];
    }
    if (tag == TAG_REQUEST_CANCEL_CART) {
        [_delegate requestSuccessActionCancelCart:successResult withOperation:operation];
    }
    if (tag == TAG_REQUEST_CHECKOUT) {
        [_delegate requestSuccessActionCheckout:successResult withOperation:operation];
    }
    if (tag == TAG_REQUEST_BUY) {
        [_delegate requestSuccessActionBuy:successResult withOperation:operation];
    }
    if (tag == TAG_REQUEST_VOUCHER) {
        [_delegate requestSuccessActionVoucher:successResult withOperation:operation];
    }
    if (tag == TAG_REQUEST_EDIT_PRODUCT) {
        [_delegate requestSuccessActionEditProductCart:successResult withOperation:operation];
    }
    if (tag == TAG_REQUEST_EMONEY) {
        [_delegate requestSuccessEMoney:successResult withOperation:operation];
    }
    if (tag == TAG_REQUEST_BCA_CLICK_PAY) {
        [_delegate requestSuccessBCAClickPay:successResult withOperation:operation];
    }
}

-(void)actionAfterFailRequestMaxTries:(int)tag
{
    [_delegate actionAfterFailRequestMaxTries:tag];
}


-(void)setParam:(NSDictionary *)param
{
    _param = param;
    NSNumber *gatewayID  = [_param objectForKey:@"gateway"];
    if([gatewayID integerValue] == TYPE_GATEWAY_CLICK_BCA){
        _objectManager = nil;
        _objectManager = [self objectManager];
    }

}

@end
