//
//  DepositFormViewController.m
//
//
//  Created by Tokopedia on 12/11/14.
//
//

#import "DepositFormViewController.h"
#import "DepositListBankViewController.h"
#import "GeneralAction.h"
#import "DepositForm.h"
#import "profile.h"

@interface DepositFormViewController () <UITableViewDataSource, UITableViewDelegate, DepositListBankViewControllerDelegate, UITextFieldDelegate> {
    NSString *_clearTotalAmount;
    
    __weak RKObjectManager *_objectManager;
    __weak RKManagedObjectRequestOperation *_request;
    NSOperationQueue *_operationQueue;
    NSInteger *_requestCount;
    
    __weak RKObjectManager *_objectDepositFormManager;
    __weak RKManagedObjectRequestOperation *_requestDepositForm;
    NSOperationQueue *_operationDepositFormQueue;
    NSInteger *_requestDepositFormCount;
    
    __weak RKObjectManager *_objectSendOTPManager;
    __weak RKManagedObjectRequestOperation *_requestSendOTP;
    NSOperationQueue *_operationSendOTPQueue;
    NSInteger *_requestSendOTPCount;
    
    NSTimer *_timer;
    
    UITextField *_activeTextField;
    
    CGPoint _keyboardPosition;
    CGSize _keyboardSize;
    
    CGRect _containerDefault;
    CGSize _scrollviewContentSize;
    
    //form value
    NSString *_bankAccountName;
    NSString *_bankAccountNumber;
    NSString *_bankAccountId;
    NSString *_isVerifiedAccount;
    
    NSString *_withdrawAmount;
    NSString *_password;
    NSString *_otpCode;
    NSString *_bankId;
    NSString *_bankName;
    NSString *_bankBranch;
    NSString *_useableSaldoStr;
    
    UIBarButtonItem *_barbuttonleft;
    UIBarButtonItem *_barbuttonright;
    
    NSMutableArray *_listBankAccount;

}

- (void)configureRestkit;
- (void)cancelCurrentAction;
- (void)loadData;
- (void)requestSuccess;
- (void)requestFail;
- (void)requestTimeout;

@property (strong, nonatomic) IBOutlet UILabel *useableSaldoIDR;
@property (strong, nonatomic) IBOutlet UILabel *useableSaldo;
@property (strong, nonatomic) IBOutlet UIButton *chooseAccountButton;
@property (strong, nonatomic) IBOutlet UIButton *kodeOTPButton;
@property (strong, nonatomic) IBOutlet UIButton *infoButton;
@property (strong, nonatomic) IBOutlet UITextField *totalAmount;
@property (strong, nonatomic) IBOutlet UITextField *tokopediaPassword;
@property (strong, nonatomic) IBOutlet UITextField *kodeOTP;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UIScrollView *containerScrollView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (strong, nonatomic) IBOutlet UIView *otpViewArea;
@property (strong, nonatomic) IBOutlet UIView *passwordViewArea;

@property (nonatomic, strong) NSDictionary *userinfo;
@property (nonatomic, strong) NSIndexPath *accountIndexPath;


@end

@implementation DepositFormViewController



#pragma mark - Initialization
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    self.title = @"Penarikan Dana";
    self.hidesBottomBarWhenPushed = YES;
    
    if (self) {
        
    }
    return self;
}

- (void)initBarButton {
    //NSBundle* bundle = [NSBundle mainBundle];
    
    _barbuttonleft = [[UIBarButtonItem alloc] initWithTitle:@"Batal" style:UIBarButtonItemStylePlain target:(self) action:@selector(tap:)];
    [_barbuttonleft setTintColor:[UIColor whiteColor]];
    [_barbuttonleft setTag:10];
    self.navigationItem.leftBarButtonItem = _barbuttonleft;
    
    _barbuttonright = [[UIBarButtonItem alloc] initWithTitle:@"Konfirmasi" style:UIBarButtonItemStylePlain target:(self) action:@selector(tap:)];
    [_barbuttonright setTintColor:[UIColor blackColor]];
    [_barbuttonright setTag:11];
    self.navigationItem.rightBarButtonItem = _barbuttonright;
}

- (void)initNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateSelectedDepositBank:)
                                                 name:@"updateSelectedDepositBank"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBankAccountFromForm:)
                                                 name:@"updateBankAccountFromForm"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    
}

#pragma mark - ViewController Life
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initBarButton];
    [self initNotificationCenter];
    
    _operationQueue = [NSOperationQueue new];
    _operationDepositFormQueue = [NSOperationQueue new];
    _operationSendOTPQueue = [NSOperationQueue new];
    _listBankAccount = [NSMutableArray new];
    
//    [_useableSaldoIDR setText:[_data objectForKey:@"summary_useable_deposit_idr"]];
    [self configureDepositInfo];
    [self loadDepositInfo];
    _useableSaldoStr = @"Loading..";
    _chooseAccountButton.enabled = NO;
    
    // Do any additional setup after loading the view from its nib.
}

-(void)viewDidLayoutSubviews
{
    _containerScrollView.contentSize = _contentView.frame.size;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

#pragma mark - Request Send OTP 
- (void)configureSendOTPRestkit {
    _objectSendOTPManager =  [RKObjectManager sharedClient];
    
    // setup object mappings
    RKObjectMapping *statusMapping = [RKObjectMapping mappingForClass:[GeneralAction class]];
    [statusMapping addAttributeMappingsFromDictionary:@{kTKPD_APISTATUSKEY:kTKPD_APISTATUSKEY,
                                                        kTKPD_APIERRORMESSAGEKEY:kTKPD_APIERRORMESSAGEKEY,
                                                        kTKPD_APISTATUSMESSAGEKEY:kTKPD_APISTATUSMESSAGEKEY,
                                                        kTKPD_APISERVERPROCESSTIMEKEY:kTKPD_APISERVERPROCESSTIMEKEY}];
    
    RKObjectMapping *resultMapping = [RKObjectMapping mappingForClass:[GeneralActionResult class]];
    [resultMapping addAttributeMappingsFromDictionary:@{kTKPD_APIISSUCCESSKEY:kTKPD_APIISSUCCESSKEY}];
    
    //relation
    RKRelationshipMapping *resulRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPD_APIRESULTKEY toKeyPath:kTKPD_APIRESULTKEY withMapping:resultMapping];
    [statusMapping addPropertyMapping:resulRel];
    
    //register mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptorStatus = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping method:RKRequestMethodGET pathPattern:@"action/deposit.pl" keyPath:@"" statusCodes:kTkpdIndexSetStatusCodeOK];
    
    [_objectSendOTPManager addResponseDescriptor:responseDescriptorStatus];
}

- (void)requestSendOTP {
    if(_requestSendOTP.isExecuting) return;
    
    _requestSendOTPCount++;
    NSDictionary *param = @{
                            @"action" : @"send_otp_verify_bank_account"
                            };
    
    NSTimer *timer;
    _requestSendOTP = [_objectSendOTPManager appropriateObjectRequestOperationWithObject:self method:RKRequestMethodPOST path:@"action/deposit.pl" parameters:[param encrypt]];
    
    [_requestSendOTP setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [self requestSuccessSendOTP:mappingResult withOperation:operation];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        [self requestFailSendOTP:error];
    }];
    
    [_operationSendOTPQueue addOperation:_requestSendOTP];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:kTKPDREQUEST_TIMEOUTINTERVAL target:self selector:@selector(requestTimeoutSendOTP) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)requestSuccessSendOTP:(id)object withOperation:(RKObjectRequestOperation*)operation {
    if (object) {
        if ([object isKindOfClass:[RKMappingResult class]]) {
            NSDictionary *result = ((RKMappingResult*)object).dictionary;
            id info = [result objectForKey:@""];
            GeneralAction *action = info;
            NSString *statusstring = action.status;
            BOOL status = [statusstring isEqualToString:kTKPDREQUEST_OKSTATUS];
            
            if (status) {
                if(action.message_error)
                {
                    NSArray *array = action.message_error?:[[NSArray alloc] initWithObjects:kTKPDMESSAGE_ERRORMESSAGEDEFAULTKEY, nil];
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:array,@"messages", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_SETUSERSTICKYERRORMESSAGEKEY object:nil userInfo:info];
                }
                if ([action.result.is_success isEqualToString:@"1"]) {
                    NSArray *array = action.message_status?:[[NSArray alloc] initWithObjects:kTKPDMESSAGE_SUCCESSMESSAGEDEFAULTKEY, nil];
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:array,@"messages", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_SETUSERSTICKYSUCCESSMESSAGEKEY object:nil userInfo:info];
                }
            }
        }
    }
    else
    {
        NSError *error = object;
        NSString *errorDescription = error.localizedDescription;
        UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:ERROR_TITLE message:errorDescription delegate:self cancelButtonTitle:ERROR_CANCEL_BUTTON_TITLE otherButtonTitles:nil];
        [errorAlert show];
    }
}

- (void)requestFailSendOTP:(id)error {
    
}

- (void)requestTimeoutSendOTP {
    
}

#pragma mark - Request Deposit Info
- (void)configureDepositInfo {
    _objectDepositFormManager = [RKObjectManager sharedClient];
    
    RKObjectMapping *statusMapping = [RKObjectMapping mappingForClass:[DepositForm class]];
    [statusMapping addAttributeMappingsFromDictionary:@{
                                                       kTKPD_APISTATUSKEY:kTKPD_APISTATUSKEY,
                                                       kTKPD_APIERRORMESSAGEKEY:kTKPD_APIERRORMESSAGEKEY,
                                                       kTKPD_APISTATUSMESSAGEKEY:kTKPD_APISTATUSMESSAGEKEY,
                                                       kTKPD_APISERVERPROCESSTIMEKEY:kTKPD_APISERVERPROCESSTIMEKEY}];
    
    RKObjectMapping *resultMapping = [RKObjectMapping mappingForClass:[DepositFormResult class]];
    [resultMapping addAttributeMappingsFromDictionary:@{
                                                       @"msisdn_verified" : @"msisdn_verified",
                                                       @"useable_deposit" : @"useable_deposit",
                                                       @"useable_deposit_idr" : @"useable_deposit_idr"
                                                       }];
    
    RKObjectMapping *bankAccountListMapping = [RKObjectMapping mappingForClass:[DepositFormBankAccountList class]];
    [bankAccountListMapping addAttributeMappingsFromArray:@[kTKPDPROFILESETTING_APIBANKIDKEY,
                                                           API_BANK_NAME_KEY,
                                                           API_BANK_ACCOUNT_NAME_KEY,
                                                           kTKPDPROFILESETTING_APIBANKACCOUNTNUMBERKEY,
                                                           kTKPDPROFILESETTING_APIBANKBRANCHKEY,
                                                           API_BANK_ACCOUNT_ID_KEY,
                                                           kTKPDPROFILESETTING_APIISDEFAULTBANKKEY,
                                                           kTKPDPROFILESETTING_APIISVERIFIEDBANKKEY
                                                           ]];
    
    [statusMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:kTKPD_APIRESULTKEY toKeyPath:kTKPD_APIRESULTKEY withMapping:resultMapping]];
    
    RKRelationshipMapping *listRel = [RKRelationshipMapping relationshipMappingFromKeyPath:@"bank_account" toKeyPath:@"bank_account" withMapping:bankAccountListMapping];
    [resultMapping addPropertyMapping:listRel];
    
    // register mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping method:RKRequestMethodPOST pathPattern:@"deposit.pl" keyPath:@"" statusCodes:kTkpdIndexSetStatusCodeOK];
    
    [_objectDepositFormManager addResponseDescriptor:responseDescriptor];
}


- (void)loadDepositInfo {
    if(_requestDepositForm.isExecuting) return;
    
    _requestDepositFormCount++;
    
    NSDictionary *param = @{
                            @"action" : @"get_withdraw_form"
                            };
    
    NSTimer *timer;
    _requestDepositForm = [_objectDepositFormManager appropriateObjectRequestOperationWithObject:self method:RKRequestMethodPOST path:@"deposit.pl" parameters:[param encrypt]];
    
    [_requestDepositForm setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [_indicator stopAnimating];
        [self requestDepositInfoSuccess:mappingResult withOperation:operation];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        [self requestDepositInfoFail:error];
    }];
    
    [_operationDepositFormQueue addOperation:_requestDepositForm];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:kTKPDREQUEST_TIMEOUTINTERVAL target:self selector:@selector(requestDepositInfoTimeout) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
}

- (void)requestDepositInfoSuccess:(id)object withOperation:(RKObjectRequestOperation *)operation {
    NSDictionary *result = ((RKMappingResult*)object).dictionary;
    id info = [result objectForKey:@""];
    DepositForm *depositForm = info;
    NSString *statusstring = depositForm.status;
    BOOL status = [statusstring isEqualToString:kTKPDREQUEST_OKSTATUS];
    
    if (status) {
        [self requestDepositInfoProceed:object];
    }
}

- (void)requestDepositInfoFail:(id)object {
    [self requestDepositInfoProceed:object];
}

- (void)requestDepositInfoProceed:(id)object {
    if (object) {
        if ([object isKindOfClass:[RKMappingResult class]]) {
            NSDictionary *result = ((RKMappingResult*)object).dictionary;
            id info = [result objectForKey:@""];
            DepositForm *depositForm = info;

            NSString *statusstring = depositForm.status;
            BOOL status = [statusstring isEqualToString:kTKPDREQUEST_OKSTATUS];
            
            if (status) {
                [_useableSaldoIDR setText:depositForm.result.useable_deposit_idr];
                _useableSaldoStr = depositForm.result.useable_deposit_idr;
                _chooseAccountButton.enabled = YES;
                [_listBankAccount addObjectsFromArray:depositForm.result.bank_account];
                NSString *verifiedState = depositForm.result.msisdn_verified;
                
                [_kodeOTPButton setTitle:[verifiedState isEqualToString:@"1"] ? @"Kirim OTP ke HP" : @"Kirim OTP ke Email"  forState:UIControlStateNormal];
            }
        }else{
            [self cancelRequestDepositInfo];
            NSLog(@" REQUEST FAILURE ERROR %@", [(NSError*)object description]);
            if ([(NSError*)object code] == NSURLErrorCancelled) {
                if (_requestDepositFormCount<kTKPDREQUESTCOUNTMAX) {

                    //[_act startAnimating];
                    [self performSelector:@selector(configureDepositInfo) withObject:nil afterDelay:kTKPDREQUEST_DELAYINTERVAL];
                    [self performSelector:@selector(loadDepositInfo) withObject:nil afterDelay:kTKPDREQUEST_DELAYINTERVAL];
                }
                else
                {
                    NSError *error = object;
                    NSString *errorDescription = error.localizedDescription;
                    UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:ERROR_TITLE message:errorDescription delegate:self cancelButtonTitle:ERROR_CANCEL_BUTTON_TITLE otherButtonTitles:nil];
                    [errorAlert show];
                }
            }
            else
            {
                NSError *error = object;
                NSString *errorDescription = error.localizedDescription;
                UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:ERROR_TITLE message:errorDescription delegate:self cancelButtonTitle:ERROR_CANCEL_BUTTON_TITLE otherButtonTitles:nil];
                [errorAlert show];
            }
        }
        
    }
}

- (void)requestDepositInfoTimeout {
    [self cancelRequestDepositInfo];
}

- (void)cancelRequestDepositInfo {
    [_requestDepositForm cancel];
    _requestDepositForm = nil;
    
    [_objectDepositFormManager.operationQueue cancelAllOperations];
    _objectDepositFormManager = nil;
}


#pragma mark - Request + Restkit Init
- (void)configureRestkit {
    _objectManager =  [RKObjectManager sharedClient];
    
    // setup object mappings
    RKObjectMapping *statusMapping = [RKObjectMapping mappingForClass:[GeneralAction class]];
    [statusMapping addAttributeMappingsFromDictionary:@{kTKPD_APISTATUSKEY:kTKPD_APISTATUSKEY,
                                                        kTKPD_APIERRORMESSAGEKEY:kTKPD_APIERRORMESSAGEKEY,
                                                        kTKPD_APISTATUSMESSAGEKEY:kTKPD_APISTATUSMESSAGEKEY,
                                                        kTKPD_APISERVERPROCESSTIMEKEY:kTKPD_APISERVERPROCESSTIMEKEY}];
    
    RKObjectMapping *resultMapping = [RKObjectMapping mappingForClass:[GeneralActionResult class]];
    [resultMapping addAttributeMappingsFromDictionary:@{kTKPD_APIISSUCCESSKEY:kTKPD_APIISSUCCESSKEY}];
    
    //relation
    RKRelationshipMapping *resulRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPD_APIRESULTKEY toKeyPath:kTKPD_APIRESULTKEY withMapping:resultMapping];
    [statusMapping addPropertyMapping:resulRel];

    //register mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptorStatus = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping method:RKRequestMethodGET pathPattern:@"action/deposit.pl" keyPath:@"" statusCodes:kTkpdIndexSetStatusCodeOK];
    
    [_objectManager addResponseDescriptor:responseDescriptorStatus];
}

- (void)disableButton {
    [_barbuttonleft setEnabled:NO];
    [_barbuttonright setEnabled:NO];
}

- (void)enableButton {
    [_barbuttonleft setEnabled:YES];
    [_barbuttonright setEnabled:YES];
}

- (void)loadData {
    if(_request.isExecuting) return;
    
    _requestCount++;
    
    NSDictionary *param = @{
                            @"action" : @"do_withdraw",
                            @"withdraw_amount" : _totalAmount.text?:@"0",
                            @"bank_account_id" : _bankAccountId?:@"0",
                            @"user_password" : _tokopediaPassword.text?:@"0",
                            @"bank_account_name" : _bankAccountName?:@"0",
                            @"otp_code" : _kodeOTP.text?:@"0",
                            @"bank_account_number" : _bankAccountNumber?:@"0",
                            @"bank_id" : _bankId?:@"0",
                            @"bank_name" : _bankName?:@"0",
                            @"bank_branch" : _bankBranch?:@"0"
                            };
    
    [self disableButton];
    _request = [_objectManager appropriateObjectRequestOperationWithObject:self method:RKRequestMethodPOST path:@"action/deposit.pl" parameters:[param encrypt]];
    
    [_request setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [self requestSuccess:mappingResult withOperation:operation];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
    }];
    
    [_operationQueue addOperation:_request];
    
    NSTimer *timer;
    timer = [NSTimer scheduledTimerWithTimeInterval:kTKPDREQUEST_TIMEOUTINTERVAL target:self selector:@selector(requestTimeout) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)requestSuccess:(id)object withOperation:operation {
    NSDictionary *result = ((RKMappingResult*)object).dictionary;
    id stats = [result objectForKey:@""];
    GeneralAction *action = stats;
    BOOL status = [action.status isEqualToString:kTKPDREQUEST_OKSTATUS];
    
    if (status) {
        [self requestProceed:object];
    }
}

- (void)requestProceed:(id)object {
    [self enableButton];
    
    if (object) {
        if ([object isKindOfClass:[RKMappingResult class]]) {
            NSDictionary *result = ((RKMappingResult*)object).dictionary;
            id stat = [result objectForKey:@""];
            GeneralAction *action = stat;
            BOOL status = [action.status isEqualToString:kTKPDREQUEST_OKSTATUS];
            
            if (status) {
                if (!action.message_error) {
                    if ([action.result.is_success isEqualToString:@"1"]) {
                        [self.navigationController popViewControllerAnimated:YES];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadListDeposit" object:nil userInfo:nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"removeButtonWithdraw" object:nil userInfo:nil];
                    }
                }
                if (action.message_status) {
                    NSArray *array = action.message_status;//[[NSArray alloc] initWithObjects:KTKPDMESSAGE_DELIVERED, nil];
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:array,@"messages", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_SETUSERSTICKYSUCCESSMESSAGEKEY object:nil userInfo:info];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"removeButtonWithdraw" object:nil userInfo:nil];
                }
                else if(action.message_error)
                {
                    NSArray *array = action.message_error;//[[NSArray alloc] initWithObjects:KTKPDMESSAGE_UNDELIVERED, nil];
                    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:array,@"messages", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_SETUSERSTICKYERRORMESSAGEKEY object:nil userInfo:info];
                }
                
            }
        }
        else{
            
            [self cancelCurrentAction];
            NSLog(@" REQUEST FAILURE ERROR %@", [(NSError*)object description]);
            if ([(NSError*)object code] == NSURLErrorCancelled) {
                if (_requestCount<kTKPDREQUESTCOUNTMAX) {

                    //TODO:: Reload handler
                }
                else
                {
                }
            }
            else
            {
            }
        }
    }
}

- (void)requestFail {
    
}

- (void)requestTimeout {
    
}

- (void)cancelCurrentAction {
    
}

#pragma mark - IBAction
-(IBAction)tap:(id)sender {
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UIBarButtonItem *barButton = (UIBarButtonItem *)sender;
        switch (barButton.tag) {
            case 10:
            {
                if (self.presentingViewController != nil) {
                    if (self.navigationController.viewControllers.count > 1) {
                        [self.navigationController popViewControllerAnimated:YES];
                    } else {
                        [self dismissViewControllerAnimated:YES completion:NULL];
                    }
                } else {
                    [self.navigationController popViewControllerAnimated:YES];
                }
                break;
            }
                
            case 11 : {
                if([self validateFormValue]) {
                    [self configureRestkit];
                    [self loadData];
                }
            }
                
            default:
                break;
        }
    }
    
    if([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *) sender;
        switch (button.tag) {
            case 10: {
                
                break;
            }
                
            case 11 : {
                DepositListBankViewController *depositListVc = [DepositListBankViewController new];
                depositListVc.data = @{@"account_indexpath" : _accountIndexPath?:[NSIndexPath indexPathForRow:0 inSection:0]};
                depositListVc.listBankAccount = _listBankAccount;
                [self.navigationController pushViewController:depositListVc animated:YES];
                break;
            }
                
            case 12 : {
                if(_requestDepositForm.isExecuting || _requestSendOTP.isExecuting) return;
                
                [self configureSendOTPRestkit];
                [self requestSendOTP];
                break;
            }
                
            case 13 : {

                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Info Saldo Tokopedia"
                                                                    message: @"Permintaan Tarik Dana akan diproses dalam waktu 1x24 jam hari kerja bank (tidak termasuk hari Sabtu/Minggu/Libur) \n\n Penarikan dana dengan tujuan nomor rekening di luar bank BCA/Mandiri/BNI/BRI, dana akan masuk dalam waktu maksimal 2x24 jam hari kerja bank (tidak termasuk hari Sabtu/Minggu/Libur) dan apabila ada biaya tambahan yang dibebankan akan menjadi tanggungan pengguna. \n\n Anda akan mendapatkan email konfirmasi ketika dana sudah kami transfer dan ketika dana sudah berhasil masuk ke rekening Anda."
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
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
}

#pragma mark - Memory Manage
- (void)dealloc {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Notification Action
- (void)updateSelectedDepositBank:(NSNotification*)notification {
    _userinfo = notification.userInfo;
    _accountIndexPath = [_userinfo objectForKey:@"indexpath"];
    
    _bankAccountId = [_userinfo objectForKey:@"bank_account_id"];
//    _isVerifiedAccount = [_userinfo objectForKey:@"is_verified_account"];
    
    if([[_userinfo objectForKey:@"is_verified_account"] integerValue] == 1) {
        _otpViewArea.hidden = YES;
        
        CGRect newFrame = _passwordViewArea.frame;
        newFrame.origin.y = 320;
        _passwordViewArea.frame = newFrame;
        
    } else {
        _otpViewArea.hidden = NO;
        
        CGRect newFrame = _passwordViewArea.frame;
        newFrame.origin.y = 420;
        _passwordViewArea.frame = newFrame;
    }
    
    [_chooseAccountButton setTitle:[_userinfo objectForKey:@"bank_account_name"] forState:UIControlStateNormal];
}

- (void)updateBankAccountFromForm:(NSNotification*)notification {
    _userinfo = notification.userInfo;
    
    NSString *bankName = [NSString stringWithFormat:@"%@ a/n %@ - %@", [_userinfo objectForKey:@"bank_account_number"], [_userinfo objectForKey:@"bank_account_name"], [_userinfo objectForKey:@"bank_name"]];
    
    _bankAccountName = [_userinfo objectForKey:@"bank_account_name"];
    _bankAccountNumber = [_userinfo objectForKey:@"bank_account_number"];
    _bankBranch = [_userinfo objectForKey:@"bank_branch"];
    _bankName = [_userinfo objectForKey:@"bank_name"];
    _bankId = [_userinfo objectForKey:@"bank_id"];
    _otpViewArea.hidden = NO;
    
    CGRect newFrame = _passwordViewArea.frame;
    newFrame.origin.y = 420;
    _passwordViewArea.frame = newFrame;
    
    [_chooseAccountButton setTitle:bankName forState:UIControlStateNormal];
}

- (void)keyboardWillShow:(NSNotification *)info {
    if(_keyboardSize.height < 0){
        _keyboardPosition = [[[info userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].origin;
        _keyboardSize= [[[info userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].size;
        
        
        _scrollviewContentSize = [_containerScrollView contentSize];
        _scrollviewContentSize.height += _keyboardSize.height;
        [_containerScrollView setContentSize:_scrollviewContentSize];
    }else{
        [UIView animateWithDuration:TKPD_FADEANIMATIONDURATION
                              delay:0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             _scrollviewContentSize = [_containerScrollView contentSize];
                             _scrollviewContentSize.height -= _keyboardSize.height;
                             
                             _keyboardPosition = [[[info userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].origin;
                             _keyboardSize= [[[info userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].size;
                             _scrollviewContentSize.height += _keyboardSize.height;
                             if ((_activeTextField.frame.origin.y+_activeTextField.frame.size.height)> _keyboardPosition.y) {
                                 UIEdgeInsets inset = _containerScrollView.contentInset;
                                 inset.top = (_keyboardPosition.y-(self.view.frame.origin.y + _activeTextField.frame.origin.y+_activeTextField.frame.size.height + 10));
                                 [_containerScrollView setContentInset:inset];
                             }
                         }
                         completion:^(BOOL finished){
                         }];
        
    }
}

- (void)keyboardWillHide:(NSNotification *)info {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    [UIView animateWithDuration:TKPD_FADEANIMATIONDURATION
                          delay:0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _containerScrollView.contentInset = contentInsets;
                         _containerScrollView.scrollIndicatorInsets = contentInsets;
                     }
                     completion:^(BOOL finished){
                     }];
}



#pragma mark - Validation Form
- (BOOL)validateFormValue {
    NSMutableArray *messages = [NSMutableArray new];
    if(
       ![_totalAmount.text isEqualToString:@""] &&
       ![_tokopediaPassword.text isEqualToString:@""] &&
       ![[_chooseAccountButton titleForState:UIControlStateNormal] isEqualToString:@"Pilih Bank"]
       ) {
        return YES;
    } else {
        if (!_totalAmount.text || [_totalAmount.text isEqualToString:@""]) {
            [messages addObject:@"Jumlah Penarikan harus diisi"];
        }
        
        if (!_tokopediaPassword.text || [_tokopediaPassword.text isEqualToString:@""]) {
            [messages addObject:@"Kata Sandi Tokopedia harus diisi"];
        }
        
        if ((!_kodeOTP.text || [_kodeOTP.text isEqualToString:@""]) && ([[_userinfo objectForKey:@"is_verified_account"] integerValue] == 0)) {
            [messages addObject:@"Kode OTP harus diisi"];
        }
        
        if ([[_chooseAccountButton titleForState:UIControlStateNormal] isEqualToString:@"Pilih Bank"]) {
            [messages addObject:@"Akun Bank harus diisi"];
        }
        
        
        
        NSString *string1 = [_totalAmount.text stringByReplacingOccurrencesOfString:@"," withString:@""];
        NSString *string2 = _useableSaldoStr;
        
        if([string1 integerValue] > [string2 integerValue]) {
            [messages addObject:@"Saldo Anda tidak mencukupi"];
        }
        
        NSArray *array = messages;
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:array,@"messages", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_SETUSERSTICKYERRORMESSAGEKEY object:nil userInfo:info];
        
        return NO;
    }
    
    
}

#pragma mark - Text Field Delegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    _activeTextField = textField;
    [textField resignFirstResponder];

    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];
    if(touch.phase == UITouchPhaseBegan) {
        [_totalAmount resignFirstResponder];
        [_tokopediaPassword resignFirstResponder];
        [_kodeOTP resignFirstResponder];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == _totalAmount) {

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
    return YES;
}



@end
