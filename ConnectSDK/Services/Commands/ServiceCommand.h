//
//  ServiceCommand.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import "ServiceCommandDelegate.h"
#import "Capability.h"

@interface ServiceCommand : NSObject

@property (nonatomic, weak) id<ServiceCommandDelegate> delegate;
@property (nonatomic, copy) SuccessBlock callbackComplete;
@property (nonatomic, copy) FailureBlock callbackError;
@property (nonatomic, strong) NSString *HTTPMethod;
@property (nonatomic, strong) id payload;
@property (nonatomic, strong) NSURL *target;


- (instancetype) initWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)url payload:(id)payload;
+ (instancetype) commandWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)url payload:(id)payload;

-(void) send;

@end
