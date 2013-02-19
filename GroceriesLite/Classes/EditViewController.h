//
//  EditViewController.h
//  QuickShopper
//
//  Created by Jon Pedersen on 07/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RootViewController;
@class Item;
@class Event;


@interface EditViewController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
	IBOutlet UITextField* nameTextField;
	IBOutlet UIPickerView* sortByPickerView;
	Item* item;
	RootViewController* rootViewController;
	NSMutableArray* sortByElements;
	
	IBOutlet UILabel* historyLabel;
	IBOutlet UIButton* clearHistoryButton;
}
//@property(nonatomic,retain)	IBOutlet UITextField* nameTextField;
@property(nonatomic,retain)	Item* item;
@property(nonatomic,retain) RootViewController* rootViewController;
@property(nonatomic,retain) NSMutableArray* sortByElements;
-(IBAction)clearHistory;
-(void)showHistory;
@end
