//
// Created by Jeremy White on 4/14/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "DeviceServiceReachability.h"


@implementation DeviceServiceReachability
{
    NSTimer *_runTimer;
    NSOperationQueue *_reachabilityQueue;
}

- (instancetype) initWithTargetURL:(NSURL *)targetURL
{
    self = [super init];

    if (self)
    {
        _running = NO;
        _targetURL = targetURL;
        _reachabilityQueue = [[NSOperationQueue alloc] init];
    }

    return self;
}

+ (instancetype) reachabilityWithTargetURL:(NSURL *)targetURL
{
    return [[self alloc] initWithTargetURL:targetURL];
}

- (void) start
{
    _running = YES;
    _runTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(checkReachability) userInfo:nil repeats:YES];
    [_runTimer fire];
}

- (void) stop
{
    if (_running)
    {
        [_runTimer invalidate];
        _runTimer = nil;

        _running = NO;
    }
}

- (void) checkReachability
{
    if (!_running)
        return;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.targetURL];
    [request setTimeoutInterval:10];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];

    [NSURLConnection sendAsynchronousRequest:request queue:_reachabilityQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        if (!_running)
            return;

        if (data == nil && connectionError && response == nil)
        {
            [self stop];

            if (self.delegate)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [self.delegate didLoseReachability:self];
                });
            }
        }
    }];
}

@end
