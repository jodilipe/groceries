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

@interface GroceriesViewController ()
//- (void)configureCell:(UITableViewCell *)cell withItem:(Item *)item atIndexPath:(NSIndexPath *)indexPath;
-(void)layoutForCurrentOrientation:(BOOL)animated;
-(void)createADBannerView;
@end

@implementation GroceriesViewController

static int const MAX_NO_OF_EVENTS = 10;
static int const MIN_HOURS_BETWEEN_EVENTS = 12;

@synthesize tv;
@synthesize contentView, banner;

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
		[self.tv reloadData];
	}
}

- (IBAction)suggestShoppingList {
	int itemsAdded = [[self rootViewController] suggestNewList];
	if (itemsAdded > 0) {
		[self sortShoppingList];
		[self updateTitle];
		[self.tv reloadData];
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
    
    if(banner == nil) {
        [self createADBannerView];
    }
    [self layoutForCurrentOrientation:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
    [self layoutForCurrentOrientation:NO];

	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
	self.tv.separatorColor = [UIColor blueColor];
	self.tv.backgroundColor = [UIColor clearColor];
	
	[self updateTitle];
	[self sortShoppingList];
	[self.tv reloadData];
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
        [self.tv reloadData];
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
	[self.tv reloadData];
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
    [contentView release]; contentView = nil;
    banner.delegate = nil;
    [banner release]; banner = nil; 
    [super dealloc];
}


#pragma mark -
#pragma mark iAdd stuff

-(void)createADBannerView {
	NSString *contentSize;
	if (&ADBannerContentSizeIdentifierPortrait != nil) {
		contentSize = ADBannerContentSizeIdentifierPortrait;
	} else {
		contentSize = ADBannerContentSizeIdentifier320x50;
    }
	
    CGRect frame;
    frame.size = [ADBannerView sizeFromBannerContentSizeIdentifier:contentSize];
    frame.origin = CGPointMake(0.0f, CGRectGetMaxY(self.view.bounds));
    
    ADBannerView *bannerView = [[ADBannerView alloc] initWithFrame:frame];
    bannerView.delegate = self;
    bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    
	bannerView.requiredContentSizeIdentifiers = (&ADBannerContentSizeIdentifierPortrait != nil) ?
    [NSSet setWithObjects:ADBannerContentSizeIdentifierPortrait, nil] : 
    [NSSet setWithObjects:ADBannerContentSizeIdentifier320x50, nil];
    
    [self.view addSubview:bannerView];
    self.banner = bannerView;
    [bannerView release];
}

-(void)layoutForCurrentOrientation:(BOOL)animated {
    CGFloat animationDuration = animated ? 0.2f : 0.0f;
    CGRect contentFrame = self.view.bounds;
	CGPoint bannerOrigin = CGPointMake(CGRectGetMinX(contentFrame), CGRectGetMaxY(contentFrame));
    CGFloat bannerHeight = 0.0f;
    
    CGRect tableFrame = self.tv.frame;
    CGFloat fullViewHeight = self.view.frame.size.height;
    
    banner.currentContentSizeIdentifier = (&ADBannerContentSizeIdentifierPortrait != nil) ? ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifier320x50; 
    bannerHeight = banner.bounds.size.height; 
	
    if(banner.bannerLoaded) {
        contentFrame.size.height -= bannerHeight;
		bannerOrigin.y -= bannerHeight;
        tableFrame.size.height = fullViewHeight - bannerHeight;
    } else {
		bannerOrigin.y += bannerHeight;
        tableFrame.size.height = fullViewHeight;
    }
    self.tv.frame = tableFrame;
    
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         contentView.frame = contentFrame;
                         [contentView layoutIfNeeded];
                         banner.frame = CGRectMake(bannerOrigin.x, bannerOrigin.y, banner.frame.size.width, banner.frame.size.height);
                     }];
}


#pragma mark ADBannerViewDelegate methods

-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self layoutForCurrentOrientation:YES];
}

-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self layoutForCurrentOrientation:YES];
}

-(BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

-(void)bannerViewActionDidFinish:(ADBannerView *)banner
{
}


@end

