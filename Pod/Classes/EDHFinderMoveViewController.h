//
//  EDHFinderMoveViewController.h
//  EDHFinder
//
//  Created by Tatsuya Tobioka on 10/2/14.
//  Copyright (c) 2014 tnantoka. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EDHFinderMoveViewControllerDelegate;
@class EDHFinderItem;

@interface EDHFinderMoveViewController : UINavigationController

@property (nonatomic, copy) void (^doneHandler)(EDHFinderItem *);

- (id)initWithItem:(EDHFinderItem *)item;

@end
