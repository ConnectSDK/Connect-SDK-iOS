//
//  ServiceConfig.h
//  Connect SDK
//
//  Created by Jeremy White on 12/9/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServiceDescription.h"
#import "ServiceConfigDelegate.h"

@interface ServiceConfig :  NSObject <NSCoding>

@property (nonatomic, strong) NSString *UUID;
@property (nonatomic) BOOL connected;
@property (nonatomic) BOOL wasConnected;
@property (nonatomic) double lastDetection;

@property (nonatomic, weak) id<ServiceConfigDelegate> delegate;

- (instancetype) initWithServiceDescription:(ServiceDescription *)serviceDescription;
- (void) addObservers;
- (void) removeObservers;

@end
