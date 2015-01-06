//
//  CastService.m
//  Connect SDK
//
//  Created by Jeremy White on 2/7/14.
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

#import <Matchstick/Flint.h>
#import "FlintService.h"
#import "ConnectError.h"
#import "FlintWebAppSession.h"

#define kFlintServiceMuteSubscriptionName @"mute"
#define kFlintServiceVolumeSubscriptionName @"volume"

NSString *const kMSFKMediaDefaultReceiverApplicationID = @"http://openflint.github.io/flint-player/player.html";


@interface FlintService () <ServiceCommandDelegate>

@end

@implementation FlintService
{
    int UID;
    
    NSString *_currentAppId;
    NSString *_launchingAppId;
    
    NSMutableDictionary *_launchSuccessBlocks;
    NSMutableDictionary *_launchFailureBlocks;
    
    NSMutableDictionary *_sessions; // TODO: are we using this? get rid of it if not
    NSMutableArray *_subscriptions;
    
    float _currentVolumeLevel;
    BOOL _currentMuteStatus;
}

- (void) commonSetup
{
    _launchSuccessBlocks = [NSMutableDictionary new];
    _launchFailureBlocks = [NSMutableDictionary new];
    
    _sessions = [NSMutableDictionary new];
    _subscriptions = [NSMutableArray new];
    
    UID = 0;
}

- (instancetype) init
{
    self = [super init];
    
    if (self)
    [self commonSetup];
    
    return self;
}

- (instancetype)initWithServiceConfig:(ServiceConfig *)serviceConfig
{
    self = [super initWithServiceConfig:serviceConfig];
    
    if (self)
    [self commonSetup];
    
    return self;
}

+ (NSDictionary *) discoveryParameters
{
    return @{
             @"serviceId":kConnectSDKFlingServiceId
             };
}

- (BOOL)isConnectable
{
    return YES;
}

- (void) updateCapabilities
{
    NSArray *capabilities = [NSArray new];
    
    capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaPlayerCapabilities];
    capabilities = [capabilities arrayByAddingObjectsFromArray:kVolumeControlCapabilities];
    capabilities = [capabilities arrayByAddingObjectsFromArray:@[
                                                                 kMediaControlPlay,
                                                                 kMediaControlPause,
                                                                 kMediaControlStop,
                                                                 kMediaControlDuration,
                                                                 kMediaControlSeek,
                                                                 kMediaControlPosition,
                                                                 kMediaControlPlayState,
                                                                 kMediaControlPlayStateSubscribe,
                                                                 kMediaControlMetadata,
                                                                 kMediaControlMetadataSubscribe,
                                                                 
                                                                 kWebAppLauncherLaunch,
                                                                 kWebAppLauncherMessageSend,
                                                                 kWebAppLauncherMessageReceive,
                                                                 kWebAppLauncherMessageSendJSON,
                                                                 kWebAppLauncherMessageReceiveJSON,
                                                                 kWebAppLauncherConnect,
                                                                 kWebAppLauncherDisconnect,
                                                                 kWebAppLauncherJoin,
                                                                 kWebAppLauncherClose
                                                                 ]];
    
    [self setCapabilities:capabilities];
}

#pragma mark - Connection

- (void)connect
{
    if (self.connected)
    return;
    
    if (!_flintDevice)
    {
        UInt32 devicePort = (UInt32) self.serviceDescription.port;
        _flintDevice = [[MSFKDevice alloc] initWithIPAddress:self.serviceDescription.address servicePort:devicePort];
    }
    
    if (!_flintDeviceManager)
    {
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSString *clientPackageName = [info objectForKey:@"CFBundleIdentifier"];
        
        _flintDeviceManager = [[MSFKDeviceManager alloc] initWithDevice:_flintDevice clientPackageName:clientPackageName];
        _flintDeviceManager.delegate = self;
        _flintDeviceManager.appId = @"~flintplayer";
    }
    
    [_flintDeviceManager connect];
}

- (void)disconnect
{
    if (!self.connected)
    return;
    
    self.connected = NO;
    
    [_flintDeviceManager leaveApplication];
    [_flintDeviceManager disconnect];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
    dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

#pragma mark - Subscriptions

- (int)sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == ServiceSubscriptionTypeUnsubscribe)
    [_subscriptions removeObject:subscription];
    else if (type == ServiceSubscriptionTypeSubscribe)
    [_subscriptions addObject:subscription];
    
    return callId;
}

- (int) getNextId
{
    UID = UID + 1;
    return UID;
}

#pragma mark - MSFKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(MSFKDeviceManager *)deviceManager
{
    DLog(@"connected");
    
    self.connected = YES;
    
    _flintMediaControlChannel = [[MSFKMediaControlChannel alloc] init];
    [_flintDeviceManager addChannel:_flintMediaControlChannel];
    
    dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void)deviceManager:(MSFKDeviceManager *)deviceManager didConnectToFlintApplication:(MSFKApplicationMetadata *)applicationMetadata launchedApplication:(BOOL)launchedApplication
{
    DLog(@"%@ (%@)", applicationMetadata.applicationName, applicationMetadata.applicationID);
    NSLog(@"1111111111----------%@ (%@)", applicationMetadata.applicationURL, applicationMetadata.applicationID);
    
    _currentAppId = applicationMetadata.applicationID;
    
    WebAppLaunchSuccessBlock success = [_launchSuccessBlocks objectForKey:applicationMetadata.applicationID];
    
    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:applicationMetadata.applicationID];
    launchSession.name = applicationMetadata.applicationName;
    launchSession.sessionId = applicationMetadata.sessionID;
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self;
    
    FlintWebAppSession *webAppSession = [[FlintWebAppSession alloc] initWithLaunchSession:launchSession service:self];
    webAppSession.metadata = applicationMetadata;
    
    [_sessions setObject:webAppSession forKey:applicationMetadata.applicationID];
    
    if (success)
    dispatch_on_main(^{ success(webAppSession); });
    
    [_launchSuccessBlocks removeObjectForKey:applicationMetadata.applicationID];
    [_launchFailureBlocks removeObjectForKey:applicationMetadata.applicationID];
    _launchingAppId = nil;
}

- (void)deviceManager:(MSFKDeviceManager *)deviceManager didDisconnectFromApplicationWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);
    
    if (!_currentAppId)
    return;
    
    WebAppSession *webAppSession = [_sessions objectForKey:_currentAppId];
    
    if (!webAppSession || !webAppSession.delegate)
    return;
    
    [webAppSession.delegate webAppSessionDidDisconnect:webAppSession];
}

- (void)deviceManager:(MSFKDeviceManager *)deviceManager didFailToConnectToApplicationWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);
    
    if (_launchingAppId)
    {
        FailureBlock failure = [_launchFailureBlocks objectForKey:_launchingAppId];
        
        if (failure)
        dispatch_on_main(^{ failure(error); });
        
        [_launchSuccessBlocks removeObjectForKey:_launchingAppId];
        [_launchFailureBlocks removeObjectForKey:_launchingAppId];
        _launchingAppId = nil;
    }
}

- (void)deviceManager:(MSFKDeviceManager *)deviceManager didFailToConnectWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);
    
    if (self.connected)
    [self disconnect];
}

- (void)deviceManager:(MSFKDeviceManager *)deviceManager didFailToStopApplicationWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);
}

- (void)deviceManager:(MSFKDeviceManager *)deviceManager didReceiveApplicationMetadata:(MSFKApplicationMetadata *)applicationMetadata
{
    DLog(@"%@", applicationMetadata);
    
    _currentAppId = applicationMetadata.applicationID;
}

- (void)deviceManager:(MSFKDeviceManager *)deviceManager volumeDidChangeToLevel:(float)volumeLevel isMuted:(BOOL)isMuted
{
    DLog(@"volume: %f isMuted: %d", volumeLevel, isMuted);
    
    _currentVolumeLevel = volumeLevel;
    _currentMuteStatus = isMuted;
    
    [_subscriptions enumerateObjectsUsingBlock:^(ServiceSubscription *subscription, NSUInteger idx, BOOL *stop)
     {
         NSString *eventName = (NSString *) subscription.payload;
         
         if (eventName)
         {
             if ([eventName isEqualToString:kFlintServiceVolumeSubscriptionName])
             {
                 [subscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger successIdx, BOOL *successStop)
                  {
                      VolumeSuccessBlock volumeSuccess = (VolumeSuccessBlock) success;
                      
                      if (volumeSuccess)
                      dispatch_on_main(^{ volumeSuccess(volumeLevel); });
                  }];
             }
             
             if ([eventName isEqualToString:kFlintServiceMuteSubscriptionName])
             {
                 [subscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger successIdx, BOOL *successStop)
                  {
                      MuteSuccessBlock muteSuccess = (MuteSuccessBlock) success;
                      
                      if (muteSuccess)
                      dispatch_on_main(^{ muteSuccess(isMuted); });
                  }];
             }
         }
     }];
}

- (void)deviceManager:(MSFKDeviceManager *)deviceManager didDisconnectWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);
    
    self.connected = NO;
    
    _flintMediaControlChannel.delegate = nil;
    _flintMediaControlChannel = nil;
    _flintDeviceManager = nil;
    
    dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:error]; });
}

#pragma mark - Media Player

- (id<MediaPlayer>)mediaPlayer
{
    return self;
}

- (CapabilityPriorityLevel)mediaPlayerPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    MSFKMediaMetadata *metaData = [[MSFKMediaMetadata alloc] initWithMetadataType:MSFKMediaMetadataTypePhoto];
    [metaData setString:title forKey:kMSFKMetadataKeyTitle];
    [metaData setString:description forKey:kMSFKMetadataKeySubtitle];
    
    if (iconURL)
    {
        MSFKImage *iconImage = [[MSFKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }
    
    MSFKMediaInformation *mediaInformation = [[MSFKMediaInformation alloc] initWithContentID:imageURL.absoluteString streamType:MSFKMediaStreamTypeNone contentType:mimeType metadata:metaData streamDuration:0 customData:nil];
    
    [self playMedia:mediaInformation webAppId:kMSFKMediaDefaultReceiverApplicationID success:success failure:failure];
}

- (void) displayImage:(MediaInfo *)mediaInfo
              success:(MediaPlayerDisplaySuccessBlock)success
              failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    [self displayImage:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType success:success failure:failure];
}

- (void) playMedia:(NSURL *)videoURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    MSFKMediaMetadata *metaData = [[MSFKMediaMetadata alloc] initWithMetadataType:MSFKMediaMetadataTypeMovie];
    [metaData setString:title forKey:kMSFKMetadataKeyTitle];
    [metaData setString:description forKey:kMSFKMetadataKeySubtitle];
    
    if (iconURL)
    {
        MSFKImage *iconImage = [[MSFKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }
    
    MSFKMediaInformation *mediaInformation = [[MSFKMediaInformation alloc] initWithContentID:videoURL.absoluteString streamType:MSFKMediaStreamTypeBuffered contentType:mimeType metadata:metaData streamDuration:1000 customData:nil];
    
    [self playMedia:mediaInformation webAppId:kMSFKMediaDefaultReceiverApplicationID success:success failure:failure];
}

- (void) playMedia:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    [self playMedia:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType shouldLoop:shouldLoop success:success failure:failure];
}

- (void) playMedia:(MSFKMediaInformation *)mediaInformation webAppId:(NSString *)mediaAppId success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    WebAppLaunchSuccessBlock webAppLaunchBlock = ^(WebAppSession *webAppSession)
    {
        NSInteger result = [_flintMediaControlChannel loadMedia:mediaInformation autoplay:YES];
        
        if (result == kMSFKInvalidRequestID)
        {
            if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
        } else
        {
            webAppSession.launchSession.sessionType = LaunchSessionTypeMedia;
            
            _flintMediaControlChannel.delegate = (FlintWebAppSession *) webAppSession;
            
            if (success)
            success(webAppSession.launchSession, webAppSession.mediaControl);
        }
    };
    
//    _launchingAppId = mediaAppId;
//    
//    [_launchSuccessBlocks setObject:webAppLaunchBlock forKey:mediaAppId];
    
    _launchingAppId = _flintDeviceManager.appId;
    [_launchSuccessBlocks setObject:webAppLaunchBlock forKey:_flintDeviceManager.appId];
    
    if (failure)
    [_launchFailureBlocks setObject:failure forKey:mediaAppId];
    
    BOOL result = [_flintDeviceManager launchApplication:mediaAppId relaunchIfRunning:NO];
    
    if (!result)
    {
//        [_launchSuccessBlocks removeObjectForKey:mediaAppId];
//        [_launchFailureBlocks removeObjectForKey:mediaAppId];
       
        [_launchSuccessBlocks removeObjectForKey:_flintDeviceManager.appId];
        [_launchFailureBlocks removeObjectForKey:_flintDeviceManager.appId];
        
        if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    }
}

- (void)closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    BOOL result = [_flintDeviceManager stopApplication];
    
    if (result)
    {
        if (success)
        success(nil);
    } else
    {
        if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    }
}

#pragma mark - Media Control

- (id<MediaControl>)mediaControl
{
    return self;
}

- (CapabilityPriorityLevel)mediaControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;
    
    @try
    {
        result = [_flintMediaControlChannel play];
    } @catch (NSException *exception)
    {
        // this exception will be caught when trying to send command with no video
        result = kMSFKInvalidRequestID;
    }
    
    if (result == kMSFKInvalidRequestID)
    {
        if (failure)
        failure(nil);
    } else
    {
        if (success)
        success(nil);
    }
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;
    
    @try
    {
        result = [_flintMediaControlChannel pause];
    } @catch (NSException *exception)
    {
        // this exception will be caught when trying to send command with no video
        result = kMSFKInvalidRequestID;
    }
    
    if (result == kMSFKInvalidRequestID)
    {
        if (failure)
        failure(nil);
    } else
    {
        if (success)
        success(nil);
    }
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;
    
    @try
    {
        result = [_flintMediaControlChannel stop];
    } @catch (NSException *exception)
    {
        // this exception will be caught when trying to send command with no video
        result = kMSFKInvalidRequestID;
    }
    
    if (result == kMSFKInvalidRequestID)
    {
        if (failure)
        failure(nil);
    } else
    {
        if (success)
        success(nil);
    }
}

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
    failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
    failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - WebAppLauncher

- (id<WebAppLauncher>)webAppLauncher
{
    return self;
}

- (CapabilityPriorityLevel)webAppLauncherPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)launchWebApp:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchWebApp:webAppId relaunchIfRunning:YES success:success failure:failure];
}

- (void)launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [_launchSuccessBlocks removeObjectForKey:webAppId];
    [_launchFailureBlocks removeObjectForKey:webAppId];
    
    if (success)
    [_launchSuccessBlocks setObject:success forKey:webAppId];
    
    if (failure)
    [_launchFailureBlocks setObject:failure forKey:webAppId];
    
    _launchingAppId = webAppId;
    
    BOOL result = [_flintDeviceManager launchApplication:webAppId relaunchIfRunning:relaunchIfRunning];
    
    if (!result)
    {
        [_launchSuccessBlocks removeObjectForKey:webAppId];
        [_launchFailureBlocks removeObjectForKey:webAppId];
        _launchingAppId = nil;
        
        if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Could not detect if web app launched -- make sure you have the Google Cast Receiver JavaScript file in your web app"]);
    }
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
    failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
    failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)joinWebApp:(LaunchSession *)webAppLaunchSession success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    WebAppLaunchSuccessBlock mySuccess = ^(WebAppSession *webAppSession)
    {
        SuccessBlock joinSuccess = ^(id responseObject)
        {
            if (success)
            success(webAppSession);
        };
        
        [webAppSession connectWithSuccess:joinSuccess failure:failure];
    };
    
    [_launchSuccessBlocks setObject:mySuccess forKey:webAppLaunchSession.appId];
    
    if (failure)
    [_launchFailureBlocks setObject:failure forKey:webAppLaunchSession.appId];
    
    _launchingAppId = webAppLaunchSession.appId;
    
    BOOL result = [_flintDeviceManager joinApplication:webAppLaunchSession.appId];
    
    if (!result)
    {
        [_launchSuccessBlocks removeObjectForKey:webAppLaunchSession.appId];
        [_launchFailureBlocks removeObjectForKey:webAppLaunchSession.appId];
        _launchingAppId = nil;
        
        if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Could not detect if web app launched -- make sure you have the Google Cast Receiver JavaScript file in your web app"]);
    }
}

- (void) joinWebAppWithId:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self;
    
    [self joinWebApp:launchSession success:success failure:failure];
}

- (void)closeWebApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    BOOL result = [self.flintDeviceManager stopApplication];
    
    if (result)
    {
        if (success)
        success(nil);
    } else
    {
        if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    }
}

#pragma mark - Volume Control

- (id <VolumeControl>)volumeControl
{
    return self;
}

- (CapabilityPriorityLevel)volumeControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)volumeUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getVolumeWithSuccess:^(float volume)
     {
         if (volume >= 1.0)
         {
             if (success)
             success(nil);
         } else
         {
             float newVolume = volume + 0.01;
             
             if (newVolume > 1.0)
             newVolume = 1.0;
             
             [self setVolume:newVolume success:success failure:failure];
         }
     } failure:failure];
}

- (void)volumeDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getVolumeWithSuccess:^(float volume)
     {
         if (volume <= 0.0)
         {
             if (success)
             success(nil);
         } else
         {
             float newVolume = volume - 0.01;
             
             if (newVolume < 0.0)
             newVolume = 0.0;
             
             [self setVolume:newVolume success:success failure:failure];
         }
     } failure:failure];
}

- (void)setMute:(BOOL)mute success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result = [self.flintDeviceManager setMuted:mute];
    
    if (result == kMSFKInvalidRequestID)
    {
        if (failure)
        [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil];
    } else
    {
        [self.flintDeviceManager requestDeviceStatus];
        
        if (success)
        success(nil);
    }
}

- (void)getMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentMuteStatus)
    {
        if (success)
        success(_currentMuteStatus);
    } else
    {
        if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Cannot get this information without media loaded"]);
    }
}

- (ServiceSubscription *)subscribeMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentMuteStatus)
    {
        if (success)
        success(_currentMuteStatus);
    }
    
    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:kFlintServiceMuteSubscriptionName callId:[self getNextId]];
    [subscription addSuccess:success];
    [subscription addFailure:failure];
    [subscription subscribe];
    
    return subscription;
}

- (void)setVolume:(float)volume success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSInteger result;
    NSString *failureMessage;
    
    @try
    {
        result = [self.flintDeviceManager setVolume:volume];
    } @catch (NSException *ex)
    {
        // this is likely caused by having no active media session
        result = kMSFKInvalidRequestID;
        failureMessage = @"There is no active media session to set volume on";
    }
    
    if (result == kMSFKInvalidRequestID)
    {
        if (failure)
        [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:failureMessage];
    } else
    {
        [self.flintDeviceManager requestDeviceStatus];
        
        if (success)
        success(nil);
    }
}

- (void)getVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentVolumeLevel)
    {
        if (success)
        success(_currentVolumeLevel);
    } else
    {
        if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Cannot get this information without media loaded"]);
    }
}

- (ServiceSubscription *)subscribeVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    if (_currentVolumeLevel)
    {
        if (success)
        success(_currentVolumeLevel);
    }
    
    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:kFlintServiceVolumeSubscriptionName callId:[self getNextId]];
    [subscription addSuccess:success];
    [subscription addFailure:failure];
    [subscription subscribe];
    
    [self.flintDeviceManager requestDeviceStatus];
    
    return subscription;
}

@end