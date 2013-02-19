//
//  DataProvider.h
//  Groceries
//
//  Created by Jon Pedersen on 15/02/11.
//  Copyright 2011 jApps. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RootViewController;


@interface DataProvider : NSObject {
	RootViewController *controller;
}

@property(nonatomic,retain)RootViewController *controller;
- (void)addDefaultData;
@end
