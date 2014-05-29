//
// Created by Jeremy White on 5/28/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "AirPlayHTTPService.h"
#import "DeviceService.h"
#import "AirPlayService.h"
#import "ConnectError.h"
#import "XMLReader.h"
#import "DeviceServiceReachability.h"
#import "Guid.h"
#import "GCDWebServer.h"

@interface AirPlayHTTPService () <ServiceCommandDelegate, DeviceServiceReachabilityDelegate>

@property (nonatomic) DeviceServiceReachability *serviceReachability;
@property (nonatomic) NSString *sessionId;
@property (nonatomic) GCDWebServer *subscriptionServer;
@property (nonatomic) NSOperationQueue *commandQueue;
@property (nonatomic) dispatch_queue_t imageProcessingQueue;

@end

@implementation AirPlayHTTPService

- (instancetype) initWithAirPlayService:(AirPlayService *)service
{
    self = [super init];

    if (self)
    {
        _service = service;
        _commandQueue = [[NSOperationQueue alloc] init];
        _imageProcessingQueue = dispatch_queue_create("com.connectsdk.AirPlayHTTPService.ImageProcessing", DISPATCH_QUEUE_SERIAL);
    }

    return self;
}

#pragma mark - Connection & Reachability

- (void) connect
{
    _connecting = YES;

    self.sessionId = [[Guid randomGuid] stringValue];

    NSURL *connectionURL = [self.service.serviceDescription.commandURL URLByAppendingPathComponent:@"reverse"];
    NSMutableURLRequest *connectionRequest = [NSMutableURLRequest requestWithURL:connectionURL];

    [connectionRequest setHTTPMethod:@"POST"];
    [connectionRequest setValue:@"PTTH/1.0" forHTTPHeaderField:@"Upgrade"];
    [connectionRequest setValue:@"Upgrade" forHTTPHeaderField:@"Connection"];
    [connectionRequest setValue:@"event" forHTTPHeaderField:@"X-Apple-Purpose"];
    [connectionRequest setValue:@"0" forHTTPHeaderField: @"Content-Length"];
    [connectionRequest setValue:@"MediaControl/1.0" forHTTPHeaderField:@"User-Agent"];
    [connectionRequest setValue:self.service.serviceDescription.UUID forHTTPHeaderField:@"X-Apple-Device-ID"];
    [connectionRequest setValue:self.sessionId forHTTPHeaderField: @"X-Apple-Session-ID"];

    [connectionRequest setValue:nil forHTTPHeaderField:@"Host"];
    [connectionRequest setValue:nil forHTTPHeaderField:@"Accept-Language"];
    [connectionRequest setValue:nil forHTTPHeaderField:@"Accept"];
    [connectionRequest setValue:nil forHTTPHeaderField:@"Accept-Encoding"];
    [connectionRequest setValue:nil forHTTPHeaderField:@"Accept-Language"];

    [NSURLConnection sendAsynchronousRequest:connectionRequest queue:self.commandQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;

        if (connectionError)
        {
            [self hConnectError:connectionError];
        } else
        {
            if (httpResponse.statusCode == 101)
                [self hConnectSuccess];
            else
            {
                NSString *errorMessage = [NSString stringWithFormat:@"Could not establish a connection with device, received HTTP status code %@", @(httpResponse.statusCode)];
                [self hConnectError:[ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:errorMessage]];
            }
        }
    }];
}

- (void) hConnectSuccess
{
    [self startSubscriptionServer];

    _connecting = NO;
    _connected = YES;

    _serviceReachability = [DeviceServiceReachability reachabilityWithTargetURL:self.service.serviceDescription.commandURL];
    _serviceReachability.delegate = self;
    [_serviceReachability start];

    if (self.service.connected && self.service.delegate && [self.service.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.service.delegate deviceServiceConnectionSuccess:self.service]; });
}

- (void) hConnectError:(NSError *)error
{
    self.sessionId = nil;

    _connecting = NO;
    _connected = NO;

    if (self.service.delegate && [self.service.delegate respondsToSelector:@selector(deviceService:didFailConnectWithError:)])
        dispatch_on_main(^{ [self.service.delegate deviceService:self.service didFailConnectWithError:error]; });
}

- (void) disconnect
{
    self.sessionId = nil;

    if (_subscriptionServer)
        [self stopSubscriptionServer];

    if (_serviceReachability)
        [_serviceReachability stop];

    _connected = NO;
}

- (void) didLoseReachability:(DeviceServiceReachability *)reachability
{
    if (self.connected)
        [self disconnect];
    else
        [_serviceReachability stop];
}

#pragma mark - HTTP server for events/subscriptions

- (void) startSubscriptionServer
{
    if (_subscriptionServer)
        [self stopSubscriptionServer];

    _subscriptionServer = [[GCDWebServer alloc] init];

    [_subscriptionServer addDefaultHandlerForMethod:@"POST"
                                       requestClass:[GCDWebServerDataRequest class]
                                       processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        GCDWebServerDataRequest *dataRequest = (GCDWebServerDataRequest *)request;

        NSString *firstPathComponent = [dataRequest.path.pathComponents[0] lowercaseString];

        if (firstPathComponent && [firstPathComponent isEqualToString:@"event"])
        {
            NSError *xmlError;
            NSDictionary *responseXML = [XMLReader dictionaryForXMLData:dataRequest.data error:&xmlError];

            if (xmlError)
            {
                return [GCDWebServerResponse responseWithStatusCode:400];
            } else
            {
                return [GCDWebServerResponse responseWithStatusCode:200];
            }
        } else
        {
            return [GCDWebServerResponse responseWithStatusCode:404];
        }
    }];

    [_subscriptionServer startWithPort:self.service.serviceDescription.port bonjourName:nil];
}

- (void) stopSubscriptionServer
{
    if (!_subscriptionServer)
        return;

    [_subscriptionServer stop];
    _subscriptionServer = nil;
}

#pragma mark - Command management

- (int) sendCommand:(ServiceCommand *)command withPayload:(id)payload toURL:(NSURL *)URL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setTimeoutInterval:6];

    if (payload || [command.HTTPMethod isEqualToString:@"POST"] || [command.HTTPMethod isEqualToString:@"PUT"])
    {
        [request setHTTPMethod:@"POST"];

        if (payload)
        {
            NSData *payloadData;

            if ([payload isKindOfClass:[NSString class]])
            {
                NSString *payloadString = (NSString *)payload;
                payloadData = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
            } else if ([payload isKindOfClass:[NSDictionary class]])
                payloadData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
            else if ([payload isKindOfClass:[NSData class]])
                payloadData = payload;

            if (payloadData == nil)
            {
                if (command.callbackError)
                    command.callbackError([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Unknown error preparing message to send"]);

                return -1;
            }

            [request addValue:[NSString stringWithFormat:@"%i", (unsigned int) [payloadData length]] forHTTPHeaderField:@"Content-Length"];
            [request addValue:@"text/plain;charset=\"utf-8\"" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:payloadData];

            DLog(@"[OUT] : %@ \n %@", [request allHTTPHeaderFields], payload);
        } else
        {
            [request addValue:@"0" forHTTPHeaderField:@"Content-Length"];
        }
    } else
    {
        [request setHTTPMethod:command.HTTPMethod];
        [request addValue:@"0" forHTTPHeaderField:@"Content-Length"];

        DLog(@"[OUT] : %@", [request allHTTPHeaderFields]);
    }

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        DLog(@"[IN] : %@", [httpResponse allHeaderFields]);

        if (connectionError)
        {
            if (command.callbackError)
                dispatch_on_main(^{ command.callbackError(connectionError); });
        } else
        {
            BOOL statusOK = NO;
            NSError *error;
            NSString *locationPath;

            switch ([httpResponse statusCode])
            {
                case 503:
                    error = [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Could not start application"];
                    break;

                case 501:
                    error = [ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:@"Was unable to perform the requested action, not supported"];
                    break;

                case 413:
                    error = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Message body is too long"];
                    break;

                case 404:
                    error = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not find requested application"];
                    break;

                case 201: // CREATED:  application launch success
                    statusOK = YES;
                    locationPath = [httpResponse.allHeaderFields objectForKey:@"Location"];
                    break;

                case 206: // PARTIAL CONTENT: not listed in DIAL spec, but don't want to exclude successful 2xx response code
                case 205: // RESET CONTENT: not listed in DIAL spec, but don't want to exclude successful 2xx response code
                case 204: // NO CONTENT: not listed in DIAL spec, but don't want to exclude successful 2xx response code
                case 203: // NON-AUTHORITATIVE INFORMATION: not listed in DIAL spec, but don't want to exclude successful 2xx response code
                case 202: // ACCEPTED: not listed in DIAL spec, but don't want to exclude successful 2xx response code
                case 200: // OK: command success
                    statusOK = YES;
                    break;

                default:
                    error = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"An unknown error occurred"];
            }

            if (statusOK)
            {
                NSError *xmlError;
                NSDictionary *responseXML = [XMLReader dictionaryForXMLData:data error:&xmlError];

                DLog(@"[IN] : %@", responseXML);

                if (xmlError)
                {
                    if (command.callbackError)
                        command.callbackError(xmlError);
                } else
                {
                    if (command.callbackComplete)
                    {
                        if (locationPath)
                            dispatch_on_main(^{ command.callbackComplete(locationPath); });
                        else
                            dispatch_on_main(^{ command.callbackComplete(responseXML); });
                    }
                }
            } else
            {
                if (command.callbackError)
                    command.callbackError(error);
            }
        }
    }];

    // TODO: need to implement callIds in here
    return -1;
}

- (int) sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    return -1;
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
    NSString *commandPathComponent = @"photo";
    NSURL *commandURL = [self.service.serviceDescription.commandURL URLByAppendingPathComponent:commandPathComponent];

    ServiceCommand *command = [ServiceCommand commandWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"PUT";
    command.callbackComplete = ^(id responseObject) {
        LaunchSession *launchSession = [LaunchSession launchSessionForAppId:commandPathComponent];
        launchSession.sessionType = LaunchSessionTypeMedia;
        launchSession.service = self.service;
        launchSession.sessionId = self.sessionId;

        if (success)
            dispatch_on_main(^{ success(launchSession, self.service.mediaControl); });
    };

    command.callbackError = failure;

    dispatch_async(self.imageProcessingQueue, ^{
        NSError *downloadError;
        NSData *downloadedImageData = [NSData dataWithContentsOfURL:imageURL options:0 error:&downloadError];

        if (!downloadedImageData || downloadError)
        {
            if (failure)
            {
                if (downloadError)
                    dispatch_on_main(^{ failure(downloadError); });
                else
                    dispatch_on_main(^{ failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not download requested image"]); });
            }

            return;
        }

        NSData *processedImageData;

        if ([imageURL.absoluteString hasSuffix:@"jpg"] || [imageURL.absoluteString hasSuffix:@"jpeg"])
            processedImageData = downloadedImageData;
        else
        {
            UIImage *image = [UIImage imageWithData:downloadedImageData];

            if (image)
            {
                processedImageData = UIImageJPEGRepresentation(image, 1.0);

                if (!processedImageData)
                {
                    if (failure)
                        dispatch_on_main(^{ failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not convert downloaded image to JPEG format"]); });

                    return;
                }
            } else
            {
                if (failure)
                    dispatch_on_main(^{ failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not convert downloaded data to a suitable image format"]); });

                return;
            }
        }

        command.payload = processedImageData;
        [command send];
    });
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{

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

}

- (void) pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{

}

- (ServiceSubscription *) subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    return nil;
}

@end
