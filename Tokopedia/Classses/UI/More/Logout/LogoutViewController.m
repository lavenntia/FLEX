//
//  LogoutViewController.m
//  Tokopedia
//
//  Created by IT Tkpd on 10/20/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import "LogoutViewController.h"
#import "TKPDTabInboxMessageNavigationController.h"
#import "TKPDTabInboxTalkNavigationController.h"
#import "ShopProductViewController.h"
#import "ShopTalkViewController.h"
#import "InboxMessageViewController.h"
#import "InboxTalkViewController.h"
#import "ShopSettingViewController.h"
#import "ShopInfoViewController.h"

@interface LogoutViewController ()
{

}

@end

@implementation LogoutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)tap:(id)sender {
    UIButton *btn = (UIButton*)sender;
    switch (btn.tag) {
        case 10:
        {
            // logout
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:kTKPDACTIVATION_DIDAPPLICATIONLOGOUTNOTIFICATION object:nil userInfo:@{}];
            break;
        }
            
        case 11 : {
            InboxMessageViewController *vc = [InboxMessageViewController new];
            vc.data=@{@"nav":@"inbox-message"};
            
            InboxMessageViewController *vc1 = [InboxMessageViewController new];
            vc1.data=@{@"nav":@"inbox-message-sent"};
            
            InboxMessageViewController *vc2 = [InboxMessageViewController new];
            vc2.data=@{@"nav":@"inbox-message-archive"};
            
            InboxMessageViewController *vc3 = [InboxMessageViewController new];
            vc3.data=@{@"nav":@"inbox-message-trash"};
            NSArray *vcs = @[vc,vc1, vc2, vc3];

            TKPDTabInboxMessageNavigationController *nc = [TKPDTabInboxMessageNavigationController new];
            [nc setSelectedIndex:2];
            [nc setViewControllers:vcs];
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:nc];
            [nav.navigationBar setTranslucent:NO];
            [self.navigationController presentViewController:nav animated:YES completion:nil];
            break;
        }
        case 12:{
            //settings
            ShopSettingViewController *vc = [ShopSettingViewController new];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 13:
        {
            ShopInfoViewController *vc = [ShopInfoViewController new];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
            
        case 14 : {
            InboxTalkViewController *vc = [InboxTalkViewController new];
            vc.data=@{@"nav":@"inbox-talk"};
            
            InboxTalkViewController *vc1 = [InboxTalkViewController new];
            vc1.data=@{@"nav":@"inbox-talk-my-product"};
            
            InboxTalkViewController *vc2 = [InboxTalkViewController new];
            vc2.data=@{@"nav":@"inbox-talk-following"};
            
            NSArray *vcs = @[vc,vc1, vc2];
            
            TKPDTabInboxTalkNavigationController *nc = [TKPDTabInboxTalkNavigationController new];
            [nc setSelectedIndex:2];
            [nc setViewControllers:vcs];
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:nc];
            [nav.navigationBar setTranslucent:NO];
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }
        default:
            break;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
