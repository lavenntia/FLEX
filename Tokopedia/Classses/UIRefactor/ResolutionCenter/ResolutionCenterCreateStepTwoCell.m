//
//  ResolutionCenterCreateStepTwoCell.m
//  Tokopedia
//
//  Created by Johanes Effendi on 8/4/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

#import "ResolutionCenterCreateStepTwoCell.h"

@implementation ResolutionCenterCreateStepTwoCell
+ (id)newcell
{
    NSArray* a = [[NSBundle mainBundle] loadNibNamed:@"ResolutionCenterCreateStepTwoCell" owner:nil options:0];
    for (id o in a) {
        if ([o isKindOfClass:[self class]]) {
            return o;
        }
    }
    return nil;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.problemTextView.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)stepperValueChanged:(id)sender {
    _quantityLabel.text = [NSString stringWithFormat:@"%.f", _quantityStepper.value];
    [_delegate didChangeStepperValue:sender];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [_delegate didRemarkFieldEndEditing:textView withSelectedCell:self];
}

@end
