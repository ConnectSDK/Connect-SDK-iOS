//
// Created by Jeremy White on 6/18/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "MultiScreenWebAppSession.h"


@implementation MultiScreenWebAppSession

- (void) closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.service.webAppLauncher closeWebApp:self.launchSession success:success failure:failure];
}

@end
