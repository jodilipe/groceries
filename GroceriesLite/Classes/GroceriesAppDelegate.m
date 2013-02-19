//
//  GroceriesAppDelegate.m
//  Groceries
//
//  Created by Jon Pedersen on 14/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import "GroceriesAppDelegate.h"
#import "RootViewController.h"
#import "GroceriesViewController.h"
#import "Item.h"
#import "Event.h"

@implementation GroceriesAppDelegate

static int const MAX_METERS_FROM_CURRENT_LOCATION = 150;
static long const MIN_SECS_BEFORE_EDIT_AFTER_LIST_GENERATE = 60;

@synthesize window;
@synthesize navigationController;
@synthesize groceriesNavigationController;
@synthesize tabBarController;
@synthesize shoppingList;
@synthesize latestShoppingListGeneratedAt;

#pragma mark -
#pragma mark Shopping list stuff

- (BOOL)canCheckItems {
	if (latestShoppingListGeneratedAt) {
		long now = [[NSDate date] timeIntervalSince1970];
		long lastListGenerate = [latestShoppingListGeneratedAt timeIntervalSince1970];
		return (lastListGenerate + MIN_SECS_BEFORE_EDIT_AFTER_LIST_GENERATE) < now;
	}
	return YES;
}

- (void)sortShoppingList {
	NSSortDescriptor *sortBySortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"sortBy" ascending:YES] autorelease];
	NSSortDescriptor *nameSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]  autorelease];
	NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortBySortDescriptor, nameSortDescriptor, nil] autorelease];

	NSArray *sortedItems = [self.shoppingList sortedArrayUsingDescriptors:sortDescriptors];
	self.shoppingList = nil;
	self.shoppingList = [NSMutableArray array];
	for (Item *item in sortedItems) {
		if (![self.shoppingList containsObject:item]) {
			[self.shoppingList addObject:item];
		}
	}		
}

-(void)clearShoppingList {
	for (Item *item in shoppingList) {
		item.onShoppingList = [NSNumber numberWithBool:NO];
		item.checked = [NSNumber numberWithBool:NO];
	}
	self.shoppingList = nil;
	self.shoppingList = [NSMutableArray array];
}

- (RootViewController *)rootViewController {
	return (RootViewController *)[navigationController topViewController];
}

#pragma mark -
#pragma mark Application lifecycle

- (void)awakeFromNib {    
    RootViewController *rootViewController = (RootViewController *)[navigationController topViewController];
    rootViewController.managedObjectContext = self.managedObjectContext;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	self.shoppingList = [NSMutableArray array];
	[self.window addSubview:tabBarController.view];
	[self.window makeKeyAndVisible];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveContext];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
}


/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}


- (void)saveContext {
    
    NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
        } 
    }
}    


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Groceries" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Groceries.sqlite"];
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
    }    
    
    return persistentStoreCoordinator_;
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
	[latestShoppingListGeneratedAt release];

    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
    
    [navigationController release];
	[tabBarController release];
    [window release];
    [super dealloc];
}


@end

