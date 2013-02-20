    //
//  EditViewController.m
//  QuickShopper
//
//  Created by Jon Pedersen on 07/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import "EditViewController.h"
#import "RootViewController.h"
#import "Item.h"
#import "Event.h"


@implementation EditViewController

@synthesize item;
@synthesize rootViewController;
@synthesize sortByElements;

- (IBAction)clearHistory {
	NSString *deleteString = NSLocalizedString(@"Delete history?", @"Delete history title");
	NSString *deleteMessage = NSLocalizedString(@"This will prevent the item...", @"Delete history message");
	NSString *deleteCancel = NSLocalizedString(@"Cancel", @"Cancel action");
	NSString *deleteOk = NSLocalizedString(@"OK", @"Confirm action");
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:deleteString message:deleteMessage
												   delegate:self cancelButtonTitle:deleteCancel otherButtonTitles:deleteOk, nil];
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		NSArray *events = [item.events allObjects];
		for (Event *event in events) {
			[rootViewController delete:event];
		}
		[rootViewController saveContext];
		historyLabel.text = nil;
		[self showHistory];
	}
}

- (void)showHistory {
	NSDate *latestEventDate = [rootViewController latestEventDate:item];
	if (latestEventDate) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init]; 
		[dateFormatter setDateStyle:NSDateFormatterLongStyle]; 
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		historyLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Latest purchase was", @"Latest purchase prefix"), [dateFormatter stringFromDate: latestEventDate]];
		[dateFormatter release];
		[clearHistoryButton setEnabled:YES];
		[clearHistoryButton setHidden:NO];
	} else {
		[clearHistoryButton setEnabled:NO];
		[clearHistoryButton setHidden:YES];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	nameTextField.text = item.name;
	[nameTextField becomeFirstResponder];
	NSLocale *locale = [NSLocale currentLocale];
	if ([@"da_DK" isEqualToString:[locale localeIdentifier]]) {
		self.sortByElements = [NSMutableArray arrayWithObjects:@"Brød og morgenmad",@"Diverse",@"Drikkevarer",@"Frostvarer",@"Frugt",@"Grøntsager",@"Husholdningsartikler",@"Ingredienser",@"Konserves",@"Krydderier & olie",@"Kød & fisk",@"Mejeri",@"Personlig pleje",@"Pålæg",@"Ris & pasta",@"Snacks & kager",@"Øl, vin & spiritus",nil];
	} else {
		self.sortByElements = [NSMutableArray arrayWithObjects:@"Bakery and Bread",@"Beverages",@"Breakfast",@"Canned Goods",@"Condiments",@"Dairy, Eggs & Cheese",@"Frozen Foods",@"Fruits",@"Health & Beauty",@"Household Supplies",@"Ingredients",@"Meat, Seafood & Poultry",@"Miscellaneous",@"Sauces, Spices & Seasoning",@"Snacks",@"Vegetables",nil];
	}
	
	self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
	self.view.backgroundColor = [UIColor clearColor];
	
	[self showHistory];
}

- (void)viewDidAppear:(BOOL)animated {
    int index = 0;
    if (item.name) {
        index = [sortByElements indexOfObject:item.sortBy];
    }
	[sortByPickerView selectRow: index inComponent: 0 animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
	if ([nameTextField.text length] > 0) {
		item.name = nameTextField.text;
		self.item.sortBy = [sortByElements objectAtIndex:[sortByPickerView selectedRowInComponent:0]];
		[rootViewController saveContext];
	} else {
		[rootViewController removeFromShoppingList:item];
		[rootViewController delete:item];
	}
	[rootViewController refreshSearch];
}

#pragma mark -
#pragma mark UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component { 
	return (NSString*) [sortByElements objectAtIndex: row];
}

#pragma mark -
#pragma mark UIPickerViewDataSource

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	[nameTextField resignFirstResponder]; 
}

-(NSInteger) pickerView: (UIPickerView*) pickerView numberOfRowsInComponent: (NSInteger) component { 
	return [sortByElements count];
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView { 
	return 1;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField { 
	[nameTextField resignFirstResponder]; 
	return YES;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [super dealloc];
	[sortByElements release];
}


@end
