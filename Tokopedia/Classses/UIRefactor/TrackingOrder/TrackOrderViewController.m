//
//  TrackOrderViewController.m
//  Tokopedia
//
//  Created by Feizal Badri Asmoro on 2/4/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "string_track_order.h"

#import "Track.h"
#import "TrackOrderHistory.h"
#import "TrackOrderDetail.h"

#import "TrackOrderViewController.h"

@interface TrackOrderViewController ()
<
    UITableViewDataSource,
    UITableViewDelegate
>
{

    __weak RKObjectManager *_objectManager;
    __weak RKManagedObjectRequestOperation *_request;
    RKResponseDescriptor *_responseDescriptorStatus;
    NSOperationQueue *_operationQueue;
    
    TrackOrder *_trackingOrder;

}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *headerViewComplete;
@property (strong, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation TrackOrderViewController

typedef enum {
    ORDER_SHIPPING                  = 500,
    ORDER_SHIPPING_TRACKER_INVALID  = 520,
    ORDER_SHIPPING_REF_NUM_EDITED   = 530,
    ORDER_DELIVERED                 = 600,
    ORDER_DELIVERED_CONFIRM         = 610,
    ORDER_DELIVERED_DUE_DATE        = 620,
} ORDER_STATUS;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Lacak Pengiriman";
        
    _objectManager =  [RKObjectManager sharedClient];
    _operationQueue = [NSOperationQueue new];
    
    _tableView.tableFooterView = _footerView;
    [_activityIndicator startAnimating];
    
    [self configureRestKit];
    [self request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = 0;
    if (_trackingOrder.detail.shipper_name) {
        sections += 2;    
    }
    if ([_trackingOrder.track_history count] > 0) {
        sections++;
    }
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    if (_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] > 0) {
        if (section == 0 || section == 1) rows = 2;
        if (section == 2) rows = [_trackingOrder.track_history count];
    } else if (_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] == 0) {
        rows = 2;
    } else if (!_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] > 0) {
        rows = [_trackingOrder.track_history count];
    }
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == nil) {
        if (_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] > 0) {
            if (indexPath.section < 2){
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
            } else {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
            }
        } else if (_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] == 0) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        } else if (!_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] > 0) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        }
    }

    cell.textLabel.font = [UIFont fontWithName:@"GothamBook" size:14];
    cell.detailTextLabel.font = [UIFont fontWithName:@"GothamBook" size:13];
    cell.detailTextLabel.textColor = [UIColor grayColor];

    if (_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] > 0) {
        if (indexPath.section < 2) {
            [self configureTrackingDetailCell:cell indexPath:indexPath];
        } else {
            [self configureTrackingHistoryCell:cell indexPath:indexPath];
        }
    } else if (_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] == 0) {
        [self configureTrackingDetailCell:cell indexPath:indexPath];
    } else if (!_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] > 0) {
        [self configureTrackingHistoryCell:cell indexPath:indexPath];
    }

    return cell;
}

- (void)configureTrackingDetailCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Nama Pengirim";
            cell.detailTextLabel.text = _trackingOrder.detail.shipper_name;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Kota Pengirim";
            cell.detailTextLabel.text = _trackingOrder.detail.shipper_city;
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Nama Penerima";
            cell.detailTextLabel.text = _trackingOrder.detail.receiver_name;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Kota Penerima";
            cell.detailTextLabel.text = _trackingOrder.detail.receiver_city;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] > 0) {
        if (section < 2) {
            return 41;
        } else {
            return 51;
        }
    } else if (_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] == 0) {
        return 41;
    } else if (!_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] > 0) {
        return 51;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 41)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 8, self.view.frame.size.width-15, 41)];
    label.font = [UIFont fontWithName:@"GothamBook" size:14];
    label.textColor = [UIColor colorWithRed:66.0/255.0 green:66.0/255.0 blue:66.0/255.0 alpha:1];

    if (_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] > 0) {
        if (section == 0){
            label.text = @"PENGIRIM";
        } else if (section == 1) {
            label.text = @"PENERIMA";
        } else {
            label.text = @"TRACKING HISTORY";
        }
    } else if (_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] == 0) {
        if (section == 0){
            label.text = @"PENGIRIM";
        } else if (section == 1) {
            label.text = @"PENERIMA";
        }
    } else if (!_trackingOrder.detail.shipper_name && [_trackingOrder.track_history count] > 0) {
        label.text = @"TRACKING HISTORY";
    }

    [view addSubview:label];
    
    return view;
}

- (void)configureTrackingHistoryCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    TrackOrderHistory *history = [_trackingOrder.track_history objectAtIndex:indexPath.row];
    cell.textLabel.text = history.status;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", history.city, history.date];
}

- (void)configureRestKit
{
    RKObjectMapping *statusMapping = [RKObjectMapping mappingForClass:[Track class]];
    [statusMapping addAttributeMappingsFromDictionary:@{
                                                        kTKPD_APISTATUSKEY              : kTKPD_APISTATUSKEY,
                                                        kTKPD_APISERVERPROCESSTIMEKEY   : kTKPD_APISERVERPROCESSTIMEKEY
                                                        }];

    RKObjectMapping *resultMapping = [RKObjectMapping mappingForClass:[TrackOrderResult class]];
    
    RKObjectMapping *trackOrderMapping = [RKObjectMapping mappingForClass:[TrackOrder class]];
    [trackOrderMapping addAttributeMappingsFromDictionary:@{
                                                        API_CHANGE_KEY              : API_CHANGE_KEY,
                                                        API_NO_HISTORY_KEY          : API_NO_HISTORY_KEY,
                                                        API_RECEIVER_NAME_KEY       : API_RECEIVER_NAME_KEY,
                                                        API_ORDER_STATUS_KEY        : API_ORDER_STATUS_KEY,
                                                        API_SHIPPING_REF_NUM_KEY    : API_SHIPPING_REF_NUM_KEY,
                                                        API_INVALID_KEY             : API_INVALID_KEY,
                                                        }];

    RKObjectMapping *trackHistoryMapping = [RKObjectMapping mappingForClass:[TrackOrderHistory class]];
    [trackHistoryMapping addAttributeMappingsFromDictionary:@{
                                                              API_DATE_KEY      : API_DATE_KEY,
                                                              API_STATUS_KEY    : API_STATUS_KEY,
                                                              API_CITY_KEY      : API_CITY_KEY,
                                                              }];
    
    RKObjectMapping *trackDetailMapping = [RKObjectMapping mappingForClass:[TrackOrderDetail class]];
    [trackDetailMapping addAttributeMappingsFromDictionary:@{
                                                             API_SHIPPER_CITY_KEY   : API_SHIPPER_CITY_KEY,
                                                             API_SHIPPER_NAME_KEY   : API_SHIPPER_NAME_KEY,
                                                             API_RECEIVER_CITY_KEY  : API_RECEIVER_CITY_KEY,
                                                             API_SEND_DATE_KEY      : API_SEND_DATE_KEY,
                                                             API_RECEIVER_NAME_KEY  : API_RECEIVER_NAME_KEY,
                                                             API_SERVICE_CODE_KEY   : API_SERVICE_CODE_KEY,
                                                             }];
    
    [statusMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:kTKPD_APIRESULTKEY
                                                                                  toKeyPath:kTKPD_APIRESULTKEY
                                                                                withMapping:resultMapping]];
    
    [resultMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:API_TRACK_ORDER_KEY
                                                                                  toKeyPath:API_TRACK_ORDER_KEY
                                                                                withMapping:trackOrderMapping]];
    
    [trackOrderMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:API_TRACK_HISTORY_KEY
                                                                                      toKeyPath:API_TRACK_HISTORY_KEY
                                                                                    withMapping:trackHistoryMapping]];
    
    [trackOrderMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:API_DETAIL_KEY
                                                                                      toKeyPath:API_DETAIL_KEY
                                                                                    withMapping:trackDetailMapping]];    
 
    RKResponseDescriptor *responseDescriptorStatus = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping
                                                                                                  method:RKRequestMethodPOST
                                                                                             pathPattern:API_TRACKING_ORDER_PATH
                                                                                                 keyPath:@""
                                                                                             statusCodes:kTkpdIndexSetStatusCodeOK];
    
    [_objectManager addResponseDescriptor:responseDescriptorStatus];

}

- (void)request
{
    TKPDSecureStorage *secureStorage = [TKPDSecureStorage standardKeyChains];
    NSDictionary *auth = [secureStorage keychainDictionary];
    
    NSDictionary* param = @{
                            API_ACTION_KEY           : API_ACTION_TRACK_ORDER,
                            API_ORDER_ID_KEY         : _order.order_detail.detail_order_id,
                            API_USER_ID_KEY          : [auth objectForKey:API_USER_ID_KEY],
                            };

    _request = [_objectManager appropriateObjectRequestOperationWithObject:self
                                                                    method:RKRequestMethodPOST
                                                                      path:API_TRACKING_ORDER_PATH
                                                                parameters:[param encrypt]];

    [_operationQueue addOperation:_request];

    [_request setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        NSDictionary *result = ((RKMappingResult *) mappingResult).dictionary;
        Track *track = [result objectForKey:@""];
        BOOL status = [track.status isEqualToString:kTKPDREQUEST_OKSTATUS];
        if (status && track.result.track_order) {
            
            _trackingOrder = track.result.track_order;
            
            TrackOrderHistory *history1 = [TrackOrderHistory new];
            history1.date = @"06 Februari 2015";
            history1.status = @"asdada";
            history1.city = @"Jakarta";

            TrackOrderHistory *history2 = [TrackOrderHistory new];
            history2.date = @"06 Februari 2015";
            history2.status = @"asdada";
            history2.city = @"Bandung";

            TrackOrderHistory *history3 = [TrackOrderHistory new];
            history3.date = @"06 Februari 2015";
            history3.status = @"asdada";
            history3.city = @"Bali";
            
            _trackingOrder.track_history = @[history1, history2, history3];
            
            _tableView.contentInset = UIEdgeInsetsMake(22, 0, 0, 0);
            [_tableView reloadData];

            if (_trackingOrder.detail.shipper_name) {
                
                _tableView.tableHeaderView = _headerViewComplete;
                
                UILabel *receiptNumberLabel = (UILabel *)[_headerViewComplete viewWithTag:1];
                receiptNumberLabel.text = _trackingOrder.shipping_ref_num;
                
                UILabel *sendDateLabel = (UILabel *)[_headerViewComplete viewWithTag:2];
                sendDateLabel.text = _trackingOrder.detail.send_date;
                
                UILabel *serviceCodeLabel = (UILabel *)[_headerViewComplete viewWithTag:3];
                serviceCodeLabel.text = _trackingOrder.detail.service_code;
                
                UILabel *statusLabel = (UILabel *)[_headerViewComplete viewWithTag:4];
                if ([_trackingOrder.order_status integerValue] == ORDER_SHIPPING_REF_NUM_EDITED) {
                    statusLabel.text = @"Nomor Resi diganti oleh penjual";
                } else if ([_trackingOrder.order_status integerValue] == ORDER_DELIVERED) {
                    statusLabel.text = @"Delivered";
                } else {
                    statusLabel.text = @"On Process";
                }
                
            } else {
                
                _tableView.tableHeaderView = _headerView;

                UILabel *receiptNumberLabel = (UILabel *)[_headerView viewWithTag:1];
                receiptNumberLabel.text = _trackingOrder.shipping_ref_num;

                UILabel *statusLabel = (UILabel *)[_headerView viewWithTag:4];
                if ([_trackingOrder.order_status integerValue] == ORDER_SHIPPING_REF_NUM_EDITED) {
                    statusLabel.text = @"Nomor Resi diganti oleh penjual";
                } else if ([_trackingOrder.order_status integerValue] == ORDER_DELIVERED) {
                    statusLabel.text = @"Delivered";
                } else {
                    statusLabel.text = @"On Process";
                }
                
            }
        }
        
        [_activityIndicator stopAnimating];
        _tableView.tableFooterView = nil;
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
       
        [_activityIndicator stopAnimating];
        _tableView.tableFooterView = nil;        
        
    }];
}

@end
