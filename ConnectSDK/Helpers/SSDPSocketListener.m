//
//  SocketListener.m
//  Connect SDK
//
//  Created by Mykhailo Vorontsov on 3/29/13.
//	Copyright (c) 2014 LG Electronics.
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

#import "SSDPSocketListener.h"

#import <sys/socket.h>
#import <sys/types.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import "ConnectError.h"

@implementation SSDPSocketListener
{
	BOOL _isListening;
	dispatch_source_t _dispatchSource;
	int _socket;
}

- (instancetype)initWithAddress:(NSString *)anAddress andPort:(NSInteger)aPort
{
	self = [super init];
	if (self)
	{
		_address = anAddress;
		_port = aPort;
    }
	return self;
}

#pragma mark -

- (dispatch_queue_t)workQueue
{
	if (nil == _workQueue)
	{
		_workQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	}
	return _workQueue;
}

- (dispatch_queue_t)delegateQueue
{
	if (nil == _delegateQueue)
	{
		_delegateQueue = dispatch_get_main_queue();
	}
	return _delegateQueue;
}

#pragma mark -

- (void)raiseError
{
	_error = [ConnectError generateErrorWithCode:ConnectStatusCodeSocketError andDetails:@"Detection socket disconnected"];
	dispatch_async(self.delegateQueue,
		^{
			if ([self.delegate respondsToSelector:@selector(socket:didEncounterError:)])
			{
				[self.delegate socket:self didEncounterError:_error];
			}
		});
}

- (void)didReceiveData:(NSData *)aData fromAddress:(NSString *)anAddress
{
	dispatch_async(self.delegateQueue,
        ^{
            if ([self.delegate respondsToSelector:@selector(socket:didReceiveData:fromAddress:)])
			{
				[self.delegate socket:self didReceiveData:aData fromAddress:anAddress];
			}
    });
}

- (void)open
{
	int   theSocketDescriptor = socket (PF_INET, SOCK_DGRAM, 0);
    
	//Create variable to  pass sot socket option setter
	static const int theYesVariable = 1;

	struct   sockaddr_in theSocketAddress;
	memset(&theSocketAddress, 0, sizeof(theSocketAddress));

	theSocketAddress.sin_family = AF_INET;
	theSocketAddress.sin_addr.s_addr = htonl(INADDR_ANY);
	theSocketAddress.sin_port = htons(self.port);

	if (![_address isEqualToString:@"0.0.0.0"])
	{
		struct ip_mreq mreq;
		mreq.imr_multiaddr.s_addr = inet_addr(self.address.UTF8String);
		mreq.imr_interface.s_addr = htonl(INADDR_ANY);
	  
		if (setsockopt(theSocketDescriptor,IPPROTO_IP,IP_ADD_MEMBERSHIP,&mreq,sizeof(mreq)) < 0)
		{
			[self raiseError];
			return;
		}
	}

    if (setsockopt(theSocketDescriptor, SOL_SOCKET, SO_REUSEADDR, &theYesVariable, sizeof(theYesVariable)) < 0)
    {
        [self raiseError];
        return;
    }
    if (setsockopt(theSocketDescriptor, SOL_SOCKET, SO_REUSEPORT, &theYesVariable, sizeof(theYesVariable)) < 0)
    {
        [self raiseError];
        return;
    }

	if (bind ( theSocketDescriptor, (void *)&theSocketAddress, sizeof(theSocketAddress)) < 0)
	{
		[self raiseError];
		return;
	}

	_dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, theSocketDescriptor, 0, self.workQueue);
	_socket = theSocketDescriptor;
	dispatch_source_set_event_handler(_dispatchSource,
		^{
			struct sockaddr_in theIncomingAddr;
			memset(&theIncomingAddr, 0, sizeof(theIncomingAddr));
			size_t theDataSize = dispatch_source_get_data(_dispatchSource);
			char theBuffer[theDataSize + 1];
			int theReceiveBytesCount = 0;
			socklen_t theAddressSize = sizeof(theIncomingAddr);
			while (theReceiveBytesCount < theDataSize)
			{
				theReceiveBytesCount += recvfrom(theSocketDescriptor, theBuffer,
					sizeof(theBuffer), 0, (struct sockaddr*)&theIncomingAddr, &theAddressSize);
			}
			char theCAddrBuffer[SOCK_MAXADDRLEN];
			memset(theCAddrBuffer, 0, SOCK_MAXADDRLEN);
			inet_ntop(theIncomingAddr.sin_family, &theIncomingAddr.sin_addr, theCAddrBuffer, SOCK_MAXADDRLEN);

			NSString *thePath = [[NSString alloc] initWithBytes:theCAddrBuffer
				length:strlen(theCAddrBuffer) encoding:NSUTF8StringEncoding];
			NSData * theReceivedData = [NSData dataWithBytes:theBuffer length:theDataSize];
            
			[self didReceiveData:theReceivedData fromAddress:thePath];
			
		});
	
	dispatch_resume(_dispatchSource);
}


- (void)sendData:(NSData *)aData toAddress:(NSString *)anAddress andPort:(NSUInteger)aPort;
{
	if (0 == _socket)
		[self open];
	
	if (_socket <= 0)
		[self raiseError];
	
	struct sockaddr_in theSocketAddress;
	
	memset((char *) &theSocketAddress, 0, sizeof(theSocketAddress));
	theSocketAddress.sin_family = AF_INET;
	theSocketAddress.sin_port = htons(aPort);

	inet_aton([anAddress UTF8String], &theSocketAddress.sin_addr);

	if (aData.length != sendto(_socket, aData.bytes, aData.length, 0,
		(void *) &theSocketAddress, sizeof(theSocketAddress)))
	{
		[self raiseError];
	}
}

- (void)close
{
    if (_dispatchSource)
	    dispatch_source_cancel(_dispatchSource);
    
	_dispatchSource = nil;
}

@end
