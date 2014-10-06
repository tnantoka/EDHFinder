//
//  EDHFinder.m
//  EDHFinder
//
//  Created by Tatsuya Tobioka on 10/1/14.
//  Copyright (c) 2014 tnantoka. All rights reserved.
//

#import "EDHFinder.h"

#import "FCFileManager.h"

@implementation EDHFinder

static EDHFinder *sharedInstance = nil;

+ (instancetype)sharedFinder {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        if (!sharedInstance) {
            sharedInstance = [[self alloc] init];
        }
    });
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        self.rootPath = [FCFileManager pathForDocumentsDirectory];
        self.iconColor = [UIColor grayColor];
        self.toolbarHidden = YES;
    }
    return self;
}

- (UINavigationController *)listNavigationController {
    return [self listNavigationControllerWithDelegate:nil];
}

- (EDHFinderListViewController *)listViewController {
    return [self listViewControllerWithDelegate:nil];
}

- (UINavigationController *)listNavigationControllerWithDelegate:(id<EDHFinderListViewControllerDelegate>)delegate {
    return [[UINavigationController alloc] initWithRootViewController:[self listViewControllerWithDelegate:delegate]];
}

- (EDHFinderListViewController *)listViewControllerWithDelegate:(id<EDHFinderListViewControllerDelegate>)delegate {
    return  [[EDHFinderListViewController alloc] initWithPath:self.rootPath delegate:delegate];
}

- (EDHFinderItem *)rootItem {
    return [[EDHFinderItem alloc] initWithPath:self.rootPath];
}

- (NSString *)relativePathFromRoot:(NSString *)path {
    NSString *relativePath = [path stringByReplacingOccurrencesOfString:self.rootPath withString:@""];
    if (relativePath.length < 1) {
        relativePath = @"/";
    }
    return relativePath;
}

- (NSString *)identifier {
    return @"com.bornneet.EDHFinder";
}

# pragma mark - Utilities

- (void)showErrorWithMessage:(NSString *)message controller:(UIViewController *)controller {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }]];
    
    [controller presentViewController:alertController animated:YES completion:nil];
}

@end
