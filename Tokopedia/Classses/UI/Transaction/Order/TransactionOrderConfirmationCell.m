//
//  TransactionOrderConfirmationCell.m
//  Tokopedia
//
//  Created by IT Tkpd on 2/4/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "TransactionOrderConfirmationCell.h"

@implementation TransactionOrderConfirmationCell

#pragma mark - Factory methods

+ (id)newcell
{
    NSArray* a = [[NSBundle mainBundle] loadNibNamed:@"TransactionOrderConfirmationCell" owner:nil options:0];
    for (id o in a) {
        if ([o isKindOfClass:[self class]]) {
            return o;
        }
    }
    return nil;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)tap:(id)sender {
    
}

@end
