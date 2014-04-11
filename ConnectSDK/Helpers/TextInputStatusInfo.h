//
// Created by Jeremy White on 1/23/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TextInputStatusInfo : NSObject

@property (nonatomic) UIKeyboardType keyboardType;
@property (nonatomic) BOOL isVisible;

@property (nonatomic, strong) id rawData;

@end
