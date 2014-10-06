//
//  EDHDetailViewController.m
//  EDHFinder
//
//  Created by Tatsuya Tobioka on 10/6/14.
//  Copyright (c) 2014 tnantoka. All rights reserved.
//

#import "EDHDetailViewController.h"

#import <WebKit/WebKit.h>

@interface EDHDetailViewController () <UITextViewDelegate>

@property (nonatomic) UITextView *textView;
@property (nonatomic) WKWebView *webView;

@property (nonatomic) EDHFinderItem *item;

@end

@implementation EDHDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), CGRectGetMidY(self.view.bounds))];
    self.textView.delegate = self;
    [self.view addSubview:self.textView];
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0.0f, CGRectGetMidY(self.view.bounds) + 1.0f, CGRectGetWidth(self.view.bounds), CGRectGetMidY(self.view.bounds) - 1.0f)];
    [self.view addSubview:self.webView];    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

# pragma mark - EDHFinderListViewControllerDelegate

- (void)listViewController:(EDHFinderListViewController *)controller didMoveToDirectory:(EDHFinderItem *)item {
    self.title = item.name;
    self.textView.text = @"";
    
    [self loadURL:[NSURL URLWithString:@"about:blank"]];
}

- (void)listViewController:(EDHFinderListViewController *)controller didBackToDirectory:(EDHFinderItem *)item {
    [self listViewController:controller didMoveToDirectory:item];
}

- (void)listViewController:(EDHFinderListViewController *)controller didSelectFile:(EDHFinderItem *)item {
    self.title = item.name;
    self.textView.text = item.content;
    
    [self loadURL:item.fileURL];

    self.item = item;
}

# pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self.item updateContent:textView.text];
    [self loadURL:self.item.fileURL];
}

# pragma mark - WebView

- (void)loadURL:(NSURL *)url {
    [self.webView loadRequest:[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:0.0f]];
}

@end
