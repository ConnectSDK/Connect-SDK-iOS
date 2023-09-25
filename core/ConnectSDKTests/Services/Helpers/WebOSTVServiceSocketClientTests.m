//
//  WebOSTVServiceSocketClientTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2/6/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
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


#import "WebOSTVService.h"
#import "WebOSTVServiceSocketClient_Private.h"

/// Tests for the @c WebOSTVServiceSocketClient class.
@interface WebOSTVServiceSocketClientTests : XCTestCase

@end

@implementation WebOSTVServiceSocketClientTests

#pragma mark - Registration Tests

/// Tests that -[WebOSTVServiceSocketClientDelegate socket:registrationFailed:]
/// method is called when the user has reject pairing on the TV. In this case,
/// the TV first sends a response with pairing info, then an error with the same
/// message id.
/// https://github.com/ConnectSDK/Connect-SDK-iOS/issues/130
- (void)testDeniedPairingShouldCallRegistrationFailed {
    // Arrange
    id serviceMock = OCMClassMock([WebOSTVService class]);
    id webSocketMock = OCMClassMock([LGSRWebSocket class]);

    id socketClientDelegateMock = OCMProtocolMock(@protocol(WebOSTVServiceSocketClientDelegate));
    OCMStub([socketClientDelegateMock socket:OCMOCK_ANY didReceiveMessage:OCMOCK_ANY]).andReturn(YES);
    XCTestExpectation *registrationFailedCalled = [self expectationWithDescription:@"socket:registrationFailed: is called"];
    OCMExpect([socketClientDelegateMock socket:OCMOCK_NOTNIL
                            registrationFailed:OCMOCK_NOTNIL]).andDo(^(NSInvocation *_) {
        [registrationFailedCalled fulfill];
    });

    // have to install a partial mock on the SUT (class under test) to stub
    // the web socket object (LGSRWebSocket) and some manifest.
    WebOSTVServiceSocketClient *socketClient = OCMPartialMock([[WebOSTVServiceSocketClient alloc] initWithService:serviceMock]);
    socketClient.delegate = socketClientDelegateMock;
    OCMStub([socketClient createSocketWithURLRequest:OCMOCK_ANY]).andReturn(webSocketMock);
    OCMStub([socketClient manifest]).andReturn(@{});

    // Act
    [socketClient connect];

    OCMStub([webSocketMock send:OCMOCK_ANY]).andDo(^(NSInvocation *inv) {
        __unsafe_unretained NSString *tmp;
        [inv getArgument:&tmp atIndex:2];
        NSString *msg = tmp;

        if (NSNotFound != [msg rangeOfString:@"\"hello\""].location) {
            NSString *response = @"{\"type\":\"hello\",\"payload\":{\"protocolVersion\":1,\"deviceType\":\"tv\",\"deviceOS\":\"webOS\",\"deviceOSVersion\":\"4.0.3\",\"deviceOSReleaseVersion\":\"1.3.2\",\"deviceUUID\":\"3C763B8E-8AED-4330-8838-3B1CFABBC16A\",\"pairingTypes\":[\"PIN\",\"PROMPT\"]}}";
            dispatch_async(dispatch_get_main_queue(), ^{
                [socketClient webSocket:webSocketMock didReceiveMessage:response];
            });
        } else if (NSNotFound != [msg rangeOfString:@"\"register\""].location) {
            // here a pairing alert is displayed on TV
            NSString *response = @"{\"type\":\"response\",\"id\":\"2\",\"payload\":{\"pairingType\":\"PROMPT\",\"returnValue\":true}}";
            dispatch_async(dispatch_get_main_queue(), ^{
                [socketClient webSocket:webSocketMock didReceiveMessage:response];
            });

            // here the user has rejected access
            NSString *error = @"{\"type\":\"error\",\"id\":\"2\",\"error\":\"403 User denied access\",\"payload\":\"\"}";
            dispatch_async(dispatch_get_main_queue(), ^{
                [socketClient webSocket:webSocketMock didReceiveMessage:error];
            });
        } else {
            XCTFail(@"Unexpected request %@", msg);
        }
    });
    [socketClient webSocketDidOpen:webSocketMock];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(socketClientDelegateMock);
                                 }];
}

-(void)testPairingShouldCallSocketWillRegister{
    id serviceMock = OCMClassMock([WebOSTVService class]);
    id webSocketMock = OCMClassMock([LGSRWebSocket class]);
    //Send Pairing type which is not supported by the TV. Supported pairing type is PROMPT
    OCMStub([serviceMock pairingType]).andReturn(DeviceServicePairingTypeMixed);
    id socketClientDelegateMock = OCMProtocolMock(@protocol(WebOSTVServiceSocketClientDelegate));
    OCMStub([socketClientDelegateMock socket:OCMOCK_ANY didReceiveMessage:OCMOCK_ANY]).andReturn(YES);
    XCTestExpectation *socketWillRegisterCalled = [self expectationWithDescription:@"socketWillRegister: is called"];
    OCMExpect([socketClientDelegateMock socketWillRegister:OCMOCK_NOTNIL]).andDo(^(NSInvocation *_) {
        [socketWillRegisterCalled fulfill];
    });
    
    // have to install a partial mock on the SUT (class under test) to stub
    // the web socket object (LGSRWebSocket) and some manifest.
    WebOSTVServiceSocketClient *socketClient = OCMPartialMock([[WebOSTVServiceSocketClient alloc] initWithService:serviceMock]);
    socketClient.delegate = socketClientDelegateMock;
    OCMStub([socketClient createSocketWithURLRequest:OCMOCK_ANY]).andReturn(webSocketMock);
    OCMStub([socketClient manifest]).andReturn(@{});
    
    // Act
    [socketClient connect];
    
    OCMStub([webSocketMock send:OCMOCK_ANY]).andDo(^(NSInvocation *inv) {
        __unsafe_unretained NSString *tmp;
        [inv getArgument:&tmp atIndex:2];
        NSString *msg = tmp;
        NSLog(@"Message %@",msg);
        if (NSNotFound != [msg rangeOfString:@"\"hello\""].location) {
            NSString *response = @"{\"type\":\"hello\",\"payload\":{\"protocolVersion\":1,\"deviceType\":\"tv\",\"deviceOS\":\"webOS\",\"deviceOSVersion\":\"4.0.3\",\"deviceOSReleaseVersion\":\"1.3.2\",\"deviceUUID\":\"3C763B8E-8AED-4330-8838-3B1CFABBC16A\",\"pairingTypes\":[\"PIN\",\"PROMPT\"]}}";
            dispatch_async(dispatch_get_main_queue(), ^{
                [socketClient webSocket:webSocketMock didReceiveMessage:response];
            });
        } else if (NSNotFound != [msg rangeOfString:@"\"register\""].location) {
            // here a pairing alert is displayed on TV
            NSLog(@"Register called");
             NSString *response = @"{\"type\":\"response\",\"id\":\"2\",\"payload\":{\"pairingType\":\"PROMPT\",\"returnValue\":true}}";
            dispatch_async(dispatch_get_main_queue(), ^{
                [socketClient webSocket:webSocketMock didReceiveMessage:response];
            });
            
        } else {
            XCTFail(@"Unexpected request %@", msg);
        }
    });
    [socketClient webSocketDidOpen:webSocketMock];
    
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(socketClientDelegateMock);
                                 }];
}

@end
