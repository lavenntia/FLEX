//
//  ProductAddEditViewController.m
//  Tokopedia
//
//  Created by IT Tkpd on 12/8/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import "detail.h"
#import "string_product.h"
#import "string_alert.h"
#import "category.h"
#import "camera.h"
#import "GenerateHost.h"
#import "UploadImage.h"
#import "Product.h"
#import "ShopSettings.h"
#import "ManageProduct.h"
#import "AlertPickerView.h"
#import "ProductAddEditViewController.h"
#import "ProductAddEditDetailViewController.h"
#import "ProductEditImageViewController.h"
#import "CameraController.h"
#import "CategoryMenuViewController.h"
#import "URLCacheController.h"
#import "StickyAlertView.h"
#import "RequestGenerateHost.h"
#import "RequestUploadImage.h"

#define DATA_SELECTED_BUTTON_KEY @"data_selected_button"

#pragma mark - Setting Add Product View Controller
@interface ProductAddEditViewController ()<UITextFieldDelegate,UIScrollViewDelegate,TKPDAlertViewDelegate,CameraControllerDelegate,CategoryMenuViewDelegate,ProductEditDetailViewControllerDelegate, ProductEditImageViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, GenerateHostDelegate, RequestUploadImageDelegate>
{
    NSMutableDictionary *_dataInput;
    NSMutableArray *_productImageURLs;
    NSMutableArray *_productImageIDs;
    NSMutableArray *_productImageDesc;
    
    UITextField *_activeTextField;
    
    CGPoint _keyboardPosition;
    CGSize _keyboardSize;
    
    CGRect _containerDefault;
    CGSize _scrollviewContentSize;
    
    NSInteger *_requestcountGenerateHost;
    GenerateHost *_generatehost;
    UploadImage *_images;
    Product *_product;
    ShopSettings *_setting;
    
    NSOperationQueue *_operationQueue;
    NSOperationQueue *_operationQueueUploadImage;
    
    __weak RKObjectManager *_objectmanager;
    __weak RKManagedObjectRequestOperation *_request;
    
    __weak RKObjectManager *_objectmanagerDeleteImage;
    __weak RKManagedObjectRequestOperation *_requestDeleteImage;
    
    NSMutableArray *_errorMessage;
    
    NSInteger _requestCount;
    NSInteger _requestcountDeleteImage;
    
    NSString *_cachepath;
    URLCacheController *_cachecontroller;
    URLCacheConnection *_cacheconnection;
    NSTimeInterval _timeinterval;
    
    NSMutableArray *_uploadingImages;
    
    UIBarButtonItem *_nextBarButtonItem;
    BOOL _isFinishedUploadImages;
    NSDictionary *_auth;
    BOOL _isNodata;
    
    GenerateHost *_generateHost;
}
@property (strong, nonatomic) IBOutlet UIView *section2FooterView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *section0TableViewCell;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *section1TableViewCell;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *section2TableViewCell;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *section3TableViewCell;

@property (weak, nonatomic) IBOutlet UIScrollView *productImageScrollView;
@property (weak, nonatomic) IBOutlet UITextField *productNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *minimumOrderTextField;
@property (weak, nonatomic) IBOutlet UITextField *productPriceTextField;
@property (weak, nonatomic) IBOutlet UITextField *productWeightTextField;
@property (weak, nonatomic) IBOutlet UIView *productImagesContentView;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *addImageButtons;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *thumbProductImageViews;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *defaultImageLabels;

-(void)cancel;
-(void)configureRestKit;
-(void)request;
-(void)requestsuccess:(id)object withOperation:(RKObjectRequestOperation*)operation;
-(void)requestfailure:(id)object;
-(void)requestprocess:(id)object;
-(void)requesttimeout;

-(void)cancelDeleteImage;
-(void)configureRestKitDeleteImage;
-(void)requestDeleteImage:(id)object;
-(void)requestSuccessDeleteImage:(id)object withOperation:(RKObjectRequestOperation*)operation;
-(void)requestFailureDeleteImage:(id)object;
-(void)requestProcessDeleteImage:(id)object;
-(void)requestTimeoutDeleteImage;

@end

@implementation ProductAddEditViewController

#pragma mark - Initialization
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _isFinishedUploadImages = YES;
    }
    return self;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _addImageButtons = [NSArray sortViewsWithTagInArray:_addImageButtons];
    _thumbProductImageViews = [NSArray sortViewsWithTagInArray:_thumbProductImageViews];
    _defaultImageLabels = [NSArray sortViewsWithTagInArray:_defaultImageLabels];
    _section1TableViewCell = [NSArray sortViewsWithTagInArray:_section1TableViewCell];
    _section2TableViewCell = [NSArray sortViewsWithTagInArray:_section2TableViewCell];
    _section3TableViewCell = [NSArray sortViewsWithTagInArray:_section3TableViewCell];
    
    _operationQueue = [NSOperationQueue new];
    _operationQueueUploadImage = [NSOperationQueue new];
    _dataInput = [NSMutableDictionary new];
    _errorMessage = [NSMutableArray new];
    _cacheconnection = [URLCacheConnection new];
    _cachecontroller = [URLCacheController new];
    _uploadingImages = [NSMutableArray new];
    
    _productImageURLs = [[NSMutableArray alloc]initWithObjects:@"",@"",@"",@"",@"", nil];
    _productImageIDs = [[NSMutableArray alloc]initWithObjects:@"",@"",@"",@"",@"", nil];
    _productImageDesc = [[NSMutableArray alloc]initWithObjects:@"",@"",@"",@"",@"", nil];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:@selector(tap:)];
    UIViewController *previousVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
    barButtonItem.tag = 10;
    [previousVC.navigationItem setBackBarButtonItem:barButtonItem];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    _nextBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:(self) action:@selector(tap:)];
    [_nextBarButtonItem setTintColor:[UIColor blackColor]];
    _nextBarButtonItem.tag = 11;
    self.navigationItem.rightBarButtonItem = _nextBarButtonItem;
    
    for (UIButton *buttonAdd in _addImageButtons) {
        buttonAdd.enabled = NO;
    }
    ((UIButton*)_addImageButtons[0]).enabled = YES;
    [_thumbProductImageViews makeObjectsPerformSelector:@selector(setHidden:) withObject:@(YES)];
    for (UIImageView *productImageView in _thumbProductImageViews) {
        productImageView.userInteractionEnabled = NO;
    }
    [self setDefaultData:_data];
    //cache
    //NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:kTKPDDETAILPRODUCT_CACHEFILEPATH];
    //_cachepath = [path stringByAppendingPathComponent:[NSString stringWithFormat:kTKPDDETAILPRODUCTFORM_APIRESPONSEFILEFORMAT,[[_data objectForKey:kTKPDDETAIL_APIPRODUCTIDKEY] integerValue]]];
    //_cachecontroller.filePath = _cachepath;
    //_cachecontroller.URLCacheInterval = 86400.0;
    //[_cachecontroller initCacheWithDocumentPath:path];
    
    TKPDSecureStorage* secureStorage = [TKPDSecureStorage standardKeyChains];
    _auth = [secureStorage keychainDictionary];
    
    NSInteger type = [[_data objectForKey:DATA_TYPE_ADD_EDIT_PRODUCT_KEY]integerValue];
    if (type == TYPE_ADD_EDIT_PRODUCT_EDIT || type == TYPE_ADD_EDIT_PRODUCT_COPY) {
        [self configureRestKit];
        [self request];
    }
    else{
        RequestGenerateHost *generateHost =[RequestGenerateHost new];
        [generateHost configureRestkitGenerateHost];
        [generateHost requestGenerateHost];
        generateHost.delegate = self;
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // keyboard notification
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardWillShow:)
               name:UIKeyboardWillShowNotification
             object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:)
               name:UIKeyboardWillHideNotification
             object:nil];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    _productImageScrollView.contentSize = _productImagesContentView.frame.size;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

#pragma mark - View Action
-(IBAction)tap:(id)sender
{
    [_activeTextField resignFirstResponder];
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UIBarButtonItem *btn = (UIBarButtonItem *)sender;
        switch (btn.tag) {
            case 10:
                [self.navigationController popViewControllerAnimated:YES];
                break;
            case 11:
            {
                if (!_isFinishedUploadImages) {
                    NSArray *errorMessage = @[ERRORMESSAGE_PROCESSING_UPLOAD_IMAGE];
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:errorMessage,@"messages", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_SETUSERSTICKYERRORMESSAGEKEY object:nil userInfo:info];
                }
                else{
                    if ([self dataInputIsValid]) {
                        NSDictionary *auth = [_data objectForKey:kTKPD_AUTHKEY];
                        NSInteger type = [[_data objectForKey:DATA_TYPE_ADD_EDIT_PRODUCT_KEY]integerValue];
                        id productDetail = [_data objectForKey:DATA_PRODUCT_DETAIL_KEY]?:@"";
                        NSString *defaultImagePath = [_dataInput objectForKey:API_PRODUCT_IMAGE_DEFAULT_KEY];
                        if (!defaultImagePath) {
                            defaultImagePath = (type == TYPE_ADD_EDIT_PRODUCT_ADD || type == TYPE_ADD_EDIT_PRODUCT_COPY)? [_productImageURLs firstObject]:[_productImageIDs firstObject];
                            [_dataInput setObject:defaultImagePath forKey:API_PRODUCT_IMAGE_DEFAULT_KEY];
                        }
                        ProductAddEditDetailViewController *vc = [ProductAddEditDetailViewController new];
                        vc.data = @{kTKPD_AUTHKEY : auth?:@{},
                                    DATA_INPUT_KEY : _dataInput,
                                    DATA_TYPE_ADD_EDIT_PRODUCT_KEY : @(type),
                                    DATA_PRODUCT_DETAIL_KEY: productDetail
                                    };
                        vc.delegate = self;
                        [self.navigationController pushViewController:vc animated:YES];
                    }
                    else
                    {
                        NSArray *errorMessage = _errorMessage;
                        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:errorMessage,@"messages", nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_SETUSERSTICKYERRORMESSAGEKEY object:nil userInfo:info];
                    }
                }
                break;
            }
            default:
                break;
        }
    }
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton*)sender;
        switch (btn.tag) {
            case BUTTON_PRODUCT_CATEGORY:
            {
                CategoryMenuViewController *categoryViewController = [CategoryMenuViewController new];
                NSInteger d_id = [[_data objectForKey:kTKPDCATEGORY_DATADEPARTMENTIDKEY] integerValue];
                categoryViewController.data = @{kTKPDCATEGORY_DATADEPARTMENTIDKEY:@(d_id),
                                                DATA_CATEGORY_MENU_PREVIOUS_VIEW_TYPE:@(CATEGORY_MENU_PREVIOUS_VIEW_ADD_PRODUCT)
                                                };
                categoryViewController.delegate = self;
                [self.navigationController pushViewController:categoryViewController animated:YES];
                break;
            }
            case BUTTON_PRODUCT_PRICE_CURRENCY:
            {
                AlertPickerView *v = [AlertPickerView newview];
                v.pickerData = ARRAY_PRICE_CURRENCY;
                v.tag = btn.tag;
                v.delegate = self;
                [v show];
                break;
            }
            case 20: // tag 20-24 add product
            case 21:
            case 22:
            case 23:
            case 24:
            { 
                CameraController* c = [CameraController new];
                [c snap];
                c.tag = btn.tag;
                c.delegate = self;
                UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:c];
                nav.wantsFullScreenLayout = YES;
                nav.modalPresentationStyle = UIModalPresentationFullScreen;
                nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                [self.navigationController presentViewController:nav animated:YES completion:nil];
                //[_dataInput setObject:@(btn.tag-20) forKey:kTKPDDETAIL_DATAINDEXKEY];
                break;
            }
            default:
                break;
        }
    }
}
- (IBAction)gesture:(id)sender
{
    [_activeTextField resignFirstResponder];
    
    UITapGestureRecognizer* gesture = (UITapGestureRecognizer*)sender;
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            if (gesture.view.tag > 0) {
                NSInteger indexImage = gesture.view.tag-10;
                NSString *defaultImagePath =[_dataInput objectForKey:API_PRODUCT_IMAGE_DEFAULT_KEY];
                NSString *selectedImagePath =_productImageURLs[indexImage];
                BOOL isDefaultImage;
                if (defaultImagePath)
                    isDefaultImage = [defaultImagePath isEqualToString:selectedImagePath];
                else
                    isDefaultImage = (gesture.view.tag-10 == 0);
                
                ProductEditImageViewController *vc = [ProductEditImageViewController new];
                vc.data = @{kTKPD_AUTHKEY : [_data objectForKey:kTKPD_AUTHKEY]?:@{},
                            kTKPDSHOPEDIT_APIUPLOADFILEPATHKEY : _productImageURLs[indexImage]?:@"",
                            kTKPDDETAIL_DATAINDEXKEY : @(indexImage),
                            DATA_IS_DEFAULT_IMAGE : @(isDefaultImage),
                            DATA_PRODUCT_IMAGE_NAME_KEY : _productImageDesc[indexImage]?:@""
                            };
                vc.delegate = self;
                [self.navigationController pushViewController:vc animated:YES];
            }

            break;
        }
        default:
            break;
    }
}

#pragma mark - Table View Data Source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger rowCount = 0;
    switch (section) {
        case 0:
            rowCount = _section0TableViewCell.count;
            break;
        case 1:
            rowCount = _section1TableViewCell.count;
            break;
        case 2:
            rowCount = _section2TableViewCell.count;
            break;
        case 3:
            rowCount = _section3TableViewCell.count;
            break;
        default:
            break;
    }
#ifdef kTKPDHOTLISTRESULT_NODATAENABLE
    return _isNodata?1:rowCount;
#else
    return _isNodata?0:rowCount;
#endif
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //NSDictionary *selectedCategory = [_dataInput objectForKey:DATA_CATEGORY_KEY];
    Breadcrumb *breadcrumb = [_dataInput objectForKey:DATA_CATEGORY_KEY];
    ProductDetail *product = [_dataInput objectForKey:DATA_PRODUCT_DETAIL_KEY];
    
    UITableViewCell* cell = nil;
    if (!_isNodata) {
        switch (indexPath.section) {
            case 0:
                cell = _section0TableViewCell[indexPath.row];
                break;
            case 1:
                cell = _section1TableViewCell[indexPath.row];
                if (indexPath.row == BUTTON_PRODUCT_CATEGORY) {
                    NSString *departmentTitle = breadcrumb.department_name?:@"Pilih Kategori";
                    cell.detailTextLabel.text = departmentTitle;
                    }
                break;
            case 2:
                cell = _section2TableViewCell[indexPath.row];
                if (indexPath.row==BUTTON_PRODUCT_PRICE_CURRENCY) {
                    NSString *currencyName = product.product_currency;
                    cell.detailTextLabel.text = currencyName;
                }
                break;
            case 3:
                cell = _section3TableViewCell[indexPath.row];
                if (indexPath.row == BUTTON_PRODUCT_WEIGHT_UNIT) {
                    NSString *weightUnitName = product.product_weight_unit_name;
                    cell.detailTextLabel.text = weightUnitName;
                }
                break;
            default:
                break;
        }
    } else {
        static NSString *CellIdentifier = kTKPDDETAIL_STANDARDTABLEVIEWCELLIDENTIFIER;
        
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.textLabel.text = kTKPDDETAIL_NODATACELLTITLE;
        cell.detailTextLabel.text = kTKPDDETAIL_NODATACELLDESCS;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}


#pragma mark - Table View Delegate
-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section==2) {
        return _section2FooterView;
    }
    else return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section==2) {
        return _section2FooterView.frame.size.height;
    }
    else return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float cellHeight;
    switch (indexPath.section) {
        case 0:
            cellHeight = ((UITableViewCell*)_section0TableViewCell[indexPath.row]).frame.size.height;
            break;
        case 1:
            cellHeight = ((UITableViewCell*)_section1TableViewCell[indexPath.row]).frame.size.height;
            break;
        case 2:
            cellHeight = ((UITableViewCell*)_section2TableViewCell[indexPath.row]).frame.size.height;
            break;
        case 3:
            cellHeight = ((UITableViewCell*)_section3TableViewCell[indexPath.row]).frame.size.height;
            break;
        default:
            break;
    }
    return cellHeight;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_activeTextField resignFirstResponder];
    switch (indexPath.section) {
        case 1:
            switch (indexPath.row) {
                case BUTTON_PRODUCT_PRODUCT_NAME:
                    [_productNameTextField becomeFirstResponder];
                    break;
                case BUTTON_PRODUCT_CATEGORY:
                {
                    CategoryMenuViewController *categoryViewController = [CategoryMenuViewController new];
                    NSInteger d_id = [[_data objectForKey:kTKPDCATEGORY_DATADEPARTMENTIDKEY] integerValue];
                    categoryViewController.data = @{kTKPDCATEGORY_DATADEPARTMENTIDKEY:@(d_id),
                                                    DATA_CATEGORY_MENU_PREVIOUS_VIEW_TYPE:@(CATEGORY_MENU_PREVIOUS_VIEW_ADD_PRODUCT)
                                                    };
                    categoryViewController.delegate = self;
                    [self.navigationController pushViewController:categoryViewController animated:YES];
                    break;
                }
                case BUTTON_PRODUCT_MIN_ORDER:
                    [_minimumOrderTextField becomeFirstResponder];
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case BUTTON_PRODUCT_PRICE_CURRENCY:
                {
                    AlertPickerView *v = [AlertPickerView newview];
                    v.pickerData = ARRAY_PRICE_CURRENCY;
                    v.tag = 11;
                    v.delegate = self;
                    [v show];
                    break;
                }
                case BUTTON_PRODUCT_PRICE:
                    [_productPriceTextField becomeFirstResponder];
                    break;
            }
            break;
        case 3:
            switch (indexPath.row) {
                case BUTTON_PRODUCT_WEIGHT_UNIT:
                {
                    AlertPickerView *v = [AlertPickerView newview];
                    v.pickerData = ARRAY_WEIGHT_UNIT;
                    v.tag = 12;
                    v.delegate = self;
                    [v show];
                    break;
                }
                case BUTTON_PRODUCT_WEIGHT:
                    [_productWeightTextField becomeFirstResponder];
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }

}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isNodata) {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    [_activeTextField resignFirstResponder];
}

#pragma mark - Request Product Detail
-(void)cancel
{
    [_objectmanager.operationQueue cancelAllOperations];
    _objectmanager = nil;
}

- (void)configureRestKit
{
    // initialize RestKit
    _objectmanager =  [RKObjectManager sharedClient];
    
    // setup object mappings
    RKObjectMapping *productMapping = [RKObjectMapping mappingForClass:[Product class]];
    [productMapping addAttributeMappingsFromDictionary:@{kTKPD_APISTATUSKEY:kTKPD_APISTATUSKEY,kTKPD_APISERVERPROCESSTIMEKEY:kTKPD_APISERVERPROCESSTIMEKEY}];
    
    RKObjectMapping *resultMapping = [RKObjectMapping mappingForClass:[DetailProductResult class]];
    [resultMapping addAttributeMappingsFromDictionary:@{API_SERVER_ID_KEY:API_SERVER_ID_KEY,
                                                        API_IS_GOLD_SHOP_KEY:API_IS_GOLD_SHOP_KEY
                                                        }];
    
    RKObjectMapping *infoMapping = [RKObjectMapping mappingForClass:[ProductDetail class]];
    [infoMapping addAttributeMappingsFromDictionary:@{API_PRODUCT_NAME_KEY:API_PRODUCT_NAME_KEY,
                                                      API_PRODUCT_WEIGHT_UNIT_KEY:API_PRODUCT_WEIGHT_UNIT_KEY,
                                                      API_PRODUCT_DESCRIPTION_KEY:API_PRODUCT_DESCRIPTION_KEY,
                                                      API_PRODUCT_PRICE_KEY:API_PRODUCT_PRICE_KEY,
                                                      API_PRODUCT_INSURANCE_KEY:API_PRODUCT_INSURANCE_KEY,
                                                      API_PRODUCT_CONDITION_KEY:API_PRODUCT_CONDITION_KEY,
                                                      API_PRODUCT_MINIMUM_ORDER_KEY:API_PRODUCT_MINIMUM_ORDER_KEY,
                                                      kTKPDDETAILPRODUCT_APIPRODUCTSTATUSKEY:kTKPDDETAILPRODUCT_APIPRODUCTSTATUSKEY,
                                                      kTKPDDETAILPRODUCT_APIPRODUCTLASTUPDATEKEY:kTKPDDETAILPRODUCT_APIPRODUCTLASTUPDATEKEY,
                                                      kTKPDDETAILPRODUCT_APIPRODUCTIDKEY:kTKPDDETAILPRODUCT_APIPRODUCTIDKEY,
                                                      kTKPDDETAILPRODUCT_APIPRODUCTPRICEALERTKEY:kTKPDDETAILPRODUCT_APIPRODUCTPRICEALERTKEY,
                                                      API_PRODUCT_WEIGHT_KEY:API_PRODUCT_WEIGHT_KEY,
                                                      API_PRODUCT_FORM_PRICE_CURRENCY_ID_KEY:API_PRODUCT_FORM_PRICE_CURRENCY_ID_KEY,
                                                      kTKPDDETAILPRODUCT_APICURRENCYKEY:kTKPDDETAILPRODUCT_APICURRENCYKEY,
                                                      API_PRODUCT_ETALASE_ID_KEY:API_PRODUCT_ETALASE_ID_KEY,
                                                      API_PRODUCT_DEPARTMENT_ID_KEY:API_PRODUCT_DEPARTMENT_ID_KEY,
                                                      API_PRODUCT_FORM_DESCRIPTION_KEY:API_PRODUCT_FORM_DESCRIPTION_KEY,
                                                      API_PRODUCT_FORM_DEPARTMENT_TREE_KEY:API_PRODUCT_FORM_DEPARTMENT_TREE_KEY,
                                                      API_PRODUCT_FORM_RETURNABLE_KEY:API_PRODUCT_FORM_RETURNABLE_KEY,
                                                      API_PRODUCT_MUST_INSURANCE_KEY:API_PRODUCT_MUST_INSURANCE_KEY,
                                                      kTKPDDETAILPRODUCT_APIPRODUCTURKKEY:kTKPDDETAILPRODUCT_APIPRODUCTURKKEY,
                                                      API_PRODUCT_FORM_ETALASE_NAME_KEY:API_PRODUCT_FORM_ETALASE_NAME_KEY
                                                      }];
    
    RKObjectMapping *statisticMapping = [RKObjectMapping mappingForClass:[Statistic class]];
    [statisticMapping addAttributeMappingsFromDictionary:@{kTKPDDETAILPRODUCT_APISTATISTICKEY:kTKPDDETAILPRODUCT_APISTATISTICKEY,
                                                           kTKPDDETAILPRODUCT_APIPRODUCTSOLDKEY:kTKPDDETAILPRODUCT_APIPRODUCTSOLDKEY,
                                                           kTKPDDETAILPRODUCT_APIPRODUCTTRANSACTIONKEY:kTKPDDETAILPRODUCT_APIPRODUCTTRANSACTIONKEY,
                                                           kTKPDDETAILPRODUCT_APIPRODUCTSUCCESSRATEKEY:kTKPDDETAILPRODUCT_APIPRODUCTSUCCESSRATEKEY,
                                                           kTKPDDETAILPRODUCT_APIPRODUCTVIEWKEY:kTKPDDETAILPRODUCT_APIPRODUCTVIEWKEY,
                                                           kTKPDDETAILPRODUCT_APIPRODUCTCANCELRATEKEY:kTKPDDETAILPRODUCT_APIPRODUCTCANCELRATEKEY,
                                                           kTKPDDETAILPRODUCT_APIPRODUCTTALKKEY:kTKPDDETAILPRODUCT_APIPRODUCTTALKKEY,
                                                           kTKPDDETAILPRODUCT_APIPRODUCTTALKKEY:kTKPDDETAILPRODUCT_APIPRODUCTTALKKEY,
                                                           kTKPDDETAILPRODUCT_APIPRODUCTREVIEWKEY:kTKPDDETAILPRODUCT_APIPRODUCTREVIEWKEY,
                                                           KTKPDDETAILPRODUCT_APIPRODUCTQUALITYRATEKEY:KTKPDDETAILPRODUCT_APIPRODUCTQUALITYRATEKEY,
                                                           KTKPDDETAILPRODUCT_APIPRODUCTACCURACYRATEKEY:KTKPDDETAILPRODUCT_APIPRODUCTACCURACYRATEKEY,
                                                           KTKPDDETAILPRODUCT_APIPRODUCTQUALITYPOINTKEY:KTKPDDETAILPRODUCT_APIPRODUCTQUALITYPOINTKEY,
                                                           KTKPDDETAILPRODUCT_APIPRODUCTACCURACYPOINTKEY:KTKPDDETAILPRODUCT_APIPRODUCTACCURACYPOINTKEY
                                                           
                                                           }];
    
    RKObjectMapping *shopinfoMapping = [RKObjectMapping mappingForClass:[ShopInfo class]];
    [shopinfoMapping addAttributeMappingsFromDictionary:@{kTKPDDETAILPRODUCT_APISHOPINFOKEY:kTKPDDETAILPRODUCT_APISHOPINFOKEY,
                                                          kTKPDDETAILPRODUCT_APISHOPOPENSINCEKEY:kTKPDDETAILPRODUCT_APISHOPOPENSINCEKEY,
                                                          kTKPDDETAILPRODUCT_APISHOPLOCATIONKEY:kTKPDDETAILPRODUCT_APISHOPLOCATIONKEY,
                                                          kTKPDDETAILPRODUCT_APISHOPLOCATIONKEY:kTKPDDETAILPRODUCT_APISHOPLOCATIONKEY,
                                                          kTKPDDETAIL_APISHOPIDKEY:kTKPDDETAIL_APISHOPIDKEY,
                                                          kTKPDDETAILPRODUCT_APISHOPLASTLOGINKEY:kTKPDDETAILPRODUCT_APISHOPLASTLOGINKEY,
                                                          kTKPDDETAILPRODUCT_APISHOPTAGLINEKEY:kTKPDDETAILPRODUCT_APISHOPTAGLINEKEY,
                                                          kTKPDDETAILPRODUCT_APISHOPNAMEKEY:kTKPDDETAILPRODUCT_APISHOPNAMEKEY,
                                                          kTKPDDETAILPRODUCT_APISHOPISFAVKEY:kTKPDDETAILPRODUCT_APISHOPISFAVKEY,
                                                          kTKPDDETAILPRODUCT_APISHOPDESCRIPTIONKEY:kTKPDDETAILPRODUCT_APISHOPDESCRIPTIONKEY,
                                                          kTKPDDETAILPRODUCT_APISHOPAVATARKEY:kTKPDDETAILPRODUCT_APISHOPAVATARKEY,
                                                          kTKPDDETAILPRODUCT_APISHOPDOMAINKEY:kTKPDDETAILPRODUCT_APISHOPDOMAINKEY
                                                          }];
    
    RKObjectMapping *shopstatsMapping = [RKObjectMapping mappingForClass:[ShopStats class]];
    [shopstatsMapping addAttributeMappingsFromDictionary:@{kTKPDDETAILPRODUCT_APISHOPSERVICERATEKEY:kTKPDDETAILPRODUCT_APISHOPSERVICERATEKEY,
                                                           kTKPDDETAILPRODUCT_APISHOPSERVICEDESCRIPTIONKEY:kTKPDDETAILPRODUCT_APISHOPSERVICEDESCRIPTIONKEY,
                                                           kTKPDDETAILPRODUCT_APISHOPSPEEDRATEKEY:kTKPDDETAILPRODUCT_APISHOPSPEEDRATEKEY,
                                                           kTKPDDETAILPRODUCT_APISHOPACURACYRATEKEY:kTKPDDETAILPRODUCT_APISHOPACURACYRATEKEY,
                                                           kTKPDDETAILPRODUCT_APISHOPACURACYDESCRIPTIONKEY:kTKPDDETAILPRODUCT_APISHOPACURACYDESCRIPTIONKEY,
                                                           kTKPDDETAILPRODUCT_APISHOPSPEEDDESCRIPTIONKEY:kTKPDDETAILPRODUCT_APISHOPSPEEDDESCRIPTIONKEY
                                                           }];
    
    RKObjectMapping *wholesaleMapping = [RKObjectMapping mappingForClass:[WholesalePrice class]];
    [wholesaleMapping addAttributeMappingsFromArray:@[kTKPDDETAILPRODUCT_APIWHOLESALEMINKEY,kTKPDDETAILPRODUCT_APIWHOLESALEPRICEKEY,kTKPDDETAILPRODUCT_APIWHOLESALEMAXKEY]];
    
    RKObjectMapping *breadcrumbMapping = [RKObjectMapping mappingForClass:[Breadcrumb class]];
    [breadcrumbMapping addAttributeMappingsFromArray:@[kTKPDDETAILPRODUCT_APIDEPARTMENTNAMEKEY,API_DEPARTMENT_ID_KEY]];
    
    RKObjectMapping *otherproductMapping = [RKObjectMapping mappingForClass:[OtherProduct class]];
    [otherproductMapping addAttributeMappingsFromArray:@[API_PRODUCT_PRICE_KEY,
                                                         API_PRODUCT_NAME_KEY,
                                                         kTKPDDETAILPRODUCT_APIPRODUCTIDKEY,
                                                         kTKPDDETAILPRODUCT_APIPRODUCTIMAGEKEY]];
    
    RKObjectMapping *imagesMapping = [RKObjectMapping mappingForClass:[ProductImages class]];
    [imagesMapping addAttributeMappingsFromArray:@[kTKPDDETAILPRODUCT_APIIMAGEIDKEY,kTKPDDETAILPRODUCT_APIIMAGESTATUSKEY,kTKPDDETAILPRODUCT_APIIMAGEDESCRIPTIONKEY,kTKPDDETAILPRODUCT_APIIMAGEPRIMARYKEY,kTKPDDETAILPRODUCT_APIIMAGESRCKEY]];
    
    // Relationship Mapping
    [productMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:kTKPDDETAIL_APIRESULTKEY toKeyPath:kTKPDDETAIL_APIRESULTKEY withMapping:resultMapping]];
    
    [resultMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:API_PRODUCT_INFO_KEY toKeyPath:API_PRODUCT_INFO_KEY withMapping:infoMapping]];
    [resultMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:kTKPDDETAILPRODUCT_APISTATISTICKEY toKeyPath:kTKPDDETAILPRODUCT_APISTATISTICKEY withMapping:statisticMapping]];
    [resultMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:kTKPDDETAILPRODUCT_APISHOPINFOKEY toKeyPath:kTKPDDETAILPRODUCT_APISHOPINFOKEY withMapping:shopinfoMapping]];
    [shopinfoMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:kTKPDDETAILPRODUCT_APISHOPSTATKEY toKeyPath:kTKPDDETAILPRODUCT_APISHOPSTATKEY withMapping:shopstatsMapping]];
    
    RKRelationshipMapping *breadcrumbRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPDDETAIL_APIBREADCRUMBPATHKEY toKeyPath:kTKPDDETAIL_APIBREADCRUMBPATHKEY withMapping:breadcrumbMapping];
    [resultMapping addPropertyMapping:breadcrumbRel];
    RKRelationshipMapping *otherproductRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPDDETAIL_APIOTHERPRODUCTPATHKEY toKeyPath:kTKPDDETAIL_APIOTHERPRODUCTPATHKEY withMapping:otherproductMapping];
    [resultMapping addPropertyMapping:otherproductRel];
    RKRelationshipMapping *productimageRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPDDETAIL_APIPRODUCTIMAGEPATHKEY toKeyPath:kTKPDDETAIL_APIPRODUCTIMAGEPATHKEY withMapping:imagesMapping];
    [resultMapping addPropertyMapping:productimageRel];
    RKRelationshipMapping *wholesaleRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPDDETAIL_APIWHOLESALEPRICEPATHKEY toKeyPath:kTKPDDETAIL_APIWHOLESALEPRICEPATHKEY withMapping:wholesaleMapping];
    [resultMapping addPropertyMapping:wholesaleRel];
    
    // Response Descriptor
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:productMapping method:RKRequestMethodGET pathPattern:kTKPDDETAILPRODUCT_APIPATH keyPath:@"" statusCodes:kTkpdIndexSetStatusCodeOK];
    
    [_objectmanager addResponseDescriptor:responseDescriptor];
}

- (void)request
{
    if (_request.isExecuting) return;
    
    _requestCount++;
    
    NSDictionary *auth = [_data objectForKey:kTKPD_AUTHKEY];
    NSInteger productID = [[_data objectForKey:kTKPDDETAIL_APIPRODUCTIDKEY]integerValue];
    NSInteger myshopID = [[auth objectForKey:kTKPD_SHOPIDKEY]integerValue];
    NSInteger userID = [[auth objectForKey:kTKPD_USERIDKEY]integerValue];
    
	NSDictionary* param = @{
                            kTKPDDETAIL_APIACTIONKEY : ACTION_GET_PRODUCT_FORM,
                            kTKPDDETAIL_APIPRODUCTIDKEY : @(productID),
                            kTKPDDETAIL_APISHOPIDKEY : @(myshopID),
                            kTKPD_USERIDKEY : @(userID),
                            //@"enc_dec" : @"off"
                            };
    [self enableButtonBeforeSuccessRequest:NO];
    
    _request = [_objectmanager appropriateObjectRequestOperationWithObject:self method:RKRequestMethodPOST path:kTKPDDETAILPRODUCT_APIPATH parameters:[param encrypt]];
	//[_cachecontroller getFileModificationDate];
	//_timeinterval = fabs([_cachecontroller.fileDate timeIntervalSinceNow]);
	//if (_timeinterval > _cachecontroller.URLCacheInterval) {
        NSTimer *timer;
        [_request setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            [timer invalidate];
            [self requestsuccess:mappingResult withOperation:operation];
            [self enableButtonBeforeSuccessRequest:YES];
        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
            [timer invalidate];
            [self requestfailure:error];
            [self enableButtonBeforeSuccessRequest:YES];
        }];
        
        [_operationQueue addOperation:_request];
        
        timer = [NSTimer scheduledTimerWithTimeInterval:kTKPDREQUEST_TIMEOUTINTERVAL target:self selector:@selector(requesttimeout) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        
    //}
    //else {
    //  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //  [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    //  [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    //  NSLog(@"Updated: %@",[dateFormatter stringFromDate:_cachecontroller.fileDate]);
    //  NSLog(@"cache and updated in last 24 hours.");
    //  [self requestfailure:nil];
    //}
}

-(void)requestsuccess:(id)object withOperation:(RKObjectRequestOperation *)operation
{
    NSDictionary *result = ((RKMappingResult*)object).dictionary;
    id stats = [result objectForKey:@""];
    _product = stats;
    BOOL status = [_product.status isEqualToString:kTKPDREQUEST_OKSTATUS];
    
    if (status) {
        //[_cacheconnection connection:operation.HTTPRequestOperation.request didReceiveResponse:operation.HTTPRequestOperation.response];
        //[_cachecontroller connectionDidFinish:_cacheconnection];
        //save response data to plist
        //[operation.HTTPRequestOperation.responseData writeToFile:_cachepath atomically:YES];
        
        [self requestprocess:object];
    }
}

-(void)requestfailure:(id)object
{
    //if (_timeinterval > _cachecontroller.URLCacheInterval) {
        [self requestprocess:object];
    //}
    //else{
    //NSError* error;
    //NSData *data = [NSData dataWithContentsOfFile:_cachepath];
    //id parsedData = [RKMIMETypeSerialization objectFromData:data MIMEType:RKMIMETypeJSON error:&error];
    //if (parsedData == nil && error) {
    //    NSLog(@"parser error");
    //}
    //
    //NSMutableDictionary *mappingsDictionary = [[NSMutableDictionary alloc] init];
    //for (RKResponseDescriptor *descriptor in _objectmanager.responseDescriptors) {
    //    [mappingsDictionary setObject:descriptor.mapping forKey:descriptor.keyPath];
    //}
    //
    //RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:parsedData mappingsDictionary:mappingsDictionary];
    //NSError *mappingError = nil;
    //BOOL isMapped = [mapper execute:&mappingError];
    //if (isMapped && !mappingError) {
    //    RKMappingResult *mappingresult = [mapper mappingResult];
    //    NSDictionary *result = mappingresult.dictionary;
    //    id stats = [result objectForKey:@""];
    //    _product = stats;
    //    BOOL status = [_product.status isEqualToString:kTKPDREQUEST_OKSTATUS];
    //    
    //    if (status) {
    //        [self requestprocess:mappingresult];
    //    }
    //}
    //}
}

-(void)requestprocess:(id)object
{
    if (object) {
        if ([object isKindOfClass:[RKMappingResult class]]) {
            NSDictionary *result = ((RKMappingResult*)object).dictionary;
            id stats = [result objectForKey:@""];
            _product = stats;
            BOOL status = [_product.status isEqualToString:kTKPDREQUEST_OKSTATUS];
            
            if (status) {
                NSMutableDictionary *data = [NSMutableDictionary new];
                [data addEntriesFromDictionary:_data];
                [self setDefaultData:data];
                [_tableView reloadData];
            }
        }else{
            [self cancel];
            NSError *error = object;
            if (!([error code] == NSURLErrorCancelled)){
                NSString *errorDescription = error.localizedDescription;
                UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:ERROR_TITLE message:errorDescription delegate:self cancelButtonTitle:ERROR_CANCEL_BUTTON_TITLE otherButtonTitles:nil];
                [errorAlert show];
            }
        }
    }
}

-(void)requesttimeout
{
    [self cancel];
}

#pragma mark Request Generate Host
-(void)successGenerateHost:(GenerateHost *)generateHost
{
    _generateHost = generateHost;
}

#pragma mark Request Action Upload Photo
-(void)successUploadObject:(id)object withMappingResult:(UploadImage *)uploadImage
{
    _images = uploadImage;
    UIImageView *thumbProductImage = [object objectForKey:DATA_SELECTED_IMAGE_VIEW_KEY];
    thumbProductImage.alpha = 1.0;
    
    thumbProductImage.userInteractionEnabled = YES;
    NSInteger type = [[_data objectForKey:DATA_TYPE_ADD_EDIT_PRODUCT_KEY]integerValue];
    
    [_productImageURLs replaceObjectAtIndex:thumbProductImage.tag-20 withObject:_images.result.file_path?:@""];
    [_productImageIDs replaceObjectAtIndex:thumbProductImage.tag-20 withObject:@(_images.result.pic_id)?:@""];
    
    NSArray *objectProductPhoto = (type == TYPE_ADD_EDIT_PRODUCT_ADD || type == TYPE_ADD_EDIT_PRODUCT_COPY)?_productImageURLs:_productImageIDs;
    NSString *stringImageURLs = [[objectProductPhoto valueForKey:@"description"] componentsJoinedByString:@"~"];
    [_dataInput setObject:stringImageURLs forKey:API_PRODUCT_IMAGE_TOUPLOAD_KEY];
    NSLog(@" Product image URL %@ with string %@ ", objectProductPhoto, stringImageURLs);
    
    [_uploadingImages removeObject:object];
    
    [self requestProcessUploadPhoto];
}

-(void)failedUploadObject:(id)object
{
    UIImageView *thumbProductImage = [object objectForKey:DATA_SELECTED_IMAGE_VIEW_KEY];
    UIButton *selectedButton = [object objectForKey:DATA_SELECTED_BUTTON_KEY];
    
    selectedButton.hidden = NO;
    selectedButton.enabled = YES;
    thumbProductImage.hidden = YES;
    
    [_uploadingImages removeObject:object];
    
    [self requestProcessUploadPhoto];
}

- (void)requestProcessUploadPhoto
{
    if (_uploadingImages.count > 0) {
        [self actionUploadImage:[_uploadingImages firstObject]];
    }
    else
    {
        _isFinishedUploadImages = YES;
    }
}

#pragma mark Request Delete Image
-(void)configureRestKitDeleteImage
{
    _objectmanagerDeleteImage =  [RKObjectManager sharedClient];
    
    // setup object mappings
    RKObjectMapping *statusMapping = [RKObjectMapping mappingForClass:[ShopSettings class]];
    [statusMapping addAttributeMappingsFromDictionary:@{kTKPD_APISTATUSMESSAGEKEY:kTKPD_APISTATUSMESSAGEKEY,
                                                        kTKPD_APIERRORMESSAGEKEY:kTKPD_APIERRORMESSAGEKEY,
                                                        kTKPD_APISTATUSKEY:kTKPD_APISTATUSKEY,
                                                        kTKPD_APISERVERPROCESSTIMEKEY:kTKPD_APISERVERPROCESSTIMEKEY,
                                                        }];
    
    RKObjectMapping *resultMapping = [RKObjectMapping mappingForClass:[ShopSettingsResult class]];
    [resultMapping addAttributeMappingsFromDictionary:@{kTKPDDETAIL_APIISSUCCESSKEY:kTKPDDETAIL_APIISSUCCESSKEY}];
    
    [statusMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:kTKPD_APIRESULTKEY toKeyPath:kTKPD_APIRESULTKEY withMapping:resultMapping]];
    
    // register mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping method:RKRequestMethodPOST pathPattern:kTKPDDETAILACTIONPRODUCT_APIPATH keyPath:@"" statusCodes:kTkpdIndexSetStatusCodeOK];
    
    [_objectmanagerDeleteImage addResponseDescriptor:responseDescriptor];
}

-(void)cancelDeleteImage
{
    [_requestDeleteImage cancel];
    _requestDeleteImage = nil;
    
    [_objectmanagerDeleteImage.operationQueue cancelAllOperations];
    _objectmanagerDeleteImage = nil;
}

- (void)requestDeleteImage:(id)object
{
    if(_requestDeleteImage.isExecuting) return;
    
    _requestcountDeleteImage ++;
    NSDictionary *userInfo = (NSDictionary*)object;
    
    NSInteger productID = [[userInfo objectForKey:API_PRODUCT_ID_KEY]integerValue];
    NSInteger myshopID = [[userInfo objectForKey:kTKPD_SHOPIDKEY]integerValue];
    NSInteger pictureID = [[userInfo objectForKey:API_PRODUCT_PICTURE_ID_KEY]integerValue];
    NSDictionary *param = @{kTKPDDETAIL_APIACTIONKEY : ACTION_DELETE_IMAGE,
                            API_PRODUCT_ID_KEY: @(productID),
                            kTKPD_SHOPIDKEY : @(myshopID),
                            API_PRODUCT_PICTURE_ID_KEY:@(pictureID)
                            };
    
    NSTimer *timer;
    
    _requestDeleteImage = [_objectmanagerDeleteImage appropriateObjectRequestOperationWithObject:self method:RKRequestMethodPOST path:kTKPDDETAILACTIONPRODUCT_APIPATH parameters:[param encrypt]];
    [_requestDeleteImage setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [self requestSuccessDeleteImage:mappingResult withOperation:operation];
        [timer invalidate];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        [self requestFailureDeleteImage:error];
        [timer invalidate];
    }];
    
    [_operationQueue addOperation:_requestDeleteImage];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:kTKPDREQUEST_TIMEOUTINTERVAL target:self selector:@selector(requestTimeoutDeleteImage) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}


-(void)requestSuccessDeleteImage:(id)object withOperation:(RKObjectRequestOperation*)operation
{
    NSDictionary *result = ((RKMappingResult*)object).dictionary;
    id info = [result objectForKey:@""];
    _setting = info;
    NSString *statusstring = _setting.status;
    BOOL status = [statusstring isEqualToString:kTKPDREQUEST_OKSTATUS];
    
    if (status) {
        [self requestProcessDeleteImage:object];
    }
}

-(void)requestFailureDeleteImage:(id)object
{
    [self requestProcessDeleteImage:object];
}

-(void)requestProcessDeleteImage:(id)object
{
    if (object) {
        if ([object isKindOfClass:[RKMappingResult class]]) {
            NSDictionary *result = ((RKMappingResult*)object).dictionary;
            id stat = [result objectForKey:@""];
            ShopSettings *setting = stat;
            BOOL status = [setting.status isEqualToString:kTKPDREQUEST_OKSTATUS];
            
            if (status) {
                if(setting.message_error)
                {
                    NSArray *array = setting.message_error?:[[NSArray alloc] initWithObjects:ERRORMESSAGE_DELETE_PRODUCT_IMAGE, nil];
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:array,@"messages", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_SETUSERSTICKYERRORMESSAGEKEY object:nil userInfo:info];
                    [self cancelDeletedImage];
                }
                if (setting.result.is_success == 1) {
                    NSArray *array = setting.message_status?:[[NSArray alloc] initWithObjects:SUCCESSMESSAGE_DELETE_PRODUCT_IMAGE, nil];
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:array,@"messages", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_SETUSERSTICKYSUCCESSMESSAGEKEY object:nil userInfo:info];
                }
            }
        }
        else{
            [self cancelDeleteImage];
            [self cancelDeletedImage];
            NSError *error = object;
            if (!([error code] == NSURLErrorCancelled)){
                NSString *errorDescription = error.localizedDescription;
                UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:ERROR_TITLE message:errorDescription delegate:self cancelButtonTitle:ERROR_CANCEL_BUTTON_TITLE otherButtonTitles:nil];
                [errorAlert show];
                [self cancelDeletedImage];
            }
        }
    }
}

-(void)requestTimeoutDeleteImage
{
    [self cancelDeleteImage];
}


#pragma mark - Camera Controller Delegate
-(void)didDismissCameraController:(CameraController *)controller withUserInfo:(NSDictionary *)userinfo
{
    NSMutableDictionary *object = [NSMutableDictionary new];
    NSDictionary* photo = [userinfo objectForKey:kTKPDCAMERA_DATAPHOTOKEY];
    UIImageView *selectedProductImageView;
    for (UIImageView *imageView in _thumbProductImageViews) {
        if (imageView.tag == controller.tag) {
            selectedProductImageView = imageView;
        }
    }
    UIButton *selectedButton;
    for (UIButton *button in _addImageButtons) {
        if (button.tag == controller.tag) {
            selectedButton = button;
            button.enabled = NO;
            button.hidden = YES;
        }
        if (button.tag == controller.tag+1) {
            button.hidden = NO;
            button.enabled = YES;
        }
    }
    
    [object setObject:userinfo forKey:DATA_SELECTED_PHOTO_KEY];
    [object setObject:selectedProductImageView forKey:DATA_SELECTED_IMAGE_VIEW_KEY];
    [object setObject:selectedButton forKey:DATA_SELECTED_BUTTON_KEY];

    UIImage* image = [photo objectForKey:kTKPDCAMERA_DATAPHOTOKEY];
    UIGraphicsBeginImageContextWithOptions(kTKPDCAMERA_UPLOADEDIMAGESIZE, NO, image.scale);
    [image drawInRect:kTKPDCAMERA_UPLOADEDIMAGERECT];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    selectedProductImageView.image = image;
    selectedProductImageView.hidden = NO;
    selectedProductImageView.alpha = 0.5f;
    
    [self actionUploadImage:object];
}

-(void)actionUploadImage:(id)object
{
    _isFinishedUploadImages = NO;
    RequestUploadImage *uploadImage = [RequestUploadImage new];
    uploadImage.imageObject = object;
    uploadImage.delegate = self;
    uploadImage.productID = _product.result.product.product_id;
    uploadImage.generateHost = _generateHost;
    uploadImage.action = ACTION_UPLOAD_PRODUCT_IMAGE;
    uploadImage.fieldName = @"fileToUpload";
    [uploadImage configureRestkitUploadPhoto];
    [uploadImage requestActionUploadPhoto];
}

-(void)failedAddImageAtIndex:(NSInteger)index
{
    NSUInteger indexDisableButton = (index<_addImageButtons.count-1)?index+1:index;
    ((UIButton*)_addImageButtons[indexDisableButton]).enabled = NO;
    ((UIButton*)_addImageButtons[index]).hidden = NO;
    ((UIImageView*)_thumbProductImageViews[index]).hidden = YES;
    
    NSArray *array = _images.message_error?:[[NSArray alloc] initWithObjects:ERRORMESSAGE_FAILED_IMAGE_UPLOAD, nil];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:array,@"messages", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_SETUSERSTICKYERRORMESSAGEKEY object:nil userInfo:info];
}

#pragma mark - Category Delegate
-(void)CategoryMenuViewController:(CategoryMenuViewController *)viewController userInfo:(NSDictionary *)userInfo
{
    [_dataInput setObject:userInfo forKey:DATA_CATEGORY_KEY];
    NSString *departmentName = [userInfo objectForKey:kTKPDCATEGORY_DATATITLEKEY];
    NSString *departmentID = [userInfo objectForKey:API_DEPARTMENT_ID_KEY];
    //[_categoryButton setTitle:departmentTitle forState:UIControlStateNormal];
    Breadcrumb *breadcrumb = [Breadcrumb new];
    breadcrumb.department_id = departmentID;
    breadcrumb.department_name = departmentName;
    [_dataInput setObject:breadcrumb forKey:DATA_CATEGORY_KEY];
    [_tableView reloadData];
}

#pragma mark - Product Edit Image Delegate

-(void)deleteProductImageAtIndex:(NSInteger)index
{
    [_dataInput setObject:_productImageIDs[index] forKey:DATA_LAST_DELETED_IMAGE_ID];
    [_dataInput setObject:_productImageURLs forKey:DATA_LAST_DELETED_IMAGE_PATH];
    [_dataInput setObject:@(index) forKey:DATA_LAST_DELETED_INDEX];
    [_dataInput setObject:((UIImageView*)_thumbProductImageViews[index]).image forKey:DATA_LAST_DELETED_IMAGE];
    
    NSInteger type = [[_data objectForKey:DATA_TYPE_ADD_EDIT_PRODUCT_KEY]integerValue];
    if (type == TYPE_ADD_EDIT_PRODUCT_EDIT || type == TYPE_ADD_EDIT_PRODUCT_COPY) {
        [self configureRestKitDeleteImage];
        TKPDSecureStorage* secureStorage = [TKPDSecureStorage standardKeyChains];
        NSDictionary* auth = [secureStorage keychainDictionary];
        
        DetailProductResult *detailProduct = _product.result;
        NSInteger productID = [detailProduct.product.product_id integerValue];
        NSInteger myshopID = [[auth objectForKey:kTKPD_SHOPIDKEY]integerValue];
        NSInteger pictureID = [_productImageIDs[index] integerValue];
        NSDictionary *userInfo = @{API_PRODUCT_ID_KEY: @(productID),
                                   kTKPD_SHOPIDKEY : @(myshopID),
                                   API_PRODUCT_PICTURE_ID_KEY:@(pictureID)
                                   };
        [self requestDeleteImage:userInfo];
    }

    ((UIButton*)_addImageButtons[index]).hidden = NO;
    ((UIButton*)_addImageButtons[index]).enabled = YES;
    [_productImageIDs replaceObjectAtIndex:index withObject:@""];
    [_productImageURLs replaceObjectAtIndex:index withObject:@""];
    ((UIImageView*)_thumbProductImageViews[index]).image = nil;
    ((UIImageView*)_thumbProductImageViews[index]).hidden = YES;
}

//-(void)updateProductImage:(UIImage *)image AtIndex:(NSInteger)index withUserInfo:(NSDictionary *)userInfo
//{
//    [self actionUploadImage:userInfo];
//    
//    UIGraphicsBeginImageContextWithOptions(kTKPDCAMERA_UPLOADEDIMAGESIZE, NO, image.scale);
//    [image drawInRect:kTKPDCAMERA_UPLOADEDIMAGERECT];
//    image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    ((UIButton*)_addImageButtons[index]).hidden = YES;
//    ((UIImageView*)_thumbProductImageViews[index]).image = image;
//    ((UIImageView*)_thumbProductImageViews[index]).hidden = NO;
//}

-(void)setDefaultImageAtIndex:(NSInteger)index
{
    for (UILabel *defaultImageLabel in _defaultImageLabels) {
        defaultImageLabel.hidden = YES;
    }
    NSInteger type = [[_data objectForKey:DATA_TYPE_ADD_EDIT_PRODUCT_KEY]integerValue];
    ((UILabel*)_defaultImageLabels[index]).hidden = NO;
    NSString *imagePath = _productImageURLs[index];
    NSString *imageID = _productImageIDs[index];
    NSString *defaultImage = (type == TYPE_ADD_EDIT_PRODUCT_ADD)?imagePath:imageID;
    [_dataInput setObject:defaultImage forKey:API_PRODUCT_IMAGE_DEFAULT_KEY];
}

-(void)setProductImageName:(NSString *)name atIndex:(NSInteger)index
{
    [_productImageDesc replaceObjectAtIndex:index withObject:name];
    NSInteger type = [[_data objectForKey:DATA_TYPE_ADD_EDIT_PRODUCT_KEY]integerValue];
    if (type == TYPE_ADD_EDIT_PRODUCT_ADD) {
        NSString *stringImageName = [[_productImageDesc valueForKey:@"description"] componentsJoinedByString:@"~"];
        [_dataInput setObject:stringImageName forKey:API_PRODUCT_IMAGE_DESCRIPTION_KEY];
    }
    else
    {
        NSInteger imageID =[_productImageIDs[index] integerValue];
        NSString *imageDescriptionKey = [NSString stringWithFormat:API_PRODUCT_IMAGE_DESCRIPTION_KEY@"%zd",imageID];
        NSDictionary *imageNames = [_dataInput objectForKey:API_PRODUCT_IMAGE_DESCRIPTION_KEY];
        NSMutableDictionary *ImageNameDictionary = [NSMutableDictionary new];
        [ImageNameDictionary addEntriesFromDictionary:imageNames];
        [ImageNameDictionary setObject:name forKey:imageDescriptionKey];
        [_dataInput setObject:ImageNameDictionary forKey:API_PRODUCT_IMAGE_DESCRIPTION_KEY];
    }
}

#pragma mark - Alert View Delegate
-(void)alertView:(TKPDAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [_productNameTextField resignFirstResponder];
    switch (alertView.tag) {
        case 11:
        {
            //price curency
            TKPDSecureStorage* secureStorage = [TKPDSecureStorage standardKeyChains];
            NSDictionary* auth = [secureStorage keychainDictionary];
            BOOL isGoldShop = [[auth objectForKey:kTKPD_SHOPISGOLD]boolValue];
            
            NSInteger index = [[alertView.data objectForKey:DATA_INDEX_KEY] integerValue];

            NSInteger previousValue = [[_dataInput objectForKey:API_PRODUCT_PRICE_CURRENCY_ID_KEY]integerValue];
            
            NSInteger value = [[ARRAY_PRICE_CURRENCY[index] objectForKey:DATA_VALUE_KEY] integerValue];
            NSString *name = [ARRAY_PRICE_CURRENCY[index] objectForKey:DATA_NAME_KEY];
            
            if ( value == PRICE_CURRENCY_ID_USD && !isGoldShop) {
                NSArray *errorMessage = @[ERRORMESSAGE_INVALID_PRICE_CURRENCY_USD];
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:errorMessage,@"messages", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_SETUSERSTICKYERRORMESSAGEKEY object:nil userInfo:info];
            }
            else{
                if (value != previousValue) {
                    _productPriceTextField.text = @"";
                }
                ProductDetail *product = [_dataInput objectForKey:DATA_PRODUCT_DETAIL_KEY];
                product.product_currency_id = [ARRAY_PRICE_CURRENCY[index] objectForKey:DATA_VALUE_KEY];
                product.product_currency = name;
                [_dataInput setObject:product forKey:DATA_PRODUCT_DETAIL_KEY];
                [_tableView reloadData];
                
            }
            break;
        }
        case 12:
        {
            //weight curency
            NSInteger index = [[alertView.data objectForKey:DATA_INDEX_KEY] integerValue];
            NSString *value = [ARRAY_WEIGHT_UNIT[index] objectForKey:DATA_VALUE_KEY];
            NSString *name = [ARRAY_WEIGHT_UNIT[index] objectForKey:DATA_NAME_KEY];
            ProductDetail *product = [_dataInput objectForKey:DATA_PRODUCT_DETAIL_KEY];
            product.product_weight_unit_name = name;
            product.product_weight_unit = value;
            [_dataInput setObject:product forKey:DATA_PRODUCT_DETAIL_KEY];
            [_tableView reloadData];
            break;
        }
        default:
            break;
    }
}


#pragma mark - Text Field Delegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    _activeTextField = textField;
    if (textField == _productNameTextField) {
        NSInteger type = [[_data objectForKey:DATA_TYPE_ADD_EDIT_PRODUCT_KEY]integerValue];
        if (type == TYPE_ADD_EDIT_PRODUCT_EDIT) {
            UIAlertView *editableNameProductAlert = [[UIAlertView alloc]initWithTitle:nil message:ERRRORMESSAGE_CANNOT_EDIT_PRODUCT_NAME delegate:self cancelButtonTitle:ERROR_CANCEL_BUTTON_TITLE otherButtonTitles:nil];
            [editableNameProductAlert show];
        }
    }
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    ProductDetail *product = [_dataInput objectForKey:DATA_PRODUCT_DETAIL_KEY];
    if (textField == _productNameTextField) {
        NSInteger type = [[_data objectForKey:DATA_TYPE_ADD_EDIT_PRODUCT_KEY]integerValue];
        if (type == TYPE_ADD_EDIT_PRODUCT_ADD || type == TYPE_ADD_EDIT_PRODUCT_COPY) {
            product.product_name = textField.text;
            [_dataInput setObject:product forKey:DATA_PRODUCT_DETAIL_KEY];
        }
    }
    if (textField == _productPriceTextField) {
        NSString *productPrice;
        NSInteger currency = [[_dataInput objectForKey:API_PRODUCT_PRICE_CURRENCY_ID_KEY]integerValue];
        BOOL isIDRCurrency = (currency == PRICE_CURRENCY_ID_RUPIAH);
        if (isIDRCurrency)
           productPrice = [textField.text stringByReplacingOccurrencesOfString:@"," withString:@""];
        else
        {
            productPrice = [textField.text stringByReplacingOccurrencesOfString:@"," withString:@""];
            
        }
        product.product_price = productPrice;
        [_dataInput setObject:product forKey:DATA_PRODUCT_DETAIL_KEY];
    }
    if (textField == _productWeightTextField) {
        product.product_weight = textField.text;
        [_dataInput setObject:product forKey:DATA_PRODUCT_DETAIL_KEY];
    }
    if (textField == _minimumOrderTextField) {
        product.product_min_order = textField.text;
        [_dataInput setObject:product forKey:DATA_PRODUCT_DETAIL_KEY];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    ProductDetail *product = [_dataInput objectForKey:DATA_PRODUCT_DETAIL_KEY];
    BOOL isIDRCurrency = ([product.product_currency_id integerValue] == PRICE_CURRENCY_ID_RUPIAH);
    if (textField == _productPriceTextField) {
        if (isIDRCurrency) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            if([string length]==0)
            {
                [formatter setGroupingSeparator:@","];
                [formatter setGroupingSize:4];
                [formatter setUsesGroupingSeparator:YES];
                [formatter setSecondaryGroupingSize:3];
                NSString *num = textField.text ;
                num = [num stringByReplacingOccurrencesOfString:@"," withString:@""];
                NSString *str = [formatter stringFromNumber:[NSNumber numberWithDouble:[num doubleValue]]];
                textField.text = str;
                return YES;
            }
            else {
                [formatter setGroupingSeparator:@","];
                [formatter setGroupingSize:2];
                [formatter setUsesGroupingSeparator:YES];
                [formatter setSecondaryGroupingSize:3];
                NSString *num = textField.text ;
                if(![num isEqualToString:@""])
                {
                    num = [num stringByReplacingOccurrencesOfString:@"," withString:@""];
                    NSString *str = [formatter stringFromNumber:[NSNumber numberWithDouble:[num doubleValue]]];
                    textField.text = str;
                }
                return YES;
            }
        }
        else
        {
            NSString *cleanCentString = [[textField.text
                                          componentsSeparatedByCharactersInSet:
                                          [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                         componentsJoinedByString:@""];
            // Parse final integer value
            NSInteger centAmount = cleanCentString.integerValue;
            // Check the user input
            if (string.length > 0)
            {
                // Digit added
                centAmount = centAmount * 10 + string.integerValue;
            }
            else
            {
                // Digit deleted
                centAmount = centAmount / 10;
            }
            // Update call amount value
            NSNumber *amount = [[NSNumber alloc] initWithFloat:(float)centAmount / 100.0f];
            // Write amount with currency symbols to the textfield
            NSNumberFormatter *_currencyFormatter = [[NSNumberFormatter alloc] init];
            [_currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            [_currencyFormatter setCurrencyCode:@"USD"];
            [_currencyFormatter setNegativeFormat:@"-¤#,##0.00"];
            textField.text = [_currencyFormatter stringFromNumber:amount];
            return NO;
        }
    }
    else if (textField == _productNameTextField) {
#define PRODUCT_NAME_CHARACTER_LIMIT 70
        return textField.text.length + (string.length - range.length) <= PRODUCT_NAME_CHARACTER_LIMIT;
    }
    else
        return YES;
}


#pragma mark - Product Edit Detail Delegate 
-(void)ProductEditDetailViewController:(ProductAddEditDetailViewController *)cell withUserInfo:(NSDictionary *)userInfo
{
    NSDictionary *updatedDataInput = [userInfo objectForKey:DATA_INPUT_KEY];
    
    [_dataInput removeAllObjects];
    [_dataInput addEntriesFromDictionary:updatedDataInput];
}


#pragma mark - Methods

- (void) setDefaultData:(NSDictionary*)data
{
    _data = data;
    if (data) {
        
        NSInteger type = [[_data objectForKey:DATA_TYPE_ADD_EDIT_PRODUCT_KEY]integerValue];
        switch (type) {
            case TYPE_ADD_EDIT_PRODUCT_ADD:
                self.title =  TITLE_ADD_PRODUCT;
                break;
            case TYPE_ADD_EDIT_PRODUCT_EDIT:
                self.title = TITLE_EDIT_PRODUCT;
                break;
            case TYPE_ADD_EDIT_PRODUCT_COPY:
                self.title = TITLE_SALIN_PRODUCT;
                break;
            default:
                break;
        }
        DetailProductResult *result = _product.result;
        ProductDetail *product = result.product;
        if (!product) {
            product = [ProductDetail new];
            product.product_weight_unit_name = [ARRAY_WEIGHT_UNIT[0] objectForKey:DATA_NAME_KEY];
            product.product_weight_unit = [ARRAY_WEIGHT_UNIT[0] objectForKey:DATA_VALUE_KEY];
            
            product.product_currency = [ARRAY_PRICE_CURRENCY[0] objectForKey:DATA_NAME_KEY];
            product.product_currency_id = [ARRAY_PRICE_CURRENCY[0] objectForKey:DATA_VALUE_KEY];
            
            product.product_min_order = @"1";
            
            product.product_condition = [ARRAY_PRODUCT_CONDITION[0] objectForKey:DATA_VALUE_KEY];
            
            NSString *value = [ARRAY_PRODUCT_MOVETO_ETALASE[0] objectForKey:DATA_VALUE_KEY];
            product.product_move_to = value;
        }
        else
        {
            product.product_weight_unit_name = [ARRAY_WEIGHT_UNIT[[product.product_weight_unit integerValue]-1] objectForKey:DATA_NAME_KEY];
            if ([product.product_currency isEqualToString:@"idr"]) {
                product.product_currency = [ARRAY_PRICE_CURRENCY[0]objectForKey:DATA_NAME_KEY];
            }
            NSInteger indexMoveTo = ([product.product_etalase_id integerValue]>0)?1:0;
            NSString *value = [ARRAY_PRODUCT_MOVETO_ETALASE[indexMoveTo] objectForKey:DATA_VALUE_KEY];
            product.product_move_to = value;
            product.product_etalase_id = product.product_etalase_id?:@(0);
            product.product_description = product.product_short_desc;
        }
        [_dataInput setObject:product forKey:DATA_PRODUCT_DETAIL_KEY];
        NSArray *images = result.product_images;
        NSInteger imageCount = images.count;
        NSInteger addProductImageCount = (imageCount<_addImageButtons.count)?imageCount:imageCount-1;
        ((UIButton*)_addImageButtons[addProductImageCount]).enabled = YES;
        
        NSMutableDictionary *productImageDescription = [NSMutableDictionary new];
        for (int i = 0 ; i<imageCount;i++) {
            ProductImages *image = images[i];
            ((UIButton*)_addImageButtons[i]).hidden = YES;
            [_productImageURLs replaceObjectAtIndex:i withObject:image.image_src];
            [_productImageIDs replaceObjectAtIndex:i withObject:@(image.image_id)];
            [_productImageDesc replaceObjectAtIndex:i withObject:image.image_description];

            NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:image.image_src] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTKPDREQUEST_TIMEOUTINTERVAL];
            UIImageView *thumb = (UIImageView*)_thumbProductImageViews[i];
            thumb.userInteractionEnabled = NO;
            thumb.hidden = NO;
            thumb.image = nil;
            //thumb.hidden = YES;	//@prepareforreuse then @reset
            [thumb setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
                [thumb setImage:image animated:YES];
#pragma clang diagnostic pop
                thumb.userInteractionEnabled = YES;
                
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            }];
            
            NSString *productImageDescriptionKey = [NSString stringWithFormat:API_PRODUCT_IMAGE_DESCRIPTION_KEY@"%zd",image.image_id];
            [productImageDescription setObject:image.image_description forKey:productImageDescriptionKey];
        }
        
        [_dataInput setObject:productImageDescription forKey:API_PRODUCT_IMAGE_DESCRIPTION_KEY];

        NSArray *objectProductPhoto = (type == TYPE_ADD_EDIT_PRODUCT_ADD||type == TYPE_ADD_EDIT_PRODUCT_COPY)?_productImageURLs:_productImageIDs;
        NSString *stringImageURLs = [[objectProductPhoto valueForKey:@"description"] componentsJoinedByString:@"~"];
        [_dataInput setObject:stringImageURLs forKey:API_PRODUCT_IMAGE_TOUPLOAD_KEY];
        NSLog(@" Product image URL %@ with string %@ ", objectProductPhoto, stringImageURLs);
        
        NSString *serverID = result.server_id?:_generatehost.result.generated_host.server_id?:@"0";
        NSArray *breadcrumbs = result.breadcrumb?:@[];
        Breadcrumb *breadcrumb = [breadcrumbs lastObject]?:[Breadcrumb new];
        [_dataInput setObject:breadcrumb forKey:DATA_CATEGORY_KEY];
        NSString *priceCurencyID = result.product.product_currency_id?:@"1";
        
        NSString *price = result.product.product_price?:@"";
        NSString *weight = result.product.product_weight?:@"";
        NSArray *wholesale = result.wholesale_price?:@[];
        [_dataInput setObject:wholesale forKey:DATA_WHOLESALE_LIST_KEY];
        BOOL isWarehouse = ([result.product.product_etalase_id integerValue]>0)?NO:YES;
        NSInteger uploadToWarehouse = isWarehouse?UPLOAD_TO_VALUE_IF_IS_WAREHOUSE:UPLOAD_TO_VALUE_IF_ISNOT_WAREHOUSE;
        BOOL isGoldShop = result.shop_is_gold;
        
        _productNameTextField.text = product.product_name;
        //_productNameTextField.enabled = (type ==TYPE_ADD_EDIT_PRODUCT_ADD || type == TYPE_ADD_EDIT_PRODUCT_COPY)?YES:NO;
        
        NSInteger priceInteger = [price integerValue];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        if ([priceCurencyID integerValue] == PRICE_CURRENCY_ID_RUPIAH) {
            [formatter setGroupingSeparator:@","];
            [formatter setGroupingSize:3];
            [formatter setUsesGroupingSeparator:YES];
            [formatter setSecondaryGroupingSize:3];
            price = (priceInteger>0)?[formatter stringFromNumber:@(priceInteger)]:@"";
        }
        else
        {
            price = (price>0)?[NSString localizedStringWithFormat:@"%.2f",(float)priceInteger]:@"";
        }
        
        _productPriceTextField.text = price;
        _productWeightTextField.text = weight;
        
        [_dataInput setObject:serverID forKey:API_SERVER_ID_KEY];
        [_dataInput setObject:wholesale forKey:DATA_WHOLESALE_LIST_KEY];
        [_dataInput setObject:@(uploadToWarehouse) forKey:API_PRODUCT_MOVETO_WAREHOUSE_KEY];
//        [_dataInput setObject:@(etalaseID) forKey:API_PRODUCT_ETALASE_ID_KEY];
        [_dataInput setObject:@(isGoldShop) forKey:API_IS_GOLD_SHOP_KEY];
//        [_dataInput setObject:@(returnable) forKey:API_PRODUCT_IS_RETURNABLE_KEY];
        
    }
}

- (BOOL)dataInputIsValid
{
    [_errorMessage removeAllObjects];
    BOOL isValid = YES;
    BOOL isValidPrice = YES;
    BOOL isValidWeight = YES;
    
    NSMutableArray *productImagesTemp = [NSMutableArray new];
    for (NSString *productImage in _productImageURLs) {
        if (![productImage isEqualToString:@""]) {
            [productImagesTemp addObject:productImage];
        }
    }
    //BOOL isValidImage = (productImagesTemp.count>0);
    BOOL isValidImage = YES;
    
    ProductDetail *product = [_dataInput objectForKey:DATA_PRODUCT_DETAIL_KEY]?:[ProductDetail new];
    Breadcrumb *department = [_dataInput objectForKey:DATA_CATEGORY_KEY]?:[Breadcrumb new];
    NSString *productName = product.product_name;
    NSString *productPrice = product.product_price;
    NSString *productPriceCurrencyID = product.product_currency_id;
    NSString *productWeight = product.product_weight;
    NSString *productWeightUnitID = product.product_weight_unit;
    NSString *departmentID = department.department_id;
    
    BOOL isPriceCurrencyRupiah = ([productPriceCurrencyID integerValue] == PRICE_CURRENCY_ID_RUPIAH);
    BOOL isPriceCurrencyUSD = ([productPriceCurrencyID integerValue] == PRICE_CURRENCY_ID_USD);
    
    BOOL isWeightUnitGram = ([productWeightUnitID integerValue] == WEIGHT_UNIT_ID_GRAM);
    BOOL isWeightUnitKilogram = ([productWeightUnitID integerValue] == WEIGHT_UNIT_ID_KILOGRAM);
    
    if (productName && ![productName isEqualToString:@""] &&
        productPrice>0 &&
        productWeight>0 &&
        departmentID>0) {
       
        if (isPriceCurrencyRupiah && [productPrice integerValue]>=MINIMUM_PRICE_RUPIAH &&
            [productPrice integerValue]<=MAXIMUM_PRICE_RUPIAH)
            isValidPrice = YES;
        else if (isPriceCurrencyUSD && [productPrice integerValue]>=MINIMUM_PRICE_USD &&
                 [productPrice integerValue]<=MAXIMUM_PRICE_USD)
            isValidPrice = YES;
        else
            isValidPrice = NO;
        
        if (isWeightUnitGram &&
            [productWeight integerValue]>=MINIMUM_WEIGHT_GRAM &&
            [productWeight integerValue]<=MAXIMUM_WEIGHT_GRAM)
            isValidWeight = YES;
        else if (isWeightUnitKilogram && [productWeight integerValue]>=MINIMUM_WEIGHT_KILOGRAM &&
                 [productWeight integerValue]<=MAXIMUM_WEIGHT_KILOGRAM)
            isValidWeight = YES;
        else
            isValidWeight = NO;
    }

    if ( !productName || [productName isEqualToString:@""]) {
        [_errorMessage addObject:ERRORMESSAGE_NULL_PRODUCT_NAME];
        isValid = NO;
    }
    if (!(productPrice > 0)) {
        [_errorMessage addObject:ERRORMESSAGE_NULL_PRICE];
        isValid = NO;
    }
    else
    {
        if ([productPriceCurrencyID integerValue] == PRICE_CURRENCY_ID_RUPIAH &&
            ([productPrice integerValue]<MINIMUM_PRICE_RUPIAH || [productPrice integerValue]>MAXIMUM_PRICE_RUPIAH)) {
            [_errorMessage addObject:ERRORMESSAGE_INVALID_PRICE_RUPIAH];
            isValid = NO;
        }
        else if ([productPriceCurrencyID integerValue] == PRICE_CURRENCY_ID_USD &&
                 ([productPrice integerValue]<MINIMUM_PRICE_USD || [productPrice integerValue]>MAXIMUM_PRICE_USD)) {
            [_errorMessage addObject:ERRORMESSAGE_INVALID_PRICE_USD];
            isValid = NO;
        }
    }
    if (!(departmentID>0)) {
        [_errorMessage addObject:ERRORMESSAGE_NULL_CATEGORY];
        isValid = NO;
    }
    if ([productWeightUnitID integerValue] == WEIGHT_UNIT_ID_GRAM &&
        ([productWeight integerValue]<MINIMUM_WEIGHT_GRAM || [productWeight integerValue]>MAXIMUM_WEIGHT_GRAM)) {
        [_errorMessage addObject:ERRORMESSAGE_INVALID_WEIGHT_GRAM];
        isValid = NO;
    }
    else if ([productWeightUnitID integerValue] == WEIGHT_UNIT_ID_KILOGRAM &&
             ([productWeight integerValue]<MINIMUM_WEIGHT_KILOGRAM || [productWeight integerValue]>MAXIMUM_WEIGHT_KILOGRAM)) {
        [_errorMessage addObject:ERRORMESSAGE_INVALID_WEIGHT_KILOGRAM];
        isValid = NO;
    }
    if (!isValidImage) {
        [_errorMessage addObject:ERRORMESSAGE_NULL_IMAGE];
    }

    return (isValidWeight && isValidPrice && isValid && isValidImage);
}

-(void)enableButtonBeforeSuccessRequest:(BOOL)isEnable
{
    _nextBarButtonItem.enabled = isEnable;
    ((UIButton*)_addImageButtons[0]).enabled = NO;

    _productNameTextField.userInteractionEnabled = isEnable;
    _minimumOrderTextField.userInteractionEnabled = isEnable;
    _productPriceTextField.userInteractionEnabled = isEnable;
    _productWeightTextField.userInteractionEnabled = isEnable;
}

-(void)cancelDeletedImage
{
    NSString *deletedImagePath = [_dataInput objectForKey:DATA_LAST_DELETED_IMAGE_PATH];
    NSInteger deletedImageID = [[_dataInput objectForKey:DATA_LAST_DELETED_IMAGE_ID]integerValue];
    NSInteger index = [[_dataInput objectForKey:DATA_LAST_DELETED_INDEX]integerValue];
    UIImage *image = [_dataInput objectForKey:DATA_LAST_DELETED_IMAGE];
    
    UIGraphicsBeginImageContextWithOptions(kTKPDCAMERA_UPLOADEDIMAGESIZE, NO, image.scale);
    [image drawInRect:kTKPDCAMERA_UPLOADEDIMAGERECT];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    ((UIButton*)_addImageButtons[index]).hidden = YES;
    ((UIImageView*)_thumbProductImageViews[index]).image = image;
    ((UIImageView*)_thumbProductImageViews[index]).hidden = NO;
    [_productImageURLs replaceObjectAtIndex:index withObject:deletedImagePath];
    [_productImageIDs replaceObjectAtIndex:index withObject:@(deletedImageID)];
}

#pragma mark - Keyboard Notification
- (void)keyboardWillShow:(NSNotification *)aNotification {
//    if(_keyboardSize.height < 0){
//        _keyboardPosition = [[[info userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].origin;
//        _keyboardSize= [[[info userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].size;
//        
//        
//        _scrollviewContentSize = [_scrollView contentSize];
//        _scrollviewContentSize.height += _keyboardSize.height;
//        [_scrollView setContentSize:_scrollviewContentSize];
//    }else{
//        [UIView animateWithDuration:TKPD_FADEANIMATIONDURATION
//                              delay:0
//                            options: UIViewAnimationOptionCurveEaseInOut
//                         animations:^{
//                             _scrollviewContentSize = [_scrollView contentSize];
//                             _scrollviewContentSize.height -= _keyboardSize.height;
//                             
//                             _keyboardPosition = [[[info userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].origin;
//                             _keyboardSize= [[[info userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].size;
//                             _scrollviewContentSize.height += _keyboardSize.height;
//                             if ((_activeTextField.frame.origin.y+_activeTextField.frame.size.height)> _keyboardPosition.y) {
//                                 UIEdgeInsets inset = _scrollView.contentInset;
//                                 inset.top = (_keyboardPosition.y-(self.view.frame.origin.y + _activeTextField.frame.origin.y+_activeTextField.frame.size.height + 10));
//                                 [_scrollView setContentInset:inset];
//                             }
//                         }
//                         completion:^(BOOL finished){
//                         }];
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    _tableView.contentInset = contentInsets;
    _tableView.scrollIndicatorInsets = contentInsets;
    
    if (_activeTextField == _productPriceTextField) {
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    else if (_activeTextField == _productWeightTextField)
    {
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:3] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
}

- (void)keyboardWillHide:(NSNotification *)info {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    [UIView animateWithDuration:TKPD_FADEANIMATIONDURATION
                          delay:0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _tableView.contentInset = contentInsets;
                         _tableView.scrollIndicatorInsets = contentInsets;
                     }
                     completion:^(BOOL finished){
                     }];
}


@end
