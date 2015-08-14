//
//  DelegateMock.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-08-13.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "DiscoveryProviderDelegate.h"

#import <XCTest/XCTest.h>

@interface DelegateMock : NSObject <DiscoveryProviderDelegate>

@property (nonatomic, strong) XCTestExpectation *exp;
@property (nonatomic, strong) ServiceDescription *capturedServiceDescription;

@end
