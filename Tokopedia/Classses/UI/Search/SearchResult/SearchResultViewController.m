//
//  SearchResultViewController.m
//  Tokopedia
//
//  Created by IT Tkpd on 8/28/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import "search.h"
#import "sortfiltershare.h"
#import "string_product.h"
#import "detail.h"

#import "SearchItem.h"
#import "SearchRedirect.h"
#import "List.h"
#import "Paging.h"
#import "DepartmentTree.h"

#import "DetailProductViewController.h"
#import "DetailCatalogViewController.h"

#import "GeneralProductCell.h"
#import "SearchResultViewController.h"
#import "SortViewController.h"
#import "FilterViewController.h"
#import "HotlistResultViewController.h"
#import "TKPDTabNavigationController.h"

#import "NoResult.h"

#import "URLCacheController.h"

#pragma mark - Search Result View Controller
@interface SearchResultViewController () <GeneralProductCellDelegate, TKPDTabNavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, SortViewControllerDelegate, FilterViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *table;
@property (strong, nonatomic) IBOutlet UIView *footer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *act;
@property (strong, nonatomic) NSMutableArray *product;
@property (weak, nonatomic) IBOutlet UIView *catalogproductview;
@property (weak, nonatomic) IBOutlet UIView *shopview;

//toolbar view without share button
@property (weak, nonatomic) IBOutlet UIView *toolbarView;

-(void)cancel;
-(void)configureRestKit;
-(void)request;
-(void)requestsuccess:(id)object withOperation:(RKObjectRequestOperation*)operation;
-(void)requestfailure:(id)object;
-(void)requestprocess:(id)object;
-(void)requesttimeout;

@end

@implementation SearchResultViewController
{
    NSInteger _page;
    NSInteger _limit;
    
    NSMutableArray *_urlarray;
    NSMutableDictionary *_params;
    
    NSString *_urinext;
    NSString *_uriredirect;
    
    BOOL _isnodata;
    BOOL _isrefreshview;
    
    UIRefreshControl *_refreshControl;
    NSInteger _requestcount;
    
    SearchItem *_searchitem;
    
    __weak RKObjectManager *_objectmanager;
    __weak RKManagedObjectRequestOperation *_request;
    NSOperationQueue *_operationQueue;
    
    NSString *_cachepath;
    URLCacheController *_cachecontroller;
    URLCacheConnection *_cacheconnection;
    NSTimeInterval _timeinterval;
}

#pragma mark - Initialization
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _isrefreshview = NO;
        _isnodata = YES;
        _requestcount = 0;
    }
    return self;
}

#pragma mark - Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
        
    _operationQueue = [NSOperationQueue new];
    _cacheconnection = [URLCacheConnection new];
    _cachecontroller = [URLCacheController new];
    
    /** create new **/
    _product = [NSMutableArray new];
    _urlarray = [NSMutableArray new];
    _params = [NSMutableDictionary new];
    
    /** set first page become 1 **/
    _page = 1;
    
    /** set max data per page request **/
    _limit = kTKPDSEARCH_LIMITPAGE;
    
    /** set table footer view (loading act) **/
    if (_product.count > 0) {
        _isnodata = NO;
    }
    
    if (_data) {
        [_params addEntriesFromDictionary:_data];
    }
    
    _table.tableFooterView = _footer;
    [_act startAnimating];
    
    /** adjust refresh control **/
    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:kTKPDREQUEST_REFRESHMESSAGE];
    [_refreshControl addTarget:self action:@selector(refreshView:)forControlEvents:UIControlEventValueChanged];
    [_table addSubview:_refreshControl];
    
    [_params setObject:[_data objectForKey:kTKPDSEARCH_APIDEPARTEMENTIDKEY]?:@"" forKey:kTKPDSEARCH_APIDEPARTEMENTIDKEY];
        _catalogproductview.hidden = YES;

    //cache
    NSString* path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:kTKPDSEARCH_CACHEFILEPATH];
    NSString *query =[_params objectForKey:kTKPDSEARCH_DATASEARCHKEY];
    NSString *deptid =[_params objectForKey:kTKPDSEARCH_APIDEPARTEMENTIDKEY];
    if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHPRODUCTKEY]) {
        _cachepath = [path stringByAppendingPathComponent:[NSString stringWithFormat:kTKPDSEARCHPRODUCT_APIRESPONSEFILEFORMAT,query?:deptid]];
    }else if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHCATALOGKEY]) {
         _cachepath = [path stringByAppendingPathComponent:[NSString stringWithFormat:kTKPDSEARCHCATALOG_APIRESPONSEFILEFORMAT,query?:deptid]];
    }
    _cachecontroller.filePath = _cachepath;
    _cachecontroller.URLCacheInterval = 86400.0;
	[_cachecontroller initCacheWithDocumentPath:path];
    
    if ([_data objectForKey:API_DEPARTMENT_ID_KEY]) {
        self.toolbarView.hidden = YES;
    }    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!_isrefreshview) {
        [self configureRestKit];
        if (_isnodata || (_urinext != NULL && ![_urinext isEqualToString:@"0"] && _urinext != 0)) {
            [self request];
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self cancel];
}

#pragma mark - Properties
-(void)setData:(NSDictionary *)data
{
    _data = data;
}

#pragma mark - Memory Management
-(void)dealloc{
    NSLog(@"%@ : %@",[self class], NSStringFromSelector(_cmd));
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (_isnodata) {
		cell.backgroundColor = [UIColor whiteColor];
	}
    
    NSInteger row = [self tableView:tableView numberOfRowsInSection:indexPath.section]-1;

	if (row == indexPath.row) {
		NSLog(@"%@", NSStringFromSelector(_cmd));
		
        if (_urinext != NULL && ![_urinext isEqualToString:@"0"] && _urinext !=0 ) {
            /** called if need to load next page **/
            [self request];
        }
        else{
            [_act stopAnimating];
            _table.tableFooterView = nil;
        }
	}
}

#pragma mark - Table View Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger count = (_product.count%2==0)?_product.count/2:_product.count/2+1;
#ifdef kTKPDSEARCHRESULT_NODATAENABLE
    return _isnodata?1:count;
#else
    return _isnodata?0:count;
#endif
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell* cell = nil;
    if (!_isnodata) {
        
        NSString *cellid = kTKPDGENERALPRODUCTCELL_IDENTIFIER;
		
		cell = (GeneralProductCell*)[tableView dequeueReusableCellWithIdentifier:cellid];
		if (cell == nil) {
			cell = [GeneralProductCell newcell];
			((GeneralProductCell*)cell).delegate = self;
		}
        
        if (_product.count > indexPath.row) {
            //reset cell
            [self reset:(GeneralProductCell*)cell];
            
            /** Flexible view count **/
            NSUInteger indexsegment = indexPath.row * 2;
            NSUInteger indexmax = indexsegment + 2;
            NSUInteger indexlimit = MIN(indexmax, _product.count);
            
            NSAssert(!(indexlimit > _product.count), @"producs out of bounds");
            
            for (int i = 0; (indexsegment + i) < indexlimit; i++) {
                List *list = [_product objectAtIndex:indexsegment + i];
                ((UIView*)((GeneralProductCell*)cell).viewcell[i]).hidden = NO;
                (((GeneralProductCell*)cell).indexpath) = indexPath;
                
                if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHPRODUCTKEY]) {
                    ((UIView*)((GeneralProductCell*)cell).viewcell[i]).hidden = NO;
                    ((UILabel*)((GeneralProductCell*)cell).labelprice[i]).text = list.product_price?:@"";
                    ((UILabel*)((GeneralProductCell*)cell).labeldescription[i]).text = list.product_name?:@"";
                    ((UILabel*)((GeneralProductCell*)cell).labelalbum[i]).text = list.shop_name?:@"";
                    
                    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:list.product_image] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTKPDREQUEST_TIMEOUTINTERVAL];
                    
                    UIImageView *thumb = (UIImageView*)((GeneralProductCell*)cell).thumb[i];
                    thumb.image = nil;
                    
                    UIActivityIndicatorView *act = (UIActivityIndicatorView*)((GeneralProductCell*)cell).act[i];
                    [act startAnimating];
                    
                    [thumb setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
                        //NSLOG(@"thumb: %@", thumb);
                        [thumb setImage:image animated:YES];
                        
                        [act stopAnimating];
#pragma clang diagnostic pop
                        
                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                        [act stopAnimating];
                        
                    }];
                    
                }else if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHCATALOGKEY]) {
                    ((UIView*)((GeneralProductCell*)cell).viewcell[i]).hidden = NO;
                    ((UILabel*)((GeneralProductCell*)cell).labelprice[i]).text = list.catalog_price?:@"";
                    ((UILabel*)((GeneralProductCell*)cell).labeldescription[i]).text = list.catalog_name?:@"";
                    ((UILabel*)((GeneralProductCell*)cell).labelalbum[i]).text = list.product_name?:@"";
                    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:list.catalog_image] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTKPDREQUEST_TIMEOUTINTERVAL];
                    //request.URL = url;
                    
                    UIImageView *thumb = (UIImageView*)((GeneralProductCell*)cell).thumb[i];
                    thumb.image = nil;
                    //thumb.hidden = YES;	//@prepareforreuse then @reset
                    
                    UIActivityIndicatorView *act = (UIActivityIndicatorView*)((GeneralProductCell*)cell).act[i];
                    [act startAnimating];
                    
                    NSLog(@"============================== START GET %@ IMAGE =====================", [_data objectForKey:kTKPDSEARCH_DATATYPE]);
                    [thumb setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
                        //NSLOG(@"thumb: %@", thumb);
                        [thumb setImage:image];
                        
                        [act stopAnimating];
                        
                        NSLog(@"============================== DONE GET %@ IMAGE =====================", [_data objectForKey:kTKPDSEARCH_DATATYPE]);
#pragma clang diagnostic pop
                        
                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                        [act stopAnimating];
                        NSLog(@"============================== DONE GET %@ IMAGE =====================", [_data objectForKey:kTKPDSEARCH_DATATYPE]);
                    }];
                }
            }
        }
	} else {
		static NSString *CellIdentifier = kTKPDSEARCH_STANDARDTABLEVIEWCELLIDENTIFIER;
		
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
		cell.textLabel.text = kTKPDSEARCH_NODATACELLTITLE;
		cell.detailTextLabel.text = kTKPDSEARCH_NODATACELLDESCS;
	}
	return cell;
}




#pragma mark - Request + Mapping
-(void)cancel
{
    [_request cancel];
    _request = nil;
    [_objectmanager.operationQueue cancelAllOperations];
    _objectmanager = nil;
}

- (void)configureRestKit
{
    // initialize RestKit
    _objectmanager =  [RKObjectManager sharedClient];
    
    // setup object mappings
    RKObjectMapping *statusMapping = [RKObjectMapping mappingForClass:[SearchItem class]];
    [statusMapping addAttributeMappingsFromDictionary:@{kTKPD_APISTATUSKEY:kTKPD_APISTATUSKEY,
                                                        kTKPD_APISERVERPROCESSTIMEKEY:kTKPD_APISERVERPROCESSTIMEKEY
                                                        }];
    
    RKObjectMapping *resultMapping = [RKObjectMapping mappingForClass:[SearchResult class]];
    [resultMapping addAttributeMappingsFromDictionary:@{kTKPDSEARCH_APIHASCATALOGKEY:kTKPDSEARCH_APIHASCATALOGKEY,
                                                        kTKPDSEARCH_APISEARCH_URLKEY:kTKPDSEARCH_APISEARCH_URLKEY,
                                                        kTKPDSEARCH_APIREDIRECTURLKEY:kTKPDSEARCH_APIREDIRECTURLKEY,
                                                        kTKPDSEARCH_APIDEPARTMENTIDKEY:kTKPDSEARCH_APIDEPARTMENTIDKEY
                                                        }];
    
    // searchs list mapping
    RKObjectMapping *listMapping = [RKObjectMapping mappingForClass:[List class]];
    [listMapping addAttributeMappingsFromArray:@[kTKPDSEARCH_APIPRODUCTIMAGEKEY,
                                                   kTKPDSEARCH_APIPRODUCTPRICEKEY,
                                                   kTKPDSEARCH_APIPRODUCTNAMEKEY,
                                                   kTKPDSEARCH_APIPRODUCTSHOPNAMEKEY,
                                                   kTKPDSEARCH_APICATALOGIMAGEKEY,
                                                   kTKPDSEARCH_APICATALOGNAMEKEY,
                                                   kTKPDSEARCH_APICATALOGPRICEKEY,
                                                   kTKPDSEARCH_APIPRODUCTIDKEY,
                                                   kTKPDSEARCH_APICATALOGIDKEY]];
    
    // paging mapping
    RKObjectMapping *pagingMapping = [RKObjectMapping mappingForClass:[Paging class]];
    [pagingMapping addAttributeMappingsFromDictionary:@{kTKPDSEARCH_APIURINEXTKEY:kTKPDSEARCH_APIURINEXTKEY}];
    
    RKObjectMapping *departmentMapping = [RKObjectMapping mappingForClass:[DepartmentTree class]];
    [departmentMapping addAttributeMappingsFromArray:@[kTKPDSEARCH_APIHREFKEY, kTKPDSEARCH_APITREEKEY, kTKPDSEARCH_APIDIDKEY, kTKPDSEARCH_APITITLEKEY,kTKPDSEARCH_APICHILDTREEKEY]];
    
    /** redirect mapping & hascatalog **/
    //RKObjectMapping *redirectMapping = [RKObjectMapping mappingForClass:[SearchRedirect class]];
    //[redirectMapping addAttributeMappingsFromDictionary: @{kTKPDSEARCH_APIREDIRECTURLKEY:kTKPDSEARCH_APIREDIRECTURLKEY,
    //                                                       kTKPDSEARCH_APIDEPARTEMENTIDKEY:kTKPDSEARCH_APIDEPARTEMENTIDKEY,
    //                                                       kTKPDSEARCH_APIHASCATALOGKEY:kTKPDSEARCH_APIHASCATALOGKEY}];

    //add list relationship
    [statusMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:kTKPD_APIRESULTKEY toKeyPath:kTKPD_APIRESULTKEY withMapping:resultMapping]];
    
    RKRelationshipMapping *listRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPDSEARCH_APILISTKEY toKeyPath:kTKPDSEARCH_APILISTKEY withMapping:listMapping];
    [resultMapping addPropertyMapping:listRel];
    
    // add page relationship
    RKRelationshipMapping *pageRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPDSEARCH_APIPAGINGKEY toKeyPath:kTKPDSEARCH_APIPAGINGKEY withMapping:pagingMapping];
    [resultMapping addPropertyMapping:pageRel];
    
    // register mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping
                                                                                            method:RKRequestMethodPOST
                                                                                       pathPattern:kTKPDSEARCH_APIPATH
                                                                                           keyPath:@""
                                                                                       statusCodes:kTkpdIndexSetStatusCodeOK];
    
    //add response description to object manager
    [_objectmanager addResponseDescriptor:responseDescriptor];
}


- (void)request
{
    if([_request isExecuting]) return;
    
    _requestcount ++;
    
    NSLog(@"========= Request Count : %zd ==============", _requestcount);
    
    NSString *query =[_params objectForKey:kTKPDSEARCH_DATASEARCHKEY]?:@"";
    NSString *type = [_params objectForKey:kTKPDSEARCH_DATATYPE]?:@"";
    NSString *deptid =[_params objectForKey:kTKPDSEARCH_APIDEPARTEMENTIDKEY]?:@"";
    BOOL isredirect = [[_params objectForKey:kTKPDSEARCH_DATAISREDIRECTKEY] boolValue];
    
    NSMutableDictionary* param = [NSMutableDictionary new];
    NSDictionary *paramDefault = @{
              kTKPDSEARCH_APIACTIONTYPEKEY    :   type?:@"",
              kTKPDSEARCH_APIPAGEKEY          :   @(_page),
              kTKPDSEARCH_APILIMITKEY         :   @(kTKPDSEARCH_LIMITPAGE),
              kTKPDSEARCH_APIORDERBYKEY       :   [_params objectForKey:kTKPDSEARCH_APIORDERBYKEY]?:@"",
              kTKPDSEARCH_APILOCATIONKEY      :   [_params objectForKey:kTKPDSEARCH_APILOCATIONKEY]?:@"",
              kTKPDSEARCH_APISHOPTYPEKEY      :   [_params objectForKey:kTKPDSEARCH_APISHOPTYPEKEY]?:@"",
              kTKPDSEARCH_APIPRICEMINKEY      :   [_params objectForKey:kTKPDSEARCH_APIPRICEMINKEY]?:@"",
              kTKPDSEARCH_APIPRICEMAXKEY      :   [_params objectForKey:kTKPDSEARCH_APIPRICEMAXKEY]?:@""
              };
    [param addEntriesFromDictionary:paramDefault];
    if (query != nil && ![query isEqualToString:@""] && !isredirect) {
        [param setObject:query forKey:kTKPDSEARCH_APIQUERYKEY];
    }
    else{
        [param setObject:deptid forKey:kTKPDSEARCH_APIDEPARTEMENTIDKEY];
    }    
    
    //[_cachecontroller getFileModificationDate];
	
    //_timeinterval = fabs([_cachecontroller.fileDate timeIntervalSinceNow]);

    //if (_timeinterval > _cachecontroller.URLCacheInterval || _page>1 || _isrefreshview) {
        
        if (!_isrefreshview) {
            _table.tableFooterView = _footer;
            [_act startAnimating];
        }

        _request = [_objectmanager appropriateObjectRequestOperationWithObject:self method:RKRequestMethodPOST path:kTKPDSEARCH_APIPATH parameters:[param encrypt]];
        
        NSTimer *timer;
        
        [_request setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            [self requestsuccess:mappingResult withOperation:operation];
            _isrefreshview = NO;
            [_refreshControl endRefreshing];
            [timer invalidate];
            
        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
            [self requestfailure:error];
            _isrefreshview = NO;
            [_refreshControl endRefreshing];
            [timer invalidate];
        }];
        
        [_operationQueue addOperation:_request];
        
        timer = [NSTimer scheduledTimerWithTimeInterval:kTKPDREQUEST_TIMEOUTINTERVAL
                                                  target:self
                                                selector:@selector(requesttimeout)
                                                userInfo:nil
                                                 repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    //}else {
    //    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    //    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    //    NSLog(@"Updated: %@",[dateFormatter stringFromDate:_cachecontroller.fileDate]);
    //    NSLog(@"cache and updated in last 24 hours.");
    //    [self requestfailure:nil];
    //}
}

-(void)requestsuccess:(id)object withOperation:(RKObjectRequestOperation *)operation
{
    NSDictionary *result = ((RKMappingResult*)object).dictionary;
    id stats = [result objectForKey:@""];
    _searchitem = stats;
    BOOL status = [_searchitem.status isEqualToString:kTKPDREQUEST_OKSTATUS];
    
    if (status) {
        //if (_page<=1 && !_isrefreshview) {
        //    [_cacheconnection connection:operation.HTTPRequestOperation.request didReceiveResponse:operation.HTTPRequestOperation.response];
        //    [_cachecontroller connectionDidFinish:_cacheconnection];
        //    //save response data to plist
        //    [operation.HTTPRequestOperation.responseData writeToFile:_cachepath atomically:YES];
        //}
        
        [self requestprocess:object];
    }
}

-(void)requestfailure:(id)object
{
    //if (_timeinterval > _cachecontroller.URLCacheInterval || _page>1 || _isrefreshview) {
        [self requestprocess:object];
    //}
    //else{
    //    NSError* error;
    //    NSData *data = [NSData dataWithContentsOfFile:_cachepath];
    //    id parsedData = [RKMIMETypeSerialization objectFromData:data MIMEType:RKMIMETypeJSON error:&error];
    //    if (parsedData == nil && error) {
    //        NSLog(@"parser error");
    //    }
    //    
    //    NSMutableDictionary *mappingsDictionary = [[NSMutableDictionary alloc] init];
    //    for (RKResponseDescriptor *descriptor in _objectmanager.responseDescriptors) {
    //        [mappingsDictionary setObject:descriptor.mapping forKey:descriptor.keyPath];
    //    }
    //    
    //    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:parsedData mappingsDictionary:mappingsDictionary];
    //    NSError *mappingError = nil;
    //    BOOL isMapped = [mapper execute:&mappingError];
    //    if (isMapped && !mappingError) {
    //        RKMappingResult *mappingresult = [mapper mappingResult];
    //        NSDictionary *result = mappingresult.dictionary;
    //        id stats = [result objectForKey:@""];
    //        _searchitem = stats;
    //        BOOL status = [_searchitem.status isEqualToString:kTKPDREQUEST_OKSTATUS];
    //        
    //        if (status) {
    //            [self requestprocess:mappingresult];
    //        }
    //    }
    //}
}

-(void)requestprocess:(id)object
{
    if (object) {
        if ([object isKindOfClass:[RKMappingResult class]]) {
            
            NSDictionary *result = ((RKMappingResult*)object).dictionary;
            
            _searchitem = [result objectForKey: @""];
            
            NSString *statusstring = _searchitem.status;
            BOOL status = [statusstring isEqualToString:kTKPDREQUEST_OKSTATUS];
            
            if (status) {
                
                NSString *uriredirect = _searchitem.result.redirect_url;
                //NSString *uriredirect = _searchitem.result.redirect_url.redirect_url;
                NSString *hascatalog = _searchitem.result.has_catalog;
                
                if (uriredirect == nil) {
                    //setting is this product has catalog or not
                    if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHPRODUCTKEY]) {
                        if ([hascatalog isEqualToString:@"1"] && hascatalog) {
                            NSDictionary *userInfo = @{@"count":@(3)};
                            [[NSNotificationCenter defaultCenter] postNotificationName: kTKPD_SEARCHSEGMENTCONTROLPOSTNOTIFICATIONNAMEKEY object:nil userInfo:userInfo];
                        }
                        else if ([hascatalog isEqualToString:@"0"] && hascatalog){
                            NSDictionary *userInfo = @{@"count":@(2)};
                            [[NSNotificationCenter defaultCenter] postNotificationName: kTKPD_SEARCHSEGMENTCONTROLPOSTNOTIFICATIONNAMEKEY object:nil userInfo:userInfo];
                        }
                    }
                    if (_page == 1) {
                        [_product removeAllObjects];
                    }
                    [_product addObjectsFromArray: _searchitem.result.list];
                    
                    if (_product.count == 0) {
                        [_act stopAnimating];
                        NoResult *noResultView = [[NoResult alloc]initWithFrame:CGRectMake(0, 0, 320, 100)];
                        _table.tableFooterView = noResultView;
                    }
                    
                    if (_product.count >0) {
                        _urinext = _searchitem.result.paging.uri_next;
                        
                        NSURL *url = [NSURL URLWithString:_urinext];
                        NSArray* query = [[url query] componentsSeparatedByString: @"&"];
                        
                        NSMutableDictionary *queries = [NSMutableDictionary new];
                        [queries removeAllObjects];
                        for (NSString *keyValuePair in query)
                        {
                            NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
                            NSString *key = [pairComponents objectAtIndex:0];
                            NSString *value = [pairComponents objectAtIndex:1];
                            
                            [queries setObject:value forKey:key];
                        }
                        
                        _page = [[queries objectForKey:kTKPDSEARCH_APIPAGEKEY] integerValue];
                        
                        NSLog(@"next page : %zd",_page);
                        _isnodata = NO;
                        [_table reloadData];
                    }
                    
                }
                else{
                    _uriredirect =  uriredirect;
                    NSURL *url = [NSURL URLWithString:_uriredirect];
                    NSArray* query = [[url path] componentsSeparatedByString: @"/"];
                    
                    // Redirect URI to hotlist
                    if ([query[1] isEqualToString:kTKPDSEARCH_DATAURLREDIRECTHOTKEY]) {
                        HotlistResultViewController *vc = [HotlistResultViewController new];
                        vc.data = @{kTKPDSEARCH_DATAISSEARCHHOTLISTKEY : @(YES), kTKPDSEARCHHOTLIST_APIQUERYKEY : query[2]};
                        [self.navigationController pushViewController:vc animated:NO];
                    }
                    // redirect uri to search category
                    if ([query[1] isEqualToString:kTKPDSEARCH_DATAURLREDIRECTCATEGORY]) {
                        NSString *departementID = _searchitem.result.department_id;
                        //NSString *deptid = _searchitem.result.redirect_url.department_id;
                        [_params setObject:departementID forKey:kTKPDSEARCH_APIDEPARTEMENTIDKEY];
                        [_params setObject:@(YES) forKey:kTKPDSEARCH_DATAISREDIRECTKEY];
                        [self cancel];
                        _table.tableFooterView = _footer;
                        [_act startAnimating];
                        
                        [self performSelector:@selector(configureRestKit) withObject:nil afterDelay:kTKPDREQUEST_DELAYINTERVAL];
                        [self performSelector:@selector(request) withObject:nil afterDelay:kTKPDREQUEST_DELAYINTERVAL];
                    }
                }
                _catalogproductview.hidden = NO;
            }
        }else{
            [self cancel];
            NSLog(@" REQUEST FAILURE ERROR %@", [(NSError*)object description]);
            if ([(NSError*)object code] == NSURLErrorCancelled) {
                if (_requestcount<kTKPDREQUESTCOUNTMAX) {
                    NSLog(@" ==== REQUESTCOUNT %zd =====",_requestcount);
                    _table.tableFooterView = _footer;
                    [_act startAnimating];
                    [self performSelector:@selector(configureRestKit) withObject:nil afterDelay:kTKPDREQUEST_DELAYINTERVAL];
                    [self performSelector:@selector(request) withObject:nil afterDelay:kTKPDREQUEST_DELAYINTERVAL];
                }
                else
                {
                    [_act stopAnimating];
                    _table.tableFooterView = nil;
                }
            }
            else
            {
                [_act stopAnimating];
                _table.tableFooterView = nil;
            }
        }
    }
}

-(void)requesttimeout
{
    [self cancel];
}


#pragma mark - Cell Delegate
-(void)GeneralProductCell:(UITableViewCell *)cell withindexpath:(NSIndexPath *)indexpath
{
    if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHPRODUCTKEY]){
        // Go to product detail
        DetailProductViewController *vc = [DetailProductViewController new];
        NSInteger index = indexpath.section+2*(indexpath.row);
        List *list = _product[index];
        vc.data = @{kTKPDDETAIL_APIPRODUCTIDKEY : list.product_id?:@(0),
                    kTKPD_AUTHKEY:[_data objectForKey:kTKPD_AUTHKEY]?:@{}};
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHCATALOGKEY])
    {
        // Go to catalog detail
        DetailCatalogViewController *vc = [DetailCatalogViewController new];
        NSInteger index = indexpath.section+2*(indexpath.row);
        List *list = _product[index];
        vc.data = @{kTKPDDETAIL_APICATALOGIDKEY : list.catalog_id?:@(0),
                    kTKPD_AUTHKEY:[_data objectForKey:kTKPD_AUTHKEY]?:@{}};
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - TKPDTabNavigationController Tap Button Notification
-(IBAction)tap:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch (button.tag) {
        case 10:
        {
            NSIndexPath *indexpath = [_params objectForKey:kTKPDFILTERSORT_DATAINDEXPATHKEY]?:[NSIndexPath indexPathForRow:0 inSection:0];
            // Action Urutkan Button
            SortViewController *vc = [SortViewController new]; 
            if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHPRODUCTKEY])
                vc.data = @{kTKPDFILTER_DATAFILTERTYPEVIEWKEY:@(kTKPDFILTER_DATATYPEPRODUCTVIEWKEY),
                            kTKPDFILTER_DATAINDEXPATHKEY: indexpath?:0};
            else
                vc.data = @{kTKPDFILTER_DATAFILTERTYPEVIEWKEY:@(kTKPDFILTER_DATATYPECATALOGVIEWKEY),
                            kTKPDFILTER_DATAINDEXPATHKEY: indexpath?:0};
            vc.delegate = self;
            UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 0);
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(iOS7_0)) {
                [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
            }
            UIImage *screenshotImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            vc.screenshotImage = screenshotImage;
            
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:vc];
            [self.navigationController presentViewController:nav animated:YES completion:nil];
            break;
        }
        case 11:
        {
            // Action Filter Button
            FilterViewController *vc = [FilterViewController new];
            if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHPRODUCTKEY])
                vc.data = @{kTKPDFILTER_DATAFILTERTYPEVIEWKEY:@(kTKPDFILTER_DATATYPEPRODUCTVIEWKEY),
                            kTKPDFILTER_DATAFILTERKEY: _params
                            };
            else
                vc.data = @{kTKPDFILTER_DATAFILTERTYPEVIEWKEY:@(kTKPDFILTER_DATATYPECATALOGVIEWKEY),
                            kTKPDFILTER_DATAFILTERKEY: _params};
            vc.delegate = self;
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:vc];
            [self.navigationController presentViewController:nav animated:YES completion:nil];
            break;
        }
        case 12:
        {
            NSString *shareText = @"";
            if ([_data objectForKey:kTKPDSEARCH_APIDEPARTEMENTTITLEKEY]) {
                shareText = [_data objectForKey:kTKPDSEARCH_APIDEPARTEMENTTITLEKEY];
            } else if ([_data objectForKey:kTKPDSEARCH_DATASEARCHKEY]) {
                shareText = [[_data objectForKey:kTKPDSEARCH_DATASEARCHKEY] capitalizedString];
            }
            NSString *activityItem = [NSString stringWithFormat:@"Jual %@ | Tokopedia %@", shareText, _searchitem.result.search_url?:@"www.tokopedia.com"];
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[activityItem,]
                                                                                             applicationActivities:nil];
            activityController.excludedActivityTypes = @[UIActivityTypeMail, UIActivityTypeMessage];
            [self presentViewController:activityController animated:YES completion:nil];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Methods
-(void)reset:(GeneralProductCell*)cell
{
    [cell.thumb makeObjectsPerformSelector:@selector(setImage:) withObject:nil];
    [cell.labelprice makeObjectsPerformSelector:@selector(setText:) withObject:nil];
    [cell.labelalbum makeObjectsPerformSelector:@selector(setText:) withObject:nil];
    [cell.labeldescription makeObjectsPerformSelector:@selector(setText:) withObject:nil];
    [cell.viewcell makeObjectsPerformSelector:@selector(setHidden:) withObject:@(YES)];
}

-(void)refreshView:(UIRefreshControl*)refresh
{
    [self cancel];
    _page = 1;
    _isrefreshview = YES;
    _requestcount = 0;
    
    [_table reloadData];
    [self configureRestKit];
    [self request];
}

#pragma mark - Filter Delegate
-(void)FilterViewController:(FilterViewController *)viewController withUserInfo:(NSDictionary *)userInfo
{
    [_params addEntriesFromDictionary:userInfo];
    [self refreshView:nil];
    _table.tableFooterView = _footer;
    [_act startAnimating];
}

#pragma mark - Sort Delegate
-(void)SortViewController:(SortViewController *)viewController withUserInfo:(NSDictionary *)userInfo
{
    [_params addEntriesFromDictionary:userInfo];
    [self refreshView:nil];
    _table.tableFooterView = _footer;
    [_act startAnimating];
}
@end
