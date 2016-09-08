//
//  ResolutionCenterCreateStepTwoViewController.m
//  Tokopedia
//
//  Created by Johanes Effendi on 8/3/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

#import "ResolutionCenterCreateStepTwoViewController.h"
#import "ResolutionCenterCreateStepTwoCell.h"
#import "DownPicker.h"
#import "RequestResolutionAction.h"
#import "Tokopedia-Swift.h"

#import <BlocksKit/BlocksKit.h>

@interface ResolutionCenterCreateStepTwoViewController ()
<
UITableViewDelegate,
UITableViewDataSource,
UIScrollViewDelegate,
ResolutionCenterCreateStepTwoCellDelegate,
UITextViewDelegate
>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITableViewCell *priceProblemCell;
@property (strong, nonatomic) IBOutlet DownPicker *priceProblemTextField;
@property (strong, nonatomic) IBOutlet RSKPlaceholderTextView *priceProblemTextView;

@end

@implementation ResolutionCenterCreateStepTwoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.allowsSelection = NO;
    [_tableView setContentInset:UIEdgeInsetsMake(0, 0, 30, 0)];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(_shouldFlushOptions){
        [self copyProductToJSONObject];
    }
    
    [TPAnalytics trackScreenName:@"Resolution Center Create Detail Problem Page"];

}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    _result.remark = _priceProblemTextView.text;
}

-(void)copyProductToJSONObject{
    _result.postObject.order_id = _order.order_detail.detail_order_id;
    [_result.postObject.product_list removeAllObjects];
    [_result.selectedProduct enumerateObjectsUsingBlock:^(ProductTrouble * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ResolutionCenterCreatePOSTProduct* postProduct = [ResolutionCenterCreatePOSTProduct new];
        postProduct.order_dtl_id = obj.pt_order_dtl_id;
        postProduct.product_id = obj.pt_product_id;
        postProduct.quantity = obj.pt_quantity;
        postProduct.trouble_id = obj.pt_trouble_id;
        postProduct.remark = obj.pt_solution_remark;
        [_result.postObject.product_list addObject:postProduct];
    }];
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableView Delegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if([_result.postObject.category_trouble_id isEqualToString:@"1"]){
        //cell untuk product
        ProductTrouble* currentProduct = [_result.selectedProduct objectAtIndex:indexPath.row];
        ResolutionCenterCreatePOSTProduct *postProduct = [_result.postObject.product_list objectAtIndex:indexPath.row];
        
        
        ResolutionCenterCreateStepTwoCell *cell = nil;
        NSString *cellid = @"ResolutionCenterCreateStepTwoCell";
        cell = (ResolutionCenterCreateStepTwoCell*)[tableView dequeueReusableCellWithIdentifier:cellid];
        if(cell == nil){
            cell = [ResolutionCenterCreateStepTwoCell newcell];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [cell.productName setTitle:currentProduct.pt_product_name forState:UIControlStateNormal];
        [cell.productImage setImageWithURL:[NSURL URLWithString:currentProduct.pt_primary_photo]];
        cell.quantityLabel.text = postProduct.quantity;
        cell.quantityStepper.value = [postProduct.quantity integerValue];
        cell.quantityStepper.stepValue = 1.0f;
        cell.quantityStepper.minimumValue = 1;
        cell.quantityStepper.maximumValue = [postProduct.quantity integerValue];
        cell.quantityStepper.tag = indexPath.row;
        
        cell.delegate = self;
        
        if(!cell.troublePicker || ![cell.troublePicker isKindOfClass:[DownPicker class]]){
            cell.troublePicker = [[DownPicker alloc] initWithTextField:cell.troublePicker];
        }
        [cell.troublePicker setData:[self generateDownPickerChoices]];
        cell.troublePicker.tag = indexPath.row;
        [cell.troublePicker addTarget:self action:@selector(troublePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
        return cell;
    }else{
        if(!_priceProblemTextField || ![_priceProblemTextField isKindOfClass:[DownPicker class]]){
            _priceProblemTextField = [[DownPicker alloc] initWithTextField:_priceProblemTextField];
        }
        [_priceProblemTextField setData:[self generateDownPickerChoices]];
        [_priceProblemTextField addTarget:self action:@selector(priceProblemPickerValueChanged:) forControlEvents:UIControlEventValueChanged];
        _priceProblemTextView.delegate = self;
        return _priceProblemCell;
    }
    
}

- (void)textViewDidChange:(UITextView *)textView {
    _result.remark = _priceProblemTextView.text;
}

-(NSMutableArray*)generateDownPickerChoices{
    return [_result generatePossibleTroubleTextListWithCategoryTroubleId:_result.postObject.category_trouble_id];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if([_result.postObject.category_trouble_id isEqualToString:@"1"]){
        return _result.selectedProduct.count;
    }else{
        return 1;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if([_result.postObject.category_trouble_id isEqualToString:@"1"]){
        return 280;
    }else{
        return _priceProblemCell.frame.size.height;
    }
}

#pragma mark - Method
-(void)troublePickerValueChanged:(id)picker{
    DownPicker* downPicker = (DownPicker*)picker;
    ResolutionCenterCreatePOSTProduct *postProduct = [_result.postObject.product_list objectAtIndex:downPicker.tag];
    NSMutableArray* possibleTroubles = [_result generatePossibleTroubleListWithCategoryTroubleId:_result.postObject.category_trouble_id];
    ResolutionCenterCreateTroubleList *selectedTrouble = [possibleTroubles objectAtIndex:[downPicker selectedIndex]];
    
    postProduct.trouble_id = selectedTrouble.trouble_id;
}

-(void)priceProblemPickerValueChanged:(id)picker{
    DownPicker* downPicker = (DownPicker*)picker;
    NSMutableArray* possibleTroubles = [_result generatePossibleTroubleListWithCategoryTroubleId:_result.postObject.category_trouble_id];
    ResolutionCenterCreateTroubleList* selectedTrouble = [possibleTroubles objectAtIndex:[downPicker selectedIndex]];
    _result.troubleId = selectedTrouble.trouble_id;
}

#pragma mark - Cell delegate
-(void)didChangeStepperValue:(UIStepper *)stepper{
    ResolutionCenterCreatePOSTProduct *postProduct = [_result.postObject.product_list objectAtIndex:stepper.tag];
    postProduct.quantity = [NSString stringWithFormat:@"%.f", stepper.value];
}

- (void)didRemarkFieldEndEditing:(RSKPlaceholderTextView *)textView withSelectedCell:(UITableViewCell *)cell {
    ResolutionCenterCreatePOSTProduct* postProduct = [_result.postObject.product_list objectAtIndex:[self.tableView indexPathForCell:cell].row];
    postProduct.remark = textView.text;
}

#pragma mark - Request
-(BOOL)verifyForm{
    for(ResolutionCenterCreatePOSTProduct *prod in _result.postObject.product_list){
        if([prod.trouble_id isEqualToString:@""]){            
            [StickyAlertView showErrorMessage:@[@"Mohon pilih masalah untuk produk yang ingin di komplain."]];
            return NO;
        }
    }
    
    if(([_result.postObject.category_trouble_id isEqualToString:@"2"] || [_result.postObject.category_trouble_id isEqualToString:@"3"] ) && (_result.remark == nil || [_result.remark isEqualToString:@""])) {
        [StickyAlertView showErrorMessage:@[@"Mohon isi alasan Anda terlebih dahulu."]];
        return NO;
    }

    return YES;
}
@end
