////
////  ShopInfoViewController.m
////  Tokopedia
////
////  Created by IT Tkpd on 10/6/14.
////  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
////

#import "detail.h"
#import "Shop.h"
#import "Payment.h"
#import "StarsRateView.h"
#import "ShopInfoShipmentCell.h"
#import "ShopInfoPaymentCell.h"
#import "ShopInfoAddressCell.h"
#import "ShopInfoAddressView.h"

#import "ShopFavoritedViewController.h"
#import "ShopEditViewController.h"
#import "ShopInfoViewController.h"

//profile
#import "TKPDTabProfileNavigationController.h"
//#import "ProfileBiodataViewController.h"
#import "ProfileContactViewController.h"
#import "ProfileFavoriteShopViewController.h"

#import "NavigateViewController.h"
#import "UserContainerViewController.h"

#import <QuartzCore/QuartzCore.h>

@interface ShopInfoViewController()<UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>
{
    Shop *_shop;
    BOOL _isnodata;
    NavigateViewController *_navigateController;
    
    BOOL _isHideAddress;
    
    NSMutableArray *_shipments;
    NSMutableArray *_tempNameShipments;
}
@property (strong, nonatomic) IBOutlet UITableViewCell *paymentHeaderCell;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImage;
@property (strong, nonatomic) IBOutlet UITableViewCell *ownerCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *topCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *statisticCell;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIImageView *thumb;
@property (weak, nonatomic) IBOutlet UILabel *labelshopname;
@property (weak, nonatomic) IBOutlet UILabel *labelshoptagline;
@property (weak, nonatomic) IBOutlet UILabel *labelshopdescription;
@property (weak, nonatomic) IBOutlet UIButton *buttonfav;
@property (weak, nonatomic) IBOutlet UIButton *buttonitemsold;
@property (weak, nonatomic) IBOutlet StarsRateView *speedrate;
@property (weak, nonatomic) IBOutlet StarsRateView *accuracyrate;
@property (weak, nonatomic) IBOutlet StarsRateView *servicerate;
@property (weak, nonatomic) IBOutlet UILabel *labellocation;
@property (weak, nonatomic) IBOutlet UILabel *labellastlogin;
@property (weak, nonatomic) IBOutlet UILabel *labelopensince;
@property (weak, nonatomic) IBOutlet UIButton *buttonArrowLocation;

@property (weak, nonatomic) IBOutlet UILabel *labelsuccessfulltransaction;
@property (weak, nonatomic) IBOutlet UILabel *labelsold;
@property (weak, nonatomic) IBOutlet UILabel *labeletalase;
@property (weak, nonatomic) IBOutlet UILabel *labeltotalproduct;

@property (weak, nonatomic) IBOutlet UIImageView *thumbowner;
@property (weak, nonatomic) IBOutlet UILabel *nameowner;

- (IBAction)gesture:(id)sender;

- (IBAction)tap:(id)sender;
@end

@implementation ShopInfoViewController

#pragma mark - Initialization
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _isnodata = YES;
    }
    return self;
}



#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Informasi Toko";
    
    _isHideAddress = YES;
    _shipments = [NSMutableArray new];
    _tempNameShipments =[NSMutableArray new];
    
    _navigateController = [NavigateViewController new];

    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(tap:)];
    UIViewController *previousVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
    barButtonItem.tag = 10;
    [previousVC.navigationItem setBackBarButtonItem:barButtonItem];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [self setData:_data];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateShopPicture:)
                                                 name:EDIT_SHOP_AVATAR_NOTIFICATION_NAME
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

#pragma mark - Memory Management
-(void)dealloc{
    NSLog(@"%@ : %@",[self class], NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Action
- (IBAction)gesture:(id)sender {
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *gesture = (UITapGestureRecognizer*)sender;
        switch (gesture.state) {
            case UIGestureRecognizerStateBegan: {
                break;
            }
            case UIGestureRecognizerStateChanged: {
                break;
            }
            case UIGestureRecognizerStateEnded: {
                // go to profile
                [_navigateController navigateToProfileFromViewController:self withUserID:[NSString stringWithFormat:@"%ld", (long)_shop.result.owner.owner_id]];
                break;
            }
                
            default:
                break;
        }
    }
}

- (IBAction)tap:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton*)sender;
        switch (btn.tag) {
            case 10:
            {
                //expand location
                if (_isHideAddress) {
                    _isHideAddress = NO;
                    _arrowImage.image =[UIImage imageNamed:@"icon_arrow_up"];
                } else {
                    _isHideAddress = YES;
                    _arrowImage.image =[UIImage imageNamed:@"icon_arrow_down"];

                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
                break;
            }
            case 11:
            {
                //favorited button action
                ShopFavoritedViewController *vc = [ShopFavoritedViewController new];
                vc.data = @{kTKPDDETAIL_APISHOPIDKEY : _shop.result.info.shop_id?:@"",
                            kTKPD_AUTHKEY:[_data objectForKey:kTKPD_AUTHKEY]?:[NSNull null]};
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
            case 12:
            {
                // sold item button action
                NSDictionary *userinfo = @{kTKPDDETAIL_DATAINDEXKEY:@(0)};
                [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_ETALASEPOSTNOTIFICATIONNAMEKEY object:nil userInfo:userinfo];
                [self.navigationController popViewControllerAnimated:YES];
                break;
            }
            case 13:
            {
                // go to pofile shop owner (transparant button)
                NSString *userId = [NSString stringWithFormat:@"%zd",_shop.result.owner.owner_id];
                NavigateViewController *navigateController = [NavigateViewController new];
                [navigateController navigateToProfileFromViewController:self withUserID:userId];
                
                break;
            }
            default:
                break;
        }
    }
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UIBarButtonItem *btn = (UIBarButtonItem*)sender;
        switch (btn.tag) {
            case 10:
            {
                [self.navigationController popViewControllerAnimated:YES];
                break;
            }
            case 11:
            {
                ShopEditViewController *vc = [ShopEditViewController new];
                vc.data = @{
                            kTKPD_AUTHKEY : [_data objectForKey:kTKPD_AUTHKEY]?:@{},
                            kTKPDDETAIL_DATASHOPSKEY : _shop.result?:@{}
                            };
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
            default:
                break;
        }
        
    }
    
}


#pragma mark - Table View Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 4+_shipments.count+_shop.result.payment.count+_shop.result.address.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = nil;
    
    if (indexPath.row == 0) {
        cell = _topCell;
    }
    else if (indexPath.row <=_shop.result.address.count) {
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
        cell = [self addressCellIndexPath:newIndexPath];
    }
    else if (indexPath.row == _shop.result.address.count+1)
    {
        cell = _statisticCell;
    }
    else if (indexPath.row<=_shipments.count+_shop.result.address.count+1)
    {
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row-_shop.result.address.count-2 inSection:indexPath.section];
        NSInteger newSection = 0;
        Shipment *shipment = _shop.result.shipment[newSection];
        if (indexPath.row%shipment.shipment_package.count == 0 && newIndexPath.row!=0)
        {
            newSection +=1;
        }
        newIndexPath = [NSIndexPath indexPathForRow:indexPath.row-_shop.result.address.count-2 inSection:newSection];
        
        cell = [self shipmentCellIndexPath:newIndexPath];
    }
    else if (indexPath.row==_shipments.count+_shop.result.address.count+2)
    {
        cell = _paymentHeaderCell;
    }
    else if (indexPath.row<=_shop.result.payment.count+_shipments.count+_shop.result.address.count+2)
    {
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row-_shop.result.address.count-_shipments.count-3 inSection:indexPath.section];
        cell = [self paymentCellIndexPath:newIndexPath];
    }
    else
    {
        cell = _ownerCell;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.row == 0) {
        cell = _topCell;
    }
    else if (indexPath.row <=_shop.result.address.count) {
        if (_isHideAddress) {
            return 0;
        }
        else
        {
            return 190;
        }
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
        cell = [self addressCellIndexPath:newIndexPath];
    }
    else if (indexPath.row == _shop.result.address.count+1)
    {
        cell = _statisticCell;

    }
    else if (indexPath.row<=_shipments.count+_shop.result.address.count+1)
    {
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row-_shop.result.address.count-2 inSection:indexPath.section];
        cell = [self shipmentCellIndexPath:newIndexPath];
    }
    else if (indexPath.row==_shipments.count+_shop.result.address.count+2)
    {
        cell = _paymentHeaderCell;
    }
    else if (indexPath.row<=_shop.result.payment.count+_shipments.count+_shop.result.address.count+2)
    {
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row-_shop.result.address.count-_shipments.count-3 inSection:indexPath.section];
        cell = [self paymentCellIndexPath:newIndexPath];
    }
    else
    {
        cell = _ownerCell;
    }
    
    return cell.frame.size.height;
}

-(UITableViewCell*)addressCellIndexPath:(NSIndexPath*)indexPath
{
    NSString *cellid = @"ShopInfoAddressCellIdentifier";
    
    ShopInfoAddressCell* cell = (ShopInfoAddressCell*)[_tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [ShopInfoAddressCell newcell];
    }
    
    Address *address = _shop.result.address[indexPath.row];
    cell.labelname.text = (address.location_address == 0) ? @"-" : [NSString convertHTML:address.location_address];
    cell.labelDistric.text = (address.location_district_name == 0) ? @"-" : address.location_district_name;
    cell.labelcity.text = (address.location_city_name ==0) ? @"-" : address.location_city_name;
    cell.labelprov.text = (address.location_province_name ==0) ? @"-" : address.location_province_name;
    cell.labelpostal.text = (address.location_postal_code ==0) ? @"-" : address.location_postal_code;
    cell.labelemail.text = (address.location_email ==0) ? @"-" : address.location_email;
    cell.labelfax.text = (address.location_fax ==0) ? @"-" : address.location_fax;
    cell.labelphone.text = (address.location_phone ==0) ? @"-" : address.location_phone;
    
    
    return cell;
}

-(UITableViewCell*)shipmentCellIndexPath:(NSIndexPath*)indexPath
{
    NSString *cellid = kTKPDSHOPINFOSHIPMENTCELL_IDENTIFIER;
    
    ShopInfoShipmentCell* cell = (ShopInfoShipmentCell*)[_tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [ShopInfoShipmentCell newcell];
    }
    
    cell.packageLabel.text = _shipments[indexPath.row];
    
    cell.labelshipment.text = _tempNameShipments[indexPath.row];
    cell.labelshipment.hidden = ([cell.labelshipment.text isEqualToString:@""]);

    return cell;
}

-(UITableViewCell*)paymentCellIndexPath:(NSIndexPath*)indexPath
{
    NSString *cellid = kTKPDSHOPINFOPAYMENTCELL_IDENTIFIER;
    
    ShopInfoPaymentCell* cell = (ShopInfoPaymentCell*)[_tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [ShopInfoPaymentCell newcell];
    }
    
        Payment *payment = _shop.result.payment[indexPath.row];
        cell.labelpayment.text = payment.payment_name;
        
        NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:payment.payment_image] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTKPDREQUEST_TIMEOUTINTERVAL];
        //request.URL = url;
        
        UIImageView *thumb = cell.image;
        thumb.image = nil;
        //thumb.hidden = YES;	//@prepareforreuse then @reset
        
        //[((ShopInfoPaymentCell*)cell).act startAnimating];
        
        [thumb setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
            //NSLOG(@"thumb: %@", thumb);
            [thumb setImage:image];
            thumb.contentMode = UIViewContentModeScaleAspectFit;
            
            //[((ShopInfoPaymentCell*)cell).act stopAnimating];
#pragma clang diagnostic pop
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            //[((ShopInfoPaymentCell*)cell).act stopAnimating];
        }];
    
    return cell;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (_isnodata) {
		cell.backgroundColor = [UIColor whiteColor];
	}
    
    NSInteger row = [self tableView:tableView numberOfRowsInSection:indexPath.section] -1;
	if (row == indexPath.row) {
		NSLog(@"%@", NSStringFromSelector(_cmd));
	}
}

#pragma mark - Methods

-(void)updateShopPicture:(NSNotification*)notif
{
    NSDictionary *userInfo = notif.userInfo;
    
    NSString *strAvatar = [userInfo objectForKey:@"file_th"]?:@"";
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:strAvatar]
                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                              timeoutInterval:kTKPDREQUEST_TIMEOUTINTERVAL];
    
    [_thumb setImageWithURLRequest:request
                          placeholderImage:[UIImage imageNamed:@"icon_default_shop.jpg"]
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
                                       //NSLOG(@"thumb: %@", thumb);
                                       [_thumb setImage:image];
#pragma clang diagnostic pop
                                   } failure: nil];
}

-(void)setShopInfoData
{
    _labelshopname.text = _shop.result.info.shop_name;
//    _labelshoptagline.text = _shop.result.info.shop_tagline;
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 4.0;
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName            : [UIFont fontWithName:@"GothamBook" size:13],
                                 NSParagraphStyleAttributeName  : style
                                 };
    
    NSString *tagline = _shop.result.info.shop_tagline;
    _labelshoptagline.attributedText = [[NSAttributedString alloc] initWithString:tagline
                                                                       attributes:attributes];
    _labelshoptagline.numberOfLines = 0;
    [_labelshoptagline sizeToFit];
    
    _labelshopdescription.text = _shop.result.info.shop_description;
    [_buttonfav setTitle:_shop.result.info.shop_total_favorit forState:UIControlStateNormal];
    [_buttonitemsold setTitle:_shop.result.stats.shop_item_sold forState:UIControlStateNormal];
    _speedrate.starscount = _shop.result.stats.shop_service_rate;
    _accuracyrate.starscount = _shop.result.stats.shop_accuracy_rate;
    _servicerate.starscount = _shop.result.stats.shop_service_rate;
    _labellocation.text = _shop.result.info.shop_location;
    _labellastlogin.text = _shop.result.info.shop_owner_last_login;
    _labelopensince.text = _shop.result.info.shop_open_since;
    _nameowner.text = _shop.result.owner.owner_name;
    NSInteger totallocation = _shop.result.address.count;
    
    [_buttonArrowLocation setTitle:[NSString stringWithFormat:@"%zd Offline", totallocation] forState:UIControlStateNormal];
    
    _labelsuccessfulltransaction.text = _shop.result.stats.shop_total_transaction;
    _labelsold.text = _shop.result.stats.shop_item_sold;
    _labeletalase.text = _shop.result.stats.shop_total_etalase;
    _labeltotalproduct.text = _shop.result.stats.shop_total_product;
    
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:_shop.result.info.shop_avatar] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTKPDREQUEST_TIMEOUTINTERVAL];
    //request.URL = url;
    
    UIImageView *thumb = _thumb;
    thumb.layer.cornerRadius = thumb.frame.size.width/2;
    thumb.image = nil;
    //thumb.hidden = YES;	//@prepareforreuse then @reset
    
    //[((ShopInfoPaymentCell*)cell).act startAnimating];
    [thumb setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"icon_default_shop.jpg"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        //NSLOG(@"thumb: %@", thumb);
        [thumb setImage:image];
        //[((ShopInfoPaymentCell*)cell).act stopAnimating];
#pragma clang diagnostic pop
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        //[((ShopInfoPaymentCell*)cell).act stopAnimating];
    }];
    
    request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:_shop.result.owner.owner_image] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTKPDREQUEST_TIMEOUTINTERVAL];
    //request.URL = url;
    
    thumb = _thumbowner;
    thumb.layer.cornerRadius = thumb.frame.size.width/2;
    thumb.image = nil;
    //thumb.hidden = YES;	//@prepareforreuse then @reset
    
    //[((ShopInfoPaymentCell*)cell).act startAnimating];
    
    [thumb setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        //NSLOG(@"thumb: %@", thumb);
        [thumb setImage:image];
        
        //[((ShopInfoPaymentCell*)cell).act stopAnimating];
#pragma clang diagnostic pop
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        //[((ShopInfoPaymentCell*)cell).act stopAnimating];
    }];
    

    for (Shipment *shipment in _shop.result.shipment) {
        for (int i =0; i<shipment.shipment_package.count; i++) {
            ShipmentPackage *package = shipment.shipment_package[i];
            [_shipments addObject:package.product_name];
            if (i == 0) {
                [_tempNameShipments addObject:shipment.shipment_name];
            }
            else
                [_tempNameShipments addObject:@""];
        }
    }
    
}

#pragma mark - Properties
-(void)setData:(NSDictionary *)data
{
    _data = data;
    if (data) {
        _isnodata = NO;
        _shop = [_data objectForKey:kTKPDDETAIL_DATAINFOSHOPSKEY];
        [self setShopInfoData];
        
        NSDictionary *auth = [_data objectForKey:kTKPD_AUTHKEY];
        NSInteger shop_id = [[auth objectForKey:kTKPD_SHOPIDKEY]integerValue];
        if ([_shop.result.info.shop_id integerValue]==shop_id)
        {
            UIBarButtonItem *barbutton = [[UIBarButtonItem alloc] initWithTitle:@"Ubah" style:UIBarButtonItemStylePlain target:(self) action:@selector(tap:)];
            [barbutton setTintColor:[UIColor whiteColor]];
            barbutton.tag = 11;
            self.navigationItem.rightBarButtonItem = barbutton;
        }
    }
}

@end
