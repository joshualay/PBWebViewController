//
//  PBWebViewController.m
//  Pinbrowser
//
//  Created by Mikael Konutgan on 11/02/2013.
//  Copyright (c) 2013 Mikael Konutgan. All rights reserved.
//

#import "PBWebViewController.h"

@interface PBWebViewController () <UIPopoverControllerDelegate>

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicatorView;

@property (strong, nonatomic) UIBarButtonItem *stopLoadingButton;
@property (strong, nonatomic) UIBarButtonItem *reloadButton;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) UIBarButtonItem *forwardButton;

@property (strong, nonatomic) UIPopoverController *activitiyPopoverController;

@property (assign, nonatomic) BOOL toolbarPreviouslyHidden;

@end

@implementation PBWebViewController

- (void)dealloc
{
    self.delegate = nil;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _showsNavigationToolbar = YES;
    _timeoutInterval = 4.0;
    _showsActionButton = YES;
}

- (void)load
{
    if (self.activityIndicatorView == nil) {
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicatorView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
        self.activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        self.activityIndicatorView.hidesWhenStopped = YES;
        [self.view addSubview:self.activityIndicatorView];
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:self.URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:self.timeoutInterval];
    [self.webView loadRequest:request];
    
    if (self.navigationController.toolbarHidden) {
        self.toolbarPreviouslyHidden = YES;
        if (self.showsNavigationToolbar) {
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    }
}

- (void)clear
{
    [self.webView loadHTMLString:@"" baseURL:nil];
    self.title = @"";
}

#pragma mark - View controller lifecycle

- (void)loadView
{
    self.webView = [[UIWebView alloc] init];
    self.webView.scalesPageToFit = YES;
    self.view = self.webView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupToolBarItems];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.webView.delegate = self;
    if (self.URL) {
        [self load];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.webView stopLoading];
    self.webView.delegate = nil;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (self.toolbarPreviouslyHidden && self.showsNavigationToolbar) {
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

#pragma mark - Helpers

- (UIImage *)backButtonImage
{
    static UIImage *image;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        CGSize size = CGSizeMake(12.0, 21.0);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        path.lineWidth = 1.5;
        path.lineCapStyle = kCGLineCapButt;
        path.lineJoinStyle = kCGLineJoinMiter;
        [path moveToPoint:CGPointMake(11.0, 1.0)];
        [path addLineToPoint:CGPointMake(1.0, 11.0)];
        [path addLineToPoint:CGPointMake(11.0, 20.0)];
        [path stroke];
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    
    return image;
}

- (UIImage *)forwardButtonImage
{
    static UIImage *image;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        UIImage *backButtonImage = [self backButtonImage];
        
        CGSize size = backButtonImage.size;
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGFloat x_mid = size.width / 2.0;
        CGFloat y_mid = size.height / 2.0;
        
        CGContextTranslateCTM(context, x_mid, y_mid);
        CGContextRotateCTM(context, M_PI);
        
        [backButtonImage drawAtPoint:CGPointMake(-x_mid, -y_mid)];
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    
    return image;
}

- (void)setupToolBarItems
{
    self.stopLoadingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                           target:self.webView
                                                                           action:@selector(stopLoading)];
    
    self.reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                      target:self.webView
                                                                      action:@selector(reload)];
    
    self.backButton = [[UIBarButtonItem alloc] initWithImage:[self backButtonImage]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self.webView
                                                      action:@selector(goBack)];
    
    self.forwardButton = [[UIBarButtonItem alloc] initWithImage:[self forwardButtonImage]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self.webView
                                                         action:@selector(goForward)];
    
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                  target:self
                                                                                  action:@selector(action:)];
    
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                           target:nil
                                                                           action:nil];
    
    UIBarButtonItem *space_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                            target:nil
                                                                            action:nil];
    space_.width = 60.0f;

    if (self.showsActionButton)
        self.toolbarItems = @[self.stopLoadingButton, space, self.backButton, space_, self.forwardButton, space, actionButton];
    else
        self.toolbarItems = @[self.stopLoadingButton, space, self.backButton, space_, self.forwardButton, space];
}

- (void)toggleState
{
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
    
    NSMutableArray *toolbarItems = [self.toolbarItems mutableCopy];
    if (self.webView.loading) {
        toolbarItems[0] = self.stopLoadingButton;
    } else {
        toolbarItems[0] = self.reloadButton;
    }
    self.toolbarItems = [toolbarItems copy];
}

- (void)finishLoad
{
    [self toggleState];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - Button actions

- (void)action:(id)sender
{
    if (self.activitiyPopoverController.popoverVisible) {
        [self.activitiyPopoverController dismissPopoverAnimated:YES];
        return;
    }
    
    NSArray *activityItems = @[self.URL];
    
    if (self.activityItems) {
        activityItems = self.activityItems;
    }
    
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                     applicationActivities:self.applicationActivities];
    vc.excludedActivityTypes = self.excludedActivityTypes;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:vc animated:YES completion:NULL];
    } else {
        if (!self.activitiyPopoverController) {
            self.activitiyPopoverController = [[UIPopoverController alloc] initWithContentViewController:vc];
        }
        
        self.activitiyPopoverController.delegate = self;
        
        UIBarButtonItem *barButtonItem = [self.toolbarItems lastObject];
        [self.activitiyPopoverController presentPopoverFromBarButtonItem:barButtonItem
                                                permittedArrowDirections:UIPopoverArrowDirectionAny
                                                                animated:YES];
    }
}

#pragma mark - Web view delegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self toggleState];

    [self.activityIndicatorView startAnimating];

    if ([self.delegate respondsToSelector:@selector(webViewController:didStartLoadingURL:)]) {
        [self.delegate webViewController:self didStartLoadingURL:webView.request.URL];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.URL = self.webView.request.URL;

    [self.activityIndicatorView stopAnimating];

    if ([self.delegate respondsToSelector:@selector(webViewController:didFinishLoadingURL:)]) {
        [self.delegate webViewController:self didFinishLoadingURL:self.URL];
    }

    [self finishLoad];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.activityIndicatorView stopAnimating];

    if ([self.delegate respondsToSelector:@selector(webViewController:didFailLoadingURL:)]) {
        [self.delegate webViewController:self didFailLoadingURL:webView.request.URL];
    }

    [self finishLoad];
}

#pragma mark - Popover controller delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.activitiyPopoverController = nil;
}

@end
