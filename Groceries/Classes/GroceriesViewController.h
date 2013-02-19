//
//  GroceriesViewController.h
//  Groceries
//
//  Created by Jon Pedersen on 14/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RootViewController;


@interface GroceriesViewController : UITableViewController <UIAlertViewDelegate> {
	IBOutlet UIBarButtonItem *actionButton;
}

-(IBAction)clearShoppingList;
-(IBAction)suggestShoppingList;
-(RootViewController *)rootViewController;
-(NSMutableArray *)shoppingList;
-(void)updateTitle;

@end
