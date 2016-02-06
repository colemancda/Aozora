//
//  WSWebScraper.h
//  GoogleSearchBridge
//
//  Created by  on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "TFHpple.h"

@interface WSWebScraper : NSObject <WKNavigationDelegate>

typedef void(^WSRequestHandler)(TFHpple *hpple);
typedef void(^HTTPRequestHandler)(NSString *body);

@property (nonatomic, copy) WSRequestHandler completion;
@property (nonatomic, copy) HTTPRequestHandler completionPOST;
@property (strong, nonatomic) WKWebView* webView;

- (id)initWithViewController:(UIViewController *)aViewController;

- (void)scrape:(NSString *)url handler:(WSRequestHandler)handler;
@end
