//
// Created by Jeremy White on 1/23/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


/*! Normalized reference object for information about a text input event. */
@interface TextInputStatusInfo : NSObject

/*! Type of keyboard that should be displayed to the user. */
@property (nonatomic) UIKeyboardType keyboardType;

/*! Whether the keyboard is/should be visible to the user. */
@property (nonatomic) BOOL isVisible;

/*! Raw data from the first screen device about the text input status. In most cases, this is an NSDictionary. */
@property (nonatomic, strong) id rawData;

@end
