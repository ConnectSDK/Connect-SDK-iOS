//
//  WebOSTVServiceMouse.m
//  Connect SDK
//
//  Created by Jeremy White on 1/3/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "WebOSTVServiceMouse.h"
#import "LGSRWebSocket.h"
#import "ConnectError.h"

@interface WebOSTVServiceMouse () <LGSRWebSocketDelegate>

@end

@implementation WebOSTVServiceMouse
{
    LGSRWebSocket *_mouseSocket;

    SuccessBlock _success;
    FailureBlock _failure;

    double _mouseMoveX;
    double _mouseMoveY;
    BOOL _mouseIsMoving;
}

- (instancetype) initWithSocket:(NSString*)socket success:(SuccessBlock)success failure:(FailureBlock)failure
{
    self = [super init];

    if (self)
    {
        _success = success;
        _failure = failure;

        _mouseSocket = [[LGSRWebSocket alloc] initWithURL:[[NSURL alloc] initWithString:socket]];
        _mouseSocket.delegate = self;
        [_mouseSocket open];
    }

    return self;
}

- (void)moveWithX:(double)xVal andY:(double)yVal
{
    _mouseMoveX += xVal;
    _mouseMoveY += yVal;

    if (!_mouseIsMoving)
    {
        _mouseIsMoving = YES;

        [self moveMouse];
    }
}

- (void) moveMouse
{
    NSString *moveString = [NSString stringWithFormat:@"type:move\ndx:%f\ndy:%f\ndown:%d\n\n", _mouseMoveX, _mouseMoveY, 0];
    [self sendPackage:moveString];

    _mouseMoveX = 0;
    _mouseMoveY = 0;
    _mouseIsMoving = NO;
}

- (void) scrollWithX:(double)xVal andY:(double)yVal
{
    NSString *scrollString = [NSString stringWithFormat:@"type:scroll\ndx:%f\ndy:%f\n\n", xVal, yVal];
    [self sendPackage:scrollString];
}

- (void) click
{
    NSString *clickString = @"type:click\n\n";
    [self sendPackage:clickString];
}

-(void) button:(WebOSTVMouseButton)keyName
{
    NSString *keyString;

    switch (keyName)
    {
        case WebOSTVMouseButtonHome: keyString = @"HOME"; break;
        case WebOSTVMouseButtonBack: keyString = @"BACK"; break;
        case WebOSTVMouseButtonUp: keyString = @"UP"; break;
        case WebOSTVMouseButtonDown: keyString = @"DOWN"; break;
        case WebOSTVMouseButtonLeft: keyString = @"LEFT"; break;
        case WebOSTVMouseButtonRight: keyString = @"RIGHT"; break;
        default:break;
    }

    if (keyString)
    {
        NSString *buttonString = [NSString stringWithFormat:@"type:button\nname:%@\n\n", keyString];
        [self sendPackage:buttonString];
    }
}

- (void) sendPackage:(NSString*)package
{
    if ([_mouseSocket readyState] == LGSR_OPEN)
        [_mouseSocket send:package];
}

- (void) disconnect
{
    _mouseMoveX = 0;
    _mouseMoveY = 0;
    _mouseIsMoving = NO;

    [_mouseSocket close];
    _mouseSocket.delegate = nil;
    _mouseSocket = nil;

    _success = nil;
    _failure = nil;
}

#pragma mark LGSRWebSocketDelegate

- (void)webSocketDidOpen:(LGSRWebSocket *)webSocket
{
    _mouseMoveX = 0;
    _mouseMoveY = 0;
    _mouseIsMoving = NO;

    if (_success)
        _success(nil);
}

- (void)webSocket:(LGSRWebSocket *)webSocket didReceiveMessage:(id)message
{
    // don't need to handle incoming messages on the mouseControl socket
}

- (void)webSocket:(LGSRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    if (_failure)
        _failure(error);
}

- (void)webSocket:(LGSRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    if (wasClean)
    {
        _mouseMoveX = 0;
        _mouseMoveY = 0;
        _mouseIsMoving = NO;

        _success = nil;
        _failure = nil;
    }

    if (!wasClean && _failure)
        _failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:reason]);
}

@end
