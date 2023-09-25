//
//  CTASIHTTPRequestDelegate.h
//  Part of CTASIHTTPRequest -> http://allseeing-i.com/CTASIHTTPRequest
//
//  Created by Ben Copsey on 13/04/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//
//  Connect SDK Note:
//  CT has been prepended to all members of this framework to avoid namespace collisions
//

@class CTASIHTTPRequest;

@protocol CTASIHTTPRequestDelegate <NSObject>

@optional

// These are the default delegate methods for request status
// You can use different ones by setting didStartSelector / didFinishSelector / didFailSelector
- (void)requestStarted:(CTASIHTTPRequest *)request;
- (void)request:(CTASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders;
- (void)request:(CTASIHTTPRequest *)request willRedirectToURL:(NSURL *)newURL;
- (void)requestFinished:(CTASIHTTPRequest *)request;
- (void)requestFailed:(CTASIHTTPRequest *)request;
- (void)requestRedirected:(CTASIHTTPRequest *)request;

// When a delegate implements this method, it is expected to process all incoming data itself
// This means that responseData / responseString / downloadDestinationPath etc are ignored
// You can have the request call a different method by setting didReceiveDataSelector
- (void)request:(CTASIHTTPRequest *)request didReceiveData:(NSData *)data;

// If a delegate implements one of these, it will be asked to supply credentials when none are available
// The delegate can then either restart the request ([request retryUsingSuppliedCredentials]) once credentials have been set
// or cancel it ([request cancelAuthentication])
- (void)authenticationNeededForRequest:(CTASIHTTPRequest *)request;
- (void)proxyAuthenticationNeededForRequest:(CTASIHTTPRequest *)request;

@end
