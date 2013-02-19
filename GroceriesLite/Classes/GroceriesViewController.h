//
//  GroceriesViewController.h
//  Groceries
//
//  Created by Jon Pedersen on 14/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
@class RootViewController;


@interface GroceriesViewController : UIViewController <UIAlertViewDelegate, ADBannerViewDelegate> {
	IBOutlet UIBarButtonItem *actionButton;

    UIView *contentView;
    ADBannerView *banner;

    IBOutlet UITableView *tv;
}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet ADBannerView *banner;
@property (nonatomic, retain) UITableView *tv;

-(IBAction)clearShoppingList;
-(IBAction)suggestShoppingList;
-(RootViewController *)rootViewController;
-(NSMutableArray *)shoppingList;
-(void)updateTitle;

@end
