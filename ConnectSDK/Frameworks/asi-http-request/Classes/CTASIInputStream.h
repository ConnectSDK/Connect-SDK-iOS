//
//  CTASIInputStream.h
//  Part of CTASIHTTPRequest -> http://allseeing-i.com/CTASIHTTPRequest
//
//  Created by Ben Copsey on 10/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//
//  Connect SDK Note:
//  CT has been prepended to all members of this framework to avoid namespace collisions
//

#import <Foundation/Foundation.h>

@class CTASIHTTPRequest;

// This is a wrapper for NSInputStream that pretends to be an NSInputStream itself
// Subclassing NSInputStream seems to be tricky, and may involve overriding undocumented methods, so we'll cheat instead.
// It is used by CTASIHTTPRequest whenever we have a request body, and handles measuring and throttling the bandwidth used for uploading

@interface CTASIInputStream : NSObject {
	NSInputStream *stream;
	CTASIHTTPRequest *request;
}
+ (id)inputStreamWithFileAtPath:(NSString *)path request:(CTASIHTTPRequest *)request;
+ (id)inputStreamWithData:(NSData *)data request:(CTASIHTTPRequest *)request;

@property (retain, nonatomic) NSInputStream *stream;
@property (assign, nonatomic) CTASIHTTPRequest *request;
@end
