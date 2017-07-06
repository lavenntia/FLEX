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

#import "SearchAWS.h"
#import "SearchAWSProduct.h"
#import "SearchAWSResult.h"

#import "SearchItem.h"
#import "SearchRedirect.h"
#import "List.h"
@class Paging;
#import "DepartmentTree.h"

#import "DetailProductViewController.h"
#import "CatalogViewController.h"

#import "SearchResultViewController.h"
#import "SortViewController.h"
#import "FilterViewController.h"
#import "HotlistResultViewController.h"

#import "TokopediaNetworkManager.h"
#import "LoadingView.h"
#import "NSString+MD5.h"
#import "URLCacheController.h"

#import "ProductCell.h"
#import "ProductSingleViewCell.h"
#import "ProductThumbCell.h"

#import "NavigateViewController.h"

#import "PromoCollectionReusableView.h"

#import "UIActivityViewController+Extensions.h"
#import "NoResultReusableView.h"
#import "SpellCheckRequest.h"
#import "Tokopedia-Swift.h"

#import "ImageSearchResponse.h"
#import "TKPDTabNavigationController.h"

#pragma mark - Search Result View Controller

typedef NS_ENUM(NSInteger, UITableViewCellType) {
    UITableViewCellTypeOneColumn,
    UITableViewCellTypeTwoColumn,
    UITableViewCellTypeThreeColumn,
};

typedef enum ScrollDirection {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
} ScrollDirection;

static NSString *const startPerPage = @"12";

@interface SearchResultViewController ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
SortViewControllerDelegate,
FilterViewControllerDelegate,
PromoCollectionViewDelegate,
NoResultDelegate,
SpellCheckRequestDelegate,
ProductCellDelegate
>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *act;

@property (strong, nonatomic) NSMutableArray *product;
@property (strong, nonatomic) NSMutableArray<NSArray<PromoResult*>*> *promo;
@property (strong, nonatomic) NSMutableDictionary *similarityDictionary;

@property (nonatomic) UITableViewCellType cellType;

@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UIView *firstFooter;
@property (weak, nonatomic) IBOutlet UIButton *changeGridButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

@property (strong, nonatomic) TopAdsService *topAdsService;
@property PromoCollectionViewCellType promoCellType;
@property (strong, nonatomic) NSMutableArray *promoScrollPosition;

@property (assign, nonatomic) CGFloat lastContentOffset;
@property ScrollDirection scrollDirection;
@property (strong, nonatomic) SpellCheckRequest *spellCheckRequest;

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *activeSortImageViews;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *activeFilterImageViews;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *imageSearchToolbarButtons;
@property (weak, nonatomic) IBOutlet UIButton *tryAgainButton;

@end

@implementation SearchResultViewController {
    NSInteger _start;
    NSInteger _limit;
    
    NSMutableDictionary *_params;
    NSString *_urinext;
    
    
    UIRefreshControl *_refreshControl;
    SearchProductWrapper *_searchObject;
    
    __weak RKObjectManager *_objectmanager;
    TokopediaNetworkManager *_networkManager;
    NSOperationQueue *_operationQueue;
    
    UserAuthentificationManager *_userManager;
    TAGContainer *_gtmContainer;
    NoResultReusableView *_noResultView;
    
    NSString *_searchBaseUrl;
    NSString *_searchPostUrl;
    NSString *_searchFullUrl;
    NSString *_suggestion;
    
    NSString *_strImageSearchResult;
    NSInteger allProductsCount;
    
    BOOL _isFailRequest;
    
    NSIndexPath *_sortIndexPath;
    NSArray *_initialBreadcrumb;
    
    FilterData *_filterResponse;
    NSArray<ListOption*> *_selectedFilters;
    NSDictionary *_selectedFilterParam;
    ListOption *_selectedSort;
    NSDictionary *_selectedSortParam;
    NSArray<CategoryDetail*> *_selectedCategories;
    
    NSString *_rootCategoryID;
    
    NSString *_defaultSearchCategory;
    ProductAndWishlistNetworkManager *moyaNetworkManager;
}

#pragma mark - Initialization
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _params = [NSMutableDictionary new];
    }
    return self;
}

- (void)initNoResultView{
    _noResultView = [[NoResultReusableView alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    [_noResultView generateAllElements:@"no-result.png"
                                 title:@"Oops... hasil pencarian Anda tidak dapat ditemukan."
                                  desc:@"Silahkan lakukan pencarian dengan kata kunci / filter lain"
                               btnTitle:@""];
    [_noResultView hideButton:YES];
    _noResultView.delegate = self;
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    _userManager = [UserAuthentificationManager new];
    _product = [NSMutableArray new];
    _promo = [NSMutableArray new];
    _promoScrollPosition = [NSMutableArray new];
    _similarityDictionary = [NSMutableDictionary new];
    _defaultSearchCategory = [_data objectForKey:kTKPDSEARCH_DATASEARCHKEY]?:[_params objectForKey:@"department_name"];
    _start = 0;
    
    [self initNoResultView];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:kTKPDREQUEST_REFRESHMESSAGE]];
    [_refreshControl addTarget:self action:@selector(refreshView:)forControlEvents:UIControlEventValueChanged];
    [_collectionView addSubview:_refreshControl];
    
    CGFloat headerHeight = [PromoCollectionReusableView collectionViewHeightForType:_promoCellType];
    [_flowLayout setHeaderReferenceSize:CGSizeMake([[UIScreen mainScreen]bounds].size.width, headerHeight)];
    [_flowLayout setFooterReferenceSize:CGSizeMake([[UIScreen mainScreen]bounds].size.width, 50)];
//    [_flowLayout setSectionInset:UIEdgeInsetsMake(10, 10, 10, 10)];
    
    [_collectionView setCollectionViewLayout:_flowLayout];
    [_collectionView setAlwaysBounceVertical:YES];
    [_collectionView setDelegate:self];
    [_collectionView setDataSource:self];
    [_firstFooter setFrame:CGRectMake(0, 0, _flowLayout.footerReferenceSize.width, 50)];
    [_collectionView addSubview:_firstFooter];
    
//    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    
    if ([[_data objectForKey:@"type"] isEqualToString:@"search_product"]||[[_data objectForKey:@"type"] isEqualToString:[self directoryType]]) {
        if(self.isFromAutoComplete) {
            [AnalyticsManager trackScreenName:@"Product Search Results (From Auto Complete Search)" gridType:self.cellType];
        } else {
            [AnalyticsManager trackScreenName:@"Product Search Results" gridType:self.cellType];
        }
    }
    else if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHCATALOGKEY]) {
        [AnalyticsManager trackScreenName:@"Catalog Search Results"];
    }
    
    if ([_data objectForKey:API_DEPARTMENT_ID_KEY]) {
        self.toolbarView.hidden = YES;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeCategory:)
                                                 name:kTKPD_DEPARTMENTIDPOSTNOTIFICATIONNAMEKEY
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddedProductToWishList:) name:@"didAddedProductToWishList" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemovedProductFromWishList:) name:@"didRemovedProductFromWishList" object:nil];
    
    NSDictionary *data = [[TKPDSecureStorage standardKeyChains] keychainDictionary];
    if ([data objectForKey:USER_LAYOUT_PREFERENCES]) {
        self.cellType = [[data objectForKey:USER_LAYOUT_PREFERENCES] integerValue];
        if (self.cellType == UITableViewCellTypeOneColumn) {
            [self.changeGridButton setImage:[UIImage imageNamed:@"icon_grid_dua.png"]
                                   forState:UIControlStateNormal];
            self.promoCellType = PromoCollectionViewCellTypeNormal;
            
        } else if (self.cellType == UITableViewCellTypeTwoColumn) {
            [self.changeGridButton setImage:[UIImage imageNamed:@"icon_grid_tiga.png"]
                                   forState:UIControlStateNormal];
            self.promoCellType = PromoCollectionViewCellTypeNormal;
            
        } else if (self.cellType == UITableViewCellTypeThreeColumn) {
            [self.changeGridButton setImage:[UIImage imageNamed:@"icon_grid_satu.png"]
                                   forState:UIControlStateNormal];
            self.promoCellType = PromoCollectionViewCellTypeThumbnail;
            
        }
    } else {
        self.cellType = UITableViewCellTypeTwoColumn;
        self.promoCellType = PromoCollectionViewCellTypeNormal;
        [self.changeGridButton setImage:[UIImage imageNamed:@"icon_grid_tiga.png"]
                               forState:UIControlStateNormal];
    }
    
    [_flowLayout setEstimatedSizeWithCellType:self.cellType];
    UINib *cellNib = [UINib nibWithNibName:@"ProductCell" bundle:nil];
    [_collectionView registerNib:cellNib forCellWithReuseIdentifier:@"ProductCellIdentifier"];
    
    UINib *singleCellNib = [UINib nibWithNibName:@"ProductSingleViewCell" bundle:nil];
    [_collectionView registerNib:singleCellNib forCellWithReuseIdentifier:@"ProductSingleViewIdentifier"];
    
    UINib *thumbCellNib = [UINib nibWithNibName:@"ProductThumbCell" bundle:nil];
    [_collectionView registerNib:thumbCellNib forCellWithReuseIdentifier:@"ProductThumbCellIdentifier"];
    
    UINib *footerNib = [UINib nibWithNibName:@"FooterCollectionReusableView" bundle:nil];
    [_collectionView registerNib:footerNib forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView"];
    
    UINib *retryNib = [UINib nibWithNibName:@"RetryCollectionReusableView" bundle:nil];
    [_collectionView registerNib:retryNib forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"RetryView"];
    
    UINib *promoNib = [UINib nibWithNibName:@"PromoCollectionReusableView" bundle:nil];
    [_collectionView registerNib:promoNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PromoCollectionReusableView"];
    
    [self configureGTM];
    
    _topAdsService = [TopAdsService new];
    self.scrollDirection = ScrollDirectionDown;
    
    _networkManager = [TokopediaNetworkManager new];
    _networkManager.isUsingHmac = YES;
    moyaNetworkManager = [[ProductAndWishlistNetworkManager alloc]init];
    
    if(_isFromImageSearch){
        [_fourButtonsToolbar setHidden:YES];
        [_threeButtonsToolbar setHidden:NO];
        [_fourButtonsToolbar setUserInteractionEnabled:NO];
        [_threeButtonsToolbar setUserInteractionEnabled:YES];
    } else{
        [self requestSearch];
        
        [_fourButtonsToolbar setHidden:NO];
        [_threeButtonsToolbar setHidden:YES];
        [_fourButtonsToolbar setUserInteractionEnabled:YES];
        [_threeButtonsToolbar setUserInteractionEnabled:NO];
    }
    
    _spellCheckRequest = [SpellCheckRequest new];
    _spellCheckRequest.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWishlist) name:TKPDUserDidLoginNotification object:nil];
}

-(NSString*)getSearchSource{
    return [_data objectForKey:@"type"]?:@"";
}

-(NSString*)searchProductSource{
    return @"search_product";
}

-(NSString*)searchCatalogSource{
    return @"search_catalog";
}

-(void)setDefaultSort{
    if ([_params objectForKey:@"search"] != nil) {

        if ([[self getSearchSource] isEqualToString:[self searchProductSource]]) {
            [self setDefaultSortProduct];
        }
        if ([[self getSearchSource] isEqualToString:[self searchCatalogSource]]) {
            [self setDefaultSortCatalog];
        }
        if ([[self getSearchSource] isEqualToString:[self directoryType]]) {
            [self setDefaultSortDirectory];
        }
    }
}

-(void)setDefaultSortDirectory{
    [_params setObject:[self defaultSortDirectoryID] forKey:[self defaultSortDirectoryKey]];
    _selectedSort = [self defaultSortDirectory];
    _selectedSortParam = @{[self defaultSortDirectoryKey]:[self defaultSortDirectoryID]};
}

-(ListOption*)defaultSortDirectory{
    ListOption *sort = [ListOption new];
    sort.value = [self defaultSortDirectoryID];
    sort.key = [self defaultSortDirectoryKey];
    return sort;
}

-(NSString*)defaultSortDirectoryKey{
    return @"ob";
}

-(NSString*)defaultSortDirectoryID{
    return @"23";
}

-(void)setDefaultSortCatalog{
    [_params setObject:[self defaultSortCatalogID] forKey:[self defaultSortCatalogKey]];
    _selectedSort = [self defaultSortCatalog];
    _selectedSortParam = @{[self defaultSortCatalogKey]:[self defaultSortCatalogID]};
}

-(ListOption*)defaultSortCatalog{
    ListOption *sort = [ListOption new];
    sort.value = [self defaultSortCatalogID];
    sort.key = [self defaultSortCatalogKey];
    return sort;
}

-(NSString*)defaultSortCatalogKey{
    return @"ob";
}

-(NSString*)defaultSortCatalogID{
    return @"1";
}

-(void)setDefaultSortProduct{
    [_params setObject:[self defaultSortProductID] forKey:[self defaultSortProductKey]];
    _selectedSort = [self defaultSortProduct];
    _selectedSortParam = @{[self defaultSortProductKey]:[self defaultSortProductID]};
}

-(ListOption*)defaultSortProduct{
    ListOption *sort = [ListOption new];
    sort.value = [self defaultSortProductID];
    sort.key = [self defaultSortProductKey];
    return sort;
}

-(NSString*)defaultSortProductKey{
    return @"ob";
}

-(NSString*)defaultSortProductID{
    return @"23";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _suggestion = @"";
    [_collectionView reloadData];
}

- (void) viewDidAppear:(BOOL)animated {
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_networkManager requestCancel];
}

#pragma mark - Properties
- (void)setData:(NSDictionary *)data {
    _data = data;
    
    if (_data) {
        [_params addEntriesFromDictionary:_data];
        [_params removeObjectForKey:@"default_sc"];
        [_params setObject:data[@"search"]?:@"" forKey:@"q"];
        _rootCategoryID = data[@"sc"]?:@"";
        [self adjustSelectedFilterFromData:_params];
        [self adjustSelectedSortFromData:_params];
        [self setDefaultSort];
    }
}

-(void)adjustSelectedFilterFromData:(NSDictionary*)data{
    NSMutableArray *selectedFilters = [NSMutableArray new];
    for (NSString *key in [data allKeys]) {
        if ([[data objectForKey:key] isKindOfClass:[NSDictionary class]] || [[data objectForKey:key] isKindOfClass:[NSArray class]]) {
            break;
        }
        if (![key isEqualToString:@"sc"]) {
            ListOption *filter = [ListOption new];
            filter.key = key;
            filter.value = [data objectForKey:key]?:@"";
            if ([key isEqualToString:@"pmax"] || [key isEqualToString:@"pmin"]) {
                filter.input_type = [self filterTextInputType];
            }
            [selectedFilters addObject:filter];
        }
    }
    _selectedFilters = [selectedFilters copy];
    _selectedFilterParam = data;
}

-(NSString *)filterTextInputType{
    return @"textbox";
}

-(void)adjustSelectedSortFromData:(NSDictionary*)data{
    ListOption *sort = [ListOption new];
    sort.key = [self defaultSortProductKey];
    sort.value = [data objectForKey:@"ob"]?:@"";
    _selectedSort = sort;
    _selectedSortParam = @{[self defaultSortProductKey]:[data objectForKey:@"ob"]?:@""};
    
}

#pragma mark - Memory Management
- (void)dealloc{
    NSLog(@"%@ : %@",[self class], NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_networkManager requestCancel];
    _networkManager = nil;
}

#pragma mark - Collection Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _product.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return ([[_product objectAtIndex:section] count] != 0)?[[_product objectAtIndex:section] count]:0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellid;
    UICollectionViewCell *cell = nil;
    
    SearchProduct *list = [[_product objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];;
    if (self.cellType == UITableViewCellTypeOneColumn) {
        cellid = @"ProductSingleViewIdentifier";
        cell = (ProductSingleViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:cellid forIndexPath:indexPath];
        
        if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHCATALOGKEY]) {
            [(ProductSingleViewCell*)cell setCatalogViewModel:list.catalogViewModel];
            ((ProductSingleViewCell*)cell).infoContraint.constant = 0;
        }
        else {
            [(ProductSingleViewCell*)cell setViewModel:list.viewModel];
            ((ProductSingleViewCell*)cell).infoContraint.constant = 19;
        }
    } else if (self.cellType == UITableViewCellTypeTwoColumn) {
        cellid = @"ProductCellIdentifier";
        cell = (ProductCell*)[collectionView dequeueReusableCellWithReuseIdentifier:cellid forIndexPath:indexPath];
        ((ProductCell*) cell).parentViewController = self;
        if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHCATALOGKEY]) {
            [(ProductCell*)cell setCatalogViewModel:list.catalogViewModel];
        } else {
            [(ProductCell*)cell setViewModel:list.viewModel];
        }
        ((ProductCell*) cell).parentViewController = self;
        ((ProductCell*) cell).delegate = self;
        
    } else {
        cellid = @"ProductThumbCellIdentifier";
        cell = (ProductThumbCell*)[collectionView dequeueReusableCellWithReuseIdentifier:cellid forIndexPath:indexPath];
        if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHCATALOGKEY]) {
            [(ProductThumbCell*)cell setCatalogViewModel:list.catalogViewModel];
        } else {
            [(ProductThumbCell*)cell setViewModel:list.viewModel];
        }
    }
    
    //next page if already last cell
    
    NSInteger section = [self numberOfSectionsInCollectionView:collectionView] - 1;
    NSInteger row = [self collectionView:collectionView numberOfItemsInSection:indexPath.section] - 1;
    if (indexPath.section == section && indexPath.row == row) {
        if (_urinext != NULL && ![_urinext isEqualToString:@"0"] && _urinext != 0 && ![_urinext isEqualToString:@""]) {
            _isFailRequest = NO;

            [self requestSearch];
        }
    }
    
    return cell;
}

- (UICollectionReusableView*)collectionView:(UICollectionView*)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        if (([[_data objectForKey:@"type"] isEqualToString:@"search_product"]||[[_data objectForKey:@"type"] isEqualToString:[self directoryType]]) &&
            _promo.count > indexPath.section) {
            
            NSArray *currentPromo = [_promo objectAtIndex:indexPath.section];
//            if(_promoCellType == PromoCollectionViewCellTypeThumbnail){
//                if(indexPath.section % 2 == 0){
//                    if (currentPromo && currentPromo.count > 0) {
//                        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PromoCollectionReusableView"
//                                                                                 forIndexPath:indexPath];
//                        NSMutableArray<PromoResult*> *combinedPromoResults = [NSMutableArray arrayWithArray:[_promo objectAtIndex:indexPath.section]];
//                        if(_promo.count > indexPath.section){
//                            [combinedPromoResults addObjectsFromArray:[_promo objectAtIndex:indexPath.section+1]];
//                        }
//                        ((PromoCollectionReusableView *)reusableView).collectionViewCellType = _promoCellType;
//                        ((PromoCollectionReusableView *)reusableView).promo = combinedPromoResults;
//                        ((PromoCollectionReusableView *)reusableView).delegate = self;
//                        ((PromoCollectionReusableView *)reusableView).indexPath = indexPath;
//                        if (self.scrollDirection == ScrollDirectionDown && indexPath.section == 1) {
//                            [((PromoCollectionReusableView *)reusableView) scrollToCenter];
//                        }
//                    }
//                }
//            }else{
                if (currentPromo && currentPromo.count > 0) {
                    reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PromoCollectionReusableView"
                                                                             forIndexPath:indexPath];
                    ((PromoCollectionReusableView *)reusableView).collectionViewCellType = _promoCellType;
                    ((PromoCollectionReusableView *)reusableView).promo = [_promo objectAtIndex:indexPath.section];
                    ((PromoCollectionReusableView *)reusableView).delegate = self;
                    ((PromoCollectionReusableView *)reusableView).indexPath = indexPath;
                    
                }
//            }
        } else {
            reusableView = nil;
        }
    }
    else if(kind == UICollectionElementKindSectionFooter) {
        if(_isFailRequest) {
            reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                              withReuseIdentifier:@"RetryView"
                                                                     forIndexPath:indexPath];
        } else {
            reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                              withReuseIdentifier:@"FooterView"
                                                                     forIndexPath:indexPath];
        }
    }
    return reusableView;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    SearchProduct *product = [[_product objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHCATALOGKEY]) {
        [AnalyticsManager trackEventName:@"clickKatalog" category:@"Katalog" action:GA_EVENT_ACTION_CLICK label:product.catalog_name];
        CatalogViewController *vc = [CatalogViewController new];
        vc.catalogID = product.catalog_id;
        vc.catalogName = product.catalog_name;
        vc.catalogPrice = product.catalog_price;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [AnalyticsManager trackProductClick:product];
        if (_isFromImageSearch) {
            [NavigateViewController navigateToProductFromViewController:self
                                                          withProductID:product.product_id
                                                                andName:product.product_name
                                                               andPrice:product.product_price
                                                            andImageURL:product.product_image
                                                            andShopName:nil];
        } else {
            [NavigateViewController navigateToProductFromViewController:self
                                                          withProductID:product.product_id
                                                                andName:product.product_name
                                                               andPrice:product.product_price
                                                            andImageURL:product.product_image
                                                            andShopName:product.shop_name];
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [ProductCellSize sizeWithType:self.cellType];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGSize size = CGSizeZero;
    if ([[_data objectForKey:@"type"] isEqualToString:@"search_product"]||[[_data objectForKey:@"type"] isEqualToString:[self directoryType]]) {
        if (_promo.count > section) {
            NSArray *currentPromo = [_promo objectAtIndex:section];
            
//            if(_promoCellType == PromoCollectionViewCellTypeThumbnail){
//                if(section % 2 == 0){
//                    if (currentPromo && currentPromo.count > 0) {
//                        CGFloat headerHeight = [PromoCollectionReusableView collectionViewHeightForType:_promoCellType];
//                        size = CGSizeMake(self.view.frame.size.width, headerHeight);
//                    }
//                }
//            }else{
                if (currentPromo && currentPromo.count > 0) {
                    CGFloat headerHeight = [PromoCollectionReusableView collectionViewHeightForType:_promoCellType];
                    size = CGSizeMake(self.view.frame.size.width, headerHeight);
                }
//            }
        }
    }
    return size;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    CGSize size = CGSizeZero;
    NSInteger lastSection = [self numberOfSectionsInCollectionView:collectionView] - 1;
    if (section == lastSection) {
        if (_urinext != NULL && ![_urinext isEqualToString:@"0"] && _urinext != 0 && ![_urinext isEqualToString:@""]) {
            size = CGSizeMake(self.view.frame.size.width, 50);
        }
    } else if (_product.count == 0 && _start == 0) {
        size = CGSizeMake(self.view.frame.size.width, 50);
    }
    return size;
}

#pragma mark - Methods

-(void)refreshView:(UIRefreshControl*)refresh {
    _start = 0;
    _urinext = nil;
    
    [_refreshControl beginRefreshing];
    [_collectionView setContentOffset:CGPointMake(0, -_refreshControl.frame.size.height) animated:YES];
    
    [self requestSearch];
    
    [_act startAnimating];
}

-(IBAction)tap:(id)sender { 
    UIButton *button = (UIButton *)sender;
    switch (button.tag) {
        case 10:
        {
            [self didTapSortButton:sender];
            break;
        }
        case 11:
        {
            [self didTapFilterButton:sender];
            break;
        }
        case 12:
        {
            NSString *title = @"";
            if ([_data objectForKey:kTKPDSEARCH_APIDEPARTEMENTTITLEKEY]) {
                title = [_data objectForKey:kTKPDSEARCH_APIDEPARTEMENTTITLEKEY];
            } else if ([_data objectForKey:kTKPDSEARCH_APIDEPARTMENTNAMEKEY]) {
                title = [_data objectForKey:kTKPDSEARCH_APIDEPARTMENTNAMEKEY];
            } else if ([_data objectForKey:kTKPDSEARCH_DATASEARCHKEY]) {
                title = [_data objectForKey:kTKPDSEARCH_DATASEARCHKEY];
            }else if ([_data objectForKey:kTKPDSEARCH_APIDEPARTMENT_1]){
                title = [_data objectForKey:kTKPDSEARCH_APIDEPARTMENT_1];
            }
            
            title = [[NSString stringWithFormat:@"Jual %@ | Tokopedia", title] capitalizedString];
            NSURL *url = [NSURL URLWithString: _searchObject.data.shareUrl?:@"www.tokopedia.com"];
            UIActivityViewController *controller = [UIActivityViewController shareDialogWithTitle:title
                                                                                              url:url
                                                                                           anchor:button];
            
            [self presentViewController:controller animated:YES completion:nil];
            break;
        }
        case 13:
        {
            TKPDSecureStorage* secureStorage = [TKPDSecureStorage standardKeyChains];
            
            if (self.cellType == UITableViewCellTypeOneColumn) {
                self.cellType = UITableViewCellTypeTwoColumn;
                self.promoCellType = PromoCollectionViewCellTypeNormal;
                [self.changeGridButton setImage:[UIImage imageNamed:@"icon_grid_tiga.png"]
                                       forState:UIControlStateNormal];
                
            } else if (self.cellType == UITableViewCellTypeTwoColumn) {
                self.cellType = UITableViewCellTypeThreeColumn;
                self.promoCellType = PromoCollectionViewCellTypeThumbnail;
                [self.changeGridButton setImage:[UIImage imageNamed:@"icon_grid_satu.png"]
                                       forState:UIControlStateNormal];
                
            } else if (self.cellType == UITableViewCellTypeThreeColumn) {
                self.cellType = UITableViewCellTypeOneColumn;
                self.promoCellType = PromoCollectionViewCellTypeNormal;
                [self.changeGridButton setImage:[UIImage imageNamed:@"icon_grid_dua.png"]
                                       forState:UIControlStateNormal];
            }
            
            _collectionView.contentOffset = CGPointMake(0, 0);
            [_flowLayout setEstimatedSizeWithCellType:self.cellType];
            [_collectionView reloadData];
            [_collectionView layoutIfNeeded];
            
            NSNumber *cellType = [NSNumber numberWithInteger:self.cellType];
            [secureStorage setKeychainWithValue:cellType withKey:USER_LAYOUT_PREFERENCES];
            
            break;
        }
        default:
            break;
    }
}

- (IBAction)didTapTryAgainButton:(UIButton *)sender {
    [_tryAgainButton setHidden:YES];
    [_act setHidden:NO];
}

#pragma mark - Filter Delegate
-(void)FilterViewController:(FilterViewController *)viewController withUserInfo:(NSDictionary *)userInfo {
    [_params addEntriesFromDictionary:userInfo];
    [self refreshView:nil];
}

#pragma mark - Sort Delegate
- (void)didSelectSort:(NSString *)sort atIndexPath:(NSIndexPath *)indexPath {
    [_params setObject:sort forKey:@"ob"];
    
    if([[_params objectForKey:@"ob"] isEqualToString:@"99"]){
        [self restoreSimilarity];
        //image search sort by similarity
        NSArray* sortedProducts = [[_product firstObject] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            CGFloat first = (CGFloat)[[(SearchAWSProduct*)a similarity_rank] floatValue];
            CGFloat second = (CGFloat)[[(SearchAWSProduct*)b similarity_rank] floatValue];
            return first > second;
        }];
        _product[0] = [NSMutableArray arrayWithArray:sortedProducts];
        _sortIndexPath = indexPath;
        [_refreshControl beginRefreshing];
        [_collectionView setContentOffset:CGPointMake(0, -_refreshControl.frame.size.height) animated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [_refreshControl endRefreshing];
            [_collectionView reloadData];
        });
    } else {
        //normal sort
        [self refreshView:nil];
        _sortIndexPath = indexPath;
    }
    
}

#pragma mark - Category notification
- (void)changeCategory:(NSNotification *)notification {
    [_params setObject:[notification.userInfo objectForKey:@"department_id"]?:@"" forKey:@"sc"];
    [_params setObject:[notification.userInfo objectForKey:@"department_name"]?:@"" forKey:@"department_name"];
    [_params setObject:[_data objectForKey:@"search"]?:@"" forKey:@"search"];
    
    [self refreshView:nil];
}

- (void)didAddedProductToWishList:(NSNotification*)notification {
    if (![notification object] || [notification object] == nil) {
        return;
    }
    
    NSString *productId = [notification object];
    for(NSArray* products in _product) {
        for(SearchProduct *product in products) {
            if([product.product_id isEqualToString:productId]) {
                product.isOnWishlist = YES;
                break;
            }
        }
    }
}

- (void)didRemovedProductFromWishList:(NSNotification*)notification {
    if (![notification object] || [notification object] == nil) {
        return;
    }
    
    NSString *productId = [notification object];
    for(NSArray* products in _product) {
        for(SearchProduct *product in products) {
            if([product.product_id isEqualToString:productId]) {
                product.isOnWishlist = NO;
                break;
            }
        }
    }
}

-(void)searchWithDynamicSort{
    FiltersController *controller = [[FiltersController alloc]initWithSource:[self getSourceSearchData]
                                                                sortResponse:_filterResponse?:[FilterData new]
                                                                selectedSort:_selectedSort
                                                                 presentedVC:self
                                                              rootCategoryID:_rootCategoryID
                                                                onCompletion:^(ListOption * sort, NSDictionary*paramSort) {
                                                                    
                                                                    [_params removeObjectForKey:@"ob"];
                                                                    _selectedSortParam = paramSort;
                                                                    _selectedSort = sort;
                                                                    
                                                                    [self showSortingIsActive:[self getSortingIsActive]];
                                                                    
                                                                    [self refreshSearchDataWithDynamicSort];
                                                                    
                                                                } onReceivedFilterDataOption:^(FilterData * filterResponse) {
                                                                    _filterResponse = filterResponse;
                                                                }];
}

-(void)refreshSearchDataWithDynamicSort{
    if([[_selectedSortParam objectForKey:@"ob"] isEqualToString:@"99"]){
        [self restoreSimilarity];
        //image search sort by similarity
        NSArray* sortedProducts = [[_product firstObject] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            CGFloat first = (CGFloat)[[(SearchAWSProduct*)a similarity_rank] floatValue];
            CGFloat second = (CGFloat)[[(SearchAWSProduct*)b similarity_rank] floatValue];
            return first > second;
        }];
        _product[0] = [NSMutableArray arrayWithArray:sortedProducts];
        [_refreshControl beginRefreshing];
        [_collectionView setContentOffset:CGPointMake(0, -_refreshControl.frame.size.height) animated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [_refreshControl endRefreshing];
            [_collectionView reloadData];
        });
    } else {
        //normal sort
        [self refreshView:nil];
    }
}

-(BOOL)getSortingIsActive{
    return (_selectedSort != nil);
}

-(void)showSortingIsActive:(BOOL)isActive{
    for (UIImageView *image in _activeSortImageViews) {
        image.hidden = !isActive;
    }
}

- (IBAction)didTapSortButton:(UIButton*)sender {
    [self searchWithDynamicSort];
}

-(IBAction)didTapFilterButton:(UIButton*)sender{
    [self searchWithDynamicFilter];
}

-(Source)getSourceSearchData{
    if (_isFromDirectory) {
        return SourceDirectory;
    }
    
    NSString * type = [_data objectForKey:kTKPDSEARCH_DATATYPE]?:@"";
    if ([type isEqualToString:@"hot_product"]) {
        return SourceHotlist;
    } else if ([type isEqualToString:@"search_product"]) {
        return SourceProduct;
    } else if ([type isEqualToString:@"search_catalog"]) {
        return SourceCatalog;
    } else if ([type isEqualToString:@"search_shop"]) {
        return SourceShop;
    } else if ([type isEqualToString:@"directory"]) {
        return SourceDirectory;
    } else {
        return SourceDefault;
    }
}

-(void)searchWithDynamicFilter{
    FiltersController *controller = [[FiltersController alloc]initWithSearchDataSource:[self getSourceSearchData]
                                                                        filterResponse:_filterResponse?:[FilterData new]
                                                                        rootCategoryID:_rootCategoryID
                                                                            categories:[_initialBreadcrumb copy]
                                                                    selectedCategories:_selectedCategories
                                                                       selectedFilters:_selectedFilters
                                                                           presentedVC:self onCompletion:^(NSArray<CategoryDetail *> * selectedCategories , NSArray<ListOption *> * selectedFilters, NSDictionary* paramFilters) {
                                                                               
           _selectedCategories = selectedCategories;
           if(_selectedCategories.count == 0) {
               _rootCategoryID = @"";
           }
                                                                               
          // if search result is category result, then if filter is being added, change the navigation title
          for (ListFilter *filter in _filterResponse.filter){
              if ([filter.title  isEqual: @"Kategori"]){
                  if (filter.isMultipleSelect == NO) {
                      if (selectedCategories.count > 0) {
                          [self.tkpdTabNavigationController setNavigationTitle: [selectedCategories objectAtIndex: 0].name];
                      } else {
                          [self.tkpdTabNavigationController setNavigationTitle: _defaultSearchCategory];
                      }
                  }
              }
          }
                                                                               
           _selectedFilters = selectedFilters;
           _selectedFilterParam = paramFilters;
           [self showFilterIsActive:[self hasSelectedFilterOrCategory]];
           [_params removeObjectForKey:@"sc"];

           [self refreshView:nil];
           
       } onReceivedFilterDataOption:^(FilterData * filterDataOption){
           
           _filterResponse = filterDataOption;
           
       }];
}

-(BOOL)hasSelectedFilterOrCategory {
    return (_selectedCategories.count + _selectedFilters.count > 0);
}

-(void)showFilterIsActive:(BOOL)isActive{
    for (UIImageView *image in _activeFilterImageViews) {
        image.hidden = !isActive;
    }
}

#pragma mark - LoadingView Delegate
- (IBAction)pressRetryButton:(id)sender {
    [self requestSearch];
    _isFailRequest = NO;
    [_collectionView reloadData];
}

#pragma mark - TokopediaNetworkManager Delegate
- (NSDictionary*)getParameter {
    return [self parameterDynamicFilter];
}

-(NSDictionary*)parameterDynamicFilter{
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc]init];
    [parameter setObject:@"ios" forKey:@"device"];
    [parameter setObject:[self selectedCategoryIDsString]?:@"" forKey:@"sc"];
    if(_isFromImageSearch){
        [parameter setObject:_image_url?:@"" forKey:@"image_url"];
        if (_strImageSearchResult) {
            [parameter setObject:_strImageSearchResult forKey:@"id"];
            [parameter setObject:@(allProductsCount) forKey:@"rows"];
        }
        if([_product firstObject] != nil && [[_product firstObject] count] > 0){
            [parameter setObject:@(0) forKey:@"start"];
        }
    } else {
        [parameter setObject:[_params objectForKey:@"search"]?:@"" forKey:@"q"];
        [parameter setObject:startPerPage forKey:@"rows"];
        [parameter setObject:@(_start) forKey:@"start"];
        [parameter setObject:@"true" forKey:@"breadcrumb"];
        if(_isFromAutoComplete){
            [parameter setObject:@"jahe" forKey:@"source"];
        }else if(_isFromDirectory){
            [parameter setObject:@"directory" forKey:@"source"];
        }else{
            [parameter setObject:@"search" forKey:@"source"];
        }
        [parameter setObject:[self getUniqueId] forKey:@"unique_id"];
    }
    
    [parameter addEntriesFromDictionary:_selectedSortParam];
    [parameter addEntriesFromDictionary:_selectedFilterParam];
    return parameter;
}

-(NSString*) getUniqueId {
    NSString *userId = [_userManager getUserId];
    
    if ([userId  isEqual: @"0"]) {
        userId = [_userManager getMyDeviceToken];
    }
    
    return [userId encryptWithMD5];
}

-(NSString*)selectedCategoryIDsString{
    NSString *selectedCategory = [[_selectedCategories valueForKey:@"categoryId"] componentsJoinedByString:@","];
    NSString *categories;
    if ([[_params objectForKey:@"sc"] integerValue] != 0 && _selectedCategories.count > 0 && [_rootCategoryID isEqualToString:@""]) {
        categories = [NSString stringWithFormat:@"%@,%@",selectedCategory,[_params objectForKey:@"sc"]?:@""];
    } else if (_selectedCategories.count == 0){
        categories = _rootCategoryID?:@"";
    } else {
        categories = selectedCategory;
    }
    return categories;
}

- (NSString*)generateProductIdString{
    NSString* strResult = @"";
    NSMutableArray *products = [_product firstObject];
    for(SearchAWSProduct *prod in products){
        strResult = [strResult stringByAppendingString:[NSString stringWithFormat:@"%@,", prod.product_id]];
    }
    if([strResult length] > 0){
        strResult = [strResult substringToIndex:[strResult length] - 1];
    }
    return strResult;
}


#pragma mark - requestWithBaseUrl
- (void)requestSearch {
    __weak typeof(self) weakSelf = self;
    
    [moyaNetworkManager requestSearchWithParams:[self getParameter]
                                        andPath:[[self pathUrls] objectForKey:[_data objectForKey:@"type"]]
                    withCompletionHandler:^(SearchProductWrapper *result) {
                        [weakSelf reloadView];
                        [weakSelf searchMappingResult:result];
                    } andErrorHandler:^(NSError *error) {
                        //do nothing
                    }];
}

- (NSDictionary*)pathUrls {
    NSDictionary *pathDictionary = @{
                                     @"search_catalog" : @"/search/v2.1/catalog",
                                     @"search_shop" : @"/search/v1/shop",
                                     @"search_product" : @"/search/v2.5/product",
                                     [self directoryType] : @"/search/v2.5/product"
                                     };
    return pathDictionary;
}

- (void)backupSimilarity{
    for(SearchAWSProduct *prod in [_product firstObject]){
        [_similarityDictionary setObject:prod.similarity_rank forKey:prod.product_id];
    }
}

- (void)restoreSimilarity{
    NSMutableArray *products = [_product firstObject];
    for(int i=0;i<[products count];i++){
        NSString* productId = ((SearchAWSProduct*)products[i]).product_id;
        ((SearchAWSProduct*)products[i]).similarity_rank = [_similarityDictionary objectForKey:productId];
    }
    if (_product.count > 0) {
        _product[0] = products;
    }
}

- (void)reloadView {
    [_noResultView removeFromSuperview];
    [_firstFooter removeFromSuperview];
    
    if(_start == 0) {
        [_product removeAllObjects];
        [_promo removeAllObjects];
    }
}


- (void)imageSearchMappingResult:(RKMappingResult *)mappingResult {
    ImageSearchResponse *search = [mappingResult.dictionary objectForKey:@""];
    if(search.data.similar_prods.count > 0){
        
        [_product addObject:search.data.similar_prods];
        
        [self backupSimilarity];
        
        _strImageSearchResult = [self generateProductIdString];
        allProductsCount = [[_product firstObject] count];
        _start = [[self splitUriToPage:_urinext] integerValue];
        if([_urinext isEqualToString:@""]) {
            [_flowLayout setFooterReferenceSize:CGSizeZero];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"changeNavigationTitle" object:[_params objectForKey:@"search"]];
        [_noResultView removeFromSuperview];
        
        for (UIButton *button in self.imageSearchToolbarButtons) {
            button.enabled = YES;
        }
        
    } else {
        //no data at all
        [_flowLayout setFooterReferenceSize:CGSizeZero];
        
        [_noResultView setNoResultDesc:@"Mohon maaf, gambar serupa tidak dapat ditemukan. Coba foto lagi dari sisi yang berbeda."];
        [_noResultView hideButton:YES];

        [_collectionView addSubview:_noResultView];
    }
    
    //if(_start > 0) [self requestPromo];
    
    if(_refreshControl.isRefreshing) {
        [_refreshControl endRefreshing];
        [_collectionView setContentOffset:CGPointMake(0, 0) animated:YES];
    } else  {
        [_collectionView reloadData];
    }
}

-(NSString*)directoryType{
    return @"directory";
}

- (void)searchMappingResult:(SearchProductWrapper *)searchResult {
    _searchObject = searchResult;
    
    [self reloadView];
    
    //set initial category
    if (_initialBreadcrumb.count == 0) {
        _initialBreadcrumb = searchResult.data.breadcrumb;
        if ([_delegate respondsToSelector:@selector(updateCategories:)]) {
            [_delegate updateCategories:searchResult.data.breadcrumb];
        }
    }

    if (_start == 0) {
        if (searchResult.data.products.count > 0) {
            [AnalyticsManager localyticsEvent:@"Search Summary" attributes:@{@"Search Results Found": @"Yes"}];
        } else {
            [AnalyticsManager localyticsEvent:@"Search Summary" attributes:@{@"Search Results Found": @"No"}];
        }
    }
    
    NSString *redirect_url = searchResult.data.redirectUrl;
    if(searchResult.data.departmentId && searchResult.data.departmentId != 0) {
        _rootCategoryID = ([_rootCategoryID integerValue] == 0)?searchResult.data.departmentId:_rootCategoryID;
        NSString *departementID = searchResult.data.departmentId;
        [_params setObject:departementID forKey:@"sc"];
        NSString *departementName = [_params objectForKey:@"department_name"]?:@"";
        if ([_delegate respondsToSelector:@selector(updateTabCategory:)]) {
            CategoryDetail *category = [CategoryDetail new];
            category.categoryId = departementID;
            category.name = departementName;
            [_delegate updateTabCategory:category];
        }
    }
    if([redirect_url isEqualToString:@""] || redirect_url == nil || [redirect_url isEqualToString:@"0"]) {
        int hascatalog = searchResult.data.hasCatalog;
        if ([[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:kTKPDSEARCH_DATASEARCHCATALOGKEY]) {
            hascatalog = 1;
        }
        
        //setting is this product has catalog or not
        if (hascatalog == 1) {
            NSDictionary *userInfo = @{@"count":@(3)};
            [[NSNotificationCenter defaultCenter] postNotificationName: kTKPD_SEARCHSEGMENTCONTROLPOSTNOTIFICATIONNAMEKEY object:nil userInfo:userInfo];
        }
        else if (hascatalog == 0){
            NSDictionary *userInfo = @{@"count":@(2)};
            [[NSNotificationCenter defaultCenter] postNotificationName: kTKPD_SEARCHSEGMENTCONTROLPOSTNOTIFICATIONNAMEKEY object:nil userInfo:userInfo];
        }
        
        
        if([[_data objectForKey:@"type"] isEqualToString:@"search_product"]||[[_data objectForKey:@"type"] isEqualToString:[self directoryType]]) {
            if(searchResult.data.products.count > 0) {
                [_product addObject: searchResult.data.products];
                [AnalyticsManager trackProductImpressions:searchResult.data.products];
            }
            
        } else {
            if(searchResult.data.catalogs.count > 0) {
                //_product[0] is for products
                //so everything is in first index
                //you're welcome!
                [_product addObject: searchResult.data.catalogs];
            }
            
        }
        
        if(_start == 0) {
            [_collectionView setContentOffset:CGPointZero animated:YES];
            
            [_collectionView reloadData];
            [_collectionView.collectionViewLayout invalidateLayout];
            //            [_collectionView layoutIfNeeded];
        }
        [self requestPromo];
        if (searchResult.data.products.count > 0 || searchResult.data.catalogs.count > 0) {
            _urinext =  searchResult.data.paging.uri_next;
            _start = [[self splitUriToPage:_urinext] integerValue];
            if([_urinext isEqualToString:@""]) {
                [_flowLayout setFooterReferenceSize:CGSizeZero];
            }
            
            [_noResultView removeFromSuperview];
            
            if(_isFromImageSearch && [_params objectForKey:@"ob"] && [[_params objectForKey:@"ob"] isEqualToString:@"99"]){
                [self restoreSimilarity];
                //image search sort by similarity
                NSArray* sortedProducts = [[_product firstObject] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                    CGFloat first = (CGFloat)[[(SearchAWSProduct*)a similarity_rank] floatValue];
                    CGFloat second = (CGFloat)[[(SearchAWSProduct*)b similarity_rank] floatValue];
                    return first > second;
                }];
                _product[0] = [NSMutableArray arrayWithArray:sortedProducts];
            }
        } else {
            //no data at all
            [_flowLayout setFooterReferenceSize:CGSizeZero];
            
            [AnalyticsManager trackEventName:@"noSearchResult" category:GA_EVENT_CATEGORY_NO_SEARCH_RESULT action:@"No Result" label:[_data objectForKey:@"search"]?:@""];

            if([self isUsingAnyFilter]){
                [_spellCheckRequest getSpellingSuggestion:@"product" query:[_data objectForKey:@"search"] category:@"0"];
            }else{
                _suggestion = @"";
            }
            
            [self adjustNoResultView];
            [_collectionView addSubview:_noResultView];
        }
        
        
        if(_refreshControl.isRefreshing) {
            [_refreshControl endRefreshing];
            [_collectionView setContentOffset:CGPointMake(0, 0) animated:YES];
        } else  {
            [_collectionView reloadData];
            [_collectionView.collectionViewLayout invalidateLayout];
        }
    } else {
        NSURL *url = [NSURL URLWithString:searchResult.data.redirectUrl];
        NSArray* query = [[url path] componentsSeparatedByString: @"/"];
        
        // Redirect URI to hotlist
        if ([query[1] isEqualToString:kTKPDSEARCH_DATAURLREDIRECTHOTKEY]) {
            [self performSelector:@selector(redirectToHotlistResult) withObject:nil afterDelay:1.0f];
        }
        
        // redirect uri to search category
        else if ([query[1] isEqualToString:kTKPDSEARCH_DATAURLREDIRECTCATEGORY]) {
            NSMutableArray *pathComponent = [NSMutableArray new];
            for (NSInteger i = 2; i < query.count; i++) {
                [pathComponent addObject:query[i]];
            }
            
            CategoryDataForCategoryResultVC *categoryDataForCategoryResultVC = [[CategoryDataForCategoryResultVC alloc] initWithPathComponent:pathComponent];
            CategoryResultViewController *categoryResultVC = [CategoryResultViewController new];
            categoryResultVC.redirectedSearchKeyword = [_params objectForKey:@"search"]?:@"";
            categoryResultVC.isIntermediary = YES;
            categoryResultVC.data = [categoryDataForCategoryResultVC mapToDictionary];
            categoryResultVC.title = [[query lastObject] stringByReplacingOccurrencesOfString:@"-" withString:@" "];
            categoryResultVC.hidesBottomBarWhenPushed = YES;
            
            [self.navigationController replaceTopViewControllerWithViewController:categoryResultVC];
            
            [Localytics triggerInAppMessage:@"Category Result Screen"];
        }
        
        else if ([query[1] isEqualToString:@"catalog"]) {
            [self performSelector:@selector(redirectToCatalogResult) withObject:nil afterDelay:1.0f];
        }
        
        else {
            [Localytics triggerInAppMessage:@"Search Result Screen"];
        }
    }
}

- (void)redirectToCatalogResult{
    NSURL *url = [NSURL URLWithString:_searchObject.data.redirectUrl];
    NSArray* query = [[url path] componentsSeparatedByString: @"/"];
    
    NSString *catalogID = query[2];
    CatalogViewController *vc = [CatalogViewController new];
    vc.catalogID = catalogID;
    NSArray *catalogNames = [query[3] componentsSeparatedByCharactersInSet:
                             [NSCharacterSet characterSetWithCharactersInString:@"-"]
                             ];
    vc.catalogName = [[catalogNames componentsJoinedByString:@" "] capitalizedString];
    vc.catalogPrice = @"";
    vc.hidesBottomBarWhenPushed = YES;
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    
    if(viewControllers.count > 0) {
        [viewControllers replaceObjectAtIndex:(viewControllers.count - 1) withObject:vc];
    }
    
    self.navigationController.viewControllers = viewControllers;
}

- (void)redirectToHotlistResult{
    [Localytics triggerInAppMessage:@"Hot List Result Screen"];
    
    NSURL *url = [NSURL URLWithString:_searchObject.data.redirectUrl];
    NSArray* query = [[url path] componentsSeparatedByString: @"/"];
    
    HotlistResultViewController *vc = [HotlistResultViewController new];
    vc.redirectedSearchKeyword = [_params objectForKey:@"search"]?:@"";
    vc.data = @{
                kTKPDSEARCH_DATAISSEARCHHOTLISTKEY : @(YES),
                kTKPDSEARCHHOTLIST_APIQUERYKEY : query[2]
                };
    
    vc.hidesBottomBarWhenPushed = YES;
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    
    if(viewControllers.count > 0) {
        [viewControllers replaceObjectAtIndex:(viewControllers.count - 1) withObject:vc];
    }
    self.navigationController.viewControllers = viewControllers;
}

- (NSString*)splitUriToPage:(NSString*)uri {
    NSURL *url = [NSURL URLWithString:uri];
    NSArray* querry = [[url query] componentsSeparatedByString: @"&"];
    
    NSMutableDictionary *queries = [NSMutableDictionary new];
    [queries removeAllObjects];
    for (NSString *keyValuePair in querry)
    {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [pairComponents objectAtIndex:0];
        NSString *value = [pairComponents objectAtIndex:1];
        
        [queries setObject:value forKey:key];
    }
    
    return [queries objectForKey:@"start"];
}

#pragma mark - No Result Delegate

- (void) buttonDidTapped:(UIButton*)sender{
    _suggestion = sender.titleLabel.text ?:@"";
    [_params setObject:_suggestion forKey:@"search"];
    [_noResultView removeFromSuperview];
    
    NSDictionary *newData = @{
                            @"type" : [_data objectForKey:@"type"],
                            @"search": _suggestion
                            };
    [self setData:newData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeNavigationTitle" object:_suggestion];

//    [_networkManager doRequest];
    [self requestSearch];
}

#pragma mark - Other Method
- (void)configureGTM {
    [AnalyticsManager trackUserInformation];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _gtmContainer = appDelegate.container;
    
    _searchBaseUrl = [_gtmContainer stringForKey:GTMKeySearchBase];
    _searchPostUrl = [_gtmContainer stringForKey:GTMKeySearchPost];
    _searchFullUrl = [_gtmContainer stringForKey:GTMKeySearchFull];
}

- (BOOL) isUsingAnyFilter{
    return [_activeFilterImageViews.firstObject isHidden];
}

- (void) refreshWishlist {
    [moyaNetworkManager checkWishlistStatusForProducts:_product
                                 withCompletionHandler:^(NSArray* productArray) {
                                     [_product removeAllObjects];
                                     for(NSArray* products in productArray) {
                                         [_product addObject:products];
                                     }
                                     [_collectionView reloadData];
                                 }andErrorHandler:^(NSError * _Nonnull error) {
                                     //do nothing
                                 }];
}

#pragma mark - Product Cell Delegate
- (void) changeWishlistForProductId:(NSString*)productId withStatus:(BOOL) isOnWishlist {
    for(NSArray* products in _product) {
        for(SearchProduct *product in products) {
            if([product.product_id isEqualToString:productId]) {
                product.isOnWishlist = isOnWishlist;
                break;
            }
        }
    }
}

#pragma mark - Promo collection delegate
- (void)requestPromo {
    NSInteger page = _start/[startPerPage integerValue];
    
    TopAdsFilter *filter = [[TopAdsFilter alloc] init];
    filter.searchKeyword = [_params objectForKey:@"search"]?:@"";
    filter.source = [filter.searchKeyword isEqualToString:@""]?TopAdsSourceDirectory:TopAdsSourceSearch;
    filter.departementId = [self selectedCategoryIDsString]?:@"";
    filter.currentPage = page;
    filter.userFilter = _selectedFilterParam;
    
    [_topAdsService getTopAdsWithTopAdsFilter:filter onSuccess:^(NSArray<PromoResult *> *promoResult) {
        if (promoResult) {
            [_promo addObject:promoResult];
        }
        
        [_collectionView reloadData];
    } onFailure:^(NSError *error) {
        [_collectionView reloadData];
    }];
}

- (void)promoDidScrollToPosition:(NSNumber *)position atIndexPath:(NSIndexPath *)indexPath {
    [_promoScrollPosition replaceObjectAtIndex:indexPath.section withObject:position];
}

- (TopadsSource)topadsSource {
    if(_isFromDirectory) {
        return TopadsSourceDirectory;
    }
    return TopadsSourceSearch;
}

- (void)didSelectPromoProduct:(PromoResult *)promoResult {
    if ([[_data objectForKey:@"type"] isEqualToString:@"search_product"]||[[_data objectForKey:kTKPDSEARCH_DATATYPE] isEqualToString:[self directoryType]]){
        
        if(promoResult.applinks){
            if(promoResult.shop.shop_id != nil){
                [TopAdsService sendClickImpressionWithClickURLString:promoResult.product_click_url];
            }
            [TPRoutes routeURL:[NSURL URLWithString:promoResult.applinks]];
        }
    }
}

#pragma mark - Scroll delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.lastContentOffset > scrollView.contentOffset.y) {
        self.scrollDirection = ScrollDirectionUp;
    } else if (self.lastContentOffset < scrollView.contentOffset.y) {
        self.scrollDirection = ScrollDirectionDown;
    }
    self.lastContentOffset = scrollView.contentOffset.y;
}

#pragma mark - Spell Check Delegate

-(void)didReceiveSpellSuggestion:(NSString *)suggestion totalData:(NSString *)totalData{
    _suggestion = suggestion;
    [self adjustNoResultView];
}

-(void)adjustNoResultView{
    if(![_suggestion isEqual:nil] && ![_suggestion isEqual:@""]){
        [_noResultView setNoResultDesc:@"Silakan lakukan pencarian dengan kata kunci lain. Mungkin maksud Anda: "];
        [_noResultView setNoResultButtonTitle:_suggestion];
        [_noResultView hideButton:NO];
    } else {
        [_noResultView setNoResultDesc:@"Silahkan lakukan pencarian dengan kata kunci / filter lain"];
        [_noResultView hideButton:YES];
    }
}

- (void)orientationChanged:(NSNotification*)note {
    [_collectionView reloadData];
}


@end
