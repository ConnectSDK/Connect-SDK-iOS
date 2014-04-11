//
//  ServiceDescription.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServiceDescription : NSObject <NSCoding>

@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *serviceId;
@property (nonatomic) NSUInteger port;
@property (nonatomic, strong) NSString *UUID;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *friendlyName;
@property (nonatomic, strong) NSString *manufacturer;
@property (nonatomic, strong) NSString *modelName;
@property (nonatomic, strong) NSString *modelDescription;
@property (nonatomic, strong) NSString *modelNumber;
@property (nonatomic, strong) NSURL *commandURL;
@property (nonatomic, strong) NSString *locationXML;
@property (nonatomic, strong) NSDictionary *locationResponseHeaders;
@property (nonatomic) double lastDetection;

- (instancetype)initWithAddress:(NSString *)address UUID:(NSString*)UUID;
+ (instancetype)descriptionWithAddress:(NSString *)address UUID:(NSString*)UUID;

@end
