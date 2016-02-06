//
//  WSWebScraper.m
//  GoogleSearchBridge
//
//  Created by  on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WSWebScraper.h"


@interface WSWebScraper(){
  UIViewController* _viewController;
}

@property (weak, nonatomic) UIViewController* viewController;

@property (nonatomic) BOOL catchFlag;
@property (strong, nonatomic) NSURL* targetUrl;

@property (strong, nonatomic) NSString *script;

@end

@implementation WSWebScraper

- (UIViewController *)viewController
{
  return _viewController;
}

- (void)setViewController:(UIViewController *)aViewController
{
  _viewController = aViewController;
}

- (id)initWithViewController:(UIViewController *)aViewController {
    
    self = [super init];
    
    if(!self) {
        return nil;
    }
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 1, 0)];
    self.webView.hidden = YES;
    self.webView.navigationDelegate = self;
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.viewController = aViewController;
    [self.viewController.view addSubview:self.webView];
    
    self.catchFlag = NO;

    return self;
}

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView setNavigationDelegate:nil];
}

- (void)scrape:(NSString *)url handler:(WSRequestHandler)handler
{
    self.catchFlag = YES;
    [self.webView stopLoading];
    self.targetUrl = [NSURL URLWithString:url];
    self.completion = handler;

    NSMutableURLRequest *rq = [NSMutableURLRequest requestWithURL:self.targetUrl];

    [self.webView loadRequest:rq];    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"] && object == self.webView) {
        
        if(self.catchFlag && self.webView.estimatedProgress > 0.9) {
            self.catchFlag = NO;
            [self.webView evaluateJavaScript:@"document.documentElement.innerHTML" completionHandler:^(NSString *body, NSError *error) {
                
                NSString *newHTML = [[[body stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"  " withString:@""] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
                newHTML = [newHTML stringByReplacingOccurrencesOfString:@"> <" withString:@"><"];
                
                TFHpple *hpple = [TFHpple hppleWithHTMLData:[newHTML dataUsingEncoding:NSUTF8StringEncoding]];
                self.completion(hpple);
                [self.webView stopLoading];
                
            }];
            
        }
    }
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    self.catchFlag = YES;
    NSLog(@"didCommitNavigation");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"didFinishNavigation");
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"didFailNavigation");
    if ([error code]!=NSURLErrorCancelled) {
        NSLog(@"[ERROR] %@", [error localizedDescription]);
        self.completion(nil);
    }
}
@end
