//
//  TxOrderObjectMapping.m
//  Tokopedia
//
//  Created by IT Tkpd on 2/6/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "TxOrderObjectMapping.h"

@implementation TxOrderObjectMapping

#pragma mark - Order
-(RKObjectMapping*)confirmationDetailMapping
{
    RKObjectMapping *confirmationMapping = [RKObjectMapping mappingForClass:[OrderConfirmationDetail class]];
    [confirmationMapping addAttributeMappingsFromArray:@[
                                                         API_CONFIRMATION_KEY,
                                                         API_CONFIRMATION_LEFT_AMOUNT_KEY,
                                                         API_CONFIRMATION_STATUS_KEY,
                                                         API_CONFIRMATION_PAY_DUE_DATE_KEY,
                                                         API_CONFIRMATION_CREATE_TIME_KEY,
                                                         API_CONFIRMATION_OPEN_AMOUNT_BEFORE_FEE_KEY,
                                                         API_CONFIRMATION_CONFIRMATION_ID_KEY,
                                                         API_CONFIRMATION_DEPOSIT_AMOUNT_KEY,
                                                         API_CONFIRMATION_OPEN_AMOUNT_KEY,
                                                         API_CONFIRMATION_DEPOSIT_AMOUNT_PLAIN_KEY,
                                                         API_CONFIRMATION_VOUCHER_AMOUNT_KEY,
                                                         API_CONFIRMATION_COSTUMER_ID_KEY,
                                                         API_CONFIRMATION_PAYMENT_TYPE_KEY,
                                                         API_CONFIRMATION_TOTAL_ITEM_KEY,
                                                         API_CONFIRMATION_SHOP_LIST_KEY
                                                         ]];
    return confirmationMapping;
}

-(RKObjectMapping*)orderListMapping
{
    RKObjectMapping *orderListMapping = [RKObjectMapping mappingForClass:[TxOrderConfirmationListOrder class]];
    [orderListMapping addAttributeMappingsFromArray:@[API_ORDER_LIST_JOB_STATUS_KEY,
                                                      API_ORDER_LIST_AUTO_RESI_KEY
                                                      ]];
    return orderListMapping;
}

-(RKObjectMapping*)orderExtraFeeMapping
{
    RKObjectMapping *extraFeeMapping = [RKObjectMapping mappingForClass:[OrderExtraFee class]];
    [extraFeeMapping addAttributeMappingsFromArray:@[API_EXTRA_FEE_KEY,
                                                     API_EXTRA_FEE_AMOUNT_KEY,
                                                     API_EXTRA_FEE_AMOUNT_IDR_KEY,
                                                     API_EXTRA_FEE_TYPE_KEY
                                                     ]];
    return extraFeeMapping;
}

-(RKObjectMapping*)orderProductsMapping
{
    RKObjectMapping *orderProductMapping = [RKObjectMapping mappingForClass:[OrderProduct class]];
    [orderProductMapping addAttributeMappingsFromArray:@[API_PRODUCT_ORDER_DELIVERY_QUANTITY,
                                                         API_PRODUCT_PICTURE,
                                                         API_PRODUCT_PRICE,
                                                         API_PRODUCT_ORDER_DETAIL_ID,
                                                         API_PRODUCT_NOTES,
                                                         API_PRODUCT_STATUS,
                                                         API_PRODUCT_ORDER_SUBTOTAL_PRICE,
                                                         API_PRODUCT_ID,
                                                         API_PRODUCT_QUANTITY,
                                                         API_PRODUCT_WEIGHT,
                                                         API_PRODUCT_ORDER_SUBTOTAL_PRICE_IDR,
                                                         API_PRODUCT_REJECT_QUANTITY,
                                                         API_PRODUCT_NAME,
                                                         API_PRODUCT_URL
                                                         ]];
    return orderProductMapping;
}

-(RKObjectMapping*)orderShopMapping
{
    RKObjectMapping *orderShopMapping = [RKObjectMapping mappingForClass:[OrderShop class]];
    [orderShopMapping addAttributeMappingsFromArray:@[API_SHOP_URI_KEY,
                                                      API_SHOP_ID_KEY,
                                                      API_SHOP_NAME_KEY,
                                                      API_SHOP_PIC_KEY
                                                      ]];
    return orderShopMapping;
}

-(RKObjectMapping*)orderShipmentsMapping
{
    RKObjectMapping *shipmentsMapping = [RKObjectMapping mappingForClass:[OrderShipment class]];
    [shipmentsMapping addAttributeMappingsFromArray:@[API_ORDER_SHIPMENT_LOGO_KEY,
                                                      API_ORDER_SHIPMENT_PACKAGE_ID_KEY,
                                                      API_ORDER_SHIPMENT_SHIPMENT_ID_KEY,
                                                      API_ORDER_SHIPMENT_PRODUCT_KEY,
                                                      API_ORDER_SHIPMENT_NAME_KEY
                                                      ]];
    return shipmentsMapping;
}

-(RKObjectMapping *)orderDestinationMapping
{
    RKObjectMapping *destinationMapping = [RKObjectMapping mappingForClass:[OrderDestination class]];
    [destinationMapping addAttributeMappingsFromArray:@[API_DESTINATION_RECEIVER_NAME,
                                                        API_DESTINATION_ADDRESS_COUNTRY,
                                                        API_DESTINATION_ADDRESS_POSTAL,
                                                        API_DESTINATION_ADDRESS_DISTRICT,
                                                        API_DESTINATION_RECEIVER_PHONE,
                                                        API_DESTINATION_ADDRESS_STREET,
                                                        API_DESTINATION_ADDRESS_CITY,
                                                        API_DESTINATION_ADDRESS_PROVINCE
                                                        ]];
    return destinationMapping;
}

-(RKObjectMapping *)orderDetailMapping
{
    RKObjectMapping *orderDetailMapping = [RKObjectMapping mappingForClass:[OrderDetail class]];
    [orderDetailMapping addAttributeMappingsFromArray:@[API_DETAIL_INSURANCE_PRICE,
                                                        API_DETAIL_OPEN_AMOUNT,
                                                        API_DETAIL_QUANTITY,
                                                        API_DETAIL_PRODUCT_PRICE_IDR,
                                                        API_DETAIL_INVOICE,
                                                        API_DETAIL_SHIPPING_PRICE_IDR,
                                                        API_DETAIL_PDF_PATH,
                                                        API_DETAIL_ADDITIONAL_FEE_IDR,
                                                        API_DETAIL_PRODUCT_PRICE,
                                                        API_DETAIL_FORCE_INSURANCE,
                                                        API_DETAIL_ADDITIONAL_FEE,
                                                        API_DETAIL_ORDER_ID,
                                                        API_DETAIL_TOTAL_ADD_FEE_IDR,
                                                        API_DETAIL_ORDER_DATE,
                                                        API_DETAIL_SHIPPING_PRICE,
                                                        API_DETAIL_PAY_DUE_DATE,
                                                        API_DETAIL_TOTAL_WEIGHT,
                                                        API_DETAIL_INSURANCE_PRICE_IDR,
                                                        API_DETAIL_PDF_URI,
                                                        API_DETAIL_SHIP_REF_NUM,
                                                        API_DETAIL_FORCE_CANCEL,
                                                        API_DETAIL_PRINT_ADDRESS_URI,
                                                        API_DETAIL_PDF,
                                                        API_DETAIL_ORDER_STATUS,
                                                        API_DETAIL_TOTAL_ADD_FEE,
                                                        API_DETAIL_OPEN_AMOUNT_IDR,
                                                        API_DETAIL_PARTIAL_ORDER,
                                                        API_DETAIL_DROPSHIP_NAME,
                                                        API_DETAIL_DROPSHIP_TELP
                                                        ]];
    return orderDetailMapping;
}

-(RKObjectMapping*)orderDeadlineMapping
{
    RKObjectMapping *deadlineMapping = [RKObjectMapping mappingForClass:[OrderDeadline class]];
    [deadlineMapping addAttributeMappingsFromArray:@[API_DEADLINE_PROCESS_DAY_LEFT_KEY,
                                                     API_DEADLINE_SHIPPING_DAY_LEFT_KEY
                                                     ]];
    
    return deadlineMapping;
}

-(RKObjectMapping*)orderLastMapping
{
    RKObjectMapping *orderLastMapping = [RKObjectMapping mappingForClass:[OrderLast class]];
    [orderLastMapping addAttributeMappingsFromDictionary:@{
                                                           API_LAST_ORDER_ID            : API_LAST_ORDER_ID,
                                                           API_LAST_SHIPMENT_ID         : API_LAST_SHIPMENT_ID,
                                                           API_LAST_EST_SHIPPING_LEFT   : API_LAST_EST_SHIPPING_LEFT,
                                                           API_LAST_ORDER_STATUS        : API_LAST_ORDER_STATUS,
                                                           API_LAST_ORDER_STATUS_DATE   : API_LAST_ORDER_STATUS_DATE,
                                                           API_LAST_POD_CODE            : API_LAST_POD_CODE,
                                                           API_LAST_POD_DESC            : API_LAST_POD_DESC,
                                                           API_LAST_SHIPPING_REF_NUM    : API_LAST_SHIPPING_REF_NUM,
                                                           API_LAST_POD_RECEIVER        : API_LAST_POD_RECEIVER,
                                                           API_LAST_COMMENTS            : API_LAST_COMMENTS,
                                                           API_LAST_BUYER_STATUS        : API_LAST_BUYER_STATUS,
                                                           API_LAST_STATUS_DATE_WIB     : API_LAST_STATUS_DATE_WIB,
                                                           API_LAST_SELLER_STATUS       : API_LAST_SELLER_STATUS,
                                                           }];
    return orderLastMapping;
}

-(RKObjectMapping*)orderHistoryMapping
{
    RKObjectMapping *orderHistoryMapping = [RKObjectMapping mappingForClass:[OrderHistory class]];
    [orderHistoryMapping addAttributeMappingsFromDictionary:@{
                                                              API_HISTORY_STATUS_DATE       : API_HISTORY_STATUS_DATE,
                                                              API_HISTORY_STATUS_DATE_FULL  : API_HISTORY_STATUS_DATE_FULL,
                                                              API_HISTORY_ORDER_STATUS      : API_HISTORY_ORDER_STATUS,
                                                              API_HISTORY_COMMENTS          : API_HISTORY_COMMENTS,
                                                              API_HISTORY_ACTION_BY         : API_HISTORY_ACTION_BY,
                                                              API_HISTORY_BUYER_STATUS      : API_HISTORY_BUYER_STATUS,
                                                              API_HISTORY_SELLER_STATUS     : API_HISTORY_SELLER_STATUS,
                                                              }];
    return orderHistoryMapping;
}

-(RKObjectMapping*)orderButtonMapping
{
    RKObjectMapping *orderButtonMapping = [RKObjectMapping mappingForClass:[OrderButton class]];
    [orderButtonMapping addAttributeMappingsFromArray:@[API_BUTTON_OPEN_DISPUTE_KEY,
                                                        API_BUTTON_RES_CENTER_URL_KEY,
                                                        API_BUTTON_OPEN_TIME_LEFT_KEY,
                                                        API_BUTTON_RES_CENTER_GO_TO_KEY,
                                                        API_BUTTON_UPLOAD_PROOF_KEY
                                                        ]];
    return orderButtonMapping;
}

#pragma mark - Confirmed

-(RKObjectMapping*)confirmedListMapping
{
    RKObjectMapping *confirmedMapping = [RKObjectMapping mappingForClass:[TxOrderConfirmedList class]];
    [confirmedMapping addAttributeMappingsFromArray:@[API_ORDER_COUNT_KEY,
                                                      API_ORDER_USER_ACOUNT_NAME_KEY,
                                                      API_ORDER_USER_BANK_NAME_KEY,
                                                      API_ORDER_PAYMENT_DATE_KEY,
                                                      API_ORDER_PAYMENT_REF_NUMBER_KEY,
                                                      API_ORDER_USER_ACCOUNT_NO_KEY,
                                                      API_ORDER_BANK_NAME_KEY,
                                                      API_ORDER_SYSTEM_ACCOUNT_NO_KEY,
                                                      API_ORDER_PAYMENT_ID_KEY,
                                                      API_ORDER_BUTTON_KEY,
                                                      API_ORDER_BUTTON_UPLOAD_PROOF_KEY,
                                                      API_ORDER_HAS_USER_BANK_KEY,
                                                      API_ORDER_PAYMENT_AMOUNT_KEY,
                                                      @"img_proof_url"
                                                      ]];
    return confirmedMapping;
}

-(RKObjectMapping*)bankAccountListMapping
{
    RKObjectMapping *listBankMapping = [RKObjectMapping mappingForClass:[BankAccountFormList class]];
    [listBankMapping addAttributeMappingsFromArray:@[API_BANK_ID_KEY,
                                                     API_BANK_NAME_KEY,
                                                     API_BANK_ACCOUNT_NAME_KEY,
                                                     API_BANK_ACCOUNT_NUMBER_KEY,
                                                     API_BANK_ACCOUNT_BRANCH_KEY,
                                                     API_BANK_ACCOUNT_ID_KEY,
                                                     ]];
    return listBankMapping;
}

-(RKObjectMapping*)systemBankListMapping
{
    RKObjectMapping *listSystemBankMapping = [RKObjectMapping mappingForClass:[SystemBankAcount class]];
    [listSystemBankMapping addAttributeMappingsFromArray:@[API_SYSTEM_BANK_ACCOUNT_NUMBER_KEY,
                                                           API_SYSTEM_BANK_ACCOUNT_NAME_KEY,
                                                           API_SYSTEM_BANK_NAME_KEY,
                                                           API_SYSTEM_BANK_NOTE_KEY,
                                                           API_SYSTEM_BANK_ID_KEY
                                                           ]];
    return listSystemBankMapping;
}

-(RKObjectMapping*)methodListMapping
{
    RKObjectMapping *listMethodMapping = [RKObjectMapping mappingForClass:[MethodList class]];
    [listMethodMapping addAttributeMappingsFromArray:@[API_METHOD_ID_KEY,
                                                       API_METHOD_NAME_KEY
                                                       ]];
    
    return listMethodMapping;
}

-(RKObjectMapping*)confirmedOrderDetailMapping
{
    RKObjectMapping *orderMapping = [RKObjectMapping mappingForClass:[OrderDetailForm class]];
    [orderMapping addAttributeMappingsFromArray:@[API_ORDER_FORM_LEFT_AMOUNT_IDR_KEY,
                                                  API_ORDER_FORM_DEPOSIT_USED_IDR_KEY,
                                                  API_ORDER_FORM_INVOICE_KEY,
                                                  API_ORDER_FORM_CONFIRMATION_CODE_IDR_KEY,
                                                  API_ORDER_FORM_GRAND_TOTAL_IDR_KEY,
                                                  API_ORDER_FORM_LEFT_AMOUNT_KEY,
                                                  API_ORDER_FORM_CONFIRMATION_CODE_KEY,
                                                  API_ORDER_FORM_DEPOSIT_USED_KEY,
                                                  API_ORDER_FORM_DEPOSITABLE_KEY,
                                                  API_ORDER_FORM_GRAND_TOTAL_KEY,
                                                  API_ORDER_FORM_PAYMENT_DAY_KEY,
                                                  API_ORDER_FORM_PAYMENT_MONTH_KEY,
                                                  API_ORDER_FORM_PAYMENT_YEAR_KEY,
                                                  API_ORDER_FORM_PAYMENT_AMOUNT_KEY
                                                  ]];
    return orderMapping;
}

@end
