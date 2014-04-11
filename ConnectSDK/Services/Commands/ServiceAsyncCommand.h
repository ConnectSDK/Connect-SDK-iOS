//
//  ServiceAsyncCommand.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/23/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "ServiceCommand.h"

@interface ServiceAsyncCommand : ServiceCommand

+ (instancetype) asyncWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)URL payload:(id)payload;

@end
