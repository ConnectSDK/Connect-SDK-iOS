//
//  JSONObjectCoding.h
//  ConnectSDK
//
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JSONObjectCoding <NSObject>

- (instancetype) initWithJSONObject:(NSDictionary*)dict;
- (NSDictionary*) toJSONObject;

@end
