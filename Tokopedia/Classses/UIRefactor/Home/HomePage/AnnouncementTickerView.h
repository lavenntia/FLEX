//
//  AnnouncementTickerView.h
//  Tokopedia
//
//  Created by Kenneth Vincent on 7/27/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

@interface AnnouncementTickerView : UIView <TTTAttributedLabelDelegate>

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet TTTAttributedLabel *messageLabel;

@property (copy) void(^onTapMessageWithUrl)(NSURL *url);

+ (id)newView;
- (void)setTitle:(NSString *)text;
- (void)setMessage:(NSString *)text;

@end
