//
//  EDHFinderListViewController.m
//  EDHFinder
//
//  Created by Tatsuya Tobioka on 10/1/14.
//  Copyright (c) 2014 tnantoka. All rights reserved.
//

#import "EDHFinderListViewController.h"

#import "EDHFinder.h"
#import "EDHFinderMoveViewController.h"
#import "EDHUtility.h"

#import "FCFileManager.h"
#import <FontAwesomeKit/FontAwesomeKit.h>
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"

static NSString * const reuseIdentifier = @"reuseIdentifier";

static const CGFloat kIconSize = 32.0f;

typedef NS_ENUM(NSUInteger, EDHFinderListViewControllerCreateType) {
    EDHFinderListViewControllerCreateTypeFile,
    EDHFinderListViewControllerCreateTypeDirectory,
    EDHFinderListViewControllerCreateTypeDownload,
};

@interface EDHFinderListViewController () <MGSwipeTableCellDelegate>

@property (nonatomic) NSMutableArray *items;

@end

@implementation EDHFinderListViewController

- (id)initWithPath:(NSString *)path delegate:(id<EDHFinderListViewControllerDelegate>)delegate {
    EDHFinderItem *item = [[EDHFinderItem alloc] initWithPath:path];
    return [self initWithItem:item delegate:delegate];
}

- (id)initWithItem:(EDHFinderItem *)item delegate:(id<EDHFinderListViewControllerDelegate>)delegate {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.item = item;
        self.listDelegate = delegate;
        
        self.title = [[EDHFinder sharedFinder] relativePathFromRoot:self.item.name];
        
        UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItemDidTap:)];
        self.navigationItem.rightBarButtonItem = addItem;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    if (![EDHFinder sharedFinder].toolbarHidden) {
        [self.navigationController setToolbarHidden:NO animated:YES];        
    }

    CGRect pathFrame = self.navigationController.toolbar.bounds;
    pathFrame.size.width -= 10.0f; // Padding * 2
    UILabel *pathLabel = [[UILabel alloc] initWithFrame:pathFrame];
    pathLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    pathLabel.text = [self.item relativePath];
    pathLabel.textAlignment = NSTextAlignmentCenter;
    pathLabel.textColor = [UIToolbar appearance].tintColor;
    UIBarButtonItem *pathItem = [[UIBarButtonItem alloc] initWithCustomView:pathLabel];
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = @[flexibleItem, pathItem, flexibleItem];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlDidChange:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self loadItems];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        EDHFinderListViewController *parentController = (EDHFinderListViewController *)self.navigationController.viewControllers.lastObject;
        EDHFinderItem *item = parentController.item;
        if ([self.listDelegate respondsToSelector:@selector(listViewController:didBackToDirectory:)]) {
            [self.listDelegate listViewController:parentController didBackToDirectory:item];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

# pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MGSwipeTableCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[MGSwipeTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
        //cell.accessoryType = UITableViewCellAccessoryDetailButton;
        //cell.tintColor = [EDHFinder sharedFinder].iconColor;
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        EDHFinderItem *item = [self itemAtIndexPath:indexPath];
        
        NSString *title = [NSString stringWithFormat:[EDHUtility localizedString:@"Delete %@" withScope:EDHFinderPodName], item.name];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:[EDHUtility localizedString:@"Are you sure?" withScope:EDHFinderPodName] preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"OK" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [item destroy:^{
                [self removeItem:item atIndexPath:indexPath];
                if ([self.listDelegate respondsToSelector:@selector(listViewController:didDestroyFile:)]) {
                    [self.listDelegate listViewController:self didDestroyFile:item];
                }
                if ([self.listDelegate respondsToSelector:@selector(listViewController:didBackToDirectory:)]) {
                    [self.listDelegate listViewController:self didBackToDirectory:self.item];
                }
            } failure:^(NSError *error) {
                [EDHUtility showErrorWithMessage:error.localizedDescription controller:self];
            }];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Cancel" withScope:EDHFinderPodName] style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

# pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EDHFinderItem *item = [self itemAtIndexPath:indexPath];

    if (item.isDirectory) {
        EDHFinderListViewController *nextController = [[[self class] alloc] initWithPath:item.path delegate:self.listDelegate];
        [self.navigationController pushViewController:nextController animated:YES];
        if ([self.listDelegate respondsToSelector:@selector(listViewController:didMoveToDirectory:)]) {
            [self.listDelegate listViewController:nextController didMoveToDirectory:item];
        }
    } else {
        if ([self.listDelegate respondsToSelector:@selector(listViewController:didSelectFile:)]) {
            [self.listDelegate listViewController:self didSelectFile:item];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    EDHFinderItem *item = [self itemAtIndexPath:indexPath];
    NSLog(@"%@", item.name);
}

# pragma mark - MGSwipeTableCellDelegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion {

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    switch (index) {
        case 0:
            [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
            break;
        case 1: {
            EDHFinderItem *item = [self itemAtIndexPath:indexPath];

            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[EDHUtility localizedString:@"Action" withScope:EDHFinderPodName] message:item.name preferredStyle:UIAlertControllerStyleActionSheet];
            
            [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Rename" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self renameItem:item atIndexPath:indexPath];
            }]];
            
            [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Duplicate" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [item duplicate:^(EDHFinderItem *newItem) {
                    [self insertItem:newItem atIndex:0];
                } failure:^(NSError *error) {
                    [EDHUtility showErrorWithMessage:error.localizedDescription controller:self];
                }];
            }]];
            
            [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Compress" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                UIAlertController *alertPasswordController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please enter password", nil)                                                                            message:@""
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                [alertPasswordController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.secureTextEntry = YES;
                }];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSString *pwdTmp = [[[alertPasswordController textFields] firstObject] text] == nil ? @"": [[[alertPasswordController textFields] firstObject] text];
                    //NSLog(@"Current password ->%@<-", pwdTmp);
                    [item compressWithPassword:pwdTmp success:^(EDHFinderItem *newItem) {
                        [self insertItem:newItem atIndex:0];
                    } failure:^(NSError *error) {
                        [EDHUtility showErrorWithMessage:error.localizedDescription controller:self];
                    }];
                }];
                [alertPasswordController addAction:okAction];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                [alertPasswordController addAction:cancelAction];
                [self presentViewController:alertPasswordController animated:YES completion:nil];
            }]];
            
            [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Uncompress" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                UIAlertController *alertPasswordController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please enter password", nil)                                                                            message:@""
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                [alertPasswordController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.secureTextEntry = YES;
                }];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSString *pwdTmp = [[[alertPasswordController textFields] firstObject] text] == nil ? @"": [[[alertPasswordController textFields] firstObject] text];
                    //NSLog(@"Current password %@", [[alertController textFields][0] text]);
                    //NSLog(@"Current password ->%@<-", pwdTmp);
                    [item uncompressWithPassword:pwdTmp success:^(EDHFinderItem *newItem) {
                        [self insertItem:newItem atIndex:0];
                    } failure:^(NSError *error) {
                        [EDHUtility showErrorWithMessage:error.localizedDescription controller:self];
                    }];
                }];
                [alertPasswordController addAction:okAction];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                [alertPasswordController addAction:cancelAction];
                [self presentViewController:alertPasswordController animated:YES completion:nil];
            }]];

            [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Move" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                EDHFinderMoveViewController *moveController = [[EDHFinderMoveViewController alloc] initWithItem:item];
                moveController.doneHandler = ^(EDHFinderItem *toItem) {
                    [item moveTo:toItem success:^{
                        [self removeItem:item atIndexPath:indexPath];
                    } failure:^(NSError *error) {
                        [EDHUtility showErrorWithMessage:error.localizedDescription controller:self];
                    }];
                };
                [self presentViewController:moveController animated:YES completion:nil];
            }]];
            
            [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Share" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                UIActivityViewController *shareActivityController = [[UIActivityViewController alloc] initWithActivityItems:@[item.fileURL] applicationActivities:nil];
                [self presentViewController:shareActivityController animated:YES completion:nil];
            }]];
            
            [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Cancel" withScope:EDHFinderPodName] style:UIAlertActionStyleCancel handler:nil]];
            
            alertController.popoverPresentationController.sourceView = self.view;
            alertController.popoverPresentationController.sourceRect = cell.frame;
            
            [self presentViewController:alertController animated:YES completion:nil];
            break;
        }
    }
    
    return YES;
}

# pragma mark - Actions

- (void)addItemDidTap:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[EDHUtility localizedString:@"New" withScope:EDHFinderPodName] message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"File" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self create:EDHFinderListViewControllerCreateTypeFile];
    }]];

    [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Directory" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self create:EDHFinderListViewControllerCreateTypeDirectory];
    }]];

    [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Download" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self create:EDHFinderListViewControllerCreateTypeDownload];
    }]];

    [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Cancel" withScope:EDHFinderPodName] style:UIAlertActionStyleCancel handler:nil]];

    alertController.popoverPresentationController.barButtonItem = sender;
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)refreshControlDidChange:(id)sender {
    [self loadItems];
}

# pragma mark - Utilities

- (void)loadItems {
    [self.refreshControl beginRefreshing];

    self.items = [self.item children];
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)configureCell:(MGSwipeTableCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    EDHFinderItem *item = [self itemAtIndexPath:indexPath];
    cell.textLabel.text = item.name;

    FAKIonIcons *icon;
    if (item.isDirectory) {
        icon = [FAKIonIcons iosFolderIconWithSize:kIconSize];
    } else {
        icon = [FAKIonIcons documentIconWithSize:kIconSize];
    }
    [icon addAttribute:NSForegroundColorAttributeName value:[EDHFinder sharedFinder].iconColor];
    UIImage *image = [icon imageWithSize:CGSizeMake(kIconSize, kIconSize)];
    cell.imageView.image = image;
    
    if (item.isFile) {
        NSString *formateFileSize = [NSByteCountFormatter stringFromByteCount:item.fileSize.longLongValue countStyle:NSByteCountFormatterCountStyleFile];
        NSString *detailText = [NSString stringWithFormat:@"%@, %@",item.modificationDate.description,formateFileSize];
        cell.detailTextLabel.text = detailText;
    } else {
        NSString *detailText = [NSString stringWithFormat:@"%@, %lu %@",item.modificationDate.description, (unsigned long)item.folderFileCount, [EDHUtility localizedString:@"Item" withScope:EDHFinderPodName]];
        cell.detailTextLabel.text = detailText;
    }
    
    cell.delegate = self;
    
    cell.rightButtons = @[
                          [MGSwipeButton buttonWithTitle:[EDHUtility localizedString:@"Delete" withScope:EDHFinderPodName] backgroundColor:[UIColor redColor]],
                          [MGSwipeButton buttonWithTitle:[EDHUtility localizedString:@"More" withScope:EDHFinderPodName] backgroundColor:[UIColor lightGrayColor]]
                          ];
}

- (EDHFinderItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    return (EDHFinderItem *)[self.items objectAtIndex:indexPath.row];
}

- (void)create:(EDHFinderListViewControllerCreateType)type {

    NSString *title;
    NSString *placeholder;
    NSString *text;
    
    switch (type) {
        case EDHFinderListViewControllerCreateTypeFile:
            title = [EDHUtility localizedString:@"New file" withScope:EDHFinderPodName];
            placeholder = [EDHUtility localizedString:@"Name" withScope:EDHFinderPodName];
            text = @"";
            break;
        case EDHFinderListViewControllerCreateTypeDirectory:
            title = [EDHUtility localizedString:@"New directory" withScope:EDHFinderPodName];
            placeholder = [EDHUtility localizedString:@"Name" withScope:EDHFinderPodName];
            text = @"";
            break;
        case EDHFinderListViewControllerCreateTypeDownload:
            title = [EDHUtility localizedString:@"Download" withScope:EDHFinderPodName];
            placeholder = [EDHUtility localizedString:@"URL" withScope:EDHFinderPodName];
            text = @"http://";
            break;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:@"" preferredStyle:UIAlertControllerStyleAlert];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = placeholder;
        textField.text = text;
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"OK" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alertController.textFields.firstObject;
        NSString *text = textField.text;
        if (text.length > 0) {
            switch (type) {
                case EDHFinderListViewControllerCreateTypeFile: {
                    [self.item createFileWithName:text success:^(EDHFinderItem *item) {
                        [self insertItem:item atIndex:0];
                    } failure:^(NSError *error) {
                        [EDHUtility showErrorWithMessage:error.localizedDescription controller:self];
                    }];
                    break;
                }
                case EDHFinderListViewControllerCreateTypeDirectory: {
                    [self.item createDirectoryWithName:text success:^(EDHFinderItem *item) {
                        [self insertItem:item atIndex:0];
                    } failure:^(NSError *error) {
                        [EDHUtility showErrorWithMessage:error.localizedDescription controller:self];
                    }];
                    break;
                }
                case EDHFinderListViewControllerCreateTypeDownload: {
                    [self startLoading];
                    [self.item downloadWithURL:text success:^(EDHFinderItem *item) {
                        [self insertItem:item atIndex:0];
                        [self endLoading];
                    } failure:^(NSError *error) {
                        if (error) {
                            [EDHUtility showErrorWithMessage:error.localizedDescription controller:self];
                        } else {
                            [self insertItem:nil atIndex:0];
                        }
                        [self endLoading];
                    }];
                    break;
                }
            }
        }
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Cancel" withScope:EDHFinderPodName] style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)renameItem:(EDHFinderItem *)item atIndexPath:(NSIndexPath *)indexPath {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[EDHUtility localizedString:@"Rename" withScope:EDHFinderPodName] message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = [EDHUtility localizedString:@"Name" withScope:EDHFinderPodName];
        textField.text = item.name;
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"OK" withScope:EDHFinderPodName] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alertController.textFields.firstObject;
        NSString *text = textField.text;
        if (text.length > 0) {
            [item renameTo:text success:^{
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } failure:^(NSError *error) {
                [EDHUtility showErrorWithMessage:error.localizedDescription controller:self];
            }];
        }
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[EDHUtility localizedString:@"Cancel" withScope:EDHFinderPodName] style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)insertItem:(EDHFinderItem *)item atIndex:(NSUInteger)index {
    if (item) {
        [self.items insertObject:item atIndex:index];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [EDHUtility showErrorWithMessage:[EDHUtility localizedString:@"Already exists." withScope:EDHFinderPodName] controller:self];
    }
}

- (void)startLoading {
    [self.refreshControl beginRefreshing];
    CGPoint offset = self.tableView.contentOffset;
    offset.y -= CGRectGetHeight(self.refreshControl.bounds);
    [self.tableView setContentOffset:offset animated:YES];
}

- (void)endLoading {
    [self.refreshControl endRefreshing];
}

- (void)removeItem:(EDHFinderItem *)item atIndexPath:(NSIndexPath *)indexPath {
    [self.items removeObject:item];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}


@end
