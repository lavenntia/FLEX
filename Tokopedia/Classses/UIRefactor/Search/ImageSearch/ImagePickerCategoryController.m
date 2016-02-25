//
//  ImagePickerCategoryController.m
//  Tokopedia
//
//  Created by Tokopedia on 2/24/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

#import "ImagePickerCategoryController.h"
#import "SearchResultViewController.h"
#import "UIImage+ImageEffects.h"

@interface ImagePickerCategoryController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (strong, nonatomic) NSArray *categories;

@end

@implementation ImagePickerCategoryController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setBlurBackground];
    
    [self setSearchButtonStyle];
    
    self.categories = @[
                        @"Aksesoris",
                        @"Aksesoris Rambut",
                        @"Baju Korea",
                        @"Baju Muslim",
                        @"Barang Couple",
                        @"Batik",
                        @"Fashion & Aksesoris Lainnya",
                        @"Jam Tangan",
                        @"Kaos",
                        @"Pakaian Anak Laki-Laki",
                        @"Pakaian Anak Perempuan",
                        @"Pakaian Pria",
                        @"Pakaian Wanita",
                        @"Sepatu", @"Perhiasan",
                        @"Tas Pria & Wanita",
                        ];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setBlurBackground {
    UIImage *image = [_imageQuery objectForKey:UIImagePickerControllerEditedImage];
    self.backgroundImageView.image = [image applyLightEffect];
}

- (void)setSearchButtonStyle {
    self.searchButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    self.searchButton.layer.cornerRadius = 3;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.categories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"categories"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"categories"];
    }
    cell.textLabel.text = self.categories[indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"GothamBook" size:14];
    cell.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.separatorInset = UIEdgeInsetsZero;
    cell.tintColor = [UIColor whiteColor];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (IBAction)didTapSearchButton:(UIButton *)sender {
    SearchResultViewController *controller = [SearchResultViewController new];
    controller.isFromAutoComplete = NO;
    controller.isFromImageSearch = YES;
    controller.title = @"Image Search";
    controller.hidesBottomBarWhenPushed = YES;
    controller.data = @{@"type":@"search_product"};
    controller.imageQueryInfo = _imageQuery;
    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    navigation.navigationBar.translucent = NO;
    
    [self presentViewController:navigation animated:YES completion:nil];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (IBAction)tapCancelButton:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
