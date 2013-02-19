//
//  RootViewController.h
//  Groceries
//
//  Created by Jon Pedersen on 14/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <iAd/iAd.h>
@class Item;
@class Event;

@interface RootViewController : UIViewController <NSFetchedResultsControllerDelegate, UISearchDisplayDelegate, UISearchBarDelegate, ADBannerViewDelegate> {
    
    UIView *contentView;
    ADBannerView *banner;
    
    IBOutlet UITableView *tv;
    NSString *lastSearchString;

@private
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;
	NSMutableArray	*searchResults;
}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet ADBannerView *banner;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, retain) UITableView *tv;
@property (nonatomic, retain) NSString *lastSearchString;

-(void)saveContext;
-(void)insertNewObject:(NSString *) name;
-(void)insertNewObject:(NSString *) name sortBy:(NSString *) sortBy;
-(void)insertNewObject:(NSString *) name defaultEventsWithHours:(int) hours sortBy:(NSString *) sortBy;
-(NSMutableArray *)shoppingList;
-(void)insertNewEvent:(Item *)item checkedAt:(NSDate *) date;
-(void)toggleOnShoppingList:(Item *)item;
-(int)suggestNewList;
-(NSDate*)latestEventDate:(Item *)item;
-(void)addToShoppingList:(Item *)item;
-(void)removeFromShoppingList:(Item *)item;
-(long)getAverageSeconds:(Item *)item;
-(int)getAverageHours:(Item *)item;
-(NSDate *)getBuyAt:(Item *)item;
-(void)refreshSearch;

@end
