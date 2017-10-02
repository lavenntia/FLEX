//
//  FilterCategoryViewController.m
//  Tokopedia
//
//  Created by Tokopedia on 2/10/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

#import "FilterCategoryViewController.h"
#import "FilterCategoryViewCell.h"
#import "LoadingView.h"
#import "Tokopedia-Swift.h"

#define cellIdentifier @"filterCategoryViewCell"

@interface FilterCategoryViewController () <LoadingViewDelegate>

@property (strong, nonatomic) NSMutableArray *initialCategories;
@property BOOL requestError;

@property (strong, nonatomic) LoadingView *loadingView;

@end

@implementation FilterCategoryViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.tableView.contentInset = UIEdgeInsetsMake(-1, 0, 0, 0);
        self.tableView.backgroundColor = [UIColor colorWithRed:231.0/255.0 green:231.0/255.0 blue:231.0/255.0 alpha:1];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Pilih Kategori";
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.categories == nil || [self.categories count] == 0) {
        [self loadData];
    } else {
        if (self.filterType == FilterCategoryTypeSearchProduct) {
            ListOption *category = [ListOption new];
            category.categoryId = @"0";
            category.name = @"Semua Kategori";
            category.tree = @"1";
            [self.categories insertObject:category atIndex:0];
        }
        [self showPresetCategories];
    }
    if (self == self.navigationController.viewControllers.firstObject) {
        [self setCancelButton];
    }
    [self setDoneButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setCancelButton {
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Batal" style:UIBarButtonItemStylePlain target:self action:@selector(didTapCancelButton)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}


- (void)setDoneButton {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Selesai" style:UIBarButtonItemStyleDone target:self action:@selector(didTapDoneButton)];
    self.navigationItem.rightBarButtonItem = doneButton;
    [self updateDoneButtonAppearance];
}

- (void)updateDoneButtonAppearance {
    UIBarButtonItem *doneButton = self.navigationItem.rightBarButtonItem;
    if (self.filterType == FilterCategoryTypeProductAddEdit) {
        if (self.selectedCategory.child.count > 0 || self.selectedCategory == nil) {
            doneButton.enabled = NO;
            doneButton.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        } else {
            doneButton.enabled = YES;
            doneButton.tintColor = [UIColor whiteColor];
        }
    } else {
        if (self.selectedCategory) {
            doneButton.enabled = YES;
            doneButton.tintColor = [UIColor whiteColor];
        } else {
            doneButton.enabled = NO;
            doneButton.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        }
    }
}

- (void)didTapCancelButton {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didTapDoneButton {
    if (self.selectedCategory == nil) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didSelectCategory:)]) {
        [self.delegate didSelectCategory:self.selectedCategory];
    }
    if (self.navigationItem.leftBarButtonItem == nil) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)loadData {
    [RequestFilterCategory fetchListFilterCategory:_rootCategoryID?:@"" success:^(NSArray<ListOption *> * categories) {
        self.initialCategories = [NSMutableArray arrayWithArray:categories];
        if (self.filterType == FilterCategoryTypeSearchProduct) {
            ListOption *category = [ListOption new];
            category.categoryId = @"0";
            category.name = @"Semua Kategori";
            category.tree = @"1";
            [self.initialCategories insertObject:category atIndex:0];
        }
        [self expandSelectedCategories];
        [self hidesOtherCategories];
        if (self.selectedCategory) {
            [self scrollToCategory:self.selectedCategory];
        }
        [self updateDoneButtonAppearance];
        [self.tableView reloadData];
        
    } failed:^(NSError * error) {
        [self requestFail];
    }];
}

- (void)showPresetCategories {
    for (ListOption *category in self.categories) {
        for (ListOption *childCategory in category.child) {
            childCategory.parent = category.categoryId;
            for (ListOption *lastCategory in childCategory.child) {
                lastCategory.parent = childCategory.categoryId;
            }
        }
    }
    self.initialCategories = self.categories;
    if (self.selectedCategory) {
        [self expandSelectedCategories];
    }
    [self updateDoneButtonAppearance];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.categories.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FilterCategoryViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[FilterCategoryViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    ListOption *category = [self.categories objectAtIndex:indexPath.row];
    
    cell.categoryNameLabel.text = category.name;
    
    if ([category.tree isEqualToString:@"1"]) {
        cell.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    if ([self.selectedCategory isEqual:category]) {
        UIColor *greenColor = [UIColor colorWithRed:72.0/255.0 green:187.0/255.0 blue:72.0/255.0 alpha:1];
        cell.categoryNameLabel.textColor = greenColor;
        cell.categoryNameLabel.font = [UIFont largeThemeMedium];
        cell.arrowImageView.tintColor = greenColor;
        cell.checkmarkImageView.tintColor = greenColor;
    } else {
        cell.categoryNameLabel.textColor = [UIColor blackColor];
        cell.categoryNameLabel.font = [UIFont largeTheme];
        cell.arrowImageView.tintColor = [UIColor grayColor];
    }
    
    cell.leftPaddingConstraint.constant = [category.tree integerValue] * 15;
    
    if (self.filterType == FilterCategoryTypeHotlist ||
        self.filterType == FilterCategoryTypeCategory ||
        self.filterType == FilterCategoryTypeSearchProduct) {
        if ([category isEqual:_selectedCategory]) {
            [cell showCheckmark];
        } else {
            [cell hideCheckmark];
        }
    } else {
        // Selected category is last category
        if (category.child.count == 0 && [category isEqual:_selectedCategory]) {
            [cell showCheckmark];
        } else {
            [cell hideCheckmark];
        }
    }
    
    if (category.child.count > 0) {
        [cell showArrow];
        ArrowDirection direction = category.isExpanded ? ArrowDirectionUp : ArrowDirectionDown;
        [cell setArrowDirection:direction];
    } else {
        [cell hideArrow];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (self.categories.count > 0 || self.requestError) {
        return nil;
    }
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicatorView.center = view.center;
    [indicatorView startAnimating];
    [view addSubview:indicatorView];
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ListOption *category = [self.categories objectAtIndex:indexPath.row];
    if (self.filterType == FilterCategoryTypeCategory ||
        self.filterType == FilterCategoryTypeHotlist ||
        self.filterType == FilterCategoryTypeSearchProduct) {
        if ([category isEqual:_selectedCategory]) {
            if (category.isExpanded) {
                [self deselectCategory:category];
            } else {
                [self selectCategory:category];
            }
        } else {
            [self selectCategory:category];
        }
    } else {
        if (category.isExpanded) {
            [self deselectCategory:category];
        } else {
            [self selectCategory:category];
        }
    }
    [self updateDoneButtonAppearance];
    [tableView reloadData];
}

- (void)selectCategory:(ListOption *)category {
    self.selectedCategory = category;
    [self expandSelectedCategories];
    [self scrollToCategory:category];
}

- (void)deselectCategory:(ListOption *)selectedCategory {
    self.selectedCategory = selectedCategory;
    [self collapseSelectedCategories];
    [self scrollToCategory:selectedCategory];
}

- (void)scrollToCategory:(ListOption *)category {
    NSInteger index = 0;
    for (ListOption *category in self.categories) {
        if ([self.selectedCategory isEqual:category]) {
            index = [self.categories indexOfObject:category];
        }
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}


- (void)expandSelectedCategories {
    [self collapseAllCategories];
    NSMutableArray *categories = [NSMutableArray new];
    for (ListOption *category in self.initialCategories) {
        [categories addObject:category];
        if ([self.selectedCategory isEqual:category]) {
            category.isExpanded = YES;
            NSInteger location = [categories indexOfObject:category] + 1;
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(location, category.child.count)];
            [categories insertObjects:category.child atIndexes:indexSet];
        } else {
            for (ListOption *childCategory in category.child) {
                if ([self.selectedCategory isEqual:childCategory]) {
                    category.isExpanded = YES;
                    childCategory.isExpanded = YES;
                    categories = [self categories:categories addChildCategory:category];
                    categories = [self categories:categories addChildCategory:childCategory];
                } else {
                    for (ListOption *lastCategory in childCategory.child) {
                        if ([self.selectedCategory isEqual:lastCategory]) {
                            category.isExpanded = YES;
                            childCategory.isExpanded = YES;
                            categories = [self categories:categories addChildCategory:category];
                            categories = [self categories:categories addChildCategory:childCategory];
                        }
                    }
                }
            }
        }
    }
    self.categories = categories;
    [self hidesOtherCategories];
    [self.tableView reloadData];
}

// For Search Category, remove other categories at level 1. Shows only selected category level 1 and its childs
- (void)hidesOtherCategories {
    if (self.filterType == FilterCategoryTypeCategory) {
        NSMutableArray *deletedCategories = [NSMutableArray new];
        for (ListOption *category in self.initialCategories) {
            if ([category.tree isEqualToString:@"1"] && category.isExpanded == NO) {
                [deletedCategories addObject:category];
            }
        }
        [self.categories removeObjectsInArray:deletedCategories];
    }
}

- (NSMutableArray *)categories:(NSMutableArray *)categories addChildCategory:(ListOption *)category  {
    NSInteger location = [categories indexOfObject:category] + 1;
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(location, category.child.count)];
    [categories insertObjects:category.child atIndexes:indexSet];
    return categories;
}

- (void)collapseSelectedCategories {
    NSMutableArray *categories = [NSMutableArray new];
    for (ListOption *category in self.initialCategories) {
        [categories addObject:category];
        if ([self.selectedCategory isEqual:category]) {
            category.isExpanded = NO;
        }
        for (ListOption *childCategory in category.child) {
            if ([self.selectedCategory isEqual:childCategory]) {
                childCategory.isExpanded = NO;
                NSInteger location = [categories indexOfObject:category] + 1;
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(location, category.child.count)];
                [categories insertObjects:category.child atIndexes:indexSet];
            }
        }
    }
    self.categories = categories;
    [self.tableView reloadData];
}

- (void)collapseAllCategories {
    for (ListOption *category in _categories) {
        category.isExpanded = NO;
        for (ListOption *childCategory in category.child) {
            childCategory.isExpanded = NO;
            for (ListOption *lastCategory in childCategory.child) {
                lastCategory.isExpanded = NO;
            }
        }
    }
}

- (void)requestFail {
    [[[StickyAlertView alloc] initWithErrorMessages:@[@"Mohon maaf sedang terjadi kendala pada internet."] delegate:self] show];
    self.requestError = YES;
    self.tableView.tableFooterView = self.loadingView;
    [self.tableView reloadData];
}

#pragma mark - Loading view delegate

- (void)pressRetryButton {
    [self loadData];
}

#pragma mark - Objects

- (LoadingView *)loadingView {
    if (_loadingView == nil) {
        _loadingView = [LoadingView new];
        _loadingView.delegate = self;
    }
    return _loadingView;
}

@end
