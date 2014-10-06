//
//  EDHFinder.h
//  EDHFinder
//
//  Created by Tatsuya Tobioka on 10/1/14.
//  Copyright (c) 2014 tnantoka. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EDHFinderListViewController.h"
#import "EDHFinderItem.h"

@interface EDHFinder : NSObject

@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, copy) UIColor *iconColor;
@property (nonatomic) BOOL toolbarHidden;


+ (instancetype)sharedFinder;

- (UINavigationController *)listNavigationController;
- (EDHFinderListViewController *)listViewController;

- (UINavigationController *)listNavigationControllerWithDelegate:(id<EDHFinderListViewControllerDelegate>)delegate;
- (EDHFinderListViewController *)listViewControllerWithDelegate:(id<EDHFinderListViewControllerDelegate>)delegate;

- (EDHFinderItem *)rootItem;

- (NSString *)relativePathFromRoot:(NSString *)path;

- (void)showErrorWithMessage:(NSString *)message controller:(UIViewController *)controller;

- (NSString *)identifier;

@end
