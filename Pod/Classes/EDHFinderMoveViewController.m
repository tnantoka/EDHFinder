//
//  EDHFinderMoveViewController.m
//  EDHFinder
//
//  Created by Tatsuya Tobioka on 10/2/14.
//  Copyright (c) 2014 tnantoka. All rights reserved.
//

#import "EDHFinderMoveViewController.h"

#import "EDHFinder.h"

@interface EDHFinderMoveViewController () <EDHFinderListViewControllerDelegate>

@property (nonatomic) EDHFinderItem *item;

@property (nonatomic) UIBarButtonItem *cancelItem;
@property (nonatomic) UIBarButtonItem *doneItem;

@end

@implementation EDHFinderMoveViewController

- (id)initWithItem:(EDHFinderItem *)item {
    EDHFinderListViewController *listController = [[EDHFinder sharedFinder] listViewControllerWithDelegate:self];
    listController.title = NSLocalizedString(@"Move", nil);
    listController.navigationItem.prompt = [item relativePath];

    self.cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelItemDidTap:)];
    listController.navigationItem.leftBarButtonItem = self.cancelItem;
    
    self.doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneItemDidTap:)];
    listController.navigationItem.rightBarButtonItem = self.doneItem;
    
    if (self = [super initWithRootViewController:listController]) {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        self.item = [[EDHFinderItem alloc] initWithPath:listController.item.path];
        listController.navigationItem.prompt = [self.item relativePath];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

# pragma mark - EDHFinderListViewControllerDelegate

- (void)listViewController:(EDHFinderListViewController *)controller didMoveToDirectory:(EDHFinderItem *)item {
    [self selectItem:item withController:controller];
}

- (void)listViewController:(EDHFinderListViewController *)controller didBackToDirectory:(EDHFinderItem *)item {
    [self selectItem:item withController:controller];
}

# pragma mark - Actions

- (void)cancelItemDidTap:(id)sender {
    [self close];
}

- (void)doneItemDidTap:(id)sender {
    NSLog(@"%@", self.doneHandler);
    [self close];
    self.doneHandler(self.item);
}

# pragma mark - Utilities

- (void)close {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectItem:(EDHFinderItem *)item withController:(EDHFinderListViewController *)controller {
    self.item = item;
    //controller.navigationItem.leftBarButtonItem = self.cancelItem;
    controller.navigationItem.rightBarButtonItem = self.doneItem;
    controller.navigationItem.prompt = [self.item relativePath];
}

@end
