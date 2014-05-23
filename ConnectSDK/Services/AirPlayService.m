//
//  AirPlayService.m
//  Connect SDK
//
//  Created by Jeremy White on 4/18/14.
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

#import "AirPlayService.h"
#import "ConnectError.h"
#import "ConnectUtil.h"
#import "AirPlayWebAppSession.h"
#import <AVFoundation/AVPlayerItem.h>
#import <AVFoundation/AVAsset.h>


@interface AirPlayService () <UIWebViewDelegate>
{
    BOOL _isConnecting;
    NSTimer *_connectTimer;

    SuccessBlock _launchSuccessBlock;
    FailureBlock _launchFailureBlock;
    AirPlayWebAppSession *_activeWebAppSession;
}

@end

@implementation AirPlayService

+ (NSDictionary *) discoveryParameters
{
    return @{
        @"serviceId" : kConnectSDKAirPlayServiceId,
        @"zeroconf" : @{
                @"filter" : @"_airplay._tcp"
        }
    };
}

- (NSArray *) capabilities
{
    NSArray *caps = [NSArray array];

    caps = [caps arrayByAddingObjectsFromArray:kMediaPlayerCapabilities];
    caps = [caps arrayByAddingObjectsFromArray:@[
            kMediaControlPlay,
            kMediaControlPause,
            kMediaControlSeek,
            kMediaControlPosition,
            kMediaControlDuration,
            kMediaControlPlayState,
            kMediaControlStop,
            kMediaControlRewind,
            kMediaControlFastForward
    ]];
    caps = [caps arrayByAddingObjectsFromArray:kWebAppLauncherCapabilities];

    return caps;
}

- (BOOL) isConnectable
{
    return YES;
}

- (void) connect
{
    self.connected = YES;

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void) disconnect
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    [self closeMedia:nil success:nil failure:nil];

    [self hScreenDisconnected:nil];

    self.connected = NO;
    _isConnecting = NO;

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

#pragma mark - MediaPlayer

- (id <MediaPlayer>) mediaPlayer
{
    return self;
}

- (CapabilityPriorityLevel) mediaPlayerPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void) displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    [self closeMedia:nil success:nil failure:nil];

    [self checkForExistingScreenAndInitializeIfPresent];

    if (self.secondWindow && self.secondWindow.screen)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.secondWindow.screen.bounds];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];

        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view = imageView;

        self.secondWindow.rootViewController = viewController;
        self.secondWindow.hidden = NO;

        LaunchSession *launchSession = [LaunchSession launchSessionForAppId:@"image"];
        launchSession.service = self;
        launchSession.sessionType = LaunchSessionTypeMedia;

        __weak id<MediaControl> weakMediaControl = self.mediaControl;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSError *error;
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL options:0 error:&error];

            dispatch_on_main(^{
                if (imageData)
                {
                    [imageView setImage:[UIImage imageWithData:imageData]];

                    if (success)
                        success(launchSession, weakMediaControl);
                } else
                {
                    if (error)
                        failure(error);
                    else
                        failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not download image from specified URL"]);
                }
            });
        });
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Not currently mirrored with an AirPlay device"]);
    }
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    [self closeMedia:nil success:nil failure:nil];

    _avPlayer = [[AVPlayer alloc] initWithURL:mediaURL];
    _avPlayer.allowsExternalPlayback = YES;
    _avPlayer.usesExternalPlaybackWhileExternalScreenIsActive = YES;

    [self.avPlayer play];

    if (success)
    {
        LaunchSession *launchSession = [LaunchSession new];
        launchSession.sessionType = LaunchSessionTypeMedia;
        launchSession.service = self;

        success(launchSession, self.mediaControl);
    }
}

- (void) closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.avPlayer)
    {
        [self.avPlayer pause];

        _avPlayer.allowsExternalPlayback = NO;
        _avPlayer.usesExternalPlaybackWhileExternalScreenIsActive = NO;
        _avPlayer = nil;

        if (success)
            dispatch_on_main(^{ success(nil); });
    } else if (self.secondWindow && self.secondWindow.screen)
    {
        [self hScreenDisconnected:nil];

        if (success)
            dispatch_on_main(^{ success(nil); });
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"AirPlay media views are not set up yet"]);
    }
}

#pragma mark - Media Control

- (id <MediaControl>) mediaControl
{
    return self;
}

- (CapabilityPriorityLevel) mediaControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void) playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.avPlayer)
    {
        [self.avPlayer play];

        if (self.avPlayer.rate != 1.0)
            self.avPlayer.rate = 1.0;

        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"AirPlay media views are not set up yet"]);
    }
}

- (void) pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.avPlayer)
    {
        [self.avPlayer pause];

        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"AirPlay media views are not set up yet"]);
    }
}

- (void) stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self closeMedia:nil success:success failure:failure];
}

- (void) rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.avPlayer)
    {
        // TODO: implement different playback rates

        if (self.avPlayer.rate == -1.0 || self.avPlayer.rate == 1.5)
            self.avPlayer.rate = 1.0;
        else if (self.avPlayer.currentItem.canPlayReverse)
        {
            self.avPlayer.rate = -1.0;

            if (success)
                success(nil);
        } else
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"This media file does not support that playback rate"]);
        }
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"AirPlay media views are not set up yet"]);
    }
}

- (void) fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.avPlayer)
    {
        // TODO: implement different playback rates

        if (self.avPlayer.rate == -1.0 || self.avPlayer.rate == 1.5)
            self.avPlayer.rate = 1.0;
        else if (self.avPlayer.currentItem.canPlayFastForward)
        {
            self.avPlayer.rate = 1.5;

            if (success)
                success(nil);
        } else
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"This media file does not support that playback rate"]);
        }
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"AirPlay media views are not set up yet"]);
    }
}

- (void) seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.avPlayer)
    {
        CMTime seekToTime = CMTimeMakeWithSeconds(position, 1);

        [self.avPlayer seekToTime:seekToTime completionHandler:^(BOOL finished)
        {
            if (success && finished)
                success(nil);
            else if (failure && !finished)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Unknown error seeking"]);
        }];
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"AirPlay media views are not set up yet"]);
    }
}

- (void) getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    if (self.avPlayer)
    {
        MediaControlPlayState playState = MediaControlPlayStateUnknown;

        if (self.avPlayer.rate > 0.0)
            playState = MediaControlPlayStatePlaying;
        else if (self.avPlayer.rate == 0.0)
            playState = MediaControlPlayStateIdle;

        if (success)
            success(playState);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"AirPlay media views are not set up yet"]);
    }
}

- (ServiceSubscription *) subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    return nil;
}

- (void) getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure
{
    if (self.avPlayer)
    {
        CMTime currentDurationTime = self.avPlayer.currentItem.asset.duration;
        NSTimeInterval currentDuration = CMTimeGetSeconds(currentDurationTime);

        if (success)
            success(currentDuration);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"AirPlay media views are not set up yet"]);
    }
}

- (void) getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    if (self.avPlayer)
    {
        CMTime currentPositionTime = self.avPlayer.currentTime;
        NSTimeInterval currentPosition = CMTimeGetSeconds(currentPositionTime);

        if (success)
            success(currentPosition);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"AirPlay media views are not set up yet"]);
    }
}

#pragma mark - Helpers

- (void) closeLaunchSession:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (launchSession.sessionType == LaunchSessionTypeWebApp)
    {
        [self closeWebApp:launchSession success:success failure:failure];
    } else if (launchSession.sessionType == LaunchSessionTypeMedia)
    {
        [self closeMedia:launchSession success:success failure:failure];
    } else {
        if (failure)
            dispatch_on_main(^{ failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@""]); });
    }
}

#pragma mark - External display detection, setup

- (void) checkScreenCount
{
    if (self.connected)
    {
        if ([[UIScreen screens] count] <= 1)
            [self disconnect];
    } else if (!self.connected && _isConnecting)
    {
        if ([[UIScreen screens] count] > 1 && self.secondWindow == nil)
        {
            [self checkForExistingScreenAndInitializeIfPresent];
        }
    }

    [self performSelector:@selector(checkScreenCount) withObject:nil afterDelay:1];
}

- (void)checkForExistingScreenAndInitializeIfPresent
{
    if ([[UIScreen screens] count] > 1)
    {
        UIScreen *secondScreen = [[UIScreen screens] objectAtIndex:1];
        [secondScreen setOverscanCompensation:UIScreenOverscanCompensationScale];

        CGRect screenBounds = secondScreen.bounds;

        _secondWindow = [[UIWindow alloc] initWithFrame:screenBounds];
        _secondWindow.screen = secondScreen;
    }
}

- (void) hScreenConnected:(NSNotification *)notification
{
    DLog(@"%@", notification);

    if (!self.secondWindow)
        [self checkForExistingScreenAndInitializeIfPresent];
}

- (void) hScreenDisconnected:(NSNotification *)notification
{
    DLog(@"%@", notification);

    if (self.secondWindow)
    {
        _secondWindow.hidden = YES;
        _secondWindow = nil;
    }
}

#pragma mark - WebAppLauncher

- (id <WebAppLauncher>) webAppLauncher
{
    return self;
}

- (CapabilityPriorityLevel) webAppLauncherPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void) launchWebApp:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (!webAppId || webAppId.length == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid web app URL"]);

        return;
    }

    [self checkForExistingScreenAndInitializeIfPresent];

    if (!self.secondWindow)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not detect a second screen -- make sure you have mirroring enabled"]);

        return;
    }

    if (_webAppWebView)
    {
        [self closeWebApp:nil success:^(id responseObject)
        {
            [self launchWebApp:webAppId success:success failure:failure];
        } failure:failure];

        return;
    }

    _webAppWebView = [[UIWebView alloc] initWithFrame:self.secondWindow.bounds];
    _webAppWebView.allowsInlineMediaPlayback = YES;
    _webAppWebView.mediaPlaybackAllowsAirPlay = NO;
    _webAppWebView.mediaPlaybackRequiresUserAction = NO;

    UIViewController *secondScreenViewController = [[UIViewController alloc] init];
    secondScreenViewController.view = _webAppWebView;
    _webAppWebView.delegate = self;
    self.secondWindow.rootViewController = secondScreenViewController;
    self.secondWindow.hidden = NO;

    NSURL *URL = [NSURL URLWithString:webAppId];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];

    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self;

    AirPlayWebAppSession *webAppSession = [[AirPlayWebAppSession alloc] initWithLaunchSession:launchSession service:self];
    _activeWebAppSession = webAppSession;

    __weak AirPlayWebAppSession *weakSession = _activeWebAppSession;

    _launchSuccessBlock = ^(id responseObject)
    {
        if (success)
            success(weakSession);
    };

    _launchFailureBlock = failure;

    [self.webAppWebView loadRequest:request];
}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) joinWebApp:(LaunchSession *)webAppLaunchSession success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) joinWebAppWithId:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) disconnectFromWebApp
{
    if (_activeWebAppSession)
    {
        if (_activeWebAppSession.delegate)
            dispatch_on_main(^{ [_activeWebAppSession.delegate webAppSessionDidDisconnect:_activeWebAppSession]; });

        _activeWebAppSession = nil;
    }

    _launchSuccessBlock = nil;
    _launchFailureBlock = nil;
}

- (void) closeWebApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self disconnectFromWebApp];

    if (_secondWindow)
    {
        _secondWindow.rootViewController = nil;
        _secondWindow.hidden = YES;
        _secondWindow.screen = nil;
        _secondWindow = nil;
        _webAppWebView.delegate = nil;
        _webAppWebView = nil;
    }

    if (success)
        success(nil);
}

#pragma mark - UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);

    if (_launchFailureBlock)
        _launchFailureBlock(error);

    _launchSuccessBlock = nil;
    _launchFailureBlock = nil;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.absoluteString hasPrefix:@"connectsdk://"])
    {
        NSString *jsonString = [[request.URL.absoluteString componentsSeparatedByString:@"connectsdk://"] lastObject];
        jsonString = [ConnectUtil urlDecode:jsonString];

        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

        NSError *jsonError;
        id messageObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];

        if (jsonError || !messageObject)
            messageObject = jsonString;

        DLog(@"Got p2p message from web app:\n%@", messageObject);

        if (_activeWebAppSession && _activeWebAppSession.delegate)
            dispatch_on_main(^{ [_activeWebAppSession.delegate webAppSession:_activeWebAppSession didReceiveMessage:messageObject]; });

        return NO;
    } else
    {
        return YES;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DLog(@"%@", webView.request.URL.absoluteString);

    if (_launchSuccessBlock)
        _launchSuccessBlock(nil);

    _launchSuccessBlock = nil;
    _launchFailureBlock = nil;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    DLog(@"%@", webView.request.URL.absoluteString);
}

@end
