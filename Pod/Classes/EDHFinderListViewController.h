//
//  EDHFinderListViewController.h
//  EDHFinder
//
//  Created by Tatsuya Tobioka on 10/1/14.
//  Copyright (c) 2014 tnantoka. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EDHFinderListViewControllerDelegate;
@class EDHFinderItem;

@interface EDHFinderListViewController : UITableViewController

@property (nonatomic, weak) id<EDHFinderListViewControllerDelegate> listDelegate;
@property (nonatomic) EDHFinderItem *item;

- (id)initWithPath:(NSString *)path delegate:(id<EDHFinderListViewControllerDelegate>)delegate;
- (id)initWithItem:(EDHFinderItem *)item delegate:(id<EDHFinderListViewControllerDelegate>)delegate;

@end


@protocol EDHFinderListViewControllerDelegate <NSObject>

@optional

- (void)listViewController:(EDHFinderListViewController *)controller didSelectFile:(EDHFinderItem *)item;
- (void)listViewController:(EDHFinderListViewController *)controller didDestroyFile:(EDHFinderItem *)item;
- (void)listViewController:(EDHFinderListViewController *)controller didMoveToDirectory:(EDHFinderItem *)item;
- (void)listViewController:(EDHFinderListViewController *)controller didBackToDirectory:(EDHFinderItem *)item;

@end