//
//  Item.h
//  Groceries
//
//  Created by Jon Pedersen on 26/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Event;

@interface Item :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * checked;
@property (nonatomic, retain) NSNumber * onShoppingList;
@property (nonatomic, retain) NSString * sortBy;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* events;

@end


@interface Item (CoreDataGeneratedAccessors)
- (void)addEventsObject:(Event *)value;
- (void)removeEventsObject:(Event *)value;
- (void)addEvents:(NSSet *)value;
- (void)removeEvents:(NSSet *)value;


@end

