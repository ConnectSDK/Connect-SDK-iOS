//
//  ServiceConfigDelegate.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/12/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ServiceConfig;

@protocol ServiceConfigDelegate <NSObject>

- (void) serviceConfigUpdate:(ServiceConfig*)serviceConfig;

@end
