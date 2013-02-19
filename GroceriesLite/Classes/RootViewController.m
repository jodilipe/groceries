//
//  RootViewController.m
//  Groceries
//
//  Created by Jon Pedersen on 14/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import "RootViewController.h"
#import "Item.h"
#import "Event.h"
#import "EditViewController.h"
#import "DataProvider.h"
#import "GroceriesAppDelegate.h"

@interface RootViewController ()
- (void)configureCell:(UITableViewCell *)cell withItem:(Item *)item atIndexPath:(NSIndexPath *)indexPath;
-(void)layoutForCurrentOrientation:(BOOL)animated;
-(void)createADBannerView;
@end


@implementation RootViewController
static BOOL const GENERATE_DEFAULT_EVENTS = NO;
static int const MIN_NO_OF_EVENTS_FOR_AVG = 2;
static int const MAX_ITEMS_DA = 205;
static int const MAX_ITEMS_US = 135;

@synthesize fetchedResultsController=fetchedResultsController_, managedObjectContext=managedObjectContext_;
@synthesize searchResults;
@synthesize lastSearchString;
@synthesize tv;
@synthesize contentView, banner;


- (void)saveContext {
	// Save the context.
	NSError *error = nil;
	if (![[self.fetchedResultsController managedObjectContext] save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//		abort();
	}
}

- (void)delete:(NSManagedObject*) managedObject {
	NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
	[context deleteObject:managedObject];
	[self saveContext];
}

- (NSMutableArray *)shoppingList {
	GroceriesAppDelegate *mainDelegate = (GroceriesAppDelegate*)[[UIApplication sharedApplication]delegate];
	NSMutableArray *shoppingList = [mainDelegate shoppingList];
	return shoppingList;
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)performSearch:(NSString *)searchText {
    if (!searchText) {
        searchText = lastSearchString;
    } else {
        self.lastSearchString = searchText;
    }
	[self.searchResults removeAllObjects];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:[self managedObjectContext]];
	[request setEntity:entity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE[cd] %@", [NSString stringWithFormat:@"*%@*", searchText]];
	[request setPredicate:predicate];
	NSError *error = nil;
	NSArray *items = [[self managedObjectContext] executeFetchRequest:request error:&error];
	if (items) {
		for (Item *item in items) {
			[self.searchResults addObject:item];
		}
	}
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)refreshSearch {
    if (lastSearchString) {
        [self performSearch:nil];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self performSearch:searchText];
}

#pragma mark -
#pragma mark Guess new shopping list

-(long)getAverageSeconds:(Item *)item {
	if ([item.events count] >= MIN_NO_OF_EVENTS_FOR_AVG) {
		long timeDiffSum = 0;
		NSDate *previousDate = nil;
		NSSortDescriptor *sorter = [[[NSSortDescriptor alloc] initWithKey:@"checkedAt" ascending:NO] autorelease]; 
		NSArray *sortedEvents = [[item.events allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
		for (Event *event in sortedEvents) {
			if (previousDate) {
				timeDiffSum += [previousDate timeIntervalSince1970] - [event.checkedAt timeIntervalSince1970];
			}				
			previousDate = event.checkedAt;
		}
		return timeDiffSum / ([item.events count] - 1);
	}
	return 0;
}

-(int)getAverageHours:(Item *)item {
	long avgSecs = [self getAverageSeconds:item];
	if (avgSecs > 0) {
		return avgSecs / 60 / 60;
	}
	return 0;
}

-(NSDate *)getBuyAt:(Item *)item {
	long avgSecs = [self getAverageSeconds:item];
	if (avgSecs > 0) {
		NSDate *latestEventDate = [self latestEventDate:item];
		long latestEventSecs = [latestEventDate timeIntervalSince1970];
		long secs = latestEventSecs + avgSecs;
		return [NSDate dateWithTimeIntervalSince1970:secs];
	}
	return nil;
}

-(int) suggestNewList {
	int itemsAdded = 0;
	for (Item *item in self.fetchedResultsController.fetchedObjects) {
		BOOL onShoppingList = [item.onShoppingList boolValue];
		if (!onShoppingList && [item.events count] >= MIN_NO_OF_EVENTS_FOR_AVG) {
			long timeDiffSum = 0;
			long timeSinceLastCheck = 0;
			NSDate *previousDate = nil;
			NSSortDescriptor *sorter = [[[NSSortDescriptor alloc] initWithKey:@"checkedAt" ascending:NO] autorelease]; 
			NSArray *sortedEvents = [[item.events allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sorter]];
			for (Event *event in sortedEvents) {
				if (!previousDate) {
					timeSinceLastCheck += [[NSDate date] timeIntervalSince1970] - [event.checkedAt timeIntervalSince1970];
				} else {
					timeDiffSum += [previousDate timeIntervalSince1970] - [event.checkedAt timeIntervalSince1970];
				}				
				previousDate = event.checkedAt;
			}
			int avgHours = timeDiffSum / 60 / 60 / ([item.events count] + 1);
			int hoursSinceLastCheck = timeSinceLastCheck / 60 / 60;
			if (hoursSinceLastCheck >= avgHours) {
				[self addToShoppingList:item];
				itemsAdded++;
			}
		}
	}
	if (itemsAdded > 0) {
		GroceriesAppDelegate *mainDelegate = (GroceriesAppDelegate*)[[UIApplication sharedApplication]delegate];
		mainDelegate.latestShoppingListGeneratedAt = [NSDate date];
		[self saveContext];
		[self.tv reloadData];
	}
	return itemsAdded;
}


#pragma mark -
#pragma mark Event stuff

- (void) insertNewEvent:(Item *)item checkedAt:(NSDate *) date {
	Event *newEvent = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
	[item addEventsObject:newEvent];
	newEvent.checkedAt = date;
	newEvent.item = item;
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

#pragma mark -
#pragma mark View lifecycle

- (BOOL)noItems {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:[self managedObjectContext]];
	[request setEntity:entity];
	NSError *error = nil;
	NSArray *items = [[self managedObjectContext] executeFetchRequest:request error:&error];
	if (items && [items count] > 0) {
		return NO;
	} else {
		return YES;
	}

}

- (void)viewDidLoad {
    [super viewDidLoad];
		
    if(banner == nil) {
        [self createADBannerView];
    }
    [self layoutForCurrentOrientation:NO];

	[NSFetchedResultsController deleteCacheWithName:nil];

	self.searchResults = [[NSMutableArray alloc] init];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	self.navigationItem.title = NSLocalizedString(@"Title", "Application title");
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(editNewObject)];
    self.navigationItem.rightBarButtonItem = addButton;
    [addButton release];

	if ([self noItems]) {
		DataProvider *dataProvider = [DataProvider alloc];
		dataProvider.controller = self;
		[dataProvider addDefaultData];
		[dataProvider release];
	}

	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:[self managedObjectContext]];
	[request setEntity:entity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"onShoppingList == %@", [NSNumber numberWithBool:YES]];
	[request setPredicate:predicate];
	NSError *error = nil;
	NSArray *items = [[self managedObjectContext] executeFetchRequest:request error:&error];
	if (items) {
		for (Item *item in items) {
			[self addToShoppingList:item];
		}
	}
}


// Implement viewWillAppear: to do additional setup before the view is presented.
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self layoutForCurrentOrientation:NO];

	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
	self.tv.separatorColor = [UIColor blueColor];
	self.tv.backgroundColor = [UIColor clearColor];
}


- (void)configureCell:(UITableViewCell *)cell withItem:(Item *)item atIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.text = item.name;
	NSDate *checkedAt = [self latestEventDate:item];
	if (checkedAt) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init]; 
		[dateFormatter setDateStyle:NSDateFormatterLongStyle]; 
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		
		cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Purchased by",@"Purchased by"), [dateFormatter stringFromDate: checkedAt]];
		[dateFormatter release];
	} else {
		cell.detailTextLabel.text = NSLocalizedString(@"Never purchased",@"Never purchased");
	}
	BOOL onShoppingList = [item.onShoppingList boolValue];
	if (onShoppingList) {
		cell.textLabel.textColor = [UIColor lightGrayColor];
		cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:19];
		cell.detailTextLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:11];
		cell.detailTextLabel.textColor = [UIColor lightGrayColor];
	} else {
		cell.textLabel.textColor = [UIColor blackColor];
		cell.textLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:19];
		cell.detailTextLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:11];
		cell.detailTextLabel.textColor = [UIColor darkGrayColor];
	}
	cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
}


#pragma mark -
#pragma mark Add a new object

- (Item *)createNewObject {
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    Item *item = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
	item.sortBy = @"1";
	return item;
}

- (void)insertNewObject:(NSString *) name defaultEventsWithHours:(int) hours sortBy:(NSString *) sortBy {
	Item *item = [self createNewObject];
	item.name = name;
	if (GENERATE_DEFAULT_EVENTS && hours > 0) {
		NSTimeInterval hoursAsTimeInterval = (hours * 60 * 60) * -1;
		[self insertNewEvent:item checkedAt:[[NSDate date] dateByAddingTimeInterval:hoursAsTimeInterval]];
		[self insertNewEvent:item checkedAt:[[NSDate date] dateByAddingTimeInterval:hoursAsTimeInterval * 2]];
		[self insertNewEvent:item checkedAt:[[NSDate date] dateByAddingTimeInterval:hoursAsTimeInterval * 3]];
	}
	item.sortBy = sortBy;
	[self saveContext];
}

- (void)insertNewObject:(NSString *) name {
	[self insertNewObject:name defaultEventsWithHours:0 sortBy:@"Z"];
}

- (void)insertNewObject:(NSString *) name sortBy:(NSString *) sortBy {
	[self insertNewObject:name defaultEventsWithHours:0 sortBy:sortBy];
}

- (void)pushEditViewController:(Item*) item {
	EditViewController *editViewController = [[EditViewController alloc] initWithNibName:@"EditViewController" bundle:nil];
	editViewController.item = item;
	editViewController.rootViewController = self;
	if (item.name) {
		editViewController.title = item.name;
	} else {
		editViewController.title = NSLocalizedString(@"New item",@"New item");
	}

	[self.navigationController pushViewController:editViewController animated:YES];
	[editViewController release];
}

- (void)editNewObject {
    int maxItems = 0;
	NSLocale *locale = [NSLocale currentLocale];
	if ([@"da_DK" isEqualToString:[locale localeIdentifier]]) {
        maxItems = MAX_ITEMS_DA;
    } else {
        maxItems = MAX_ITEMS_US;
    }
    if ([self.fetchedResultsController.fetchedObjects count] >= maxItems) {
		NSString *clearTitle = NSLocalizedString(@"Maximum number of Grocery Items exceeded",@"Max exceeded title");
		NSString *clearMessage = NSLocalizedString(@"Delete/Edit existing Items or buy the full, Add free Version and get unlimited number of Grocery Items",@"Buy full version");
		NSString *clearOK = NSLocalizedString(@"Dismiss",@"OK action");
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:clearTitle message:clearMessage
													   delegate:self cancelButtonTitle:clearOK otherButtonTitles:nil];
		[alert show];
		[alert release];
    } else {
        Item *item = [self createNewObject];
        [self addToShoppingList:item];
        [self pushEditViewController:item];
	}
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    // Prevent new objects being added when in editing mode.
    [super setEditing:(BOOL)editing animated:(BOOL)animated];
    self.navigationItem.rightBarButtonItem.enabled = !editing;
    [self.tv setEditing:editing animated:animated];
	[self.tv reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		return nil;
	} else {
		id <NSFetchedResultsSectionInfo> theSection = [[fetchedResultsController_ sections] objectAtIndex:section];
		return [theSection name];
	}

}
	
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		return 1;
	} else {
		return [[self.fetchedResultsController sections] count];
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		return [self.searchResults count];
	} else {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
		return [sectionInfo numberOfObjects];
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    Item *item = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		item = [self.searchResults objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	} else {
		item = [self.fetchedResultsController objectAtIndexPath:indexPath];
	}
    [self configureCell:cell withItem:item atIndexPath:indexPath];
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Detemine if it's in editing mode
    if (self.editing) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
        }
    }   
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // The table view should not be re-orderable.
    return NO;
}

#pragma mark -
#pragma mark Table view delegate

- (void)addToShoppingList:(Item *)item {
	if (![[self shoppingList] containsObject:item]) {
		item.onShoppingList = [NSNumber numberWithBool:YES];
		[[self shoppingList] addObject:item];
	}
}

- (void)removeFromShoppingList:(Item *)item {
	item.onShoppingList = [NSNumber numberWithBool:NO];
	[[self shoppingList] removeObject:item];
}

- (void)toggleOnShoppingList:(Item *)item {
	BOOL onShoppingList = [item.onShoppingList boolValue];
	if (onShoppingList) {
        BOOL checked = [item.checked boolValue];
        if (checked) {
            item.checked = [NSNumber numberWithBool:NO];
        }
		[self removeFromShoppingList:item];
	} else {
		[self addToShoppingList:item];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Item *item = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		item = [self.searchResults objectAtIndex:indexPath.row];
	} else {
		item = [self.fetchedResultsController objectAtIndexPath:indexPath];
	}
	if(YES == self.editing) {
		[self pushEditViewController:item];
	} else {
		[self toggleOnShoppingList:item];
		[self saveContext];
		[tableView reloadData];
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	if (tableView == self.searchDisplayController.searchResultsTableView) {
		Item *item = [self.searchResults objectAtIndex:indexPath.row];
        [self pushEditViewController:item];
    }
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
    
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Item" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortBySortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortBy" ascending:YES];
    NSSortDescriptor *nameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortBySortDescriptor, nameSortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"sortBy" cacheName:@"Root"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortBySortDescriptor release];
    [nameSortDescriptor release];
    [sortDescriptors release];
    
    NSError *error = nil;
    if (![fetchedResultsController_ performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
    }
    
    return fetchedResultsController_;
}    


#pragma mark -
#pragma mark Fetched results controller delegate


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tv beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tv insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tv deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tv;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] withItem:[self.fetchedResultsController objectAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tv endUpdates];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


- (void)viewDidUnload {
    self.contentView = nil;
    banner.delegate = nil;
    self.banner = nil;
}


- (void)dealloc {
    [contentView release]; contentView = nil;
    banner.delegate = nil;
    [banner release]; banner = nil; 
    [fetchedResultsController_ release];
    [managedObjectContext_ release];
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

