//
//  AirPlayViewController.m
//  Connect SDK
//
//  Created by Jeremy White on 4/22/14.
//  Copyright (c) 2014 LG Electronics.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "AirPlayViewController.h"


@implementation AirPlayViewController

- (id) initWithBounds:(CGRect)bounds
{
    self = [super init];

    if (self)
    {
        self.view = [[UIView alloc] initWithFrame:bounds];
        self.view.backgroundColor = [UIColor blackColor];

        self.webView = [[UIWebView alloc] initWithFrame:bounds];
        self.webView.opaque = NO;
        self.webView.backgroundColor = [UIColor blackColor];
        self.webView.allowsInlineMediaPlayback = YES;
        [self.view addSubview:self.webView];

        [self viewDidLoad];
    }

    return self;
}

- (void) viewDidLoad
{
//    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://gitlab.idean.com/jwhite/myreceiver.html"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval: 10.0];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://gitlab.idean.com/jwhite/myreceiver.html"]];

    [self.webView loadRequest:urlRequest];
}

- (void) playVideo:(NSString *)videoPath
{
    [self cleanup];

    self.moviePlayer = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:videoPath]];
    self.moviePlayer.allowsExternalPlayback = YES;
    self.moviePlayer.usesExternalPlaybackWhileExternalScreenIsActive = YES;
    self.moviePlayer.externalPlaybackVideoGravity = AVLayerVideoGravityResizeAspect;

    self.moviePlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cleanup)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.moviePlayer currentItem]];

    [self.moviePlayer play];
}

- (void) cleanup
{
    if (self.moviePlayer == nil)
        return;

    self.moviePlayer.allowsExternalPlayback = NO;
    self.moviePlayer.usesExternalPlaybackWhileExternalScreenIsActive = NO;
    [self.moviePlayer pause];
    self.moviePlayer = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
