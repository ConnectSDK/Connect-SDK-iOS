//
//   Copyright 2013-2014 LG Electronics.
//   Copyright 2012 Square Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//


#import "LGSRWebSocket.h"

#if TARGET_OS_IPHONE
#define HAS_ICU
#endif

#ifdef HAS_ICU
#import <unicode/utf8.h>
#endif

#if TARGET_OS_IPHONE
#import <Endian.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#import <CommonCrypto/CommonDigest.h>
#import <Security/SecRandom.h>

#if OS_OBJECT_USE_OBJC_RETAIN_RELEASE
#define lgsr_dispatch_retain(x)
#define lgsr_dispatch_release(x)
#else
#define lgsr_dispatch_retain(x) dispatch_retain(x)
#define lgsr_dispatch_release(x) dispatch_release(x)
#endif

#if !__has_feature(objc_arc) 
#error SocketRocket must be compiled with ARC enabled
#endif


typedef enum  {
    LGSROpCodeTextFrame = 0x1,
    LGSROpCodeBinaryFrame = 0x2,
    // 3-7 reserved.
    LGSROpCodeConnectionClose = 0x8,
    LGSROpCodePing = 0x9,
    LGSROpCodePong = 0xA,
    // B-F reserved.
} LGSROpCode;

typedef struct {
    BOOL fin;
//  BOOL rsv1;
//  BOOL rsv2;
//  BOOL rsv3;
    uint8_t opcode;
    BOOL masked;
    uint64_t payload_length;
} frame_header;

static NSString *const LGSRWebSocketAppendToSecKeyString = @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

static NSString *const LGServerCertificatePublicKeyString = {@"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2At7fSUHuMw6bm/z3Q+X4oY9KpDa1s06\n"
@"mht9vNmSkZE5xMo9asOtZAWLLbJLxifY6qz6LWKgNw4Pyk6HVTLFdj4jrV//gNGQvYtCp3HRriqg\n"
@"2YoceBNG59+SW3xNzuhUqy5/nerQPfNQiz9z9RqtGj/YWItlJcKrNOBecNmHc7Xmu+3yPN6kD1G2\n"
@"6uU8wPBqzMdqFpPcubedIOmh4nNa2sNkfvMkbR4Pk/YupsDpic56dMxX0Twvg6SiaKGjv8NO9Lcv\n"
@"hLt2dR2XXi/z2F6uVjP5oYPvlSAK9GHVo96khpafKGPvIwPSSGtlHI4is/yT7WEeLuQs5FD/vAs9\n"
@"eqQNkQIDAQAB\n"};

static NSString *const LGIntermediateCAPublicKeyString ={@"MIMAAiMwDQYJKoZIhvcNAQEBBQADgwACDwAwggIKAoICAQDl5xeN+UkKyfHifIGtO4igsl/UxXosQ0qeAMadDSdI8XLHAsfEnlCDVWwYSFD76A7+GO6mttN5MTlsdVJPQ/lyy032cPkz38R9MHS6sOxqOCXurkX0wN/7fTODKVkS/Q3dCqYzeluWaMrZQBAW6vGQVgoilBxf5Z9jpV9Dj6IxXThomUlyM8HVCWmg38eht8ItiuSe1Bzpr8Bqv35wLEnPPK1QhKu9oxU10GS6Yn1GNQ6xMvpayf1jPuRK443tdR+IA2mDy/N8h623yvIbBxMt/rLmvzjWevLC8wyTlrEw5ei/GOfMlJq8fK3TK1S9CMqqe6uSO9YHJo5/ibg+aFKkJEDO4RNzK2W0A7F+a2eJIk8lz49rvZNC+X/waRUfso8YrAcXvQo4EbYDWTlFDNa15rYiZEE3lzqROto440Wb6v5ZavyvkRyQbUNbodUh42Wvo616kD6GG5/Le1QUpO6I66Hjs0MyJQApFuOR2OZhS8FjHPRONSNZJl1rAP7xtZ7fDikad0oqU9hHKOKQSb8e8QTLUyQGCW17FB8pgC8Du7ZZquRU/0RhK002yEdlWY+yDWs18aLqKl64P5GiipYufRTWVS3Ev8e4W/ycdI3n4gOWNAUuHUkO+LRXxm1fimPV1rigQrth9KtRc1g9FsDr+s2ZfxPft3LTozt1HRSBeQIDAQAB"};

/*static NSString *const LGSSCPublicKeyString ={@"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2qdDinEsRPX/5XigbSzzO4PtTq3ZizLH\n"
    @"ywwmRobnix/Ajn8LGSYQfrV3+HBg5Zdcc0SWxx66i7Guy1UOFXV7q28roLSui94nS9jyjsgiXqZL\n"
    @"57bcj8HrNBfRIiBUvE7FfBn8dKnVO7+61qXw4Eal7CR3602vHg4INpWt/xA8HPKrlnqrW03lAu22\n"
    @"nz9bij+3VHAdJ1kb9txGJ4yxXmseS3LwcoV/6NuHcP5ZGccTo1Wglw9RKWYUFqyKh7i1P6jalA3U\n"
    @"kFZ6wNJZKayFGPMeBRIZdH5E61bb5lgnTcSHWi0HrBIUql/KC4Gxh4PDQn3QrPZJKp/Ne+/8ReMn\n"
    @"nA4XNwIDAQAB\n"};*/

static inline int32_t validate_dispatch_data_partial_string(NSData *data);
static inline void LGSRFastLog(NSString *format, ...);

@interface NSData (LGSRWebSocket)

- (NSString *)stringBySHA1ThenBase64Encoding;

@end


@interface NSString (LGSRWebSocket)

- (NSString *)stringBySHA1ThenBase64Encoding;

@end


@interface NSURL (LGSRWebSocket)

// The origin isn't really applicable for a native application.
// So instead, just map ws -> http and wss -> https.
- (NSString *)LGSR_origin;

@end


@interface _LGSRRunLoopThread : NSThread

@property (nonatomic, readonly) NSRunLoop *runLoop;

@end


static inline NSString *base64EncodedData(NSData *data) {
    // based on https://github.com/square/SocketRocket/pull/168
    if ([data respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        return [data base64EncodedStringWithOptions:0];
    }

    _Pragma("clang diagnostic push");
    _Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"");
    // legacy, before iOS 7
    return [data base64Encoding];
    _Pragma("clang diagnostic pop");
}

static NSString *newSHA1String(const char *bytes, size_t length) {
    uint8_t md[CC_SHA1_DIGEST_LENGTH];
    
    assert(length >= 0);
    assert(length <= UINT32_MAX);
    CC_SHA1(bytes, (CC_LONG)length, md);
    
    return base64EncodedData([NSData dataWithBytes:md length:CC_SHA1_DIGEST_LENGTH]);
}

@implementation NSData (LGSRWebSocket)

- (NSString *)stringBySHA1ThenBase64Encoding;
{
    return newSHA1String(self.bytes, self.length);
}

@end


@implementation NSString (LGSRWebSocket)

- (NSString *)stringBySHA1ThenBase64Encoding;
{
    return newSHA1String(self.UTF8String, self.length);
}

@end

NSString *const LGSRWebSocketErrorDomain = @"LGSRWebSocketErrorDomain";

// Returns number of bytes consumed. Returning 0 means you didn't match.
// Sends bytes to callback handler;
typedef size_t (^stream_scanner)(NSData *collected_data);

typedef void (^data_callback)(LGSRWebSocket *webSocket,  NSData *data);

@interface LGSRIOConsumer : NSObject {
    stream_scanner _scanner;
    data_callback _handler;
    size_t _bytesNeeded;
    BOOL _readToCurrentFrame;
    BOOL _unmaskBytes;
}
@property (nonatomic, copy, readonly) stream_scanner consumer;
@property (nonatomic, copy, readonly) data_callback handler;
@property (nonatomic, assign) size_t bytesNeeded;
@property (nonatomic, assign, readonly) BOOL readToCurrentFrame;
@property (nonatomic, assign, readonly) BOOL unmaskBytes;

@end

// This class is not thread-safe, and is expected to always be run on the same queue.
@interface LGSRIOConsumerPool : NSObject

- (id)initWithBufferCapacity:(NSUInteger)poolSize;

- (LGSRIOConsumer *)consumerWithScanner:(stream_scanner)scanner handler:(data_callback)handler bytesNeeded:(size_t)bytesNeeded readToCurrentFrame:(BOOL)readToCurrentFrame unmaskBytes:(BOOL)unmaskBytes;
- (void)returnConsumer:(LGSRIOConsumer *)consumer;

@end

@interface LGSRWebSocket ()  <NSStreamDelegate>

- (void)_writeData:(NSData *)data;
- (void)_closeWithProtocolError:(NSString *)message;
- (void)_failWithError:(NSError *)error;

- (void)_readFrameNew;
- (void)_readFrameContinue;

- (void)_pumpScanner;

- (void)_pumpWriting;

- (void)_addConsumerWithScanner:(stream_scanner)consumer callback:(data_callback)callback;
- (void)_addConsumerWithDataLength:(size_t)dataLength callback:(data_callback)callback readToCurrentFrame:(BOOL)readToCurrentFrame unmaskBytes:(BOOL)unmaskBytes;
- (void)_addConsumerWithScanner:(stream_scanner)consumer callback:(data_callback)callback dataLength:(size_t)dataLength;
- (void)_readUntilBytes:(const void *)bytes length:(size_t)length callback:(data_callback)dataHandler;
- (void)_readUntilHeaderCompleteWithCallback:(data_callback)dataHandler;

- (void)_sendFrameWithOpcode:(LGSROpCode)opcode data:(id)data;

- (BOOL)_checkHandshake:(CFHTTPMessageRef)httpMessage;
- (void)_LGSR_commonInit;

- (void)_initializeStreams;

- (size_t) encodeLength:(unsigned char *) buf :(size_t)length; //newly added for connectSDKPorting
- (NSString *) getPublicKeyAsBase64:(SecKeyRef) publicKey ; //newly added for ConnectSDkPorting
@property (nonatomic) LGSRReadyState readyState;

@property (nonatomic) NSOperationQueue *delegateOperationQueue;
@property (nonatomic) dispatch_queue_t delegateDispatchQueue;
@property (nonatomic) NSArray *sslData;

@end


@implementation LGSRWebSocket {
    NSInteger _webSocketVersion;
    
    NSOperationQueue *_delegateOperationQueue;
    dispatch_queue_t _delegateDispatchQueue;
    
    dispatch_queue_t _workQueue;
    NSMutableArray *_consumers;

    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
   
    NSMutableData *_readBuffer;
    NSUInteger _readBufferOffset;
 
    NSMutableData *_outputBuffer;
    NSUInteger _outputBufferOffset;

    uint8_t _currentFrameOpcode;
    size_t _currentFrameCount;
    size_t _readOpCount;
    uint32_t _currentStringScanPosition;
    NSMutableData *_currentFrameData;
    
    NSString *_closeReason;
    
    NSString *_secKey;
    
    BOOL _pinnedCertFound;

    uint8_t _currentReadMaskKey[4];
    size_t _currentReadMaskOffset;

    BOOL _consumerStopped;
    
    BOOL _closeWhenFinishedWriting;
    BOOL _failed;

    BOOL _secure;
    NSMutableURLRequest *_urlRequest;

    CFHTTPMessageRef _receivedHTTPHeaders;
    
    BOOL _sentClose;
    BOOL _didFail;
    BOOL _cleanupScheduled;
    int _closeCode;
    
    BOOL _isPumping;
    
    NSMutableSet *_scheduledRunloops;
    
    // We use this to retain ourselves.
    __strong LGSRWebSocket *_selfRetain;
    
    NSArray *_requestedProtocols;
    LGSRIOConsumerPool *_consumerPool;
    int _ipublicKeyvalue;
    int _icertificateValidity;
}

@synthesize delegate = _delegate;
@synthesize url = _url;
@synthesize readyState = _readyState;
@synthesize protocol = _protocol;

static __strong NSData *CRLFCRLF;

+ (void)initialize;
{
    CRLFCRLF = [[NSData alloc] initWithBytes:"\r\n\r\n" length:4];
}

- (id)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols;
{
    self = [super init];
    if (self) {
        assert(request.URL);
        _url = request.URL;
        _urlRequest = request;
        
        _requestedProtocols = [protocols copy];
        
        [self _LGSR_commonInit];
    }
    
    return self;
}

- (id)initWithURLRequest:(NSURLRequest *)request;
{
    return [self initWithURLRequest:request protocols:nil];
}

- (id)initWithURL:(NSURL *)url;
{
    return [self initWithURL:url protocols:nil];
}

- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols;
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    return [self initWithURLRequest:request protocols:protocols];
}

- (void)_LGSR_commonInit;
{
    
    NSString *scheme = _url.scheme.lowercaseString;
    assert([scheme isEqualToString:@"ws"] || [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"wss"] || [scheme isEqualToString:@"https"]);
    
    if ([scheme isEqualToString:@"wss"] || [scheme isEqualToString:@"https"]) {
        _secure = YES;
    }
    
    _readyState = LGSR_CONNECTING;
    _consumerStopped = YES;
    _webSocketVersion = 13;
    
    _workQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    
    // Going to set a specific on the queue so we can validate we're on the work queue
    dispatch_queue_set_specific(_workQueue, (__bridge void *)self, (__bridge void *)(_workQueue), NULL);

    _delegateDispatchQueue = dispatch_get_main_queue();
    lgsr_dispatch_retain(_delegateDispatchQueue);
    
    _readBuffer = [[NSMutableData alloc] init];
    _outputBuffer = [[NSMutableData alloc] init];
    
    _currentFrameData = [[NSMutableData alloc] init];

    _consumers = [[NSMutableArray alloc] init];
    
    _consumerPool = [[LGSRIOConsumerPool alloc] init];
    
    _scheduledRunloops = [[NSMutableSet alloc] init];
    
    _ipublicKeyvalue =-1;
    _icertificateValidity=-1;
    
    [self _initializeStreams];
    
    // default handlers
}

- (void)assertOnWorkQueue;
{
    assert(dispatch_get_specific((__bridge void *)self) == (__bridge void *)_workQueue);
}

- (void)dealloc
{
    _inputStream.delegate = nil;
    _outputStream.delegate = nil;

    [_inputStream close];
    [_outputStream close];
    
    if (_workQueue)
    {
        lgsr_dispatch_release(_workQueue);
        _workQueue = NULL;
    }
    
    if (_receivedHTTPHeaders) {
        CFRelease(_receivedHTTPHeaders);
        _receivedHTTPHeaders = NULL;
    }
    
    if (_delegateDispatchQueue) {
        lgsr_dispatch_release(_delegateDispatchQueue);
        _delegateDispatchQueue = NULL;
    }
}

#ifndef NDEBUG

- (void)setReadyState:(LGSRReadyState)aReadyState;
{
    [self willChangeValueForKey:@"readyState"];
    assert(aReadyState > _readyState);
    _readyState = aReadyState;
    [self didChangeValueForKey:@"readyState"];
}

#endif

- (void)open;
{
    assert(_url);
    NSAssert(_readyState == LGSR_CONNECTING, @"Cannot call -(void)open on LGSRWebSocket more than once");

    _selfRetain = self;
    
    [self openConnection];
}

// Calls block on delegate queue
- (void)_performDelegateBlock:(dispatch_block_t)block;
{
    if (_delegateOperationQueue) {
        [_delegateOperationQueue addOperationWithBlock:block];
    } else {
        assert(_delegateDispatchQueue);
        dispatch_async(_delegateDispatchQueue, block);
    }
}

- (void)setDelegateDispatchQueue:(dispatch_queue_t)queue;
{
    if (queue) {
        lgsr_dispatch_retain(queue);
    }
    
    if (_delegateDispatchQueue) {
        lgsr_dispatch_release(_delegateDispatchQueue);
    }
    
    _delegateDispatchQueue = queue;
}

- (BOOL)_checkHandshake:(CFHTTPMessageRef)httpMessage;
{
    NSString *acceptHeader = CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(httpMessage, CFSTR("Sec-WebSocket-Accept")));

    if (acceptHeader == nil) {
        return NO;
    }
    
    NSString *concattedString = [_secKey stringByAppendingString:LGSRWebSocketAppendToSecKeyString];
    NSString *expectedAccept = [concattedString stringBySHA1ThenBase64Encoding];
    
    return [acceptHeader isEqualToString:expectedAccept];
}

- (void)_HTTPHeadersDidFinish;
{
    NSInteger responseCode = CFHTTPMessageGetResponseStatusCode(_receivedHTTPHeaders);
    
    if (responseCode >= 400) {
        LGSRFastLog(@"Request failed with response code %d", responseCode);
        [self _failWithError:[NSError errorWithDomain:@"org.lolrus.SocketRocket" code:2132 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"received bad response code from server %ld", (long)responseCode] forKey:NSLocalizedDescriptionKey]]];
        return;

    }
    
    if(![self _checkHandshake:_receivedHTTPHeaders]) {
        [self _failWithError:[NSError errorWithDomain:LGSRWebSocketErrorDomain code:2133 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Invalid Sec-WebSocket-Accept response"] forKey:NSLocalizedDescriptionKey]]];
        return;
    }
    
    NSString *negotiatedProtocol = CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(_receivedHTTPHeaders, CFSTR("Sec-WebSocket-Protocol")));
    if (negotiatedProtocol) {
        // Make sure we requested the protocol
        if ([_requestedProtocols indexOfObject:negotiatedProtocol] == NSNotFound) {
            [self _failWithError:[NSError errorWithDomain:LGSRWebSocketErrorDomain code:2133 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Server specified Sec-WebSocket-Protocol that wasn't requested"] forKey:NSLocalizedDescriptionKey]]];
            return;
        }
        
        _protocol = negotiatedProtocol;
    }
    
    self.readyState = LGSR_OPEN;
    
    if (!_didFail) {
        [self _readFrameNew];
    }

    [self _performDelegateBlock:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(webSocketDidOpen:)]) {
            [self.delegate webSocketDidOpen:self];
        };
    }];
}


- (void)_readHTTPHeader;
{
    if (_receivedHTTPHeaders == NULL) {
        _receivedHTTPHeaders = CFHTTPMessageCreateEmpty(NULL, NO);
    }
                        
    [self _readUntilHeaderCompleteWithCallback:^(LGSRWebSocket *self,  NSData *data) {
        CFHTTPMessageAppendBytes(_receivedHTTPHeaders, (const UInt8 *)data.bytes, data.length);
        
        if (CFHTTPMessageIsHeaderComplete(_receivedHTTPHeaders)) {
            LGSRFastLog(@"Finished reading headers %@", CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(_receivedHTTPHeaders)));
            [self _HTTPHeadersDidFinish];
        } else {
            [self _readHTTPHeader];
        }
    }];
}

- (void)didConnect
{
    LGSRFastLog(@"Connected");
    CFHTTPMessageRef request = CFHTTPMessageCreateRequest(NULL, CFSTR("GET"), (__bridge CFURLRef)_url, kCFHTTPVersion1_1);
    
    // Set host first so it defaults
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Host"), (__bridge CFStringRef)(_url.port ? [NSString stringWithFormat:@"%@:%@", _url.host, _url.port] : _url.host));
        
    NSMutableData *keyBytes = [[NSMutableData alloc] initWithLength:16];
    SecRandomCopyBytes(kSecRandomDefault, keyBytes.length, keyBytes.mutableBytes);
    _secKey = base64EncodedData(keyBytes);
    
    assert([_secKey length] == 24);
    
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Upgrade"), CFSTR("websocket"));
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Connection"), CFSTR("Upgrade"));
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Sec-WebSocket-Key"), (__bridge CFStringRef)_secKey);
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Sec-WebSocket-Version"), (__bridge CFStringRef)[NSString stringWithFormat:@"%ld", (long)_webSocketVersion]);
    
    //CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Origin"), (__bridge CFStringRef)_url.SR_origin);
    
    if (_requestedProtocols) {
        CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Sec-WebSocket-Protocol"), (__bridge CFStringRef)[_requestedProtocols componentsJoinedByString:@", "]);
    }

    [_urlRequest.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        CFHTTPMessageSetHeaderFieldValue(request, (__bridge CFStringRef)key, (__bridge CFStringRef)obj);
    }];
    
    NSData *message = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(request));
    
    CFRelease(request);

    [self _writeData:message];
    [self _readHTTPHeader];
}

- (void)_initializeStreams;
{
    assert(_url.port.unsignedIntValue <= UINT32_MAX);
    uint32_t port = _url.port.unsignedIntValue;
    if (port == 0) {
        if (!_secure) {
            port = 80;
        } else {
            port = 443;
        }
    }
    NSString *host = _url.host;
    
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, (UInt32)port, &readStream, &writeStream);
    
    _outputStream = CFBridgingRelease(writeStream);
    _inputStream = CFBridgingRelease(readStream);
    
    
    if (_secure) {
        NSMutableDictionary *SSLOptions = [[NSMutableDictionary alloc] init];
        
        [_outputStream setProperty:(__bridge id)kCFStreamSocketSecurityLevelNegotiatedSSL forKey:(__bridge id)kCFStreamPropertySocketSecurityLevel];
        
        // If we're using pinned certs, don't validate the certificate chain
        /*
        if ([_urlRequest SR_SSLPinnedCertificates].count) {
            [SSLOptions setValue:[NSNumber numberWithBool:NO] forKey:(__bridge id)kCFStreamSSLValidatesCertificateChain];
        }
         */
        [SSLOptions setValue:[NSNumber numberWithBool:NO] forKey:(__bridge id)kCFStreamSSLValidatesCertificateChain];
        
        [_outputStream setProperty:SSLOptions
                            forKey:(__bridge id)kCFStreamPropertySSLSettings];
    }
    
    _inputStream.delegate = self;
    _outputStream.delegate = self;
}

- (void)openConnection;
{
    if (!_scheduledRunloops.count) {
        [self scheduleInRunLoop:[NSRunLoop LGSR_networkRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
    
    [_outputStream open];
    [_inputStream open];
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;
{
    [_outputStream scheduleInRunLoop:aRunLoop forMode:mode];
    [_inputStream scheduleInRunLoop:aRunLoop forMode:mode];
    
    [_scheduledRunloops addObject:@[aRunLoop, mode]];
}

- (void)unscheduleFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;
{
    [_outputStream removeFromRunLoop:aRunLoop forMode:mode];
    [_inputStream removeFromRunLoop:aRunLoop forMode:mode];
    
    [_scheduledRunloops removeObject:@[aRunLoop, mode]];
}

- (void)close;
{
    [self closeWithCode:0 reason:nil];
}

- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;
{
    //assert(code);
    [self _scheduleCleanup];
    dispatch_async(_workQueue, ^{
        if (self.readyState == LGSR_CLOSING || self.readyState == LGSR_CLOSED) {
            return;
        }
        
        BOOL wasConnecting = self.readyState == LGSR_CONNECTING;
        
        self.readyState = LGSR_CLOSING;
        
        LGSRFastLog(@"Closing with code %d reason %@", code, reason);
        
        if (wasConnecting) {
            [self closeConnection];
            return;
        }

        size_t maxMsgSize = [reason maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        NSMutableData *mutablePayload = [[NSMutableData alloc] initWithLength:sizeof(uint16_t) + maxMsgSize];
        NSData *payload = mutablePayload;
        
        ((uint16_t *)mutablePayload.mutableBytes)[0] = EndianU16_BtoN(code);
        
        if (reason) {
            NSRange remainingRange = {0};
            
            NSUInteger usedLength = 0;
            
            BOOL success = [reason getBytes:(char *)mutablePayload.mutableBytes + sizeof(uint16_t) maxLength:payload.length - sizeof(uint16_t) usedLength:&usedLength encoding:NSUTF8StringEncoding options:NSStringEncodingConversionExternalRepresentation range:NSMakeRange(0, reason.length) remainingRange:&remainingRange];
            
            assert(success);
            assert(remainingRange.length == 0);

            if (usedLength != maxMsgSize) {
                payload = [payload subdataWithRange:NSMakeRange(0, usedLength + sizeof(uint16_t))];
            }
        }
        
        
        [self _sendFrameWithOpcode:LGSROpCodeConnectionClose data:payload];
    });
}

- (void)_closeWithProtocolError:(NSString *)message;
{
    // Need to shunt this on the _callbackQueue first to see if they received any messages 
    [self _performDelegateBlock:^{
        [self closeWithCode:LGSRStatusCodeProtocolError reason:message];
        dispatch_async(_workQueue, ^{
            [self closeConnection];
        });
    }];
}

- (void)_failWithError:(NSError *)error;
{
    dispatch_async(_workQueue, ^{
        if (self.readyState != LGSR_CLOSED) {
            _failed = YES;
            [self _performDelegateBlock:^{
                if ([self.delegate respondsToSelector:@selector(webSocket:didFailWithError:)]) {
                    [self.delegate webSocket:self didFailWithError:error];
                }
            }];

            self.readyState = LGSR_CLOSED;

            LGSRFastLog(@"Failing with error %@", error.localizedDescription);
            
            [self closeConnection];
            [self _scheduleCleanup];
        }
    });
}

- (void)_writeData:(NSData *)data;
{    
    [self assertOnWorkQueue];

    if (_closeWhenFinishedWriting) {
            return;
    }
    [_outputBuffer appendData:data];
    [self _pumpWriting];
}
- (void)send:(id)data;
{
    NSAssert(self.readyState != LGSR_CONNECTING, @"Invalid State: Cannot call send: until connection is open");
    // TODO: maybe not copy this for performance
    
    data = [data copy];
    
    dispatch_async(_workQueue, ^{
        if ([data isKindOfClass:[NSString class]]) {
            LGSRFastLog(@"LGSRWebSocket::send string: %@", data);
            [self _sendFrameWithOpcode:LGSROpCodeTextFrame data:[(NSString *)data dataUsingEncoding:NSUTF8StringEncoding]];
        } else if ([data isKindOfClass:[NSData class]]) {
            NSData *theData = (NSData *)data;
            LGSRFastLog(@"LGSRWebSocket::send data of length %d", (int)theData.length);
            [self _sendFrameWithOpcode:LGSROpCodeBinaryFrame data:data];
        } else if (data == nil) {;
            LGSRFastLog(@"LGSRWebSocket::send nil");
            [self _sendFrameWithOpcode:LGSROpCodeTextFrame data:data];
        } else {
            LGSRFastLog(@"LGSRWebSocket::send unknown object type");
            assert(NO);
        }
    });
}

- (void)handlePing:(NSData *)pingData;
{
    // Need to pingpong this off _callbackQueue first to make sure messages happen in order
    [self _performDelegateBlock:^{
        dispatch_async(_workQueue, ^{
            [self _sendFrameWithOpcode:LGSROpCodePong data:pingData];
        });
    }];
}

- (void)handlePong;
{
    // NOOP
}

- (void)_handleMessage:(id)message
{
    LGSRFastLog(@"Received message");
    [self _performDelegateBlock:^{
        [self.delegate webSocket:self didReceiveMessage:message];
    }];
}


static inline BOOL closeCodeIsValid(int closeCode) {
    if (closeCode < 1000) {
        return NO;
    }
    
    if (closeCode >= 1000 && closeCode <= 1011) {
        if (closeCode == 1004 ||
            closeCode == 1005 ||
            closeCode == 1006) {
            return NO;
        }
        return YES;
    }
    
    if (closeCode >= 3000 && closeCode <= 3999) {
        return YES;
    }
    
    if (closeCode >= 4000 && closeCode <= 4999) {
        return YES;
    }

    return NO;
}

//  Note from RFC:
//
//  If there is a body, the first two
//  bytes of the body MUST be a 2-byte unsigned integer (in network byte
//  order) representing a status code with value /code/ defined in
//  Section 7.4.  Following the 2-byte integer the body MAY contain UTF-8
//  encoded data with value /reason/, the interpretation of which is not
//  defined by this specification.

- (void)handleCloseWithData:(NSData *)data;
{
    size_t dataSize = data.length;
    __block uint16_t closeCode = 0;
    
    LGSRFastLog(@"Received close frame");
    
    if (dataSize == 1) {
        // TODO handle error
        [self _closeWithProtocolError:@"Payload for close must be larger than 2 bytes"];
        return;
    } else if (dataSize >= 2) {
        [data getBytes:&closeCode length:sizeof(closeCode)];
        _closeCode = EndianU16_BtoN(closeCode);
        if (!closeCodeIsValid(_closeCode)) {
            [self _closeWithProtocolError:[NSString stringWithFormat:@"Cannot have close code of %d", _closeCode]];
            return;
        }
        if (dataSize > 2) {
            _closeReason = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(2, dataSize - 2)] encoding:NSUTF8StringEncoding];
            if (!_closeReason) {
                [self _closeWithProtocolError:@"Close reason MUST be valid UTF-8"];
                return;
            }
        }
    } else {
        _closeCode = LGSRStatusNoStatusReceived;
    }
    
    [self assertOnWorkQueue];
    
    if (self.readyState == LGSR_OPEN) {
        [self closeWithCode:1000 reason:nil];
    }
    dispatch_async(_workQueue, ^{
        [self closeConnection];
    });
}

- (void)closeConnection;
{
    [self assertOnWorkQueue];
    LGSRFastLog(@"Trying to disconnect");
    _closeWhenFinishedWriting = YES;
    [self _pumpWriting];
}

- (void)_handleFrameWithData:(NSData *)frameData opCode:(NSInteger)opcode;
{                
    // Check that the current data is valid UTF8
    
    BOOL isControlFrame = (opcode == LGSROpCodePing || opcode == LGSROpCodePong || opcode == LGSROpCodeConnectionClose);
    if (!isControlFrame) {
        [self _readFrameNew];
    } else {
        dispatch_async(_workQueue, ^{
            [self _readFrameContinue];
        });
    }
    
    switch (opcode) {
        case LGSROpCodeTextFrame: {
            NSString *str = [[NSString alloc] initWithData:frameData encoding:NSUTF8StringEncoding];
            if (str == nil && frameData) {
                [self closeWithCode:LGSRStatusCodeInvalidUTF8 reason:@"Text frames must be valid UTF-8"];
                dispatch_async(_workQueue, ^{
                    [self closeConnection];
                });

                return;
            }
            [self _handleMessage:str];
            break;
        }
        case LGSROpCodeBinaryFrame:
            [self _handleMessage:[frameData copy]];
            break;
        case LGSROpCodeConnectionClose:
            [self handleCloseWithData:frameData];
            break;
        case LGSROpCodePing:
            [self handlePing:frameData];
            break;
        case LGSROpCodePong:
            [self handlePong];
            break;
        default:
            [self _closeWithProtocolError:[NSString stringWithFormat:@"Unknown opcode %ld", (long)opcode]];
            // TODO: Handle invalid opcode
            break;
    }
}

- (void)_handleFrameHeader:(frame_header)frame_header curData:(NSData *)curData;
{
    assert(frame_header.opcode != 0);
    
    if (self.readyState != LGSR_OPEN) {
        return;
    }
    
    
    BOOL isControlFrame = (frame_header.opcode == LGSROpCodePing || frame_header.opcode == LGSROpCodePong || frame_header.opcode == LGSROpCodeConnectionClose);
    
    if (isControlFrame && !frame_header.fin) {
        [self _closeWithProtocolError:@"Fragmented control frames not allowed"];
        return;
    }
    
    if (isControlFrame && frame_header.payload_length >= 126) {
        [self _closeWithProtocolError:@"Control frames cannot have payloads larger than 126 bytes"];
        return;
    }
    
    if (!isControlFrame) {
        _currentFrameOpcode = frame_header.opcode;
        _currentFrameCount += 1;
    }
    
    if (frame_header.payload_length == 0) {
        if (isControlFrame) {
            [self _handleFrameWithData:curData opCode:frame_header.opcode];
        } else {
            if (frame_header.fin) {
                [self _handleFrameWithData:_currentFrameData opCode:frame_header.opcode];
            } else {
                // TODO add assert that opcode is not a control;
                [self _readFrameContinue];
            }
        }
    } else {
        assert(frame_header.payload_length <= SIZE_T_MAX);
        [self _addConsumerWithDataLength:(size_t)frame_header.payload_length callback:^(LGSRWebSocket *self, NSData *newData) {
            if (isControlFrame) {
                [self _handleFrameWithData:newData opCode:frame_header.opcode];
            } else {
                if (frame_header.fin) {
                    [self _handleFrameWithData:self->_currentFrameData opCode:frame_header.opcode];
                } else {
                    // TODO add assert that opcode is not a control;
                    [self _readFrameContinue];
                }
                
            }
        } readToCurrentFrame:!isControlFrame unmaskBytes:frame_header.masked];
    }
}

/* From RFC:

 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 +-+-+-+-+-------+-+-------------+-------------------------------+
 |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
 |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
 |N|V|V|V|       |S|             |   (if payload len==126/127)   |
 | |1|2|3|       |K|             |                               |
 +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
 |     Extended payload length continued, if payload len == 127  |
 + - - - - - - - - - - - - - - - +-------------------------------+
 |                               |Masking-key, if MASK set to 1  |
 +-------------------------------+-------------------------------+
 | Masking-key (continued)       |          Payload Data         |
 +-------------------------------- - - - - - - - - - - - - - - - +
 :                     Payload Data continued ...                :
 + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
 |                     Payload Data continued ...                |
 +---------------------------------------------------------------+
 */

static const uint8_t LGSRFinMask          = 0x80;
static const uint8_t LGSROpCodeMask       = 0x0F;
static const uint8_t LGSRRsvMask          = 0x70;
static const uint8_t LGSRMaskMask         = 0x80;
static const uint8_t LGSRPayloadLenMask   = 0x7F;


- (void)_readFrameContinue;
{
    assert((_currentFrameCount == 0 && _currentFrameOpcode == 0) || (_currentFrameCount > 0 && _currentFrameOpcode > 0));

    [self _addConsumerWithDataLength:2 callback:^(LGSRWebSocket *self, NSData *data) {
        __block frame_header header = {0};
        
        const uint8_t *headerBuffer = data.bytes;
        assert(data.length >= 2);
        
        if (headerBuffer[0] & LGSRRsvMask) {
            [self _closeWithProtocolError:@"Server used RSV bits"];
            return;
        }
        
        uint8_t receivedOpcode = (LGSROpCodeMask & headerBuffer[0]);
        
        BOOL isControlFrame = (receivedOpcode == LGSROpCodePing || receivedOpcode == LGSROpCodePong || receivedOpcode == LGSROpCodeConnectionClose);
        
        if (!isControlFrame && receivedOpcode != 0 && self->_currentFrameCount > 0) {
            [self _closeWithProtocolError:@"all data frames after the initial data frame must have opcode 0"];
            return;
        }
        
        if (receivedOpcode == 0 && self->_currentFrameCount == 0) {
            [self _closeWithProtocolError:@"cannot continue a message"];
            return;
        }
        
        header.opcode = receivedOpcode == 0 ? self->_currentFrameOpcode : receivedOpcode;
        
        header.fin = !!(LGSRFinMask & headerBuffer[0]);
        
        
        header.masked = !!(LGSRMaskMask & headerBuffer[1]);
        header.payload_length = LGSRPayloadLenMask & headerBuffer[1];
        
        headerBuffer = NULL;
        
        if (header.masked) {
            [self _closeWithProtocolError:@"Client must receive unmasked data"];
        }
        
        size_t extra_bytes_needed = header.masked ? sizeof(_currentReadMaskKey) : 0;
        
        if (header.payload_length == 126) {
            extra_bytes_needed += sizeof(uint16_t);
        } else if (header.payload_length == 127) {
            extra_bytes_needed += sizeof(uint64_t);
        }
        
        if (extra_bytes_needed == 0) {
            [self _handleFrameHeader:header curData:self->_currentFrameData];
        } else {
            [self _addConsumerWithDataLength:extra_bytes_needed callback:^(LGSRWebSocket *self, NSData *data) {
                size_t mapped_size = data.length;
                const void *mapped_buffer = data.bytes;
                size_t offset = 0;
                
                if (header.payload_length == 126) {
                    assert(mapped_size >= sizeof(uint16_t));
                    uint16_t newLen = EndianU16_BtoN(*(uint16_t *)(mapped_buffer));
                    header.payload_length = newLen;
                    offset += sizeof(uint16_t);
                } else if (header.payload_length == 127) {
                    assert(mapped_size >= sizeof(uint64_t));
                    header.payload_length = EndianU64_BtoN(*(uint64_t *)(mapped_buffer));
                    offset += sizeof(uint64_t);
                } else {
                    assert(header.payload_length < 126 && header.payload_length >= 0);
                }
                
                
                if (header.masked) {
                    assert(mapped_size >= sizeof(_currentReadMaskOffset) + offset);
                    memcpy(self->_currentReadMaskKey, ((uint8_t *)mapped_buffer) + offset, sizeof(self->_currentReadMaskKey));
                }
                
                [self _handleFrameHeader:header curData:self->_currentFrameData];
            } readToCurrentFrame:NO unmaskBytes:NO];
        }
    } readToCurrentFrame:NO unmaskBytes:NO];
}

- (void)_readFrameNew;
{
    dispatch_async(_workQueue, ^{
        [_currentFrameData setLength:0];
        
        _currentFrameOpcode = 0;
        _currentFrameCount = 0;
        _readOpCount = 0;
        _currentStringScanPosition = 0;
        
        [self _readFrameContinue];
    });
}

- (void)_pumpWriting;
{
    [self assertOnWorkQueue];
    
    NSUInteger dataLength = _outputBuffer.length;
    if (dataLength - _outputBufferOffset > 0 && _outputStream.hasSpaceAvailable) {
        NSInteger bytesWritten = [_outputStream write:_outputBuffer.bytes + _outputBufferOffset maxLength:dataLength - _outputBufferOffset];
        if (bytesWritten == -1) {
            [self _failWithError:[NSError errorWithDomain:@"org.lolrus.SocketRocket" code:2145 userInfo:[NSDictionary dictionaryWithObject:@"Error writing to stream" forKey:NSLocalizedDescriptionKey]]];
             return;
        }
        
        _outputBufferOffset += bytesWritten;

        if (_outputBufferOffset > 4096 && _outputBufferOffset > (_outputBuffer.length >> 1)) {
            _outputBuffer = [[NSMutableData alloc] initWithBytes:(char *)_outputBuffer.bytes + _outputBufferOffset length:_outputBuffer.length - _outputBufferOffset];
            _outputBufferOffset = 0;
        }
    }
    
    if (_closeWhenFinishedWriting && 
        _outputBuffer.length - _outputBufferOffset == 0 && 
        (_inputStream.streamStatus != NSStreamStatusNotOpen &&
         _inputStream.streamStatus != NSStreamStatusClosed) &&
        !_sentClose) {
        _sentClose = YES;
        @synchronized(self) {
            [_outputStream close];
            [_inputStream close];

            for (NSArray *runLoop in [_scheduledRunloops copy]) {
                [self unscheduleFromRunLoop:[runLoop objectAtIndex:0] forMode:[runLoop objectAtIndex:1]];
            }
        }
        
        if (!_failed) {
            [self _performDelegateBlock:^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(webSocket:didCloseWithCode:reason:wasClean:)]) {
                    [self.delegate webSocket:self didCloseWithCode:_closeCode reason:_closeReason wasClean:YES];
                }
            }];
        }
        
        [self _scheduleCleanup];
    }
}

- (void)_scheduleCleanup
{
    @synchronized(self) {
        if (_cleanupScheduled) {
            return;
        }

        _cleanupScheduled = YES;

        // Cleanup NSStream delegate's in the same RunLoop used by the streams themselves:
        // This way we'll prevent race conditions between handleEvent and SRWebsocket's dealloc
        NSTimer *timer = [NSTimer timerWithTimeInterval:(0.0f) target:self selector:@selector(_cleanupSelfReference:) userInfo:nil repeats:NO];
        [[NSRunLoop LGSR_networkRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}

- (void)_cleanupSelfReference:(NSTimer *)timer
{
    @synchronized(self) {
        // Nuke NSStream delegate's
        _inputStream.delegate = nil;
        _outputStream.delegate = nil;

        // Remove the streams, right now, from the networkRunLoop
        [_inputStream close];
        [_outputStream close];
    }

    // Cleanup selfRetain in the same GCD queue as usual
    dispatch_async(_workQueue, ^{
        _selfRetain = nil;
    });
}

- (void)_addConsumerWithScanner:(stream_scanner)consumer callback:(data_callback)callback;
{
    [self assertOnWorkQueue];
    [self _addConsumerWithScanner:consumer callback:callback dataLength:0];
}

- (void)_addConsumerWithDataLength:(size_t)dataLength callback:(data_callback)callback readToCurrentFrame:(BOOL)readToCurrentFrame unmaskBytes:(BOOL)unmaskBytes;
{   
    [self assertOnWorkQueue];
    assert(dataLength);
    
    [_consumers addObject:[_consumerPool consumerWithScanner:nil handler:callback bytesNeeded:dataLength readToCurrentFrame:readToCurrentFrame unmaskBytes:unmaskBytes]];
    [self _pumpScanner];
}

- (void)_addConsumerWithScanner:(stream_scanner)consumer callback:(data_callback)callback dataLength:(size_t)dataLength;
{    
    [self assertOnWorkQueue];
    [_consumers addObject:[_consumerPool consumerWithScanner:consumer handler:callback bytesNeeded:dataLength readToCurrentFrame:NO unmaskBytes:NO]];
    [self _pumpScanner];
}


static const char CRLFCRLFBytes[] = {'\r', '\n', '\r', '\n'};

- (void)_readUntilHeaderCompleteWithCallback:(data_callback)dataHandler;
{
    [self _readUntilBytes:CRLFCRLFBytes length:sizeof(CRLFCRLFBytes) callback:dataHandler];
}

- (void)_readUntilBytes:(const void *)bytes length:(size_t)length callback:(data_callback)dataHandler;
{
    // TODO optimize so this can continue from where we last searched
    stream_scanner consumer = ^size_t(NSData *data) {
        __block size_t found_size = 0;
        __block size_t match_count = 0;
        
        size_t size = data.length;
        const unsigned char *buffer = data.bytes;
        for (size_t i = 0; i < size; i++ ) {
            if (((const unsigned char *)buffer)[i] == ((const unsigned char *)bytes)[match_count]) {
                match_count += 1;
                if (match_count == length) {
                    found_size = i + 1;
                    break;
                }
            } else {
                match_count = 0;
            }
        }
        return found_size;
    };
    [self _addConsumerWithScanner:consumer callback:dataHandler];
}


// Returns true if did work
- (BOOL)_innerPumpScanner {
    
    BOOL didWork = NO;
    
    if (self.readyState >= LGSR_CLOSING) {
        dispatch_async(_workQueue, ^{
            _closeCode = LGSRStatusCodeNormal;
            [self closeConnection];
        });
        return didWork;
    }
    
    if (!_consumers.count) {
        return didWork;
    }
    
    size_t curSize = _readBuffer.length - _readBufferOffset;
    if (!curSize) {
        return didWork;
    }
    
    LGSRIOConsumer *consumer = [_consumers objectAtIndex:0];
    
    size_t bytesNeeded = consumer.bytesNeeded;
    
    size_t foundSize = 0;
    if (consumer.consumer) {
        NSData *tempView = [NSData dataWithBytesNoCopy:(char *)_readBuffer.bytes + _readBufferOffset length:_readBuffer.length - _readBufferOffset freeWhenDone:NO];  
        foundSize = consumer.consumer(tempView);
    } else {
        assert(consumer.bytesNeeded);
        if (curSize >= bytesNeeded) {
            foundSize = bytesNeeded;
        } else if (consumer.readToCurrentFrame) {
            foundSize = curSize;
        }
    }
    
    NSData *slice = nil;
    if (consumer.readToCurrentFrame || foundSize) {
        NSRange sliceRange = NSMakeRange(_readBufferOffset, foundSize);
        slice = [_readBuffer subdataWithRange:sliceRange];
        
        _readBufferOffset += foundSize;
        
        if (_readBufferOffset > 4096 && _readBufferOffset > (_readBuffer.length >> 1)) {
            _readBuffer = [[NSMutableData alloc] initWithBytes:(char *)_readBuffer.bytes + _readBufferOffset length:_readBuffer.length - _readBufferOffset];            _readBufferOffset = 0;
        }
        
        if (consumer.unmaskBytes) {
            NSMutableData *mutableSlice = [slice mutableCopy];
            
            NSUInteger len = mutableSlice.length;
            uint8_t *bytes = mutableSlice.mutableBytes;
            
            for (NSUInteger i = 0; i < len; i++) {
                bytes[i] = bytes[i] ^ _currentReadMaskKey[_currentReadMaskOffset % sizeof(_currentReadMaskKey)];
                _currentReadMaskOffset += 1;
            }
            
            slice = mutableSlice;
        }
        
        if (consumer.readToCurrentFrame) {
            [_currentFrameData appendData:slice];
            
            _readOpCount += 1;
            
            if (_currentFrameOpcode == LGSROpCodeTextFrame) {
                // Validate UTF8 stuff.
                size_t currentDataSize = _currentFrameData.length;
                if (_currentFrameOpcode == LGSROpCodeTextFrame && currentDataSize > 0) {
                    // TODO: Optimize the crap out of this.  Don't really have to copy all the data each time
                    
                    size_t scanSize = currentDataSize - _currentStringScanPosition;
                    
                    NSData *scan_data = [_currentFrameData subdataWithRange:NSMakeRange(_currentStringScanPosition, scanSize)];
                    int32_t valid_utf8_size = validate_dispatch_data_partial_string(scan_data);
                    
                    if (valid_utf8_size == -1) {
                        [self closeWithCode:LGSRStatusCodeInvalidUTF8 reason:@"Text frames must be valid UTF-8"];
                        dispatch_async(_workQueue, ^{
                            [self closeConnection];
                        });
                        return didWork;
                    } else {
                        _currentStringScanPosition += valid_utf8_size;
                    }
                } 
                
            }
            
            consumer.bytesNeeded -= foundSize;
            
            if (consumer.bytesNeeded == 0) {
                [_consumers removeObjectAtIndex:0];
                consumer.handler(self, nil);
                [_consumerPool returnConsumer:consumer];
                didWork = YES;
            }
        } else if (foundSize) {
            [_consumers removeObjectAtIndex:0];
            consumer.handler(self, slice);
            [_consumerPool returnConsumer:consumer];
            didWork = YES;
        }
    }
    return didWork;
}

-(void)_pumpScanner;
{
    [self assertOnWorkQueue];
    
    if (!_isPumping) {
        _isPumping = YES;
    } else {
        return;
    }
    
    while ([self _innerPumpScanner]) {
        
    }
    
    _isPumping = NO;
}

//#define NOMASK

static const size_t LGSRFrameHeaderOverhead = 32;

- (void)_sendFrameWithOpcode:(LGSROpCode)opcode data:(id)data;
{
    [self assertOnWorkQueue];
    
    NSAssert(data == nil || [data isKindOfClass:[NSData class]] || [data isKindOfClass:[NSString class]], @"Function expects nil, NSString or NSData");
    
    size_t payloadLength = [data isKindOfClass:[NSString class]] ? [(NSString *)data lengthOfBytesUsingEncoding:NSUTF8StringEncoding] : [data length];
        
    NSMutableData *frame = [[NSMutableData alloc] initWithLength:payloadLength + LGSRFrameHeaderOverhead];
    if (!frame) {
        [self closeWithCode:LGSRStatusCodeMessageTooBig reason:@"Message too big"];
        return;
    }
    uint8_t *frame_buffer = (uint8_t *)[frame mutableBytes];
    
    // set fin
    frame_buffer[0] = LGSRFinMask | opcode;
    
    BOOL useMask = YES;
#ifdef NOMASK
    useMask = NO;
#endif
    
    if (useMask) {
    // set the mask and header
        frame_buffer[1] |= LGSRMaskMask;
    }
    
    size_t frame_buffer_size = 2;
    
    const uint8_t *unmasked_payload = NULL;
    if ([data isKindOfClass:[NSData class]]) {
        unmasked_payload = (uint8_t *)[data bytes];
    } else if ([data isKindOfClass:[NSString class]]) {
        unmasked_payload =  (const uint8_t *)[data UTF8String];
    } else {
        assert(NO);
    }
    
    if (payloadLength < 126) {
        frame_buffer[1] |= payloadLength;
    } else if (payloadLength <= UINT16_MAX) {
        frame_buffer[1] |= 126;
        *((uint16_t *)(frame_buffer + frame_buffer_size)) = EndianU16_BtoN((uint16_t)payloadLength);
        frame_buffer_size += sizeof(uint16_t);
    } else {
        frame_buffer[1] |= 127;
        *((uint64_t *)(frame_buffer + frame_buffer_size)) = EndianU64_BtoN((uint64_t)payloadLength);
        frame_buffer_size += sizeof(uint64_t);
    }
        
    if (!useMask) {
        for (size_t i = 0; i < payloadLength; i++) {
            frame_buffer[frame_buffer_size] = unmasked_payload[i];
            frame_buffer_size += 1;
        }
    } else {
        uint8_t *mask_key = frame_buffer + frame_buffer_size;
        SecRandomCopyBytes(kSecRandomDefault, sizeof(uint32_t), (uint8_t *)mask_key);
        frame_buffer_size += sizeof(uint32_t);
        
        // TODO: could probably optimize this with SIMD
        for (size_t i = 0; i < payloadLength; i++) {
            frame_buffer[frame_buffer_size] = unmasked_payload[i] ^ mask_key[i % sizeof(uint32_t)];
            frame_buffer_size += 1;
        }
    }

    assert(frame_buffer_size <= [frame length]);
    frame.length = frame_buffer_size;
    
    [self _writeData:frame];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;
{
    __weak typeof(self) weakSelf = self;
    NSMutableArray *certs;
    if ([_urlRequest LGSR_SSLPinnedCertificates] == nil && _sslData == nil && (eventCode == NSStreamEventHasBytesAvailable || eventCode == NSStreamEventHasSpaceAvailable)) {
        
        SecTrustRef secTrust = (__bridge SecTrustRef)[aStream propertyForKey:(__bridge id)kCFStreamPropertySSLPeerTrust];
        
        if (secTrust) {
            certs = [NSMutableArray array];
            NSInteger numCerts = SecTrustGetCertificateCount(secTrust);
            _Pragma("clang diagnostic push");
            _Pragma("clang diagnostic ignored \"-Wunreachable-code-loop-increment\"");
            for (NSInteger i = 0; i < numCerts; i++) {
                SecCertificateRef cert = SecTrustGetCertificateAtIndex(secTrust, i);
                //NSData *trustedCertData = CFBridgingRelease(SecCertificateCopyData(cert));
                //NSString *certSummaryString = (__bridge NSString *)(SecCertificateCopySubjectSummary(cert));
                NSString *certString = CFBridgingRelease(SecCertificateCopySubjectSummary((cert)));
              
                //NSString *convString = [trustedCertData base64EncodedStringWithOptions:0];
                //NSLog(@"CERT>>>%@",convString);
                
                ///////////************** handle CA Certificates changes ******
                
                SecKeyRef publicKey =SecCertificateCopyPublicKey((cert));
                
                NSString *certficatePublicKeyString = nil;
                certficatePublicKeyString = [weakSelf getPublicKeyAsBase64:(publicKey)];
                if(certficatePublicKeyString == nil)
                {
                    _ipublicKeyvalue =-1;
                    [certs addObject:(@"_ipublicKeyvalue =-1")];
                     break;
                }
                
                if ([certString rangeOfString:@"Intermediate CA"].length == 0 && [certString rangeOfString:@"SSG"].length == 0) {
                    // since both the keys do not exist Self signed Server certificate use its public key
                    // we are not verifying this self signed certificate, because there are several different verfions
                    // of Self signed certificates obeserved, also anyways we need not check and verify the cases for
                    //self signed as this is the case in Android side implementation also.
                    // if required for verification then we can uncomment the below part and the boabe stored self
                    //signed public key LGSSCPublicKeyString provide we get same self signed certificates
                    //Verifying the Received Certificate Publickey is Valid and both Same
                    //Verifying the Received Certificate Publickey is Valid and both Same
                    /*if((LGSSCPublicKeyString == nil)||(certficatePublicKeyString == nil)|| ([[certficatePublicKeyString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] caseInsensitiveCompare:[LGSSCPublicKeyString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]])){
                        LGSRFastLog(@"Failed Certificate Verification");
                        // logging the got data.
                        LGSRFastLog(@"PUBLICKEY-RSAPublicKey This is what is needed>>>%@",certficatePublicKeyString);
                        LGSRFastLog(@"LGSSCPublicKeyString>>>%@",LGSSCPublicKeyString);
                        _ipublicKeyvalue =-1;
                        [certs addObject:(@"_ipublicKeyvalue =-1")];
                        break;
                    }*/
                    }else { if ([certString rangeOfString:@"Intermediate CA"].length == 0) {
                        // case for ServerCertificate found and use its Publickey
                        if((LGServerCertificatePublicKeyString == nil)||(certficatePublicKeyString == nil)|| ([[certficatePublicKeyString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] caseInsensitiveCompare:[LGServerCertificatePublicKeyString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]])){
                            LGSRFastLog(@"Failed Certificate Verification");
                            // logging the got data.
                            LGSRFastLog(@"PUBLICKEY-RSAPublicKey This is what is needed>>>%@",certficatePublicKeyString);
                            LGSRFastLog(@"LGServerCertificatePublicKeyString>>>%@",LGServerCertificatePublicKeyString);
                            _ipublicKeyvalue =-1;
                            [certs addObject:(@"_ipublicKeyvalue =-1")];
                            break;
                        }
                    } else {// IntermediateCA found use its public key
                    //Verifying the Received Certificate Publickey is Valid and both Same
                    if((LGIntermediateCAPublicKeyString == nil)||(certficatePublicKeyString == nil)|| ([[certficatePublicKeyString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] caseInsensitiveCompare:[LGIntermediateCAPublicKeyString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]])){
                        LGSRFastLog(@"Failed Certificate Verification");
                        // logging the got data.
                        LGSRFastLog(@"PUBLICKEY-RSAPublicKey This is what is needed>>>%@",certficatePublicKeyString);
                        LGSRFastLog(@"LGIntermediateCAPublicKeyString>>>%@",LGIntermediateCAPublicKeyString);
                        _ipublicKeyvalue =-1;
                        [certs addObject:(@"_ipublicKeyvalue =-1")];
                        break;
                    }
                    }
                }
                
                LGSRFastLog(@"Passed Certificate Verification");
                _ipublicKeyvalue =1;
                
                //check for validity
                OSStatus            err;
                BOOL                allowConnection;
                CFArrayRef          policies;
                NSMutableArray *    certificates;
                CFIndex             certCount;
                CFIndex             certIndex;
                SecTrustRef         newTrust;
                SecTrustResultType  newTrustResult;
                
                allowConnection = NO;
                
                policies = NULL;
                newTrust = NULL;
                
                err = SecTrustCopyPolicies(secTrust, &policies);
                if (err == errSecSuccess) {
                    certificates = [NSMutableArray array];
                    
                    certCount = SecTrustGetCertificateCount(secTrust);
                    for (certIndex = 0; certIndex < certCount; certIndex++) {
                        SecCertificateRef   thisCertificate;
                        
                        thisCertificate = SecTrustGetCertificateAtIndex(secTrust, certIndex);
                        [certificates addObject:(__bridge id)thisCertificate];
                    }
                    
                    //extraIntermediate = ... the extra intermediate certificate to use ...;
                   // [certificates addObject:(__bridge id)extraIntermediate];
                    
                    err = SecTrustCreateWithCertificates(
                                                         (__bridge CFArrayRef) certificates,
                                                         policies,
                                                         &newTrust
                                                         );
                    if (err == noErr) {
                        SecPolicyRef    policy;
                        policy = SecPolicyCreateBasicX509();//SecPolicyCreateSSL(true, CFSTR("0" ));
                        err = SecTrustSetPolicies(newTrust, policy);
                        if (err != noErr) {
                             LGSRFastLog(@"Policy Setting failed");
                            [certs addObject:(@"_icertificateValidity=-1")];
                            break;
                        }
                        CFRelease(policy);
                        SecTrustSetAnchorCertificates(newTrust, (__bridge CFArrayRef) certificates);
                        err = SecTrustEvaluate(newTrust, &newTrustResult);
                    }
                    if (err == noErr) {
                        allowConnection = (newTrustResult == kSecTrustResultProceed) ||
                        (newTrustResult == kSecTrustResultUnspecified);
                        
                        if(newTrustResult == kSecTrustEvaluationDate){
                            LGSRFastLog(@"*******Failed - Trust evaluation  as the Certificate  Expired******");
                             _icertificateValidity=-1;
                            [certs addObject:(@"_icertificateValidity=-1")];
                            break;
                        }
                        _icertificateValidity=1;
                        /* From SecTrust.h:
                         *
                         * SecTrustResultType results have two dimensions.  They specify both whether
                         * evaluation suceeded and whether this is because of a user decision.
                         *
                         * In practice the commonly expected result is kSecTrustResultUnspecified,
                         * which indicates a positive result that wasn't decided by the user.
                         *
                         * The common failure is kSecTrustResultRecoverableTrustFailure, which means a
                         * negative result.  kSecTrustResultProceed and kSecTrustResultDeny are the
                         * positive and negative result respectively when decided by the user.  User
                         *  decisions are persisted through the use of SecTrustCopyExceptions() and
                         * SecTrustSetExceptions().  Finally kSecTrustResultFatalTrustFailure is a
                         * negative result that should not be circumvented.  In fact only in the case
                         * of kSecTrustResultRecoverableTrustFailure should a user ever be asked.
                         */
                        switch (newTrustResult) {
                            case kSecTrustResultProceed: // 1
                            case kSecTrustResultConfirm: // 2 depricated in ios 7.0
                                LGSRFastLog(@"Passed Trust evaluation");
                                _icertificateValidity=1;
                            break;
                            case kSecTrustResultUnspecified: // 4
                            case kSecTrustResultRecoverableTrustFailure:  // 5
                            case kSecTrustResultDeny: // 3
                            case kSecTrustResultFatalTrustFailure: // 6
                            case kSecTrustResultOtherError: // 7
                            case kSecTrustResultInvalid: // 0
                            {
                                 LGSRFastLog(@"Trust evaluation Policy Applied");
                                CFDataRef errDataRef = SecTrustCopyExceptions(newTrust);
                                LGSRFastLog(@"errDataRef=%@", errDataRef);
                                SecTrustSetExceptions(newTrust, errDataRef);
                                err = SecTrustEvaluate(newTrust, &newTrustResult);
                                if (err == noErr) {
                                    allowConnection = (newTrustResult == kSecTrustResultProceed) ||
                                    (newTrustResult == kSecTrustResultUnspecified);
                                    LGSRFastLog(@"Passed Trust evaluation");
                                     _icertificateValidity=1;
                                }
                            }
                            default:
                            {
#ifdef __IPHONE_7_0 //|| __IPHONE_9_0
                                if((newTrustResult == kSecPropertyTypeTitle) ||(newTrustResult == kSecPropertyTypeError) ||(newTrustResult == kSecTrustExtendedValidation)||
                                   (newTrustResult == kSecTrustOrganizationName)||(newTrustResult == kSecTrustResultValue)||(newTrustResult == kSecTrustRevocationChecked)
                                   || (newTrustResult == kSecTrustRevocationValidUntilDate)||(newTrustResult ==  kSecTrustCertificateTransparency))
#endif
                                {
                                    LGSRFastLog(@"Trust evaluation Policy Applied");
                                    CFDataRef errDataRef = SecTrustCopyExceptions(newTrust);
                                    LGSRFastLog(@"errDataRef=%@", errDataRef);
                                    SecTrustSetExceptions(newTrust, errDataRef);
                                     err = SecTrustEvaluate(newTrust, &newTrustResult);
                                      if (err == noErr) {
                                          allowConnection = (newTrustResult == kSecTrustResultProceed) ||
                                          (newTrustResult == kSecTrustResultUnspecified);
                                           LGSRFastLog(@"Passed Trust evaluation");
                                           _icertificateValidity=1;
                                    }
                                    
                                }
                               // return;
                              break;
                            }
                        }
                        
                    } else {
                        LGSRFastLog(@"************* Trust evaluation Failed***************");
                        _ipublicKeyvalue =-1;
                        [certs addObject:(@"_ipublicKeyvalue =-1")];
                        break;
                    }
                }
                
                if (newTrust != NULL) {
                    CFRelease(newTrust);
                }
                if (policies != NULL) {
                    CFRelease(policies);
                }
               
                if(publicKey != NULL){
                    CFRelease(publicKey);
                }

                ////////////
                if (  _icertificateValidity== 1 && _ipublicKeyvalue== 1 )
                {
                    [certs addObject:certString];
                 //   break; // to be confirmed for SSL.
                }
                
            }
            _Pragma("clang diagnostic pop");
        }
        else {
            LGSRFastLog(@"************* Trust evaluation Failed***************");
            _ipublicKeyvalue =-1;
            [certs addObject:(@"_ipublicKeyvalue =-1")];
        }
      
        if (  _icertificateValidity== 1&&_ipublicKeyvalue== 1 )
        {
            
            [_urlRequest setLGSR_SSLPinnedCertificates:certs];
            
        }
            
    }
    
    if (_secure && !_pinnedCertFound && (eventCode == NSStreamEventHasBytesAvailable || eventCode == NSStreamEventHasSpaceAvailable)) {
        
        NSArray *sslCerts = [_urlRequest LGSR_SSLPinnedCertificates];
        if (sslCerts) {
            SecTrustRef secTrust = (__bridge SecTrustRef)[aStream propertyForKey:(__bridge id)kCFStreamPropertySSLPeerTrust];
            if (secTrust) {
                NSInteger numCerts = SecTrustGetCertificateCount(secTrust);
                for (NSInteger i = 0; i < numCerts && !_pinnedCertFound; i++) {
                    SecCertificateRef cert = SecTrustGetCertificateAtIndex(secTrust, i);
                    //NSData *certData = CFBridgingRelease(SecCertificateCopyData(cert));
                    //NSString *certData = (__bridge NSString *)(SecCertificateCopySubjectSummary(cert));
                    NSString *certData = CFBridgingRelease(SecCertificateCopySubjectSummary((cert)));
                    
                    for (id ref in sslCerts) {
                        //if ([ref isEqualToData:certData]) {
                        if ([ref isEqualToString:certData]) {
                            _pinnedCertFound = YES;
                            LGSRFastLog(@"*************_secure && _pinnedCertFound ***************" );
                           // break;// to be confirmed for SSL.
                            
                        }
                    }
                }
            }
            else {
                LGSRFastLog(@"************* secTrust evaluation is nil ***************");
            }
        }else {
            LGSRFastLog(@"************* LGSR_SSLPinnedCertificates is nil ***************");
            _icertificateValidity=-1;
            [certs addObject:(@"_icertificateValidity=-1")];
        }
        _sslData = certs;
        
        [weakSelf _performDelegateBlock:^{
            if ([weakSelf.delegate respondsToSelector:@selector(webSocket:didGetCertificates:)]) {
                [weakSelf.delegate webSocket:weakSelf didGetCertificates:_sslData];
            }
        }];
        
        if (!_pinnedCertFound || (certs && (_icertificateValidity== -1 || _ipublicKeyvalue== -1))) {
            NSLog(@"*************TV CERTIFICATE FAILURE ****************");
            dispatch_async(_workQueue, ^{
                [weakSelf _failWithError:[NSError errorWithDomain:@"org.lolrus.SocketRocket" code:23556 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Invalid server cert"] forKey:NSLocalizedDescriptionKey]]];
            });
            return;
        }
    }
    dispatch_async(_workQueue, ^{
        [weakSelf safeHandleEvent:eventCode stream:aStream];
    });
}

- (void)safeHandleEvent:(NSStreamEvent)eventCode stream:(NSStream *)aStream
{

    dispatch_async(_workQueue, ^{
        switch (eventCode) {
            case NSStreamEventOpenCompleted: {
                LGSRFastLog(@"NSStreamEventOpenCompleted %@", aStream);
                if (self.readyState >= LGSR_CLOSING) {
                    return;
                }
                assert(_readBuffer);
                
                if (self.readyState == LGSR_CONNECTING && aStream == _inputStream) {
                    [self didConnect];
                }
                [self _pumpWriting];
                [self _pumpScanner];
                break;
            }
                
            case NSStreamEventErrorOccurred: {
                LGSRFastLog(@"NSStreamEventErrorOccurred %@ %@", aStream, [[aStream streamError] copy]);
                /// TODO specify error better!
                [self _failWithError:aStream.streamError];
                _readBufferOffset = 0;
                [_readBuffer setLength:0];
                break;
                
            }
                
            case NSStreamEventEndEncountered: {
                [self _pumpScanner];
                LGSRFastLog(@"NSStreamEventEndEncountered %@", aStream);
                if (aStream.streamError) {
                    [self _failWithError:aStream.streamError];
                } else {
                    if (self.readyState != LGSR_CLOSED) {
                        self.readyState = LGSR_CLOSED;
                        [self _scheduleCleanup];
                    }

                    if (!_sentClose && !_failed) {
                        _sentClose = YES;
                        // If we get closed in this state it's probably not clean because we should be sending this when we send messages
                        [self _performDelegateBlock:^{
                            if ([self.delegate respondsToSelector:@selector(webSocket:didCloseWithCode:reason:wasClean:)]) {
                                [self.delegate webSocket:self didCloseWithCode:0 reason:@"Stream end encountered" wasClean:NO];
                            }
                        }];
                    }
                }
                
                break;
            }
                
            case NSStreamEventHasBytesAvailable: {
                LGSRFastLog(@"NSStreamEventHasBytesAvailable %@", aStream);
                const int bufferSize = 2048;
                uint8_t buffer[bufferSize];
                
                while (_inputStream.hasBytesAvailable) {
                    NSInteger bytes_read = [_inputStream read:buffer maxLength:bufferSize];
                    
                    if (bytes_read > 0) {
                        [_readBuffer appendBytes:buffer length:bytes_read];
                    } else if (bytes_read < 0) {
                        [self _failWithError:_inputStream.streamError];
                    }
                    
                    if (bytes_read != bufferSize) {
                        break;
                    }
                };
                [self _pumpScanner];
                break;
            }
                
            case NSStreamEventHasSpaceAvailable: {
                LGSRFastLog(@"NSStreamEventHasSpaceAvailable %@", aStream);
                [self _pumpWriting];
                break;
            }
                
            default:
                LGSRFastLog(@"(default)  %@", aStream);
                break;
        }
    });
}
        
// Helper function for ASN.1 encoding
-(size_t) encodeLength:(unsigned char *)buf:(size_t)length {
    
    // encode length in ASN.1 DER format
    if (length < 128) {
        buf[0] = length;
        return 1;
    }
    
    size_t i = (length / 256) + 1;
    buf[0] = i + 0x80;
    for (size_t j = 0 ; j < i; ++j) {
        buf[i - j] = length & 0xFF;
        length = length >> 8;
    }
    
    return i + 1;
}
        
#define _MY_PUBLIC_KEY_TAG "com.lge.remote-app.publickey"

- (NSString *) getPublicKeyAsBase64 :(SecKeyRef)publicKey {
    
    static const unsigned char _encodedRSAEncryptionOID[15] = {
        
        /* Sequence of length 0xd made up of OID followed by NULL */
       0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00
        
    };
    
    NSData * publicTag = [NSData dataWithBytes:_MY_PUBLIC_KEY_TAG
                   length:strlen((const char *) _MY_PUBLIC_KEY_TAG)];
    
    // Now lets extract the public key - build query to get bits
    NSMutableDictionary * queryPublicKey =
    [[NSMutableDictionary alloc] init];
    
    [queryPublicKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPublicKey setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPublicKey setObject:(__bridge id)publicKey forKey:(__bridge id)kSecValueRef];
    [queryPublicKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    //[queryPublicKey setObject:@2048 forKey:(__bridge id)kSecAttrKeySizeInBits];
    [queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnData];
    
    CFTypeRef result1;
    NSData * publicKeyBits;
    OSStatus sanityCheck = SecItemAdd((__bridge CFDictionaryRef) queryPublicKey, &result1);
    sanityCheck = SecItemCopyMatching((CFDictionaryRef)queryPublicKey, &result1);
    if (sanityCheck == errSecSuccess) {
        publicKeyBits = CFBridgingRelease(result1);
        
        (void)SecItemDelete((__bridge CFDictionaryRef) queryPublicKey);
    
    }
    
    // OK - that gives us the "BITSTRING component of a full DER
    // encoded RSA public key - we now need to build the rest
    
    unsigned char builder[15];
    NSMutableData * encKey = [[NSMutableData alloc] init];
    int bitstringEncLength;
    
    // When we get to the bitstring - how will we encode it?
    if  ([publicKeyBits length ] + 1  < 128 )
        bitstringEncLength = 1 ;
    else
        bitstringEncLength = (([publicKeyBits length ] +1 ) / 256 ) + 2 ;
    
    // Overall we have a sequence of a certain length
    builder[0] = 0x30;    // ASN.1 encoding representing a SEQUENCE
    // Build up overall size made up of -
    // size of OID + size of bitstring encoding + size of actual key
    size_t i = sizeof(_encodedRSAEncryptionOID) + 2 + bitstringEncLength +
    [publicKeyBits length];
    size_t j = [self encodeLength :&builder[1]: i];
    [encKey appendBytes:builder length:j +1];
    
    // First part of the sequence is the OID
    [encKey appendBytes:_encodedRSAEncryptionOID
                 length:sizeof(_encodedRSAEncryptionOID)];
    
    // Now add the bitstring
    builder[0] = 0x03;
    j = [self encodeLength : &builder[1]: [publicKeyBits length] + 1];
    builder[j+1] = 0x00;
    [encKey appendBytes:builder length:j + 2];
    
    // Now the actual key
    [encKey appendData:publicKeyBits];
    
    // Now translate the result to a Base64 string
    NSString * ret = [encKey base64EncodedStringWithOptions:[encKey length]];
    CFRelease(CFBridgingRetain(encKey));
    return ret;
}
@end


@implementation LGSRIOConsumer

@synthesize bytesNeeded = _bytesNeeded;
@synthesize consumer = _scanner;
@synthesize handler = _handler;
@synthesize readToCurrentFrame = _readToCurrentFrame;
@synthesize unmaskBytes = _unmaskBytes;

- (void)setupWithScanner:(stream_scanner)scanner handler:(data_callback)handler bytesNeeded:(size_t)bytesNeeded readToCurrentFrame:(BOOL)readToCurrentFrame unmaskBytes:(BOOL)unmaskBytes;
{
    _scanner = [scanner copy];
    _handler = [handler copy];
    _bytesNeeded = bytesNeeded;
    _readToCurrentFrame = readToCurrentFrame;
    _unmaskBytes = unmaskBytes;
    assert(_scanner || _bytesNeeded);
}


@end


@implementation LGSRIOConsumerPool {
    NSUInteger _poolSize;
    NSMutableArray *_bufferedConsumers;
}

- (id)initWithBufferCapacity:(NSUInteger)poolSize;
{
    self = [super init];
    if (self) {
        _poolSize = poolSize;
        _bufferedConsumers = [[NSMutableArray alloc] initWithCapacity:poolSize];
    }
    return self;
}

- (id)init
{
    return [self initWithBufferCapacity:8];
}

- (LGSRIOConsumer *)consumerWithScanner:(stream_scanner)scanner handler:(data_callback)handler bytesNeeded:(size_t)bytesNeeded readToCurrentFrame:(BOOL)readToCurrentFrame unmaskBytes:(BOOL)unmaskBytes;
{
    LGSRIOConsumer *consumer = nil;
    if (_bufferedConsumers.count) {
        consumer = [_bufferedConsumers lastObject];
        [_bufferedConsumers removeLastObject];
    } else {
        consumer = [[LGSRIOConsumer alloc] init];
    }
    
    [consumer setupWithScanner:scanner handler:handler bytesNeeded:bytesNeeded readToCurrentFrame:readToCurrentFrame unmaskBytes:unmaskBytes];
    
    return consumer;
}

- (void)returnConsumer:(LGSRIOConsumer *)consumer;
{
    if (_bufferedConsumers.count < _poolSize) {
        [_bufferedConsumers addObject:consumer];
    }
}

@end


@implementation  NSURLRequest (CertificateAdditions)

- (NSArray *)LGSR_SSLPinnedCertificates;
{
    return [NSURLProtocol propertyForKey:@"LGSR_SSLPinnedCertificates" inRequest:self];
}

@end

@implementation  NSMutableURLRequest (CertificateAdditions)

- (NSArray *)LGSR_SSLPinnedCertificates;
{
    return [NSURLProtocol propertyForKey:@"LGSR_SSLPinnedCertificates" inRequest:self];
}

- (void)setLGSR_SSLPinnedCertificates:(NSArray *)LGSR_SSLPinnedCertificates;
{
    [NSURLProtocol setProperty:LGSR_SSLPinnedCertificates forKey:@"LGSR_SSLPinnedCertificates" inRequest:self];
}

@end

@implementation NSURL (LGSRWebSocket)

- (NSString *)LGSR_origin;
{
    NSString *scheme = [self.scheme lowercaseString];
        
    if ([scheme isEqualToString:@"wss"]) {
        scheme = @"https";
    } else if ([scheme isEqualToString:@"ws"]) {
        scheme = @"http";
    }
    
    if (self.port) {
        return [NSString stringWithFormat:@"%@://%@:%@/", scheme, self.host, self.port];
    } else {
        return [NSString stringWithFormat:@"%@://%@/", scheme, self.host];
    }
}

@end

//#define LGSR_ENABLE_LOG

static inline void LGSRFastLog(NSString *format, ...)  {
#ifdef LGSR_ENABLE_LOG
    __block va_list arg_list;
    va_start (arg_list, format);
    
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    
    va_end(arg_list);
    
    DLog(@"[LGSR] %@", formattedString);
#endif
}


#ifdef HAS_ICU

static inline int32_t validate_dispatch_data_partial_string(NSData *data) {
    if ([data length] > INT32_MAX) {
        // INT32_MAX is the limit so long as this Framework is using 32 bit ints everywhere.
        return -1;
    }
    
    int32_t size = (int32_t)[data length];
    
    const void * contents = [data bytes];
    const uint8_t *str = (const uint8_t *)contents;
    
    UChar32 codepoint = 1;
    int32_t offset = 0;
    int32_t lastOffset = 0;
    while(offset < size && codepoint > 0)  {
        lastOffset = offset;
        U8_NEXT(str, offset, size, codepoint);
    }
    
    if (codepoint == -1) {
        // Check to see if the last byte is valid or whether it was just continuing
        if (!U8_IS_LEAD(str[lastOffset]) || U8_COUNT_TRAIL_BYTES(str[lastOffset]) + lastOffset < (int32_t)size) {
            
            size = -1;
        } else {
            uint8_t leadByte = str[lastOffset];
            U8_MASK_LEAD_BYTE(leadByte, U8_COUNT_TRAIL_BYTES(leadByte));
            
            for (int i = lastOffset + 1; i < offset; i++) {
                if (U8_IS_SINGLE(str[i]) || U8_IS_LEAD(str[i]) || !U8_IS_TRAIL(str[i])) {
                    size = -1;
                }
            }
            
            if (size != -1) {
                size = lastOffset;
            }
        }
    }
    
    if (size != -1 && ![[NSString alloc] initWithBytesNoCopy:(char *)[data bytes] length:size encoding:NSUTF8StringEncoding freeWhenDone:NO]) {
        size = -1;
    }
    
    return (int32_t)size;
}

#else

// This is a hack, and probably not optimal
static inline int32_t validate_dispatch_data_partial_string(NSData *data) {
    static const int maxCodepointSize = 3;
    
    for (int i = 0; i < maxCodepointSize; i++) {
        NSString *str = [[NSString alloc] initWithBytesNoCopy:(char *)data.bytes length:data.length - i encoding:NSUTF8StringEncoding freeWhenDone:NO];
        if (str) {
            return data.length - i;
        }
    }
    
    return -1;
}

#endif

static _LGSRRunLoopThread *networkThread = nil;
static NSRunLoop *networkRunLoop = nil;

@implementation NSRunLoop (LGSRWebSocket)

+ (NSRunLoop *)LGSR_networkRunLoop {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkThread = [[_LGSRRunLoopThread alloc] init];
        networkThread.name = @"com.squareup.SocketRocket.NetworkThread";
        [networkThread start];
        networkRunLoop = networkThread.runLoop;
    });
    
    return networkRunLoop;
}

@end


@implementation _LGSRRunLoopThread {
    dispatch_group_t _waitGroup;
}

@synthesize runLoop = _runLoop;

- (void)dealloc
{
    lgsr_dispatch_release(_waitGroup);
}

- (id)init
{
    self = [super init];
    if (self) {
        _waitGroup = dispatch_group_create();
        dispatch_group_enter(_waitGroup);
    }
    return self;
}

- (void)main;
{
    @autoreleasepool {
        _runLoop = [NSRunLoop currentRunLoop];
        dispatch_group_leave(_waitGroup);
        
        NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate distantFuture] interval:0.0 target:nil selector:nil userInfo:nil repeats:NO];
        [_runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
        
        while ([_runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
            
        }
        assert(NO);
    }
}

- (NSRunLoop *)runLoop;
{
    dispatch_group_wait(_waitGroup, DISPATCH_TIME_FOREVER);
    return _runLoop;
}

@end
