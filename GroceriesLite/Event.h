//
//  Event.h
//  Groceries
//
//  Created by Jon Pedersen on 26/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Item;

@interface Event :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * checkedAt;
@property (nonatomic, retain) Item * item;

@end



