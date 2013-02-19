//
//  GroceriesAppDelegate.h
//  Groceries
//
//  Created by Jon Pedersen on 14/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
@class RootViewController;

@interface GroceriesAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
    UINavigationController *groceriesNavigationController;
    UITabBarController *tabBarController;
	NSMutableArray *shoppingList;
	NSDate *latestShoppingListGeneratedAt;

@private
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

@property(nonatomic,retain) NSDate *latestShoppingListGeneratedAt;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UINavigationController *groceriesNavigationController;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) NSMutableArray *shoppingList;

- (NSURL *)applicationDocumentsDirectory;
- (void)saveContext;
- (RootViewController *)rootViewController;
- (void)sortShoppingList;
- (void)clearShoppingList;
- (BOOL)canCheckItems;

@end

