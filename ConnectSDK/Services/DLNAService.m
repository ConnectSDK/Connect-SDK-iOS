//
//  DLNAService.m
//  Connect SDK
//
//  Created by Jeremy White on 12/13/13.
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

#import "DLNAService.h"
#import "ConnectError.h"
#import "XMLReader.h"
#import "ConnectUtil.h"
#import "DeviceServiceReachability.h"

#define kDataFieldName @"XMLData"
#define kActionFieldName @"SOAPAction"

@interface DLNAService() <ServiceCommandDelegate, DeviceServiceReachabilityDelegate>
{
//    NSOperationQueue *_commandQueue;
    NSURL *_commandURL;
    DeviceServiceReachability *_serviceReachability;
}

@end

@implementation DLNAService

@synthesize serviceDescription = _serviceDescription;

- (void) updateCapabilities
{
    NSArray *capabilities = @[
        kMediaPlayerDisplayImage,
        kMediaPlayerPlayVideo,
        kMediaPlayerPlayAudio,
        kMediaPlayerClose,
        kMediaPlayerMetaDataTitle,
        kMediaPlayerMetaDataMimeType,
        kMediaControlPlay,
        kMediaControlPause,
        kMediaControlStop,
        kMediaControlSeek,
        kMediaControlPosition,
        kMediaControlDuration,
        kMediaControlPlayState
    ];

    [self setCapabilities:capabilities];
}

+ (NSDictionary *) discoveryParameters
{
    return @{
            @"serviceId": kConnectSDKDLNAServiceId,
            @"ssdp":@{
                    @"filter":@"urn:schemas-upnp-org:device:MediaRenderer:1",
                    @"requiredServices":@[
                            @"urn:schemas-upnp-org:service:AVTransport:1",
                            @"urn:schemas-upnp-org:service:RenderingControl:1"
                    ]
            }
    };
}

- (id) initWithJSONObject:(NSDictionary *)dict
{
    // not supported
    return nil;
}

//- (NSDictionary *) toJSONObject
//{
//    // not supported
//    return nil;
//}

#pragma mark - Helper methods

//- (NSOperationQueue *)commandQueue
//{
//    if (_commandQueue == nil)
//    {
//        _commandQueue = [[NSOperationQueue alloc] init];
//    }
//
//    return _commandQueue;
//}

- (void)setServiceDescription:(ServiceDescription *)serviceDescription
{
    _serviceDescription = serviceDescription;
    
    if (!_serviceDescription.locationXML)
        _commandURL = nil;
}

- (NSURL *)commandURL
{
    if (_commandURL)
        return _commandURL;

    if (!self.serviceDescription.locationXML)
    {
        _commandURL = self.serviceDescription.commandURL;
        return _commandURL;
    }

    NSError *parseError;

    NSString *cleanLocationXML = [self.serviceDescription.locationXML stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSDictionary *dictionary = [XMLReader dictionaryForXMLString:cleanLocationXML error:&parseError];

    if (!parseError)
    {
        NSDictionary *root = [dictionary objectForKey:@"root"];
        NSDictionary *device = [root objectForKey:@"device"];
        NSArray *serviceList = [[device objectForKey:@"serviceList"] objectForKey:@"service"];
        __block NSDictionary *avTransport;

        [serviceList enumerateObjectsUsingBlock:^(NSDictionary *service, NSUInteger idx, BOOL *stop)
        {
            NSString *serviceType = [[service objectForKey:@"serviceType"] objectForKey:@"text"];

            if ([serviceType isEqualToString:@"urn:schemas-upnp-org:service:AVTransport:1"])
            {
                avTransport = service;
                *stop = YES;
            }
        }];

        if (avTransport)
        {
            NSString *controlPath = [[avTransport objectForKey:@"controlURL"] objectForKey:@"text"];

            if (controlPath)
            {
                NSString *commandPath = [NSString stringWithFormat:@"http://%@:%@%@",
                                self.serviceDescription.commandURL.host,
                                self.serviceDescription.commandURL.port,
                                controlPath];

                _commandURL = [NSURL URLWithString:commandPath];
                return _commandURL;
            }
        }
    }

    return nil;
}

- (BOOL) isConnectable
{
    return YES;
}

- (void) connect
{
//    NSString *targetPath = [NSString stringWithFormat:@"http://%@:%@/", self.serviceDescription.address, @(self.serviceDescription.port)];
//    NSURL *targetURL = [NSURL URLWithString:targetPath];

    _serviceReachability = [DeviceServiceReachability reachabilityWithTargetURL:self.commandURL];
    _serviceReachability.delegate = self;
    [_serviceReachability start];

    self.connected = YES;

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void) disconnect
{
    self.connected = NO;

    [_serviceReachability stop];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

- (void) didLoseReachability:(DeviceServiceReachability *)reachability
{
    if (self.connected)
        [self disconnect];
    else
        [_serviceReachability stop];
}

#pragma mark - ServiceCommandDelegate

- (int) sendCommand:(ServiceCommand *)command withPayload:(NSDictionary *)payload toURL:(NSURL *)URL
{
    NSString *actionField = [payload objectForKey:kActionFieldName];
    NSString *xml = [payload objectForKey:kDataFieldName];

    NSData *xmlData = [xml dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setTimeoutInterval:30];
    [request addValue:@"text/xml;charset=\"utf-8\"" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[NSString stringWithFormat:@"%i", (unsigned int) [xmlData length]] forHTTPHeaderField:@"Content-Length"];
    [request addValue:actionField forHTTPHeaderField:kActionFieldName];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:xmlData];

    DLog(@"[OUT] : %@ \n %@", [request allHTTPHeaderFields], xml);

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        NSError *xmlError;
        NSDictionary *dataXML = [XMLReader dictionaryForXMLData:data error:&xmlError];

        DLog(@"[IN] : %@ \n %@", [((NSHTTPURLResponse *)response) allHeaderFields], dataXML);

        if (connectionError)
        {
            if (command.callbackError)
                dispatch_on_main(^{ command.callbackError(connectionError); });
        } else if (xmlError)
        {
            if (command.callbackError)
                dispatch_on_main(^{ command.callbackError([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not parse command response"]); });
        } else
        {
            NSDictionary *upnpFault = [[[dataXML objectForKey:@"s:Envelope"] objectForKey:@"s:Body"] objectForKey:@"s:Fault"];

            if (upnpFault)
            {
                NSString *errorDescription = [[[[upnpFault objectForKey:@"detail"] objectForKey:@"UPnPError"] objectForKey:@"errorDescription"] objectForKey:@"text"];

                if (!errorDescription)
                    errorDescription = @"Unknown UPnP error";

                if (command.callbackError)
                    dispatch_on_main(^{ command.callbackError([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:errorDescription]); });
            } else
            {
                if (command.callbackComplete)
                    dispatch_on_main(^{ command.callbackComplete(dataXML); });
            }
        }
    }];

    // TODO: need to implement callIds in here
    return 0;
}

#pragma mark - Media Player

- (id <MediaControl>)mediaControl
{
    return self;
}

- (CapabilityPriorityLevel) mediaControlPriority
{
    return CapabilityPriorityLevelNormal;
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString *playXML = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:Play xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
            "<InstanceID>0</InstanceID>"
            "<Speed>1</Speed>"
            "</u:Play>"
            "</s:Body>"
            "</s:Envelope>";

    NSDictionary *playPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Play\"",
            kDataFieldName : playXML
    };

    ServiceCommand *playCommand = [[ServiceCommand alloc] initWithDelegate:self target:[self commandURL] payload:playPayload];
    playCommand.callbackComplete = ^(NSDictionary *responseDic){
        if (success)
            success(nil);
    };
    playCommand.callbackError = failure;
    [playCommand send];
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString *xml = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
    "<s:Body>"
    "<u:Pause xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
    "<InstanceID>0</InstanceID>"
    "</u:Pause>"
    "</s:Body>"
    "</s:Envelope>";
    
    NSDictionary *payload = @{
                                  kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Pause\"",
                                  kDataFieldName : xml
                                  };
    
    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:[self commandURL] payload:payload];
    command.callbackComplete = ^(NSDictionary *responseDic){
        if (success)
            success(nil);
    };
    command.callbackError = failure;
    [command send];
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString *stopXML = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
    "<s:Body>"
    "<u:Stop xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
    "<InstanceID>0</InstanceID>"
    "</u:Stop>"
    "</s:Body>"
    "</s:Envelope>";
    
    NSDictionary *stopPayload = @{
                                  kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Stop\"",
                                  kDataFieldName : stopXML
                                  };
    
    ServiceCommand *stopCommand = [[ServiceCommand alloc] initWithDelegate:self target:[self commandURL] payload:stopPayload];
    stopCommand.callbackComplete = ^(NSDictionary *responseDic){
        if (success)
            success(nil);
    };
    stopCommand.callbackError = failure;
    [stopCommand send];
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

- (void)seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString *timeString = [self stringForTime:position];

    NSString *commandXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:Seek xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
            "<InstanceID>0</InstanceID>"
            "<Unit>REL_TIME</Unit>"
            "<Target>%@</Target>"
            "</u:Seek>"
            "</s:Body>"
            "</s:Envelope>",
            timeString
    ];

    NSDictionary *commandPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Seek\"",
            kDataFieldName : commandXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:[self commandURL] payload:commandPayload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    NSString *commandXML = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:GetTransportInfo xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
            "<InstanceID>0</InstanceID>"
            "</u:GetTransportInfo>"
            "</s:Body>"
            "</s:Envelope>";

    NSDictionary *commandPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#GetTransportInfo\"",
            kDataFieldName : commandXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:[self commandURL] payload:commandPayload];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSDictionary *response = [[[responseObject objectForKey:@"s:Envelope"] objectForKey:@"s:Body"] objectForKey:@"u:GetTransportInfoResponse"];
        NSString *transportState = [[[response objectForKey:@"CurrentTransportState"] objectForKey:@"text"] uppercaseString];

        MediaControlPlayState playState = MediaControlPlayStateUnknown;

        if ([transportState isEqualToString:@"STOPPED"])
            playState = MediaControlPlayStateFinished;
        else if ([transportState isEqualToString:@"PAUSED_PLAYBACK"])
            playState = MediaControlPlayStatePaused;
        else if ([transportState isEqualToString:@"PAUSED_RECORDING"])
            playState = MediaControlPlayStateUnknown;
        else if ([transportState isEqualToString:@"PLAYING"])
            playState = MediaControlPlayStatePlaying;
        else if ([transportState isEqualToString:@"RECORDING"])
            playState = MediaControlPlayStateUnknown;
        else if ([transportState isEqualToString:@"TRANSITIONING"])
            playState = MediaControlPlayStateIdle;
        else if ([transportState isEqualToString:@"NO_MEDIA_PRESENT"])
            playState = MediaControlPlayStateIdle;

        if (success)
            success(playState);
    };
    command.callbackError = failure;
    [command send];
}

- (void)getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure
{
    [self getPositionInfoWithSuccess:^(NSDictionary *responseObject)
    {
        NSDictionary *response = [[[responseObject objectForKey:@"s:Envelope"] objectForKey:@"s:Body"] objectForKey:@"u:GetPositionInfoResponse"];
        NSString *durationString = [[response objectForKey:@"TrackDuration"] objectForKey:@"text"];
        NSTimeInterval duration = [self timeForString:durationString];

        if (success)
            success(duration);
    } failure:failure];
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    [self getPositionInfoWithSuccess:^(NSDictionary *responseObject)
    {
        NSDictionary *response = [[[responseObject objectForKey:@"s:Envelope"] objectForKey:@"s:Body"] objectForKey:@"u:GetPositionInfoResponse"];
        NSString *currentTimeString = [[response objectForKey:@"RelTime"] objectForKey:@"text"];
        NSTimeInterval currentTime = [self timeForString:currentTimeString];

        if (success)
            success(currentTime);
    } failure:failure];
}

- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (void) getPositionInfoWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString *commandXML = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:GetPositionInfo xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
            "<InstanceID>0</InstanceID>"
            "</u:GetPositionInfo>"
            "</s:Body>"
            "</s:Envelope>";

    NSDictionary *commandPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#GetPositionInfo\"",
            kDataFieldName : commandXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:[self commandURL] payload:commandPayload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (NSTimeInterval) timeForString:(NSString *)timeString
{
    if (!timeString || [timeString isEqualToString:@""])
        return 0;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:m:ss"];

    NSDate *time = [formatter dateFromString:timeString];
    NSDate *midnight = [formatter dateFromString:@"00:00:00"];

    NSTimeInterval timeInterval = [time timeIntervalSinceDate:midnight];

    if (timeInterval < 0)
        timeInterval = 0;

    return timeInterval;
}

- (NSString *) stringForTime:(NSTimeInterval)timeInterval
{
    int time = (int) round(timeInterval);

    int second = time % 60;
    int minute = (time / 60) % 60;
    int hour = time / 3600;

    NSString *timeString = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];

    return timeString;
}

#pragma mark - Media Player

- (id <MediaPlayer>)mediaPlayer
{
    return self;
}

- (CapabilityPriorityLevel) mediaPlayerPriority
{
    return CapabilityPriorityLevelNormal;
}

- (void)displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSString *shareXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>"
                                                            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                                                            "<s:Body>"
                                                            "<u:SetAVTransportURI xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
                                                            "<InstanceID>0</InstanceID>"
                                                            "<CurrentURI>%@</CurrentURI>"
                                                            "<CurrentURIMetaData>"
                                                            "&lt;DIDL-Lite xmlns=&quot;urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/&quot; xmlns:upnp=&quot;urn:schemas-upnp-org:metadata-1-0/upnp/&quot; xmlns:dc=&quot;http://purl.org/dc/elements/1.1/&quot;&gt;&lt;item id=&quot;1000&quot; parentID=&quot;0&quot; restricted=&quot;0&quot;&gt;&lt;dc:title&gt;%@&lt;/dc:title&gt;&lt;res protocolInfo=&quot;http-get:*:%@:DLNA.ORG_OP=01&quot;&gt;%@&lt;/res&gt;&lt;upnp:class&gt;object.item.imageItem&lt;/upnp:class&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;"
                                                            "</CurrentURIMetaData>"
                                                            "</u:SetAVTransportURI>"
                                                            "</s:Body>"
                                                            "</s:Envelope>",
                                                    imageURL.absoluteString, title, mimeType, imageURL.absoluteString];
    NSDictionary *sharePayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI\"",
            kDataFieldName : shareXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:[self commandURL] payload:sharePayload];
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        [self playWithSuccess:^(id responseObject) {
            if (success)
            {
                LaunchSession *launchSession = [LaunchSession new];
                launchSession.sessionType = LaunchSessionTypeMedia;
                launchSession.service = self;
                
                success(launchSession, self.mediaControl);
            }
        } failure:failure];
    };

    command.callbackError = failure;
    [command send];
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSArray *mediaElements = [mimeType componentsSeparatedByString:@"/"];
    NSString *mediaType = mediaElements[0];
    NSString *mediaFormat = mediaElements[1];

    if (!mediaType || mediaType.length == 0 || !mediaFormat || mediaFormat.length == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid mimeType (audio/*, video/*, etc"]);

        return;
    }

    mediaFormat = [mediaFormat isEqualToString:@"mp3"] ? @"mpeg" : mediaFormat;
    mimeType = [NSString stringWithFormat:@"%@/%@", mediaType, mediaFormat];

    NSString *shareXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>"
                                                            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                                                            "<s:Body>"
                                                            "<u:SetAVTransportURI xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
                                                            "<InstanceID>0</InstanceID>"
                                                            "<CurrentURI>%@</CurrentURI>"
                                                            "<CurrentURIMetaData>"
                                                            "&lt;DIDL-Lite xmlns=&quot;urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/&quot; xmlns:upnp=&quot;urn:schemas-upnp-org:metadata-1-0/upnp/&quot; xmlns:dc=&quot;http://purl.org/dc/elements/1.1/&quot;&gt;&lt;item id=&quot;0&quot; parentID=&quot;0&quot; restricted=&quot;0&quot;&gt;&lt;dc:title&gt;%@&lt;/dc:title&gt;&lt;dc:description&gt;%@&lt;/dc:description&gt;&lt;res protocolInfo=&quot;http-get:*:%@:DLNA.ORG_PN=MP3;DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01500000000000000000000000000000&quot;&gt;%@&lt;/res&gt;&lt;upnp:albumArtURI&gt;%@&lt;/upnp:albumArtURI&gt;&lt;upnp:class&gt;object.item.%@Item&lt;/upnp:class&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;"
                                                            "</CurrentURIMetaData>"
                                                            "</u:SetAVTransportURI>"
                                                            "</s:Body>"
                                                            "</s:Envelope>",
                                                    mediaURL.absoluteString, title, description, mimeType, mediaURL.absoluteString, iconURL.absoluteString, mediaType];
    NSDictionary *sharePayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI\"",
            kDataFieldName : shareXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:[self commandURL] payload:sharePayload];
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        [self playWithSuccess:^(id responseObject) {
            if (success)
            {
                LaunchSession *launchSession = [LaunchSession new];
                launchSession.sessionType = LaunchSessionTypeMedia;
                launchSession.service = self;
                
                success(launchSession, self.mediaControl);
            }
        } failure:failure];
    };

    command.callbackError = failure;
    [command send];
}

- (void)closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaControl stopWithSuccess:success failure:failure];
}

@end
