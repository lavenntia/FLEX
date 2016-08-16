//
//  EditShopDataSource.m
//  Tokopedia
//
//  Created by Tokopedia on 3/18/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

#import "EditShopDataSource.h"

@implementation EditShopDataSource

NSInteger const SectionForShopTagDescription = 0;

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SectionForShopTagDescription) {
        return 3;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell = [self tableView:tableView shopNameCellForRowAtIndexPath:indexPath];
        } else {
            cell = [self tableView:tableView shopDescriptionCellForRowAtIndexPath:indexPath];
        }
    } else if (indexPath.section == 1) {
        cell = [self tableView:tableView shopImageCellForRowAtIndexPath:indexPath];
    } else if (indexPath.section == 2) {
        cell = [self tableView:tableView shopStatusCellForRowAtIndexPath:indexPath];
    } else if (indexPath.section == 3) {
        cell = [self tableView:tableView shopTypeCellForRowAtIndexPath:indexPath];
    }
    return cell;
}

- (EditShopTypeViewCell *)tableView:(UITableView *)tableView shopTypeCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EditShopTypeViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"shopType"];
    [cell initializeInterfaceWithGoldMerchantStatus:[self.shop.info.shop_is_gold boolValue] expiryDate:self.shop.info.shop_gold_expired_time];
    cell.delegate = self;
    return cell;
}

- (EditShopImageViewCell *)tableView:(UITableView *)tableView shopImageCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EditShopImageViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"shopImage"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_shop.image.logo]];
    UIImage *placeholderImage = [UIImage imageNamed:@"icon_default_shop.jpg"];
    [cell.shopImageView setImageWithURLRequest:request
                              placeholderImage:placeholderImage
                                       success:^(NSURLRequest *request,
                                                 NSHTTPURLResponse *response,
                                                 UIImage *image) {
                                           cell.shopImageView.image = image;
                                           cell.changeImageLabel.hidden = NO;
                                           [cell.activityIndicatorView stopAnimating];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        cell.changeImageLabel.hidden = NO;        
    }];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView shopNameCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"shopName"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"shopName"];
        cell.textLabel.text = @"Nama Toko";
        cell.textLabel.font = [UIFont title2Theme];
        cell.detailTextLabel.font = [UIFont title2Theme];
        cell.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.detailTextLabel.text = _shop.info.shop_name;
    return cell;
}

- (EditShopDescriptionViewCell *)tableView:(UITableView *)tableView
      shopDescriptionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EditShopDescriptionViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"shopDescription"];
    if (indexPath.row == 1) {
        cell.textView.text = _shop.info.shop_tagline;
        cell.textView.tag = ShopTextViewForTag;
        NSNotificationCenter *notification = [NSNotificationCenter defaultCenter];
        [notification addObserver:self selector:@selector(taglineTextViewDidChange:) name:UITextViewTextDidChangeNotification object:cell.textView];

    } else if (indexPath.row == 2) {
        cell.textView.text = _shop.info.shop_description;
        cell.textView.tag = ShopTextViewForDescription;
        NSNotificationCenter *notification = [NSNotificationCenter defaultCenter];
        [notification addObserver:self selector:@selector(descriptionTextViewDidChange:) name:UITextViewTextDidChangeNotification object:cell.textView];

    }
    [cell updateCountLabel];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView shopStatusCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"shopStatus"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"shopStatus"];
        cell.textLabel.text = @"Status Toko";
        cell.textLabel.font = [UIFont title2Theme];
        cell.detailTextLabel.font = [UIFont title2Theme];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:66.0/255.0 green:189.0/255.0 blue:65.0/255.0 alpha:1];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    if (self.shop.isClosed) {
        cell.detailTextLabel.text = @"Tutup";
    } else if (self.shop.isOpen) {
        cell.detailTextLabel.text = @"Buka";
    }
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footer;
    if(section == 2 && !(_shop.closed_schedule_detail.close_status == CLOSE_STATUS_OPEN)){
        footer = [[UIView alloc]initWithFrame:CGRectMake(15, 8, 320, 40)];
        footer.backgroundColor = [UIColor clearColor];
        
        UILabel *lbl = [[UILabel alloc]initWithFrame:footer.frame];
        lbl.backgroundColor = [UIColor clearColor];
        
        if(_shop.closed_schedule_detail.close_status == CLOSE_STATUS_CLOSED){
            lbl.text = [NSString stringWithFormat:@"Toko akan buka kembali pada %@, 23:59.", _shop.closed_schedule_detail.close_end];
        }else{
            lbl.text = [NSString stringWithFormat:@"Toko akan tutup pada %@, 00:00.", _shop.closed_schedule_detail.close_start];
        }
        lbl.textAlignment = NSTextAlignmentLeft;
        lbl.font = [UIFont smallTheme];
        [lbl setNumberOfLines:0];
        [lbl sizeToFit];
        [footer addSubview:lbl];
        
        return footer;
    }
    return footer;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if(_shop.closed_schedule_detail.close_status == CLOSE_STATUS_CLOSED || _shop.closed_schedule_detail.close_status == CLOSE_STATUS_CLOSE_SCHEDULED){
        return 40.0;
    }
    return 0;
}

#pragma mark - Table view delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    if (section == 1) {
        title = @"  Gambar Toko";
    } else if (section == 2) {
        title = @"  Status";
    } else if (section == 3) {
        title = @"  Keanggotaan";
    }
    return title;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *)view;
        tableViewHeaderFooterView.textLabel.text = [tableViewHeaderFooterView.textLabel.text capitalizedString];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:[self indexPathForShopImage]]) {
        return 113;
    } else if ([indexPath isEqual:[self indexPathForShopTag]]) {
        return 60;
    } else if ([indexPath isEqual:[self indexPathForShopDescription]]) {
        return 100;
    } else if (indexPath.section == 3){
        return 100;
    }
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        [self.delegate didTapShopPhoto];
    } else if (indexPath.section == 2) {
        [self.delegate didTapShopStatus];
    }
}

- (NSIndexPath *)indexPathForShopImage {
    return [NSIndexPath indexPathForRow:0 inSection:1];
}

- (NSIndexPath *)indexPathForShopTag {
    return [NSIndexPath indexPathForRow:1 inSection:0];
}

- (NSIndexPath *)indexPathForShopDescription {
    return [NSIndexPath indexPathForRow:2 inSection:0];
}

#pragma mark - Delegate
-(void)merchantInfoButtonTapped{
    [_delegate didTapMerchantInfo];
}

#pragma mark - Notification 

- (void)taglineTextViewDidChange:(NSNotification *)notification {
    TKPDTextView *textView = notification.object;
    self.shop.info.shop_tagline = textView.text;
}

- (void)descriptionTextViewDidChange:(NSNotification *)notification {
    TKPDTextView *textView = notification.object;
    self.shop.info.shop_description = textView.text;
}

@end
