//
//  WebOSTVServiceMouse.m
//  Connect SDK
//
//  Created by Jeremy White on 1/3/14.
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

#import <CoreGraphics/CGGeometry.h>
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

    CGVector _mouseDistance;
    CGVector _scrollDistance;

    BOOL _mouseIsMoving;
    BOOL _mouseIsScrolling;
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

- (void) move:(CGVector)distance
{
    _mouseDistance = CGVectorMake(
        _mouseDistance.dx + distance.dx,
        _mouseDistance.dy + distance.dy
    );

    if (!_mouseIsMoving)
    {
        _mouseIsMoving = YES;

        [self moveMouse];
    }
}

- (void) moveMouse
{
    NSString *moveString = [NSString stringWithFormat:@"type:move\ndx:%f\ndy:%f\ndown:%d\n\n", _mouseDistance.dx, _mouseDistance.dy, 0];
    [self sendPackage:moveString];

    _mouseDistance = CGVectorMake(0, 0);
    _mouseIsMoving = NO;
}

- (void) scroll:(CGVector)distance
{
    _scrollDistance = CGVectorMake(
        _scrollDistance.dx + distance.dx,
        _scrollDistance.dy + distance.dy
    );

    if (!_mouseIsScrolling)
    {
        _mouseIsScrolling = YES;

        [self scroll];
    }
}

- (void) scroll
{
    NSString *scrollString = [NSString stringWithFormat:@"type:scroll\ndx:%f\ndy:%f\n\n", _scrollDistance.dx, _scrollDistance.dy];
    [self sendPackage:scrollString];

    _scrollDistance = CGVectorMake(0, 0);
    _mouseIsScrolling = NO;
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
    _mouseDistance = CGVectorMake(0, 0);
    _mouseIsMoving = NO;

    _scrollDistance = CGVectorMake(0, 0);
    _mouseIsScrolling = NO;

    [_mouseSocket close];
    _mouseSocket.delegate = nil;
    _mouseSocket = nil;

    _success = nil;
    _failure = nil;
}

#pragma mark LGSRWebSocketDelegate

- (void)webSocketDidOpen:(LGSRWebSocket *)webSocket
{
    _mouseDistance = CGVectorMake(0, 0);
    _mouseIsMoving = NO;

    _scrollDistance = CGVectorMake(0, 0);
    _mouseIsScrolling = NO;

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
        _mouseDistance = CGVectorMake(0, 0);
        _mouseIsMoving = NO;

        _scrollDistance = CGVectorMake(0, 0);
        _mouseIsScrolling = NO;

        _success = nil;
        _failure = nil;
    }

    if (!wasClean && _failure)
        _failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:reason]);
}

@end
