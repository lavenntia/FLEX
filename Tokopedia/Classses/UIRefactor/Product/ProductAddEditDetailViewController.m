//
//  ProductAddEditDetailViewController.m
//  Tokopedia
//
//  Created by IT Tkpd on 12/8/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import "detail.h"
#import "ShopSettings.h"
#import "string_product.h"
#import "string_alert.h"
#import "EtalaseList.h"
#import "WholesalePrice.h"
#import "sortfiltershare.h"
#import "AlertPickerView.h"
#import "ProductAddEditDetailViewController.h"
#import "EtalaseViewController.h"
#import "ProductEditWholesaleViewController.h"
#import "MyShopEtalaseEditViewController.h"
#import "MyShopNoteViewController.h"
#import "Breadcrumb.h"

#import "MyShopNoteDetailViewController.h"
#import "TokopediaNetworkManager.h"
#import "GAIDictionaryBuilder.h"
#import "CatalogAddProduct.h"
#import "UserAuthentificationManager.h"
#import "Tokopedia-Swift.h"

NSString * const ProductStatusWarehouse = @"3";

@interface ProductAddEditDetailViewController ()
<
    UITableViewDataSource,
    UITableViewDelegate,
    UITextViewDelegate,
    TKPDAlertViewDelegate,
    EtalaseViewControllerDelegate,
    ProductEditWholesaleViewControllerDelegate,
    TokopediaNetworkManagerDelegate
>
{
    CGPoint _keyboardPosition;
    CGSize _keyboardSize;
    
    CGRect _containerDefault;
    CGSize _scrollviewContentSize;
    
    NSDictionary *_auth;
    NSMutableDictionary *_dataInput;
    NSMutableArray *_wholesaleList;
    
    UITextView *_activeTextView;
    
    NSInteger _requestCount;
    NSOperationQueue *_operationQueue;
    
    UIAlertView *_processingAlert;
    
    __weak RKObjectManager *_objectmanagerActionMoveToWarehouse;
    __weak RKManagedObjectRequestOperation *_requestActionMoveToWarehouse;
    
    TokopediaNetworkManager *_validationNetworkManager;
    TokopediaNetworkManager *_addPictureNetworkManager;
    TokopediaNetworkManager *_submitNetworkManager;
    TokopediaNetworkManager *_editNetworkManager;
    TokopediaNetworkManager *_moveToWarehouseNetworkManager;
    
    UIBarButtonItem *_saveBarButtonItem;
    UserAuthentificationManager *_userManager;
    
    BOOL _isNodata;
    BOOL _isBeingPresented;
    EtalaseList *_selectedEtalase;
    
    NSString *_uniqueID;
}
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *section0TableViewCell;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *section1TableViewCell;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *section2TableViewCell;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *section3TableViewCell;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *section4TableViewCell;
@property (strong, nonatomic) IBOutlet UIView *section0FooterView;
@property (strong, nonatomic) IBOutlet UIView *section3FooterView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UISwitch *returnableProductSwitch;
@property (weak, nonatomic) IBOutlet UITextView *productDescriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *pengembalianProductLabel;

- (IBAction)gesture:(id)sender;
- (IBAction)tap:(id)sender;

@end

#define TAG_REQUEST_MOVE_TO 14

@implementation ProductAddEditDetailViewController

#pragma mark - Initialization
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _wholesaleList = [NSMutableArray new];
        _dataInput = [NSMutableDictionary new];
        _operationQueue = [NSOperationQueue new];
    }
    return self;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self adjustBarButton];
    [self setDefaultData:_data];
    [self adjustReturnableNotesLabel];
    [self initNetworkManager];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _userManager = [UserAuthentificationManager new];
    
    _processingAlert = [[UIAlertView alloc]initWithTitle:nil message:@"Uploading..." delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardWillShow:)
               name:UIKeyboardWillShowNotification
             object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:)
               name:UIKeyboardWillHideNotification
             object:nil];
    
    _isBeingPresented = self.navigationController.isBeingPresented;


    [nc addObserver:self
           selector:@selector(didUpdateShopHasTerms:)
               name:DID_UPDATE_SHOP_HAS_TERM_NOTIFICATION_NAME
             object:nil];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:nil];
    barButtonItem.tag = 10;
    self.navigationItem.backBarButtonItem = barButtonItem;
    
}

-(void)initNetworkManager
{
    
    _moveToWarehouseNetworkManager = [TokopediaNetworkManager new];
    _moveToWarehouseNetworkManager.delegate = self;
    _moveToWarehouseNetworkManager.tagRequest = TAG_REQUEST_MOVE_TO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UITableViewCell *returnableCell = (UITableViewCell*)_section0TableViewCell[1];
    
    if (_form.info.shop_has_terms) {
        returnableCell.detailTextLabel.textColor = TEXT_COLOUR_ENABLE;
    }
    else
    {
        returnableCell.detailTextLabel.textColor = TEXT_COLOUR_DISABLE;
    }
    
    _returnableProductSwitch.enabled = _form.info.shop_has_terms;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

#pragma mark - Memory Management
-(void)dealloc{
    NSLog(@"%@ : %@",[self class], NSStringFromSelector(_cmd));
    
    [_moveToWarehouseNetworkManager requestCancel];
    _moveToWarehouseNetworkManager.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View Action
-(IBAction)tap:(id)sender
{
    [_activeTextView resignFirstResponder];
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *returnableSwitch =(UISwitch*)sender;
        BOOL isReturnable = returnableSwitch.on;
        [_dataInput setObject:@(isReturnable) forKey:API_PRODUCT_IS_RETURNABLE_KEY];
    }
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UIBarButtonItem *button = (UIBarButtonItem*)sender;
        switch (button.tag) {
            case BARBUTTON_PRODUCT_BACK:
            {
                NSDictionary *userInfo = @{DATA_INPUT_KEY:_dataInput};
                [_delegate ProductEditDetailViewController:self withUserInfo:userInfo];
                [self.navigationController popViewControllerAnimated:YES];
                break;
            }
            case BARBUTTON_PRODUCT_SAVE:
            {
                if (_type == TYPE_ADD_EDIT_PRODUCT_ADD|| _type == TYPE_ADD_EDIT_PRODUCT_COPY) {
                    if ([self isValidInput]) {
                        [self fetchAddProduct];
                    }
                } else {
                    [self fetchEditProduct];
                }
                break;
            }
            default:
                break;
        }
    }
    if ([sender isKindOfClass:[UIButton class]]) {
        MyShopNoteDetailViewController *vc = [MyShopNoteDetailViewController new];
        vc.data = @{kTKPDDETAIL_DATATYPEKEY : @(NOTES_RETURNABLE_PRODUCT)
                    };
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.navigationBar.translucent = NO;
        
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }
}

-(void)fetchAddProduct{
    
    [_processingAlert show];
    _saveBarButtonItem.enabled = NO;
    
    NSString *duplicate = (_type == TYPE_ADD_EDIT_PRODUCT_COPY)?@"1":@"0";
    
    ProductEditDetail *product = _form.product;
        
    NSArray *wholesaleList = [_dataInput objectForKey:DATA_WHOLESALE_LIST_KEY]?:@[];
    NSMutableDictionary *wholesales = [NSMutableDictionary new];
    for (NSDictionary *wholesale in wholesaleList) {
        [wholesales addEntriesFromDictionary:wholesale];
    }

    [RequestAddEditProduct fetchAddProduct:_form
                                   isDuplicate:duplicate
                                 onSuccess:^{
        
        [self successAddProduct];
        
    } onFailure:^{
        
        _saveBarButtonItem.enabled = YES;
        [_processingAlert dismissWithClickedButtonIndex:0 animated:YES];
        [self trackerFailAddProduct];
        
    }];
}

-(void)trackerFailAddProduct{
    [TPAnalytics trackScreenName:@"Add Product - Fail"];
    
    // GA
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker setAllowIDFACollection:YES];
    [tracker set:kGAIScreenName value:@"Add Product - Fail"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

-(void)fetchEditProduct{
    
    [_processingAlert show];
    _saveBarButtonItem.enabled = NO;
    
    NSArray *wholesaleList = [_dataInput objectForKey:DATA_WHOLESALE_LIST_KEY]?:@[];
    NSMutableDictionary *wholesales = [NSMutableDictionary new];
    for (NSDictionary *wholesale in wholesaleList) {
        [wholesales addEntriesFromDictionary:wholesale];
    }
    
    [RequestAddEditProduct fetchEditProduct:_form onSuccess:^{
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ADD_PRODUCT_POST_NOTIFICATION_NAME object:nil userInfo:nil];
        _saveBarButtonItem.enabled = YES;
        [_processingAlert dismissWithClickedButtonIndex:0 animated:YES];
        
    } onFailure:^{
        
        _saveBarButtonItem.enabled = YES;
        [_processingAlert dismissWithClickedButtonIndex:0 animated:YES];
        
    }];
}

-(void)successAddProduct{
    
    // UA
    [TPAnalytics trackScreenName:@"Add Product - Success"];
    
    // GA
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker setAllowIDFACollection:YES];
    [tracker set:kGAIScreenName value:@"Add Product - Success"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ADD_PRODUCT_POST_NOTIFICATION_NAME object:nil userInfo:nil];
    [_processingAlert dismissWithClickedButtonIndex:0 animated:YES];
}

-(BOOL)isValidInput
{
    BOOL isValid = YES;
    NSMutableArray *errorMessages = [NSMutableArray new];
    ProductEditDetail *product = _form.product;
    
//    NSString *moveToWarehouse = product.product_move_to?:@"";
    
    NSString* etalaseUserInfoID = product.product_etalase_id;
    BOOL isNewEtalase = [etalaseUserInfoID isEqualToString:@"-1"];
    NSString *etalaseID = isNewEtalase ? @"new" : etalaseUserInfoID;
    
    NSString *etalaseName = product.product_etalase?:@"";
    
    if (isNewEtalase && (etalaseName == nil || [etalaseName isEqualToString:@""])) {
        isValid = NO;
        [errorMessages addObject:@"Nama etalase belum diisi"];
    }
    if (!isNewEtalase && [etalaseID integerValue] == 0) {
        isValid = NO;
        [errorMessages addObject:@"Etalase belum dipilih"];
    }
    
    
    if (!isValid) {
        StickyAlertView *alert = [[StickyAlertView alloc]initWithErrorMessages:errorMessages delegate:self];
        [alert show];
    }
    return isValid;
}

- (IBAction)gesture:(id)sender {
    [_activeTextView resignFirstResponder];
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *gesture = (UITapGestureRecognizer*)sender;
        if (gesture.view.tag == GESTURE_PRODUCT_EDIT_WHOLESALE) {
            ProductEditWholesaleViewController *editWholesaleVC = [ProductEditWholesaleViewController new];
            editWholesaleVC.data = @{kTKPD_AUTHKEY : [_data objectForKey:kTKPD_AUTHKEY],
                                     DATA_INPUT_KEY : _dataInput
                                     };
            editWholesaleVC.delegate = self;
            [self.navigationController pushViewController:editWholesaleVC animated:YES];
        }
    }
}

#pragma mark - Table View Data Source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
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
        case 4:
            rowCount = _section4TableViewCell.count;
            break;
        default:
            break;
    }
    
    return rowCount;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ProductEditDetail *product = _form.product;
    
    UITableViewCell *cell = nil;
    switch (indexPath.section) {
        case 0:
            cell = _section0TableViewCell[indexPath.row];
            if (indexPath.row == BUTTON_PRODUCT_INSURANCE) {
                NSString *productMustInsurance =[ARRAY_PRODUCT_INSURACE[([product.product_must_insurance integerValue]>0)?[product.product_must_insurance integerValue]:0]objectForKey:DATA_NAME_KEY];
                cell.detailTextLabel.text = productMustInsurance;
            }
            if (indexPath.row == BUTTON_PRODUCT_RETURNABLE) {
                NSString *productReturnable =[ARRAY_PRODUCT_RETURNABLE[[_returnableStatus integerValue]]objectForKey:DATA_NAME_KEY];
                cell.detailTextLabel.text = productReturnable;
            }
            break;
        case 1:
            cell = _section1TableViewCell[indexPath.row];
            BOOL isProductWarehouse = [product.product_status isEqualToString:@"3"];
            if (indexPath.row == BUTTON_PRODUCT_ETALASE) {
                NSString *moveTo = (isProductWarehouse)?[ARRAY_PRODUCT_MOVETO_ETALASE[0]objectForKey:DATA_NAME_KEY]:[ARRAY_PRODUCT_MOVETO_ETALASE[1]objectForKey:DATA_NAME_KEY];
                cell.detailTextLabel.text = moveTo;
            }
            else if (indexPath.row == BUTTON_PRODUCT_ETALASE_DETAIL)
            {
                //cell.detailTextLabel.textColor = (isProductWarehouse)?[UIColor grayColor]:[UIColor colorWithRed:(0.f/255.f) green:122.f/255.f blue:255.f/255.f alpha:1];
                cell.detailTextLabel.text = ([product.product_etalase isEqualToString:@"0"]||!product.product_etalase)?@"Pilih Etalase":product.product_etalase;
            }
            break;
        case 2:
            cell = _section2TableViewCell[indexPath.row];
            if (indexPath.row==BUTTON_PRODUCT_CONDITION) {
                NSInteger productCondition = [product.product_condition integerValue];
                BOOL isNewProduct = (productCondition == PRODUCT_CONDITION_NEW_ID || productCondition == PRODUCT_CONDITION_NOTSET_ID)?YES:NO;
                NSString *productConditionName = isNewProduct?[ARRAY_PRODUCT_CONDITION[0] objectForKey:DATA_NAME_KEY]:[ARRAY_PRODUCT_CONDITION[1] objectForKey:DATA_NAME_KEY];
                cell.detailTextLabel.text = productConditionName;
            }
            break;
        case 3:
            cell = _section3TableViewCell[indexPath.row];
            break;
        case 4:
            cell = _section4TableViewCell[indexPath.row];
            break;
        default:
            break;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}


#pragma mark - Table View Delegate
-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return _section0FooterView;
    else if (section == 3)
        return _section3FooterView;
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return _section0FooterView.frame.size.height;
    else if(section == 3)
        return _section3FooterView.frame.size.height;
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float cellHeight = 0.0f;
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
        case 4:
            cellHeight = ((UITableViewCell*)_section4TableViewCell[indexPath.row]).frame.size.height;
            break;
        default:
            break;
    }
    return cellHeight;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_productDescriptionTextView resignFirstResponder];
    [_dataInput setObject:_productDescriptionTextView.text?:@"" forKey:API_PRODUCT_DESCRIPTION_KEY];
    ProductEditDetail *product = _form.product;
    BOOL isProductWarehouse = [product.product_status isEqualToString:@"3"];
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case BUTTON_PRODUCT_INSURANCE:
                {
                    AlertPickerView *alertView = [AlertPickerView newview];
                    alertView.tag = 10;
                    alertView.delegate = self;
                    alertView.pickerData = ARRAY_PRODUCT_INSURACE;
                    [alertView show];
                    break;
                }
                case BUTTON_PRODUCT_RETURNABLE:
                {
                    if (_form.info.shop_has_terms) {
                        AlertPickerView *alertView = [AlertPickerView newview];
                        alertView.tag = 13;
                        alertView.delegate = self;
                        alertView.pickerData = ARRAY_PRODUCT_RETURNABLE;
                        [alertView show];
                    }
                    break;
                }
            }
            break;
        case 1:
            switch (indexPath.row) {
                case BUTTON_PRODUCT_ETALASE:
                {
                    AlertPickerView *alertView = [AlertPickerView newview];
                    alertView.tag = 11;
                    alertView.delegate = self;
                    alertView.pickerData = ARRAY_PRODUCT_MOVETO_ETALASE;
                    [alertView show];
                    break;
                }
                case BUTTON_PRODUCT_ETALASE_DETAIL:
                {
                    //if (!isProductWarehouse) {
                        ProductEditDetail *product = _form.product;
                        EtalaseList *newEtalase = [EtalaseList new];
                        newEtalase.etalase_name = product.product_etalase;
                        newEtalase.etalase_id = product.product_etalase_id;
                        EtalaseViewController *etalaseViewController = [EtalaseViewController new];
                        etalaseViewController.isEditable = NO;
                        etalaseViewController.showOtherEtalase = NO;
                        etalaseViewController.shopId = [_userManager getShopId];
                        etalaseViewController.initialSelectedEtalase = newEtalase;
                        etalaseViewController.delegate = self;
                        [etalaseViewController setEnableAddEtalase:YES];
                        [self.navigationController pushViewController:etalaseViewController animated:YES];
                    //}
                    break;
                }
            }
            break;
        case 2:
            switch (indexPath.row) {
                case BUTTON_PRODUCT_CONDITION:
                {
                    AlertPickerView *alertView = [AlertPickerView newview];
                    alertView.tag = 12;
                    alertView.delegate = self;
                    alertView.pickerData = ARRAY_PRODUCT_CONDITION;
                    [alertView show];
                    break;
                }
                default:
                    break;
            }
            break;
        case 4:
            switch (indexPath.row) {
                case BUTTON_PRODUCT_EDIT_WHOLESALE:
                {
                    ProductEditWholesaleViewController *editWholesaleVC = [ProductEditWholesaleViewController new];
                    editWholesaleVC.data = @{kTKPD_AUTHKEY : [_data objectForKey:kTKPD_AUTHKEY],
                                             DATA_INPUT_KEY : _dataInput
                                             };
                    editWholesaleVC.delegate = self;
                    [self.navigationController pushViewController:editWholesaleVC animated:YES];
                }
                    break;
                    
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    [_productDescriptionTextView resignFirstResponder];
}

#pragma mark - Network Manager
-(id)getObjectManager:(int)tag
{
    if (tag == TAG_REQUEST_MOVE_TO) {
        return [self objectManagerMoveToWarehouse];
    }
    return nil;
}

-(NSDictionary *)getParameter:(int)tag
{
    if (tag == TAG_REQUEST_MOVE_TO) {
        return [self paramMoveToWarehouse];
    }
    return nil;
}

-(NSString *)getPath:(int)tag
{

    return kTKPDDETAILACTIONPRODUCT_APIPATH;
}

-(NSString *)getRequestStatus:(id)result withTag:(int)tag
{
    NSDictionary *resultDict = ((RKMappingResult*)result).dictionary;
    id stat = [resultDict objectForKey:@""];
    if (tag == TAG_REQUEST_MOVE_TO) {
        ShopSettings *setting = stat;
        return setting.status;
    }
    
    return nil;
}

-(void)actionBeforeRequest:(int)tag
{
    if (tag == TAG_REQUEST_MOVE_TO) {
    }
}

-(void)actionAfterRequest:(id)successResult withOperation:(RKObjectRequestOperation *)operation withTag:(int)tag
{
    if (tag == TAG_REQUEST_MOVE_TO) {
        [self requestSuccessActionMoveToWarehouse:successResult
                                    withOperation:operation];
        
    }
}

-(void)actionFailAfterRequest:(id)errorResult withTag:(int)tag
{
    NSError *error = (NSError*)errorResult;
    
    NSArray *errorMessage;
    if (error.code == -999) {
    }
    else
    {
        if(error.code == -1011) {
            errorMessage = @[@"Mohon maaf, terjadi kendala pada server"];
        } else if (error.code==-1009) {
            errorMessage = @[@"Tidak ada koneksi internet"];
        }  else {
            errorMessage = @[[error localizedDescription]];
        }
        
        StickyAlertView *alert = [[StickyAlertView alloc]initWithErrorMessages:errorMessage delegate:self];
        [alert show];
        
        [self performSelector:@selector(dismissViewController) withObject:self afterDelay:3.0];
    }

}

-(void)dismissViewController
{
    [_processingAlert dismissWithClickedButtonIndex:0 animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)actionAfterFailRequestMaxTries:(int)tag
{
    // UA
    [TPAnalytics trackScreenName:@"Add Product - Fail"];
    
    // GA
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker setAllowIDFACollection:YES];
    [tracker set:kGAIScreenName value:@"Add Product - Fail"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    if (tag == TAG_REQUEST_MOVE_TO) {
        
    }
}

-(void)showErrorAlert
{
    NSInteger type = _type;
    NSArray *errorString;
    if (type == TYPE_ADD_EDIT_PRODUCT_ADD) {
        errorString = [[NSArray alloc] initWithObjects:@"Gagal menambahkan produk. Mohon coba kembali.", nil];
    }
    if (type == TYPE_ADD_EDIT_PRODUCT_EDIT) {
        errorString = [[NSArray alloc] initWithObjects:@"Gagal mengubah produk. Mohon coba kembali.", nil];
    }
    if (type == TYPE_ADD_EDIT_PRODUCT_COPY) {
        errorString = [[NSArray alloc] initWithObjects:@"Gagal menyalin produk. Mohon coba kembali.", nil];
    }
    StickyAlertView *alert = [[StickyAlertView alloc]initWithErrorMessages:errorString delegate:self];
    [alert show];
}


#pragma mark Request Action MoveToWarehouse

-(RKObjectManager*)objectManagerMoveToWarehouse
{
    RKObjectManager *objectmanager = [RKObjectManager sharedClient];
    
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
    
    [objectmanager addResponseDescriptor:responseDescriptor];
    
    return objectmanager;
}

-(NSDictionary*)paramMoveToWarehouse
{
    ProductEditDetail *product = _form.product;
    
    NSDictionary* param = @{kTKPDDETAIL_APIACTIONKEY:ACTION_MOVE_TO_WAREHOUSE,
                            kTKPDDETAILPRODUCT_APIPRODUCTIDKEY : product.product_id?:@"",
                            };
    return param;
}


-(void)requestSuccessActionMoveToWarehouse:(id)object withOperation:(RKObjectRequestOperation *)operation
{
    NSDictionary *result = ((RKMappingResult*)object).dictionary;
    id stat = [result objectForKey:@""];
    ShopSettings *setting = stat;
    BOOL status = [setting.status isEqualToString:kTKPDREQUEST_OKSTATUS];
    
    if (status) {
        if(setting.message_error)
        {
            NSArray *array = setting.message_error?:[[NSArray alloc] initWithObjects:kTKPDMESSAGE_ERRORMESSAGEDEFAULTKEY, nil];
            StickyAlertView *alert = [[StickyAlertView alloc]initWithErrorMessages:array delegate:self];
            [alert show];
        }
        if (setting.result.is_success == 1) {
            NSArray *array = setting.message_status?:[[NSArray alloc] initWithObjects:kTKPDMESSAGE_SUCCESSMESSAGEDEFAULTKEY, nil];
            StickyAlertView *alert = [[StickyAlertView alloc]initWithSuccessMessages:array delegate:self];
            [alert show];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - TextView Delegate
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    [textView resignFirstResponder];
    _activeTextView = textView;
    
    return YES;
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if (textView == _productDescriptionTextView) {
        if(textView.text.length != 0 && ![textView.text isEqualToString:@""]){
            ProductEditDetail *product = _form.product;
            product.product_short_desc = textView.text;
        }
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
#define PRODUCT_DESCRIPTION_CHARACTER_LIMIT 2000
    return textView.text.length + (text.length - range.length) <= PRODUCT_DESCRIPTION_CHARACTER_LIMIT;
}



#pragma mark - Keyboard Notification
- (void)keyboardWillShow:(NSNotification *)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    _tableView.contentInset = contentInsets;
    _tableView.scrollIndicatorInsets = contentInsets;
    
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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

#pragma mark - Alertview Delegate
-(void)alertView:(TKPDAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
#define DEFAULT_ETALASE_DETAIL_TITLE_BUTTON @"Pilih Etalase"
    ProductEditDetail *product = _form.product?:[ProductEditDetail new];
    switch (alertView.tag) {
        case 10:
        {
            NSInteger index = [[alertView.data objectForKey:DATA_INDEX_KEY] integerValue];
            NSString *value = [[ARRAY_PRODUCT_INSURACE[index] objectForKey:DATA_VALUE_KEY] stringValue];
            product.product_must_insurance = value;
            [_tableView reloadData];
            break;
        }
        case 12:
        {
            NSInteger index = [[alertView.data objectForKey:DATA_INDEX_KEY] integerValue];
            NSString *value = [[ARRAY_PRODUCT_CONDITION[index] objectForKey:DATA_VALUE_KEY] stringValue];
            product.product_condition = value;
            [_tableView reloadData];
            break;
        }
        case 11:
        {
            NSInteger index = [[alertView.data objectForKey:DATA_INDEX_KEY] integerValue];
            NSString *value = [[ARRAY_PRODUCT_MOVETO_ETALASE[index] objectForKey:DATA_VALUE_KEY] stringValue];
            product.product_status = [value isEqualToString:@"1"] ? @"1" : @"3";
//            product.product_move_to = value;//([value integerValue]==1)?@"0":value;
            /*
            if (index == 0) {
                product.product_etalase_id = @(0);
                product.product_etalase = nil;
            }
             */
            [_tableView reloadData];
            break;
        }
        case 13:
        {
            NSInteger index = [[alertView.data objectForKey:DATA_INDEX_KEY] integerValue];
            NSString *value = [[ARRAY_PRODUCT_RETURNABLE[index] objectForKey:DATA_VALUE_KEY] stringValue];
            _returnableStatus = value;
            [_tableView reloadData];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Product Etalase Delegate

-(void)didSelectEtalase:(EtalaseList *)selectedEtalase{
    ProductEditDetail *product = _form.product;
    product.product_etalase_id = selectedEtalase.etalase_id;
    product.product_etalase = selectedEtalase.etalase_name;
    
    [_tableView reloadData];

}

#pragma mark - Product Wholesale View Controller Delegate
-(void)ProductEditWholesaleViewController:(ProductEditWholesaleViewController *)viewController withWholesaleList:(NSArray *)list
{
    [_dataInput setObject:list forKey:DATA_WHOLESALE_LIST_KEY];
}

#pragma mark - Methods
-(void)setShopHasTerm:(NSString *)shopHasTerm
{
    _form.info.shop_has_terms = shopHasTerm;
}

-(void)setDefaultData:(NSDictionary*)data
{
    _data = data;
    if (data) {
        
        [_dataInput addEntriesFromDictionary:[_data objectForKey:DATA_INPUT_KEY]];
        
        ProductEditDetail *product = _form.product;
        NSString *productReturnable = _returnableStatus?:@"";
        if ([productReturnable isEqualToString:@""] || [productReturnable isEqualToString:@"0"] || productReturnable == nil) {
            [_dataInput setObject:@(0) forKey:API_PRODUCT_IS_RETURNABLE_KEY];
            //[_dataInput setObject:@(-1) forKey:API_PRODUCT_IS_RETURNABLE_KEY];
        }
        BOOL isProductReturnable = ([productReturnable integerValue] == RETURNABLE_YES_ID)?YES:NO;
        _returnableProductSwitch.on = isProductReturnable;
        
        NSString *productDescription = [NSString convertHTML:product.product_short_desc]?:@"";
        productDescription = ([productDescription isEqualToString:@"0"])?@"":productDescription;
        _productDescriptionTextView.text = productDescription;
        
        NSArray *wholesaleList = [_dataInput objectForKey:DATA_WHOLESALE_LIST_KEY]?:@[];
        
        if ((_type == TYPE_ADD_EDIT_PRODUCT_EDIT || _type == TYPE_ADD_EDIT_PRODUCT_COPY) && [[wholesaleList firstObject] isKindOfClass:[WholesalePrice class]]) {
            for (WholesalePrice *wholesale in wholesaleList) {
                float price = [wholesale.wholesale_price floatValue];
                NSInteger minimumQuantity = [wholesale.wholesale_min integerValue];
                NSInteger maximumQuantity = [wholesale.wholesale_max integerValue];
                [self addWholesaleListPrice:price withQuantityMinimum:minimumQuantity andQuantityMaximum:maximumQuantity];
            }
            [_dataInput setObject:_wholesaleList forKey:DATA_WHOLESALE_LIST_KEY];
        }
        
        UserAuthentificationManager *auth = [UserAuthentificationManager new];
        NSString *shopHasTerm = [auth getShopHasTerm];
        _form.info.shop_has_terms = shopHasTerm;
        
        [_tableView reloadData];
    }
}

-(void)addWholesaleListPrice:(float)price withQuantityMinimum:(NSInteger)minimum andQuantityMaximum:(NSInteger)maximum
{
    NSInteger wholesaleListIndex = _wholesaleList.count+1;
    NSString *wholesalePriceKey = [NSString stringWithFormat:@"%@%zd",API_WHOLESALE_PRICE,wholesaleListIndex];
    NSString *wholesaleQuantityMaximum = [NSString stringWithFormat:@"%@%zd",API_WHOLESALE_QUANTITY_MAXIMUM_KEY,wholesaleListIndex];
    NSString *wholesaleQuantityMinimum = [NSString stringWithFormat:@"%@%zd",API_WHOLESALE_QUANTITY_MINIMUM_KEY,wholesaleListIndex];
    
    
    NSDictionary *wholesale = @{wholesalePriceKey:@(price),
                                wholesaleQuantityMaximum:@(maximum),
                                wholesaleQuantityMinimum:@(minimum)
                                };
    [_wholesaleList addObject:wholesale];
}

-(void)adjustBarButton
{
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(tap:)];
    barButtonItem.tag = BARBUTTON_PRODUCT_BACK;
    self.navigationItem.backBarButtonItem = barButtonItem;
    
    _saveBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Simpan"
                                                          style:UIBarButtonItemStyleDone
                                                         target:(self)
                                                         action:@selector(tap:)];
    _saveBarButtonItem.tag = BARBUTTON_PRODUCT_SAVE;
    self.navigationItem.rightBarButtonItem = _saveBarButtonItem;
}

-(void)adjustReturnableNotesLabel
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 6.0;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]  initWithString:_pengembalianProductLabel.text];
    [attributedString addAttribute:NSFontAttributeName value:FONT_GOTHAM_BOOK_10 range:[_pengembalianProductLabel.text rangeOfString:@"Klik Disini"]];
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1]
                             range:[_pengembalianProductLabel.text rangeOfString:@"Klik Disini"]];
    
    [attributedString addAttribute:NSParagraphStyleAttributeName
                             value:style
                             range:[_pengembalianProductLabel.text rangeOfString:_pengembalianProductLabel.text]];
    
    _pengembalianProductLabel.attributedText = attributedString;
}

-(void)didEditNote:(NSNotification*)notification
{
    [_delegate DidEditReturnableNote];
}

-(void)didUpdateShopHasTerms:(NSNotification*)notification
{
    UserAuthentificationManager *auth = [UserAuthentificationManager new];
    NSString *shopHasTerm = [auth getShopHasTerm];
    _form.info.shop_has_terms= shopHasTerm;
    
    [_tableView reloadData];
}

@end
