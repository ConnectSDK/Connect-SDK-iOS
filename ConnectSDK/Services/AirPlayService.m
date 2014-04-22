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


@interface AirPlayService () <UIWebViewDelegate>
{
    BOOL _isConnecting;
    NSTimer *_connectTimer;
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

    return caps;
}

- (BOOL) isConnectable
{
    return YES;
}

- (void) connect
{
    _isConnecting = YES;

    [self checkScreenCount];

    if (self.secondWindow == nil)
    {
        [[[UIAlertView alloc] initWithTitle:@"Enable mirroring" message:@"You will need to manually enable AirPlay and mirroring" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
    }
}

- (void) disconnect
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.viewController cleanup];
    [self hScreenDisconnected:nil];
    self.connected = NO;
    _isConnecting = NO;
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
    [self.viewController cleanup];

    NSString *javascriptString = [NSString stringWithFormat:@"window.app.handleLaunchParams({target:'%@',title:'%@',description:'%@',mimeType:'%@',iconSrc:'%@'})", imageURL.absoluteString, title, description, mimeType, iconURL.absoluteString];

    [self.viewController.webView stringByEvaluatingJavaScriptFromString:javascriptString];
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    [self.viewController cleanup];

    [self.viewController playVideo:mediaURL.absoluteString];

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
    [self.viewController cleanup];
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
    if (self.viewController && self.viewController.moviePlayer)
    {
        [self.viewController.moviePlayer play];

        if (self.viewController.moviePlayer.rate != 1.0)
            self.viewController.moviePlayer.rate = 1.0;

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
    if (self.viewController && self.viewController.moviePlayer)
    {
        [self.viewController.moviePlayer pause];

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
    if (self.viewController && self.viewController.moviePlayer)
    {
        [self.viewController cleanup];

        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"AirPlay media views are not set up yet"]);
    }
}

- (void) rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.viewController && self.viewController.moviePlayer)
    {
        // TODO: implement different playback rates

        if (self.viewController.moviePlayer.rate == -1.0 || self.viewController.moviePlayer.rate == 1.5)
            self.viewController.moviePlayer.rate = 1.0;
        else if (self.viewController.moviePlayer.currentItem.canPlayReverse)
        {
            self.viewController.moviePlayer.rate = -1.0;

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
    if (self.viewController && self.viewController.moviePlayer)
    {
        // TODO: implement different playback rates

        if (self.viewController.moviePlayer.rate == -1.0 || self.viewController.moviePlayer.rate == 1.5)
            self.viewController.moviePlayer.rate = 1.0;
        else if (self.viewController.moviePlayer.currentItem.canPlayFastForward)
        {
            self.viewController.moviePlayer.rate = 1.5;

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
    if (self.viewController && self.viewController.moviePlayer)
    {
//        Float64 duration = CMTimeGetSeconds(self.viewController.moviePlayer.currentItem.asset.duration);
//        Float64 seekTime = duration * ((Float64) position);
        CMTime seekToTime = CMTimeMakeWithSeconds(position, 1);

        [self.viewController.moviePlayer seekToTime:seekToTime completionHandler:^(BOOL finished)
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
    if (self.viewController && self.viewController.moviePlayer)
    {
        MediaControlPlayState playState = MediaControlPlayStateUnknown;

        if (self.viewController.moviePlayer.rate > 0.0)
            playState = MediaControlPlayStatePlaying;
        else if (self.viewController.moviePlayer.rate == 0.0)
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
    if (self.viewController && self.viewController.moviePlayer)
    {
        CMTime currentDurationTime = self.viewController.moviePlayer.currentItem.asset.duration;
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
    if (self.viewController && self.viewController.moviePlayer)
    {
        CMTime currentPositionTime = self.viewController.moviePlayer.currentTime;
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
    [self.viewController cleanup];

    if (success)
        success(nil);
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

        self.secondWindow = [[UIWindow alloc] initWithFrame:screenBounds];
        self.secondWindow.screen = secondScreen;

        if (self.viewController)
        {
            if (!self.viewController.webView.isLoading)
                [self webViewDidFinishLoad:self.viewController.webView];
        } else
        {
            self.viewController = [[AirPlayViewController alloc] initWithBounds:screenBounds];
            self.viewController.webView.delegate = self;
        }

        self.secondWindow.rootViewController = self.viewController;
        self.secondWindow.hidden = NO;
    }
}

- (void) hScreenConnected:(NSNotification *)notification
{
    NSLog(@"Connected screen");

    if (!self.secondWindow)
        [self checkForExistingScreenAndInitializeIfPresent];
}

- (void) hScreenDisconnected:(NSNotification *)notification
{
    NSLog(@"Disconnected screen");

    if (self.secondWindow)
    {
        self.secondWindow.hidden = YES;
        self.secondWindow = nil;

        if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
            dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
    }
}

#pragma mark - UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"LGAppleTVViewController::didFailLoadWithError %@", error.localizedDescription);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"LGAppleTVViewController::webViewDidFinishLoad");

    self.connected = YES;
    _isConnecting = NO;

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"LGAppleTVViewController::webViewDidStartLoad");
}

@end
