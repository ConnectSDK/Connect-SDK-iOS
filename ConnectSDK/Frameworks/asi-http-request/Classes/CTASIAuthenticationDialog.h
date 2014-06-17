//
//  CTASIAuthenticationDialog.h
//  Part of CTASIHTTPRequest -> http://allseeing-i.com/CTASIHTTPRequest
//
//  Created by Ben Copsey on 21/08/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//
//  Connect SDK Note:
//  CT has been prepended to all members of this framework to avoid namespace collisions
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class CTASIHTTPRequest;

typedef enum _CTASIAuthenticationType
{
	CTASIStandardAuthenticationType = 0,
    CTASIProxyAuthenticationType = 1
} CTASIAuthenticationType;

@interface CTASIAutorotatingViewController : UIViewController
@end

@interface CTASIAuthenticationDialog : CTASIAutorotatingViewController <UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource> {
	CTASIHTTPRequest *request;
	CTASIAuthenticationType type;
	UITableView *tableView;
	UIViewController *presentingController;
	BOOL didEnableRotationNotifications;
}
+ (void)presentAuthenticationDialogForRequest:(CTASIHTTPRequest *)request;
+ (void)dismiss;

@property (atomic, retain) CTASIHTTPRequest *request;
@property (atomic, assign) CTASIAuthenticationType type;
@property (atomic, assign) BOOL didEnableRotationNotifications;
@property (retain, nonatomic) UIViewController *presentingController;
@end
