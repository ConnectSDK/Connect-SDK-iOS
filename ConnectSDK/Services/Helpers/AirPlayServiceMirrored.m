//
//  AirPlayServiceMirrored.m
//  Connect SDK
//
//  Created by Jeremy White on 5/28/14.
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

#import "AirPlayServiceMirrored.h"
#import <AVFoundation/AVPlayerItem.h>
#import <AVFoundation/AVAsset.h>
#import "ConnectError.h"
#import "AirPlayWebAppSession.h"
#import "ConnectUtil.h"
#import "AirPlayService.h"


@interface AirPlayServiceMirrored () <ServiceCommandDelegate, UIWebViewDelegate>

@property (nonatomic, copy) SuccessBlock launchSuccessBlock;
@property (nonatomic, copy) FailureBlock launchFailureBlock;

@property (nonatomic) AirPlayWebAppSession *activeWebAppSession;
@property (nonatomic) ServiceSubscription *playStateSubscription;

@end

@implementation AirPlayServiceMirrored
{
    NSTimer *_connectTimer;
    UIAlertView *_connectingAlertView;
}

- (instancetype) initWithAirPlayService:(AirPlayService *)service
{
    self = [super init];

    if (self)
    {
        _service = service;
    }

    return self;
}

- (void) connect
{
    _connecting = YES;

    [self checkScreenCount];

    if (!self.connected)
    {
        NSString *title = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_AirPlay_Mirror_Title" value:@"Mirroring Required" table:@"ConnectSDK"];
        NSString *message = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_AirPlay_Mirror_Description" value:@"Enable AirPlay mirroring to connect to this device" table:@"ConnectSDK"];
        NSString *ok = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_AirPlay_Mirror_OK" value:@"OK" table:@"ConnectSDK"];
        NSString *cancel = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_AirPlay_Mirror_Cancel" value:@"Cancel" table:@"ConnectSDK"];

        _connectingAlertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:ok, nil];

        if (self.service && self.service.delegate && [self.service.delegate respondsToSelector:@selector(deviceService:pairingRequiredOfType:withData:)])
            dispatch_on_main(^{ [self.service.delegate deviceService:self.service pairingRequiredOfType:DeviceServicePairingTypeAirPlayMirroring withData:_connectingAlertView]; });

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hScreenConnected:) name:UIScreenDidConnectNotification object:nil];
    }
}

- (void) disconnect
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidDisconnectNotification object:nil];

    [self.mediaPlayer closeMedia:nil success:nil failure:nil];

    if (self.secondWindow)
        [self hScreenDisconnected:nil];

    if (_connectTimer)
    {
        [_connectTimer invalidate];
        _connectTimer = nil;
    }

    _connected = NO;
    _connecting = NO;

    if (_connectingAlertView)
        dispatch_on_main(^{ [_connectingAlertView dismissWithClickedButtonIndex:0 animated:NO]; });

    if (self.service && self.service.delegate && [self.service.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        [self.service.delegate deviceService:self.service disconnectedWithError:nil];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    _connectingAlertView.delegate = nil;
    _connectingAlertView = nil;

    if (buttonIndex == 0 && _connecting)
        [self disconnect];
}

- (int) sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == ServiceSubscriptionTypeUnsubscribe)
    {
        if (subscription == self.playStateSubscription)
        {
            [[self.playStateSubscription successCalls] removeAllObjects];
            [[self.playStateSubscription failureCalls] removeAllObjects];
            [self.playStateSubscription setIsSubscribed:NO];
            self.playStateSubscription = nil;
        }
    }

    return -1;
}

#pragma mark - External display detection, setup

- (void) checkScreenCount
{
    if (_connectTimer)
    {
        [_connectTimer invalidate];
        _connectTimer = nil;
    }

    if (!self.connecting)
        return;

    if ([UIScreen screens].count > 1)
    {
        _connecting = NO;
        _connected = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hScreenDisconnected:) name:UIScreenDidDisconnectNotification object:nil];

        if (_connectingAlertView)
            dispatch_on_main(^{ [_connectingAlertView dismissWithClickedButtonIndex:1 animated:NO]; });

        if (self.service.connected && self.service.delegate && [self.service.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
            dispatch_on_main(^{ [self.service.delegate deviceServiceConnectionSuccess:self.service]; });
    } else
    {
        _connectTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkScreenCount) userInfo:nil repeats:NO];
    }
}

- (void)checkForExistingScreenAndInitializeIfPresent
{
    if ([[UIScreen screens] count] > 1)
    {
        UIScreen *secondScreen = [[UIScreen screens] objectAtIndex:1];

        CGRect screenBounds = secondScreen.bounds;

        _secondWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, secondScreen.bounds.size.width / secondScreen.scale, secondScreen.bounds.size.height / secondScreen.scale)];
        _secondWindow.screen = secondScreen;
        _secondWindow.contentScaleFactor = 0.5;

        DLog(@"Displaying content with bounds %@", NSStringFromCGRect(screenBounds));
    }
}

- (void) hScreenConnected:(NSNotification *)notification
{
    DLog(@"%@", notification);

    if (!self.secondWindow)
        [self checkForExistingScreenAndInitializeIfPresent];

    [self checkScreenCount];
}

- (void) hScreenDisconnected:(NSNotification *)notification
{
    DLog(@"%@", notification);

    if (self.secondWindow)
    {
        _secondWindow.hidden = YES;
        _secondWindow = nil;

        [self disconnect];
    }
}

#pragma mark - Media Player

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
    if (self.avPlayer)
        [self closeMedia:nil success:nil failure:nil];

    [self checkForExistingScreenAndInitializeIfPresent];

    if (self.secondWindow && self.secondWindow.screen)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.secondWindow.frame];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];

        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view = imageView;

        self.secondWindow.rootViewController = viewController;
        self.secondWindow.hidden = NO;

        LaunchSession *launchSession = [LaunchSession launchSessionForAppId:@"image"];
        launchSession.service = self.service;
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

    [self checkForExistingScreenAndInitializeIfPresent];

    if (self.secondWindow && self.secondWindow.screen)
    {
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @YES}];
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];

        _avPlayer = [AVPlayer playerWithPlayerItem:item];
        _avPlayer.allowsExternalPlayback = YES;
        _avPlayer.usesExternalPlaybackWhileExternalScreenIsActive = YES;
        _avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;

        [self.avPlayer play];

        if (success)
        {
            LaunchSession *launchSession = [LaunchSession new];
            launchSession.sessionType = LaunchSessionTypeMedia;
            launchSession.service = self.service;

            success(launchSession, self.mediaControl);
        }
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Not currently mirrored with an AirPlay device"]);
    }
}

- (void) closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.avPlayer)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [self.avPlayer removeObserver:self forKeyPath:@"rate"];

        if (self.playStateSubscription)
        {
            [self.playStateSubscription setIsSubscribed:NO];
            self.playStateSubscription = nil;
        }

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
            self.avPlayer.rate = (float) -1.0;

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
                    if (self.avPlayer.rate > 0.0f)
                        [self observeValueForKeyPath:@"rate" ofObject:self.avPlayer change:nil context:nil];

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
    if (!self.playStateSubscription)
        self.playStateSubscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:nil callId:-1];

    [self.playStateSubscription addSuccess:success];
    [self.playStateSubscription addFailure:failure];
    [self.playStateSubscription setIsSubscribed:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hPlaybackDidFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    [self.avPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];

    return self.playStateSubscription;
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

- (void) hPlaybackDidFinish:(NSNotification *)notification
{
    if (self.playStateSubscription)
    {
        dispatch_on_main(^{
            [self.playStateSubscription.successCalls enumerateObjectsUsingBlock:^(MediaPlayStateSuccessBlock success, NSUInteger idx, BOOL *stop) {
                success(MediaControlPlayStateFinished);
            }];
        });
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (!self.playStateSubscription)
        return;

    if (![@"rate" isEqualToString:keyPath])
        return;

    MediaControlPlayState playState = MediaControlPlayStateUnknown;

    if (self.avPlayer.rate > 0.0f)
    {
        playState = MediaControlPlayStatePlaying;
    } else if (self.avPlayer.rate == 0.0f)
    {
        int comparison = CMTimeCompare(self.avPlayer.currentTime, self.avPlayer.currentItem.duration);

        if (comparison >= 0)
            playState = MediaControlPlayStateFinished;
        else
            playState = MediaControlPlayStatePaused;
    }

    dispatch_on_main(^{
        [self.playStateSubscription.successCalls enumerateObjectsUsingBlock:^(MediaPlayStateSuccessBlock success, NSUInteger idx, BOOL *stop) {
            success(playState);
        }];
    });
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
    [self launchWebApp:webAppId params:nil relaunchIfRunning:YES success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchWebApp:webAppId params:params relaunchIfRunning:YES success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (!webAppId || webAppId.length == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid web app URL"]);

        return;
    }

    if (self.avPlayer)
        [self closeMedia:nil success:nil failure:nil];

    [self checkForExistingScreenAndInitializeIfPresent];

    if (self.secondWindow && self.secondWindow.screen)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not detect a second screen -- make sure you have mirroring enabled"]);

        return;
    }

    if (_webAppWebView)
    {
        if (relaunchIfRunning)
        {
            [self closeWebApp:nil success:^(id responseObject)
                    {
                        [self launchWebApp:webAppId params:params relaunchIfRunning:relaunchIfRunning success:success failure:failure];
                    } failure:failure];

            return;
        } else
        {
            NSString *webAppHost = _webAppWebView.request.URL.host;

            if ([webAppId rangeOfString:webAppHost].location != NSNotFound)
            {
                if (params && params.count > 0)
                {
                    [self.activeWebAppSession connectWithSuccess:^(id connectResponseObject)
                            {
                                [self.activeWebAppSession sendJSON:params success:^(id sendResponseObject)
                                        {
                                            if (success)
                                                success(self.activeWebAppSession);
                                        } failure:failure];
                            } failure:failure];
                } else
                {
                    if (success)
                        dispatch_on_main(^{ success(self.activeWebAppSession); });
                }

                return;
            }
        }
    }

    DLog(@"Created a web view with bounds %@", NSStringFromCGRect(self.secondWindow.bounds));

    _webAppWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.secondWindow.bounds.size.width / self.secondWindow.screen.scale, self.secondWindow.bounds.size.height / self.secondWindow.screen.scale)];
    _webAppWebView.allowsInlineMediaPlayback = YES;
    _webAppWebView.mediaPlaybackAllowsAirPlay = NO;
    _webAppWebView.mediaPlaybackRequiresUserAction = NO;

    UIViewController *secondScreenViewController = [[UIViewController alloc] init];
    secondScreenViewController.view = _webAppWebView;
    _webAppWebView.delegate = self;
    self.secondWindow.rootViewController = secondScreenViewController;
    self.secondWindow.hidden = NO;

    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self.service;

    AirPlayWebAppSession *webAppSession = [[AirPlayWebAppSession alloc] initWithLaunchSession:launchSession service:self.service];
    self.activeWebAppSession = webAppSession;

    __weak AirPlayWebAppSession *weakSession = self.activeWebAppSession;

    if (params && params.count > 0)
    {
        self.launchSuccessBlock = ^(id launchResponseObject)
        {
            [weakSession connectWithSuccess:^(id connectResponseObject)
                    {
                        [weakSession sendJSON:params success:^(id sendResponseObject)
                                {
                                    if (success)
                                        success(weakSession);
                                } failure:failure];
                    } failure:failure];
        };
    } else
    {
        self.launchSuccessBlock = ^(id responseObject)
        {
            if (success)
                success(weakSession);
        };
    }

    self.launchFailureBlock = failure;

    NSURL *URL = [NSURL URLWithString:webAppId];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];

    [self.webAppWebView loadRequest:request];
}

- (void) launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchWebApp:webAppId params:nil relaunchIfRunning:YES success:success failure:failure];
}

- (void) joinWebApp:(LaunchSession *)webAppLaunchSession success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (self.webAppWebView)
    {
        NSString *webAppHost = self.webAppWebView.request.URL.host;

        if ([webAppLaunchSession.appId rangeOfString:webAppHost].location != NSNotFound)
        {
            AirPlayWebAppSession *webAppSession = [[AirPlayWebAppSession alloc] initWithLaunchSession:webAppLaunchSession service:self.service];
            self.activeWebAppSession = webAppSession;

            [webAppSession connectWithSuccess:success failure:failure];
        } else
        {
            if (failure)
                dispatch_on_main(^{ failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Web is not currently running"]); });
        }
    }
}

- (void) joinWebAppWithId:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
    launchSession.service = self.service;
    launchSession.sessionType = LaunchSessionTypeWebApp;

    [self joinWebApp:launchSession success:success failure:failure];
}

- (void) disconnectFromWebApp
{
    if (self.activeWebAppSession)
    {
        if (self.activeWebAppSession.delegate && [self.activeWebAppSession.delegate respondsToSelector:@selector(webAppSessionDidDisconnect:)])
            dispatch_on_main(^{ [self.activeWebAppSession.delegate webAppSessionDidDisconnect:self.activeWebAppSession]; });

        self.activeWebAppSession = nil;
    }

    self.launchSuccessBlock = nil;
    self.launchFailureBlock = nil;
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

    if (self.launchFailureBlock)
        self.launchFailureBlock(error);

    self.launchSuccessBlock = nil;
    self.launchFailureBlock = nil;
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

        if (self.activeWebAppSession)
        {
            NSString *webAppHost = self.webAppWebView.request.URL.host;

            // check if current running web app matches the current web app session
            if ([self.activeWebAppSession.launchSession.appId rangeOfString:webAppHost].location != NSNotFound)
                dispatch_on_main(^{ self.activeWebAppSession.messageHandler(messageObject); });
            else
                [self.activeWebAppSession disconnectFromWebApp];
        }

        return NO;
    } else
    {
        return YES;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DLog(@"%@", webView.request.URL.absoluteString);

    if (self.launchSuccessBlock)
        self.launchSuccessBlock(nil);

    self.launchSuccessBlock = nil;
    self.launchFailureBlock = nil;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    DLog(@"%@", webView.request.URL.absoluteString);
}

@end
