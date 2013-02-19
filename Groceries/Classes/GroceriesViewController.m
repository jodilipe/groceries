//
//  GroceriesViewController.m
//  Groceries
//
//  Created by Jon Pedersen on 14/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import "GroceriesViewController.h"
#import "RootViewController.h"
#import "Item.h"
#import "Event.h"
#import "GroceriesAppDelegate.h"


@implementation GroceriesViewController

static int const MAX_NO_OF_EVENTS = 10;
static int const MIN_HOURS_BETWEEN_EVENTS = 12;

#pragma mark -
#pragma mark Initialization


-(RootViewController *)rootViewController {
	GroceriesAppDelegate *mainDelegate = (GroceriesAppDelegate*)[[UIApplication sharedApplication]delegate];
	return [mainDelegate rootViewController];
}

#pragma mark -
#pragma mark Shopping list

- (NSMutableArray *)shoppingList {
	GroceriesAppDelegate *mainDelegate = (GroceriesAppDelegate*)[[UIApplication sharedApplication]delegate];
	NSMutableArray *shoppingList = [mainDelegate shoppingList];
	return shoppingList;
}

- (void)sortShoppingList {
	GroceriesAppDelegate *mainDelegate = (GroceriesAppDelegate*)[[UIApplication sharedApplication]delegate];
	[mainDelegate sortShoppingList];
}

- (IBAction)clearShoppingList {
	if ([[self shoppingList] count] > 0) {
		NSString *clearTitle = NSLocalizedString(@"Clear shopping list?",@"Clear shopping list title");
		NSString *clearMessage = NSLocalizedString(@"Press OK to clear",@"Press OK to clear.");
		NSString *clearCancel = NSLocalizedString(@"Cancel",@"Cancel action");
		NSString *clearOK = NSLocalizedString(@"OK",@"OK action");
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:clearTitle message:clearMessage
													   delegate:self cancelButtonTitle:clearCancel otherButtonTitles:clearOK, nil];
		[alert show];
		[alert release];
	}
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		GroceriesAppDelegate *mainDelegate = (GroceriesAppDelegate*)[[UIApplication sharedApplication]delegate];
		[mainDelegate clearShoppingList];
		[self updateTitle];
		[[self tableView] reloadData];
	}
}

- (IBAction)suggestShoppingList {
	int itemsAdded = [[self rootViewController] suggestNewList];
	if (itemsAdded > 0) {
		[self sortShoppingList];
		[self updateTitle];
		[[self tableView] reloadData];
	} else {
		NSString *emptySuggestionTitle = NSLocalizedString(@"Nothing to do",@"Empty suggestion title");
		NSString *emptySuggestionMessage = NSLocalizedString(@"No suitable grocery items found",@"Empty suggestion message");
		NSString *emptySuggestionOK = NSLocalizedString(@"OK",@"OK action");
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:emptySuggestionTitle message:emptySuggestionMessage
													   delegate:self cancelButtonTitle:emptySuggestionOK otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
	self.tableView.separatorColor = [UIColor blueColor];
	self.tableView.backgroundColor = [UIColor clearColor];
	
	[self updateTitle];
	[self sortShoppingList];
	[[self tableView] reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Item *item = [[self shoppingList] objectAtIndex:indexPath.row];
        item.checked = [NSNumber numberWithBool:NO];
        item.onShoppingList = [NSNumber numberWithBool:NO];
        [[self shoppingList] removeObjectAtIndex:indexPath.row];
		[self updateTitle];
        [[self tableView] reloadData];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSMutableArray *shoppingList = [self shoppingList];
	return [shoppingList count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	Item *item = [[self shoppingList] objectAtIndex:indexPath.row];
    cell.textLabel.text = item.name;
	BOOL checked = [item.checked boolValue];
	if (checked) {
		cell.textLabel.textColor = [UIColor lightGrayColor];
		cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:22];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.textLabel.textColor = [UIColor blackColor];
		cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:22];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    
    return cell;
}

#pragma mark -
#pragma mark Event stuff

- (Event*) earliestEvent:(Item *)item {
	Event *earliestEvent = nil;
	for (Event *event in [item events]) {
		if (!earliestEvent || [event.checkedAt timeIntervalSince1970] < [earliestEvent.checkedAt timeIntervalSince1970]) {
			earliestEvent = event;
		}
	}
	return earliestEvent;
}

- (NSDate*) latestEventDate:(Item *)item {
	NSArray *events = [item.events allObjects];
	NSDate *currDate = nil;
	if ([events count] > 0) {
		currDate = [NSDate dateWithTimeIntervalSince1970:0];
		for (int i = 0; i < [events count]; i++) {
			NSDate *currEventDate = [[events objectAtIndex:i] checkedAt];
			currDate = [currDate laterDate:currEventDate];
		}
	}
	return currDate;
}

- (int) hoursSinceLastCheck:(Item *)item {
	NSDate *latestEventDate = [self latestEventDate:item];
	if (latestEventDate) {
		int diffInSeconds = [[NSDate date] timeIntervalSince1970] - [latestEventDate timeIntervalSince1970];
		return (diffInSeconds / 60 / 60);
	}
	return 0;
}

#pragma mark -
#pragma mark Table view delegate

- (BOOL)canCheckItems{
	GroceriesAppDelegate *mainDelegate = (GroceriesAppDelegate*)[[UIApplication sharedApplication]delegate];
	return [mainDelegate canCheckItems];
}

- (int)noOfUncheckedItems {
	int unchecked = 0;
	for (Item *item in [self shoppingList]) {
		BOOL checked = [item.checked boolValue];
		if (!checked) {
			unchecked ++;
		}
	}
	return unchecked;
}

- (void)updateTitle {
	NSString *title = NSLocalizedString(@"List",@"Shopping list title");
	int uncheckedItems = [self noOfUncheckedItems];
	if (uncheckedItems > 0) {
		self.navigationItem.title = [NSString stringWithFormat:@"%@ (%d)", title, uncheckedItems];
	} else {
		self.navigationItem.title = title;
	}
}

- (void)toggleChecked:(Item *)item {
	BOOL checked = [item.checked boolValue];
	if (checked) {
		item.checked = [NSNumber numberWithBool:NO];
	} else {
		item.checked = [NSNumber numberWithBool:YES];
		if ([self canCheckItems] && ([item.events count] == 0 || [self hoursSinceLastCheck:item] > MIN_HOURS_BETWEEN_EVENTS)) {
			if ([item.events count] > MAX_NO_OF_EVENTS) {
				[item removeEventsObject:[self earliestEvent:item]];
			}
			[[self rootViewController] insertNewEvent:item checkedAt:[NSDate date]];
		}
	}
	[self updateTitle];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Item *selectedItem = [[self shoppingList] objectAtIndex:indexPath.row];
	[self toggleChecked:selectedItem];
	[self sortShoppingList];
	[[self tableView] reloadData];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

