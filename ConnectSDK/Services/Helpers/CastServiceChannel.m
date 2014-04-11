//
// Created by Jeremy White on 2/20/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "CastServiceChannel.h"
#import "ConnectError.h"
#import "CastWebAppSession.h"

@implementation CastServiceChannel
{
    __weak CastWebAppSession *_session;
}

- (id)initWithAppId:(NSString *)appId session:(CastWebAppSession *)session
{
    self = [super initWithNamespace:@"urn:x-cast:com.connectsdk"];

    if (self)
    {
        _session = session;
    }

    return self;
}

- (void)didReceiveTextMessage:(NSString *)message
{
    if (!_session.delegate && ![_session.delegate respondsToSelector:@selector(webAppSession:didReceiveMessage:)])
        return;

    NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSError *parseError;
    id messageJSON = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:&parseError];

    if (parseError || !messageJSON)
    {
        dispatch_on_main(^{
            [_session.delegate webAppSession:_session didReceiveMessage:message];
        });
    } else
    {
        dispatch_on_main(^{
            [_session.delegate webAppSession:_session didReceiveMessage:messageJSON];
        });
    }
}

- (void)didConnect
{
    if (self.connectionSuccess)
        dispatch_on_main(^{ self.connectionSuccess(nil); });
}

- (void)didDisconnect
{
    if (_session && _session.delegate && [_session.delegate respondsToSelector:@selector(webAppSessionDidDisconnect:)])
        [_session.delegate webAppSessionDidDisconnect:_session];
}

@end
