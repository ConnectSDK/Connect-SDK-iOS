//
//  DLNAServiceTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/13/15.
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

#import <OHHTTPStubs/OHHTTPStubs.h>
#import "NSInvocation+ObjectGetter.h"
#import "OCMStubRecorder+XCTestExpectation.h"

#import "CTXMLReader.h"
#import "DLNAService_Private.h"
#import "ConnectError.h"
#import "NSDictionary+KeyPredicateSearch.h"
#import "SSDPDiscoveryProvider_Private.h"
#import "DLNAHTTPServer.h"
#import "DeviceServiceReachability.h"
#import "SubtitleInfo.h"

static NSString *const kPlatformXbox = @"xbox";
static NSString *const kPlatformSonos = @"sonos";

static NSString *const kAVTransportNamespace = @"urn:schemas-upnp-org:service:AVTransport:1";
static NSString *const kRenderingControlNamespace = @"urn:schemas-upnp-org:service:RenderingControl:1";

/// Executes the given block wrapping it in pragmas ignoring the capturing
/// @c self warning, for a rare case when a compiler thinks a method is a setter,
/// but it is not (e.g., -[DLNAService setVolume:success:failure:]).
/// @see http://stackoverflow.com/questions/15535899/blocks-retain-cycle-from-naming-convention
//
// http://stackoverflow.com/questions/13826722/how-do-i-define-a-macro-with-multiple-pragmas-for-clang
#define silence_retain_cycle_warning(block) ({\
    _Pragma("clang diagnostic push"); \
    _Pragma("clang diagnostic ignored \"-Warc-retain-cycles\""); \
    block(); \
    _Pragma("clang diagnostic pop"); \
})

static NSString *const kAVTransportControlURLKey = @"avTrCtrlURL";
static NSString *const kAVTransportEventURLKey = @"avTrEventURL";
static NSString *const kRenderingControlControlURLKey = @"rndCtrCtrlURL";
static NSString *const kRenderingControlEventURLKey = @"rndCtrEventURL";

static NSString *const kIconURLMetadataKey = @"iconURL";

static NSString *const kSecCaptionInfoTag = @"sec:CaptionInfo";
static NSString *const kSecCaptionInfoExTag = @"sec:CaptionInfoEx";


/// Tests for the @c DLNAService class.
@interface DLNAServiceTests : XCTestCase

@property (nonatomic, strong) id serviceCommandDelegateMock;
@property (nonatomic, strong) DLNAService *service;
@property (nonatomic, strong) FailureBlock failFailureBlock;
@property (nonatomic, strong) void (^failSuccessBlock)();

@end

@implementation DLNAServiceTests

- (void)setUp {
    [super setUp];
    self.serviceCommandDelegateMock = OCMProtocolMock(@protocol(ServiceCommandDelegate));
    self.service = [DLNAService new];
    self.service.serviceCommandDelegate = self.serviceCommandDelegateMock;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    self.failFailureBlock = ^(NSError *error) {
        XCTFail(@"fail? %@", error);
    };
    self.failSuccessBlock = ^() {
        XCTFail(@"success?");
    };
#pragma clang diagnostic pop
}

- (void)tearDown {
    self.service = nil;
    self.serviceCommandDelegateMock = nil;
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

#pragma mark - General Tests

- (void)testInstanceShouldHaveSubtitleSRTCapability {
    XCTAssertNotEqual([self.service.capabilities indexOfObject:kMediaPlayerSubtitleSRT],
                      NSNotFound);
}

#pragma mark - Request Generation Tests

static NSString *const kDefaultTitle = @"Hello, <World> &]]> \"others'\\ ура ξ中]]>…";
static NSString *const kDefaultDescription = @"<Description> &\"'";
static NSString *const kDefaultURL = @"http://example.com/media.ogg";
static NSString *const kDefaultAlbumArtURL = @"http://example.com/media.png";

/// Tests that @c -playMediaWithMediaInfo:shouldLoop:success:failure: creates a
/// proper and valid SetAVTransportURI XML request.
- (void)testPlayMediaShouldCreateProperSetAVTransportURIXML {
    [self checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:kDefaultTitle
                                                            description:kDefaultDescription
                                                                    url:kDefaultURL
                                                         andAlbumArtURL:kDefaultAlbumArtURL];
}

/// Tests that @c -playMediaWithMediaInfo:shouldLoop:success:failure: creates a
/// proper and valid SetAVTransportURI XML request without title.
- (void)testPlayMediaShouldCreateProperSetAVTransportURIXMLWithoutTitle {
    [self checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:nil
                                                            description:kDefaultDescription
                                                                    url:kDefaultURL
                                                         andAlbumArtURL:kDefaultAlbumArtURL];
}

/// Tests that @c -playMediaWithMediaInfo:shouldLoop:success:failure: creates a
/// proper and valid SetAVTransportURI XML request without description.
- (void)testPlayMediaShouldCreateProperSetAVTransportURIXMLWithoutDescription {
    [self checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:kDefaultTitle
                                                            description:nil
                                                                    url:kDefaultURL
                                                         andAlbumArtURL:kDefaultAlbumArtURL];
}

/// Tests that @c -playMediaWithMediaInfo:shouldLoop:success:failure: creates a
/// proper and valid SetAVTransportURI XML request without URL.
- (void)testPlayMediaShouldCreateProperSetAVTransportURIXMLWithoutURL {
    [self checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:kDefaultTitle
                                                            description:kDefaultDescription
                                                                    url:nil
                                                         andAlbumArtURL:kDefaultAlbumArtURL];
}

/// Tests that @c -playMediaWithMediaInfo:shouldLoop:success:failure: creates a
/// proper and valid SetAVTransportURI XML request without album art URL.
- (void)testPlayMediaShouldCreateProperSetAVTransportURIXMLWithoutAlbumArtURL {
    [self checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:kDefaultTitle
                                                            description:kDefaultDescription
                                                                    url:kDefaultURL
                                                         andAlbumArtURL:nil];
}

/// Tests that @c -displayImageWithMediaInfo:success:failure: creates a
/// proper and valid SetAVTransportURI XML request.
- (void)testDisplayImageShouldCreateProperSetAVTransportURIXML {
    [self checkDisplayImageShouldCreateProperSetAVTransportURIXMLWithTitle:kDefaultTitle
                                                                       url:kDefaultAlbumArtURL];
}

/// Tests that @c -displayImageWithMediaInfo:success:failure: creates a
/// proper and valid SetAVTransportURI XML request without title.
- (void)testDisplayImageShouldCreateProperSetAVTransportURIXMLWithoutTitle {
    [self checkDisplayImageShouldCreateProperSetAVTransportURIXMLWithTitle:nil
                                                                       url:kDefaultAlbumArtURL];
}

/// Tests that @c -displayImageWithMediaInfo:success:failure: creates a
/// proper and valid SetAVTransportURI XML request without URL.
- (void)testDisplayImageShouldCreateProperSetAVTransportURIXMLWithoutURL {
    [self checkDisplayImageShouldCreateProperSetAVTransportURIXMLWithTitle:kDefaultTitle
                                                                       url:nil];
}

/// Tests that @c -playWithSuccess:failure: creates a proper and valid Play XML
/// request.
- (void)testPlayShouldCreateProperPlayXML {
    [self setupSendCommandTestWithName:@"Play"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service playWithSuccess:^(id responseObject) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Speed.text"], @"1", @"Speed must equal 1");
                           }];
}

/// Tests that @c -pauseWithSuccess:failure: creates a proper and valid Pause
/// XML request.
- (void)testPauseShouldCreateProperPauseXML {
    [self setupSendCommandTestWithName:@"Pause"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service pauseWithSuccess:^(id responseObject) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -stopWithSuccess:failure: creates a proper and valid Stop XML
/// request.
- (void)testStopShouldCreateProperStopXML {
    [self setupSendCommandTestWithName:@"Stop"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service stopWithSuccess:^(id responseObject) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -seek:success:failure: creates a proper and valid Seek XML
/// request.
- (void)testSeekShouldCreateProperSeekXML {
    [self setupSendCommandTestWithName:@"Seek"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service seek:(1 * 60 * 60) + (45 * 60) + 33
                                          success:^(id responseObject) {
                                              XCTFail(@"success?");
                                          } failure:^(NSError *error) {
                                              XCTFail(@"fail? %@", error);
                                          }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Target.text"],
                                                     @"01:45:33", @"Seek position is incorrect");
                               XCTAssertEqualObjects([request valueForKeyPath:@"Unit.text"],
                                                     @"REL_TIME", @"Unit is incorrect");
                           }];
}

/// Tests that @c -getPlayStateWithSuccess:failure: creates a proper and valid
/// GetTransportInfo XML request.
- (void)testGetPlayStateShouldCreateProperGetTransportInfoXML {
    [self setupSendCommandTestWithName:@"GetTransportInfo"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service getPlayStateWithSuccess:^(MediaControlPlayState playState) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -getPositionWithSuccess:failure: creates a proper and valid
/// GetPositionInfo XML request.
- (void)testGetPositionInfoShouldCreateProperGetPositionInfoXML {
    [self setupSendCommandTestWithName:@"GetPositionInfo"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service getPositionWithSuccess:^(NSTimeInterval position) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -getVolumeWithSuccess:failure: creates a proper and valid
/// GetVolume XML request.
- (void)testGetVolumeShouldCreateProperGetVolumeXML {
    [self setupSendCommandTestWithName:@"GetVolume"
                             namespace:kRenderingControlNamespace
                           actionBlock:^{
                               [self.service getVolumeWithSuccess:^(float volume) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Channel.text"],
                                                     @"Master", @"Channel must be Master");
                           }];
}

/// Tests that @c -setVolume:success:failure: creates a proper and valid
/// SetVolume XML request.
- (void)testSetVolumeShouldCreateProperSetVolumeXML {
    [self setupSendCommandTestWithName:@"SetVolume"
                             namespace:kRenderingControlNamespace
                           actionBlock:^{
                               [self.service setVolume:0.99
                                               success:^(id responseObject) {
                                                   silence_retain_cycle_warning(^() {
                                                       XCTFail(@"success?");
                                                   });
                                               } failure:^(NSError *error) {
                                                   XCTFail(@"fail? %@", error);
                                               }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Channel.text"],
                                                     @"Master", @"Channel must be Master");
                               XCTAssertEqualObjects([request valueForKeyPath:@"DesiredVolume.text"],
                                                     @"99", @"Volume is incorrect");
                           }];
}

/// Tests that @c -getMuteWithSuccess:failure: creates a proper and valid
/// GetMute XML request.
- (void)testGetMuteShouldCreateProperGetMuteXML {
    [self setupSendCommandTestWithName:@"GetMute"
                             namespace:kRenderingControlNamespace
                           actionBlock:^{
                               [self.service getMuteWithSuccess:^(BOOL mute) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Channel.text"],
                                                     @"Master", @"Channel must be Master");
                           }];
}

/// Tests that @c -setMute:success:failure: creates a proper and valid
/// SetMute XML request.
- (void)testSetMuteShouldCreateProperSetMuteXML {
    [self setupSendCommandTestWithName:@"SetMute"
                             namespace:kRenderingControlNamespace
                           actionBlock:^{
                               [self.service setMute:YES
                                             success:^(id responseObject) {
                                                 silence_retain_cycle_warning(^() {
                                                     XCTFail(@"success?");
                                                 });
                                             } failure:^(NSError *error) {
                                                 XCTFail(@"fail? %@", error);
                                             }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Channel.text"],
                                                     @"Master", @"Channel must be Master");
                               XCTAssertEqualObjects([request valueForKeyPath:@"DesiredMute.text"],
                                                     @"1", @"DesiredMute is incorrect");
                           }];
}

/// Tests that @c -playNextWithSuccess:failure: creates a proper and valid Next
/// XML request.
- (void)testPlayNextShouldCreateProperNextXML {
    [self setupSendCommandTestWithName:@"Next"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service playNextWithSuccess:^(id responseObject) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -playPreviousWithSuccess:failure: creates a proper and valid
/// Previous XML request.
- (void)testPlayPreviousShouldCreateProperPreviousXML {
    [self setupSendCommandTestWithName:@"Previous"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service playPreviousWithSuccess:^(id responseObject) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -jumpToTrackWithIndex:success:failure: creates a proper and
/// valid Seek XML request.
- (void)testJumpToTrackShouldCreateProperSeekXML {
    [self setupSendCommandTestWithName:@"Seek"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service jumpToTrackWithIndex:0
                                                          success:^(id responseObject) {
                                                              XCTFail(@"success?");
                                                          } failure:^(NSError *error) {
                                                              XCTFail(@"fail? %@", error);
                                                          }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Target.text"],
                                                     @"1", @"Track number is incorrect");
                               XCTAssertEqualObjects([request valueForKeyPath:@"Unit.text"],
                                                     @"TRACK_NR", @"Unit is incorrect");
                           }];
}

#pragma mark - Subtitles Support Tests

- (void)testPlayVideoWithSubtitlesRequestShouldContainSMICaptionProtocolInfo {
    [self checkPlayVideoWithSubtitlesRequestShouldContainProtocolInfoWithAttributeValue:@"http-get:*:smi/caption"];
}

- (void)testPlayVideoWithSubtitlesRequestShouldContainMimeTypeProtocolInfo {
    [self checkPlayVideoWithSubtitlesRequestShouldContainProtocolInfoWithAttributeValue:@"http-get:*:text/srt:*"];
}

- (void)testPlayVideoWithSubtitlesRequestShouldContainSecCaptionInfo {
    [self checkPlayVideoWithSubtitlesRequestShouldContainSecTagWithName:kSecCaptionInfoTag];
}

- (void)testPlayVideoWithSubtitlesRequestShouldContainSecCaptionInfoEx {
    [self checkPlayVideoWithSubtitlesRequestShouldContainSecTagWithName:kSecCaptionInfoExTag];
}

- (void)testPlayVideoWithSubtitlesRequestShouldContainPVSubtitleAttributes {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithSubtitle]
           shouldContainPVSubtitleAttributes:YES];
}

- (void)testPlayVideoWithoutSubtitlesRequestShouldNotContainSMICaptionProtocolInfo {
    [self checkPlayVideoWithoutSubtitlesRequestShouldNotContainProtocolInfoWithAttributeValue:@"http-get:*:smi/caption"];
}

- (void)testPlayVideoWithoutSubtitlesRequestShouldNotContainMimeTypeProtocolInfo {
    [self checkPlayVideoWithoutSubtitlesRequestShouldNotContainProtocolInfoWithAttributeValue:@"http-get:*:text/srt:*"];
}

- (void)testPlayVideoWithoutSubtitlesRequestShouldNotContainNullMimeTypeProtocolInfo {
    [self checkPlayVideoWithoutSubtitlesRequestShouldNotContainProtocolInfoWithAttributeValue:@"http-get:*:(null):*"];
}

- (void)testPlayVideoWithoutSubtitlesRequestShouldNotContainSecCaptionInfo {
    [self checkPlayVideoWithoutSubtitlesRequestShouldNotContainSecTagWithName:kSecCaptionInfoTag];
}

- (void)testPlayVideoWithoutSubtitlesRequestShouldNotContainSecCaptionInfoEx {
    [self checkPlayVideoWithoutSubtitlesRequestShouldNotContainSecTagWithName:kSecCaptionInfoExTag];
}

- (void)testPlayVideoWithoutSubtitlesRequestShouldNotContainPVSubtitleAttributes {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithoutSubtitle]
           shouldContainPVSubtitleAttributes:NO];
}

- (void)testPlayVideoWithSubtitlesWithoutMimeTypeShouldSendDefaultMimeTypeProtocolInfo {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithSubtitleWithoutMimeType]
                               shouldContain:YES
              protocolInfoWithAttributeValue:@"http-get:*:text/srt:*"];
}

- (void)testPlayVideoWithSubtitlesWithoutMimeTypeShouldSendDefaultTypeInSecCaptionInfo {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithSubtitleWithoutMimeType]
shouldContainSecTagWithDefaultFileTypeAndName:kSecCaptionInfoTag];
}

- (void)testPlayVideoWithSubtitlesWithoutMimeTypeShouldSendDefaultTypeInSecCaptionInfoEx {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithSubtitleWithoutMimeType]
shouldContainSecTagWithDefaultFileTypeAndName:kSecCaptionInfoExTag];
}

- (void)testPlayVideoWithSubtitlesWithoutMimeTypeShouldSendDefaultTypeInPVSubtitleAttribute {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithSubtitleWithoutMimeType]
           shouldContainPVSubtitleAttributes:YES
                                withFileType:@"srt"];
}

// TODO wrong mime type tests would not be here if we used a specialized
// MIMEType class
- (void)testPlayVideoWithSubtitlesWithWrongMimeTypeShouldSendDefaultMimeTypeProtocolInfo {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithSubtitleWithWrongMimeType]
                               shouldContain:YES
              protocolInfoWithAttributeValue:@"http-get:*:text/srt:*"];
}

- (void)testPlayVideoWithSubtitlesWithWrongMimeTypeShouldSendDefaultTypeInSecCaptionInfo {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithSubtitleWithWrongMimeType]
shouldContainSecTagWithDefaultFileTypeAndName:kSecCaptionInfoTag];
}

- (void)testPlayVideoWithSubtitlesWithWrongMimeTypeShouldSendDefaultTypeInSecCaptionInfoEx {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithSubtitleWithWrongMimeType]
shouldContainSecTagWithDefaultFileTypeAndName:kSecCaptionInfoExTag];
}

- (void)testPlayVideoWithSubtitlesWithWrongMimeTypeShouldSendDefaultTypeInPVSubtitleAttribute {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithSubtitleWithWrongMimeType]
           shouldContainPVSubtitleAttributes:YES
                                withFileType:@"srt"];
}

#pragma mark - Response Parsing Tests

/// Tests that @c -getPositionWithSuccess:failure: parses the position time from
/// a sample Xbox response properly.
- (void)testGetPositionShouldParseTimeProperly_Xbox {
    [self checkGetPositionShouldParseTimeProperlyWithSamplePlatform:kPlatformXbox];
}

/// Tests that @c -getPositionWithSuccess:failure: parses the position time from
/// a sample Sonos response properly.
- (void)testGetPositionShouldParseTimeProperly_Sonos {
    [self checkGetPositionShouldParseTimeProperlyWithSamplePlatform:kPlatformSonos];
}

/// Tests that @c -getDurationWithSuccess:failure: parses the duration time from
/// a sample Xbox response properly.
- (void)testGetDurationShouldParseTimeProperly_Xbox {
    [self checkGetDurationShouldParseTimeProperlyWithSamplePlatform:kPlatformXbox];
}

/// Tests that @c -getDurationWithSuccess:failure: parses the duration time from
/// a sample Sonos response properly.
- (void)testGetDurationShouldParseTimeProperly_Sonos {
    [self checkGetDurationShouldParseTimeProperlyWithSamplePlatform:kPlatformSonos];
}

/// Tests that @c -getMediaMetaDataWithSuccess:failure: parses the metadata from
/// a sample Xbox response properly.
- (void)testGetMediaMetadataShouldParseTimeProperly_Xbox {
    NSDictionary *expectedMetadata = @{@"title": @"Sintel Character Design",
                                       @"subtitle": @"Blender Open Movie Project",
                                       @"iconURL": @"http://ec2-54-201-108-205.us-west-2.compute.amazonaws.com/samples/media/videoIcon.jpg"};
    [self checkGetMediaMetadataShouldParseTimeProperlyWithSamplePlatform:kPlatformXbox
                                                     andExpectedMetadata:expectedMetadata];
}

/// Tests that @c -getMediaMetaDataWithSuccess:failure: parses the metadata from
/// a sample Sonos response properly.
- (void)testGetMediaMetadataShouldParseTimeProperly_Sonos {
    NSDictionary *expectedMetadata = @{@"title": @"Sintel Trailer",
                                       @"subtitle": @"Durian Open Movie Team"};
    [self checkGetMediaMetadataShouldParseTimeProperlyWithSamplePlatform:kPlatformSonos
                                                     andExpectedMetadata:expectedMetadata];
}

/// Tests that @c -getPlayStateWithSuccess:failure: parses the play state from
/// a sample Xbox response properly.
- (void)testGetPlayStateShouldParsePlayStateProperly_Xbox {
    [self checkGetPlayStateShouldParsePlayStateProperlyWithSamplePlatform:kPlatformXbox];
}

/// Tests that @c -getPlayStateWithSuccess:failure: parses the play state from
/// a sample Sonos response properly.
- (void)testGetPlayStateShouldParsePlayStateProperly_Sonos {
    [self checkGetPlayStateShouldParsePlayStateProperlyWithSamplePlatform:kPlatformSonos];
}

/// Tests that @c -getVolumeWithSuccess:failure: parses the volume from a sample
/// Xbox response properly.
- (void)testGetVolumeShouldParseVolumeProperly_Xbox {
    [self checkGetVolumeShouldParseVolumeProperlyWithSamplePlatform:kPlatformXbox];
}

/// Tests that @c -getVolumeWithSuccess:failure: parses the volume from a sample
/// Sonos response properly.
- (void)testGetVolumeShouldParseVolumeProperly_Sonos {
    [self checkGetVolumeShouldParseVolumeProperlyWithSamplePlatform:kPlatformSonos];
}

/// Tests that @c -getMuteWithSuccess:failure: parses the mute from a sample
/// Xbox response properly.
- (void)testGetMuteShouldParseMuteProperly_Xbox {
    [self checkGetMuteShouldParseMuteProperlyWithSamplePlatform:kPlatformXbox];
}

/// Tests that @c -getMuteWithSuccess:failure: parses the mute from a sample
/// Sonos response properly.
- (void)testGetMuteShouldParseMuteProperly_Sonos {
    [self checkGetMuteShouldParseMuteProperlyWithSamplePlatform:kPlatformSonos];
}

/// Tests that @c DLNAService parses a UPnP error from a sample Xbox response
/// properly.
- (void)testUPnPErrorShouldBeParsedProperly_Xbox {
    [self checkUPnPErrorShouldBeParsedProperlyWithSamplePlatform:kPlatformXbox
                                             andErrorDescription:@"Invalid Action"];
}

/// Tests that @c DLNAService parses a UPnP error from a sample Sonos response
/// properly.
- (void)testUPnPErrorShouldBeParsedProperly_Sonos {
    [self checkUPnPErrorShouldBeParsedProperlyWithSamplePlatform:kPlatformSonos
                                             andErrorDescription:nil];
}

#pragma mark - Service URL Construction Tests

- (void)testUpdateControlURLsWithoutSlash {
    NSDictionary *urls = @{
        kAVTransportControlURLKey: @"http://127.0.0.0:0/control/AVTransport",
        kAVTransportEventURLKey: @"http://127.0.0.0:0/event/AVTransport",
        kRenderingControlControlURLKey: @"http://127.0.0.0:0/control/RenderingControl",
        kRenderingControlEventURLKey: @"http://127.0.0.0:0/event/RenderingControl"
    };
    [self checkUpdateControlURLForDevice:@"lg_speaker" withURLs:urls];
}

- (void)testUpdateControlURLsWithSlash {
    NSDictionary *urls = @{
        kAVTransportControlURLKey: @"http://127.0.0.0:0/MediaRenderer/AVTransport/Control",
        kAVTransportEventURLKey: @"http://127.0.0.0:0/MediaRenderer/AVTransport/Event",
        kRenderingControlControlURLKey: @"http://127.0.0.0:0/MediaRenderer/RenderingControl/Control",
        kRenderingControlEventURLKey: @"http://127.0.0.0:0/MediaRenderer/RenderingControl/Event"
    };
    [self checkUpdateControlURLForDevice:@"sonos" withURLs:urls];
}

-(void)testServiceSubscriptionURLsWithoutSlash {
    [self checkServiceSubscriptionURLForDevice:@"lg_speaker"];
}

-(void)testServiceSubscriptionURLsWithSlash {
    [self checkServiceSubscriptionURLForDevice:@"sonos"];
}

/// Tests that @c -parseMetadataDictionaryFromXMLString: returns the passed
/// album art URL if it's absolute and includes a host.
- (void)testAbsoluteAlbumArtURLShouldBeParsedAsIs {
    NSString *xml = @"<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\"><item id=\"0\" parentID=\"0\" restricted=\"0\"><upnp:albumArtURI>http://example.com/image.jpg</upnp:albumArtURI></item></DIDL-Lite>";
    NSDictionary *metadata = [self.service parseMetadataDictionaryFromXMLString:xml];
    XCTAssertEqualObjects(metadata[@"iconURL"], @"http://example.com/image.jpg",
                          @"The album art URL is incorrect");
}

/// Tests that @c -parseMetadataDictionaryFromXMLString: prepends the service's
/// @c commandURL to an absolute album art URL if it doesn't include a host.
- (void)testAbsoluteAlbumArtURLWithoutHostShouldBeRelativeToServicesCommandURL {
    id serviceDescriptionMock = OCMClassMock([ServiceDescription class]);
    [OCMStub([serviceDescriptionMock commandURL]) andReturn:[NSURL URLWithString:@"http://10.0.0.1:9099/yes"]];
    self.service.serviceDescription = serviceDescriptionMock;

    NSString *xml = @"<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\"><item id=\"0\" parentID=\"0\" restricted=\"0\"><upnp:albumArtURI>/aa?u=http%3A%2F%2Fexample.com%2Fimage.jpg&amp;v=0</upnp:albumArtURI></item></DIDL-Lite>";
    NSDictionary *metadata = [self.service parseMetadataDictionaryFromXMLString:xml];
    XCTAssertEqualObjects(metadata[@"iconURL"],
                          @"http://10.0.0.1:9099/aa?u=http%3A%2F%2Fexample.com%2Fimage.jpg&v=0",
                          @"The album art URL is incorrect");
}

/// Tests that @c -parseMetadataDictionaryFromXMLString: prepends the service's
/// @c commandURL to a relative album art URL.
- (void)testRelativeAlbumArtURLWithoutHostShouldBeRelativeToServicesCommandURL {
    id serviceDescriptionMock = OCMClassMock([ServiceDescription class]);
    [OCMStub([serviceDescriptionMock commandURL]) andReturn:[NSURL URLWithString:@"http://10.0.0.1:9099/yes"]];
    self.service.serviceDescription = serviceDescriptionMock;

    NSString *xml = @"<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\"><item id=\"0\" parentID=\"0\" restricted=\"0\"><upnp:albumArtURI>aa?u=http%3A%2F%2Fexample.com%2Fimage.jpg&amp;v=0</upnp:albumArtURI></item></DIDL-Lite>";
    NSDictionary *metadata = [self.service parseMetadataDictionaryFromXMLString:xml];
    XCTAssertEqualObjects(metadata[@"iconURL"],
                          @"http://10.0.0.1:9099/aa?u=http%3A%2F%2Fexample.com%2Fimage.jpg&v=0",
                          @"The album art URL is incorrect");
}

#pragma mark - Subscription Tests

- (void)testSubscribeVolumeShouldIgnoreMuteEvent {
    // getVolume
    OCMStub([self.serviceCommandDelegateMock sendCommand:OCMOCK_ANY
                                             withPayload:OCMOCK_ANY
                                                   toURL:OCMOCK_ANY]);

    [[OCMExpect([self.serviceCommandDelegateMock sendSubscription:OCMOCK_ANY
                                                             type:ServiceSubscriptionTypeSubscribe
                                                          payload:OCMOCK_ANY
                                                            toURL:OCMOCK_ANY
                                                           withId:0]) ignoringNonObjectArgs] andDo:^(NSInvocation *invocation) {
        ServiceSubscription *subscription = [invocation objectArgumentAtIndex:0];
        SuccessBlock block = subscription.successCalls[0];
        block(@{@"Event": @{@"InstanceID": @{@"Mute": @{@"channel": @"Master", @"val": @0}}}});
    }];

    [self.service subscribeVolumeWithSuccess:nil
                                     failure:^(NSError *error) {
                                         XCTFail(@"%@", error);
                                     }];
    OCMVerifyAll(self.serviceCommandDelegateMock);
}

- (void)testSubscribeMuteShouldIgnoreVolumeEvent {
    // getMute
    OCMStub([self.serviceCommandDelegateMock sendCommand:OCMOCK_ANY
                                             withPayload:OCMOCK_ANY
                                                   toURL:OCMOCK_ANY]);

    [[OCMExpect([self.serviceCommandDelegateMock sendSubscription:OCMOCK_ANY
                                                             type:ServiceSubscriptionTypeSubscribe
                                                          payload:OCMOCK_ANY
                                                            toURL:OCMOCK_ANY
                                                           withId:0]) ignoringNonObjectArgs] andDo:^(NSInvocation *invocation) {
        ServiceSubscription *subscription = [invocation objectArgumentAtIndex:0];
        SuccessBlock block = subscription.successCalls[0];
        block(@{@"Event": @{@"InstanceID": @{@"Volume": @{@"channel": @"Master", @"val": @0}}}});
    }];

    [self.service subscribeMuteWithSuccess:nil
                                   failure:^(NSError *error) {
                                       XCTFail(@"%@", error);
                                   }];
    OCMVerifyAll(self.serviceCommandDelegateMock);
}

#pragma mark - Disconnect Tests

/// Tests that @c -disconnect shuts down the http server.
- (void)testDisconnectShouldStopHTTPServer {
    // Arrange
    id httpServerMock = OCMClassMock([DLNAHTTPServer class]);
    XCTestExpectation *serverIsStoppedExpectation = [self expectationWithDescription:@"httpServer should be stopped"];
    [OCMExpect([httpServerMock stop]) andFulfillExpectation:serverIsStoppedExpectation];

    // have to install a partial mock to be able to inject the httpServerMock
    DLNAService *service = OCMPartialMock([DLNAService new]);
    [OCMStub([service createDLNAHTTPServer]) andReturn:httpServerMock];

    id serviceDescriptionMock = OCMClassMock([ServiceDescription class]);
    [OCMStub([serviceDescriptionMock locationXML]) andReturn:@"http://127.1/"];

    // Act
    service.serviceDescription = serviceDescriptionMock;
    [service disconnect];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(httpServerMock);
                                 }];
}

/// Tests that @c -disconnect unsubscribes from all subscriptions.
- (void)testDisconnectShouldUnsubscribeAllSubscriptions {
    // Arrange
    id httpServerMock = OCMClassMock([DLNAHTTPServer class]);
    id reachabilityMock = OCMClassMock([DeviceServiceReachability class]);

    // have to install a partial mock to be able to inject the httpServerMock
    // and reachabilityMock
    DLNAService *service = OCMPartialMock([DLNAService new]);
    [OCMStub([service createDLNAHTTPServer]) andReturn:httpServerMock];
    [OCMStub([service createDeviceServiceReachabilityWithTargetURL:OCMOCK_ANY]) andReturn:reachabilityMock];

    id serviceDescriptionMock = OCMClassMock([ServiceDescription class]);
    [OCMStub([serviceDescriptionMock locationXML]) andReturn:@"http://127.0.0.1/"];
    NSDictionary *serviceDict = @{@"serviceId": @{@"text": @"id"},
                                  @"eventSubURL": @{@"text": @"/sub"}};
    NSArray *serviceList = @[serviceDict];
    [OCMStub([serviceDescriptionMock serviceList]) andReturn:serviceList];
    NSURL *commandURL = [NSURL URLWithString:@"http://127.0.0.1:8080/"];
    [OCMStub([serviceDescriptionMock commandURL]) andReturn:commandURL];

    static NSString *const kHOST = @"127.0.0.1";
    XCTestExpectation *subscribeRequestSent = [self expectationWithDescription:@"service is subscribed"];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        XCTAssertEqualObjects(request.URL.host, kHOST);
        return ([request.URL.host isEqualToString:kHOST] &&
                [request.HTTPMethod isEqualToString:@"SUBSCRIBE"]);
    }
                        withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                            // NB: the expectation should be fulfilled after the
                            // response is handled in DLNAService, for it to
                            // save the SID!
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kDefaultAsyncTestTimeout / 2 * NSEC_PER_SEC)),
                                           dispatch_get_main_queue(), ^{
                                               [subscribeRequestSent fulfill];
                                           });
                            return [OHHTTPStubsResponse responseWithData:nil
                                                              statusCode:200
                                                                 headers:@{@"SID": @"42"}];
                        }];

    service.serviceDescription = serviceDescriptionMock;
    [service connect];

    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                 }];

    XCTestExpectation *unsubscribeRequestSent = [self expectationWithDescription:@"service is unsubscribed"];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        XCTAssertEqualObjects(request.URL.host, kHOST);
        return ([request.URL.host isEqualToString:kHOST] &&
                [request.HTTPMethod isEqualToString:@"UNSUBSCRIBE"] &&
                [request.allHTTPHeaderFields[@"SID"] isEqualToString:@"42"]);
    }
                        withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                            [unsubscribeRequestSent fulfill];
                            return [OHHTTPStubsResponse responseWithData:nil
                                                              statusCode:200
                                                                 headers:nil];
                        }];

    // Act
    [service disconnect];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                 }];
}

#pragma mark - Helpers

- (void)checkGetPositionShouldParseTimeProperlyWithSamplePlatform:(NSString *)platform {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"getpositioninfo_response_%@", platform]];
    }));

    XCTestExpectation *getPositionSuccessExpectation = [self expectationWithDescription:@"The position time is parsed properly"];

    // Act
    [self.service getPositionWithSuccess:^(NSTimeInterval position) {
        XCTAssertEqualWithAccuracy(position, 66.0, 0.001,
                                   @"The position time is incorrect");
        [getPositionSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkGetDurationShouldParseTimeProperlyWithSamplePlatform:(NSString *)platform {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"getpositioninfo_response_%@", platform]];
    }));

    XCTestExpectation *getDurationSuccessExpectation = [self expectationWithDescription:@"The duration is parsed properly"];

    // Act
    [self.service getDurationWithSuccess:^(NSTimeInterval position) {
        XCTAssertEqualWithAccuracy(position, (8.0*60 + 52), 0.001,
                                   @"The duration is incorrect");
        [getDurationSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkGetMediaMetadataShouldParseTimeProperlyWithSamplePlatform:(NSString *)platform
                                                   andExpectedMetadata:(NSDictionary *)expectedMetadata {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"getpositioninfo_response_%@", platform]];
    }));

    XCTestExpectation *getMetadataSuccessExpectation = [self expectationWithDescription:@"The metadata is parsed properly"];

    // Act
    [self.service getMediaMetaDataWithSuccess:^(NSDictionary *metadata) {
        XCTAssertEqualObjects(metadata, expectedMetadata, @"The metadata is incorrect");
        [getMetadataSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkGetPlayStateShouldParsePlayStateProperlyWithSamplePlatform:(NSString *)platform {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"gettransportinfo_response_%@", platform]];
    }));

    XCTestExpectation *getPlayStateSuccessExpectation = [self expectationWithDescription:@"The play state is parsed properly"];

    // Act
    [self.service getPlayStateWithSuccess:^(MediaControlPlayState playState) {
        XCTAssertEqual(playState, MediaControlPlayStatePlaying,
                       @"The play state is incorrect");
        [getPlayStateSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkGetVolumeShouldParseVolumeProperlyWithSamplePlatform:(NSString *)platform {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"getvolume_response_%@", platform]];
    }));

    XCTestExpectation *getVolumeSuccessExpectation = [self expectationWithDescription:@"The volume is parsed properly"];

    // Act
    [self.service getVolumeWithSuccess:^(float volume) {
        XCTAssertEqualWithAccuracy(volume, 0.14f, 0.0001, @"The volume is incorrect");
        [getVolumeSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkGetMuteShouldParseMuteProperlyWithSamplePlatform:(NSString *)platform {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"getmute_response_%@", platform]];
    }));

    XCTestExpectation *getMuteSuccessExpectation = [self expectationWithDescription:@"The mute is parsed properly"];

    // Act
    [self.service getMuteWithSuccess:^(BOOL mute) {
        XCTAssertTrue(mute, @"The mute value is incorrect");
        [getMuteSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkUPnPErrorShouldBeParsedProperlyWithSamplePlatform:(NSString *)platform
                                           andErrorDescription:(NSString *)errorDescription {
    // Arrange
    self.service.serviceCommandDelegate = nil;
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    }
                        withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                            NSString *filename = [NSString stringWithFormat:@"upnperror_response_%@.xml", platform];
                            return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(filename, nil)
                                                                    statusCode:500
                                                                       headers:nil];
                        }];

    XCTestExpectation *failExpectation = [self expectationWithDescription:@"The failure: block should be called"];

    // Act
    [self.service getMuteWithSuccess:^(BOOL mute) {
        XCTFail(@"Should not succeed here");
    }
                             failure:^(NSError *error) {
                                 XCTAssertEqualObjects(error.domain, ConnectErrorDomain, @"The error domain is incorrect");
                                 XCTAssertEqual(error.code, ConnectStatusCodeTvError, @"The error code is incorrect");
                                 if (errorDescription) {
                                     XCTAssertNotEqual(NSNotFound,
                                                       [error.localizedDescription rangeOfString:errorDescription].location,
                                                       @"The error description is incorrect");
                                 } else {
                                     XCTAssertGreaterThan(error.localizedDescription.length,
                                                          0, @"The error description must not be empty");
                                 }
                                 [failExpectation fulfill];
                             }];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                 }];
}

- (void)callCommandCallbackFromInvocation:(NSInvocation *)invocation
                      andResponseFilename:(NSString *)filename {
    __unsafe_unretained ServiceCommand *tmp;
    [invocation getArgument:&tmp atIndex:2];
    ServiceCommand *command = tmp;
    XCTAssertNotNil(command, @"Couldn't get the command argument");

    NSData *xmlData = [NSData dataWithContentsOfFile:
                       OHPathForFileInBundle([filename stringByAppendingPathExtension:@"xml"], nil)];
    XCTAssertNotNil(xmlData, @"Response data is unavailable");

    NSError *error;
    NSDictionary *dict = [CTXMLReader dictionaryForXMLData:xmlData
                                                     error:&error];
    XCTAssertNil(error, @"XML parsing error: %@", error);

    dispatch_async(dispatch_get_main_queue(), ^{
        command.callbackComplete(dict);
    });
}

- (void)setupSendCommandTestWithName:(NSString *)commandName
                           namespace:(NSString *)namespace
                         actionBlock:(void (^)())actionBlock
                andVerificationBlock:(void (^)(NSDictionary *request))checkBlock {
    // Arrange
    XCTestExpectation *commandIsSent = [self expectationWithDescription:
                                        [NSString stringWithFormat:@"%@ command is sent", commandName]];

    [OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                                withPayload:OCMOCK_NOTNIL
                                                      toURL:OCMOCK_ANY]) andDo:^(NSInvocation *inv) {
        NSDictionary *payload = [inv objectArgumentAtIndex:1];
        NSString *xmlString = payload[kDataFieldName];
        XCTAssertNotNil(xmlString, @"XML request not found");

        NSError *error = nil;
        NSDictionary *dict = [CTXMLReader dictionaryForXMLString:xmlString
                                                           error:&error];
        XCTAssertNil(error, @"XML parsing error");
        XCTAssertNotNil(dict, @"Couldn't parse XML");

        NSDictionary *envelope = [dict objectForKeyEndingWithString:@":Envelope"];
        XCTAssertNotNil(envelope, @"Envelope tag must be present");
        XCTAssertEqualObjects(envelope[@"xmlns:u"], namespace, @"Namespace is incorrect");
        XCTAssertEqualObjects(envelope[@"s:encodingStyle"], @"http://schemas.xmlsoap.org/soap/encoding/");
        NSDictionary *body = [envelope objectForKeyEndingWithString:@":Body"];
        XCTAssertNotNil(body, @"Body tag must be present");
        NSDictionary *request = [body objectForKeyEndingWithString:[@":" stringByAppendingString:commandName]];
        XCTAssertNotNil(request, @"%@ tag must be present", commandName);

        XCTAssertNotNil(request[@"InstanceID"], @"InstanceID must be present");

        // any extra verification required?
        if (checkBlock) {
            checkBlock(request);
        }

        [commandIsSent fulfill];
    }];

    // Act
    actionBlock();

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:(NSString *)sampleTitle
                                                          description:(NSString *)sampleDescription
                                                                  url:(NSString *)sampleURL
                                                       andAlbumArtURL:(NSString *)sampleAlbumArtURL {
    NSString *sampleMimeType = @"audio/ogg";

    [self setupSendCommandTestWithName:@"SetAVTransportURI"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:[NSURL URLWithString:sampleURL]
                                                                            mimeType:sampleMimeType];
                               mediaInfo.title = sampleTitle;
                               mediaInfo.description = sampleDescription;
                               mediaInfo.images = @[[[ImageInfo alloc] initWithURL:[NSURL URLWithString:sampleAlbumArtURL]
                                                                              type:ImageTypeAlbumArt]];

                               [self.service playMediaWithMediaInfo:mediaInfo
                                                         shouldLoop:NO
                                                            success:^(MediaLaunchObject *mediaLanchObject) {
                                                                XCTFail(@"success?");
                                                            } failure:^(NSError *error) {
                                                                XCTFail(@"fail? %@", error);
                                                            }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"CurrentURI.text"], sampleURL, @"CurrentURI must match");

                               NSString *metadataString = [request valueForKeyPath:@"CurrentURIMetaData.text"];
                               XCTAssertNotNil(metadataString, @"CurrentURIMetaData must be present");

                               NSError *error = nil;
                               NSDictionary *metadata = [CTXMLReader dictionaryForXMLString:metadataString
                                                                                      error:&error];
                               XCTAssertNil(error, @"Metadata XML parsing error");
                               XCTAssertNotNil(metadata, @"Couldn't parse metadata XML");

                               NSDictionary *didl = metadata[@"DIDL-Lite"];
                               XCTAssertNotNil(didl, @"DIDL-Lite tag must be present");
                               NSDictionary *item = didl[@"item"];
                               XCTAssertNotNil(item, @"item tag must be present");

                               NSString *title = [item objectForKeyEndingWithString:@":title"][@"text"];
                               XCTAssertEqualObjects(title, sampleTitle, @"Title must match");

                               NSString *description = [item objectForKeyEndingWithString:@":description"][@"text"];
                               XCTAssertEqualObjects(description, sampleDescription, @"Description must match");

                               NSDictionary *res = item[@"res"];
                               XCTAssertEqualObjects(res[@"text"], sampleURL, @"res URL must match");
                               XCTAssertNotEqual([res[@"protocolInfo"] rangeOfString:sampleMimeType].location, NSNotFound, @"mimeType must be in protocolInfo");

                               NSString *albumArtURI = [item objectForKeyEndingWithString:@":albumArtURI"][@"text"];
                               XCTAssertEqualObjects(albumArtURI, sampleAlbumArtURL, @"albumArtURI must match");

                               NSString *itemClass = [item objectForKeyEndingWithString:@":class"][@"text"];
                               XCTAssertEqualObjects(itemClass, @"object.item.audioItem", @"class must be audioItem");
                           }];
}

- (void)checkDisplayImageShouldCreateProperSetAVTransportURIXMLWithTitle:(NSString *)sampleTitle
                                                                     url:(NSString *)sampleURL {
    NSString *sampleMimeType = @"image/png";

    [self setupSendCommandTestWithName:@"SetAVTransportURI"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:[NSURL URLWithString:sampleURL]
                                                                            mimeType:sampleMimeType];
                               mediaInfo.title = sampleTitle;

                               [self.service displayImageWithMediaInfo:mediaInfo
                                                               success:^(MediaLaunchObject *mediaLanchObject) {
                                                                   XCTFail(@"success?");
                                                               } failure:^(NSError *error) {
                                                                   XCTFail(@"fail? %@", error);
                                                               }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"CurrentURI.text"], sampleURL, @"CurrentURI must match");

                               NSString *metadataString = [request valueForKeyPath:@"CurrentURIMetaData.text"];
                               XCTAssertNotNil(metadataString, @"CurrentURIMetaData must be present");

                               NSError *error = nil;
                               NSDictionary *metadata = [CTXMLReader dictionaryForXMLString:metadataString
                                                                                      error:&error];
                               XCTAssertNil(error, @"Metadata XML parsing error");
                               XCTAssertNotNil(metadata, @"Couldn't parse metadata XML");

                               NSDictionary *didl = metadata[@"DIDL-Lite"];
                               XCTAssertNotNil(didl, @"DIDL-Lite tag must be present");
                               NSDictionary *item = didl[@"item"];
                               XCTAssertNotNil(item, @"item tag must be present");

                               NSString *title = [item objectForKeyEndingWithString:@":title"][@"text"];
                               XCTAssertEqualObjects(title, sampleTitle, @"Title must match");

                               NSDictionary *res = item[@"res"];
                               XCTAssertEqualObjects(res[@"text"], sampleURL, @"res URL must match");
                               XCTAssertNotEqual([res[@"protocolInfo"] rangeOfString:sampleMimeType].location, NSNotFound, @"mimeType must be in protocolInfo");

                               NSString *itemClass = [item objectForKeyEndingWithString:@":class"][@"text"];
                               XCTAssertEqualObjects(itemClass, @"object.item.imageItem", @"class must be imageItem");
                           }];
}

- (void)checkUpdateControlURLForDevice:(NSString *)device
                              withURLs:(NSDictionary *)urls{
    ServiceDescription *serviceDescription = [self serviceDescriptionForDevice:device];
    [self.service setServiceDescription:serviceDescription];

    XCTAssertEqualObjects(urls[kAVTransportControlURLKey], self.service.avTransportControlURL.absoluteString);
    XCTAssertEqualObjects(urls[kAVTransportEventURLKey], self.service.avTransportEventURL.absoluteString);
    XCTAssertEqualObjects(urls[kRenderingControlControlURLKey], self.service.renderingControlControlURL
                          .absoluteString);
    XCTAssertEqualObjects(urls[kRenderingControlEventURLKey], self.service.renderingControlEventURL.absoluteString);
}

- (void)checkServiceSubscriptionURLForDevice:(NSString *)device{
    ServiceDescription *serviceDescription = [self serviceDescriptionForDevice:device];
    [self.service setServiceDescription:serviceDescription];

    [serviceDescription.serviceList enumerateObjectsUsingBlock:^(id service, NSUInteger idx, BOOL *stop) {
        NSString *eventPath = service[@"eventSubURL"][@"text"];
        NSURL *eventSubURL = [self.service serviceURLForPath:eventPath];
        [self assertURLIsValid:eventSubURL];
    }];
}

- (ServiceDescription *)serviceDescriptionForDevice:(NSString *)device {
    NSString *filename = [NSString stringWithFormat:@"ssdp_device_description_%@", device];
    NSData *xmlData = [NSData dataWithContentsOfFile:
                       OHPathForFileInBundle([filename stringByAppendingPathExtension:@"xml"], nil)];
    ServiceDescription *serviceDescription = [ServiceDescription new];
    serviceDescription.locationXML = @"<?xml version=\"1.0\" encoding=\"utf-8\" ?>";
    serviceDescription.commandURL = [NSURL URLWithString:@"http://127.0.0.0:0"];
    NSError *error;
    NSDictionary *dict = [CTXMLReader dictionaryForXMLData:xmlData error:&error];
    SSDPDiscoveryProvider *ssdp = [SSDPDiscoveryProvider new];
    serviceDescription.serviceList = [ssdp serviceListForDevice:[dict valueForKeyPath:@"root.device"]];

    return serviceDescription;
}

- (void)assertURLIsValid:(NSURL *)url {
    XCTAssertNotNil(url);
    XCTAssertNotNil(url.scheme);
    XCTAssertNotNil(url.host);
    XCTAssertNotNil(url.port);
    XCTAssertNotNil(url.path);
}

#pragma mark - Subtitle Helpers

- (void)checkPlayVideoWithSubtitles:(MediaInfo *)mediaInfo
          DIDLRequestShouldPassTest:(void (^)(NSDictionary *didl))testBlock {
    [self setupSendCommandTestWithName:@"SetAVTransportURI"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service playMediaWithMediaInfo:mediaInfo
                                                         shouldLoop:NO
                                                            success:self.failSuccessBlock
                                                            failure:self.failFailureBlock];
                           }
                  andVerificationBlock:^(NSDictionary *request) {
                      NSString *metadataString = [request valueForKeyPath:@"CurrentURIMetaData.text"];
                      NSDictionary *metadata = [CTXMLReader dictionaryForXMLString:metadataString
                                                                             error:nil];
                      testBlock(metadata[@"DIDL-Lite"]);
                  }];
}

- (void)checkPlayVideoWithSubtitlesRequestShouldContainProtocolInfoWithAttributeValue:(NSString *)attributeValue {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithSubtitle]
                               shouldContain:YES
              protocolInfoWithAttributeValue:attributeValue];
}

- (void)checkPlayVideoWithoutSubtitlesRequestShouldNotContainProtocolInfoWithAttributeValue:(NSString *)attributeValue {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithoutSubtitle]
                               shouldContain:NO
              protocolInfoWithAttributeValue:attributeValue];
}

- (void)checkPlayVideoRequestWithMediaInfo:(MediaInfo *)mediaInfo
                             shouldContain:(BOOL)shouldContain
            protocolInfoWithAttributeValue:(NSString *)attributeValue {
    [self checkPlayVideoWithSubtitles:mediaInfo
            DIDLRequestShouldPassTest:^(NSDictionary *didl) {
                // TODO switch from the current XMLReader?
                // we have to parse tags as either a dictionary or an array,
                // depending on the number of tags with the same name in XML

                if (shouldContain) {
                    // in this case we're expecting to have 2+ res tags
                    NSArray *resources = [didl valueForKeyPath:@"item.res"];
                    NSPredicate *attributePredicate = [NSPredicate predicateWithFormat:@"protocolInfo == %@",
                                                                                       attributeValue];
                    NSArray *filteredResources = [resources filteredArrayUsingPredicate:attributePredicate];

                    XCTAssertEqual(filteredResources.count, 1);
                    XCTAssertEqualObjects(filteredResources[0][@"text"],
                                          mediaInfo.subtitleInfo.url.absoluteString);
                } else {
                    // in this case we're expecting 1 res tag for media file only
                    NSDictionary *resource = [didl valueForKeyPath:@"item.res"];
                    XCTAssertNotEqualObjects(resource[@"protocolInfo"],
                                             attributeValue);
                }
            }];
}

- (void)checkPlayVideoWithSubtitlesRequestShouldContainSecTagWithName:(NSString *)tagName {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithSubtitle]
                               shouldContain:YES
                              secTagWithName:tagName];
}

- (void)checkPlayVideoWithoutSubtitlesRequestShouldNotContainSecTagWithName:(NSString *)tagName {
    [self checkPlayVideoRequestWithMediaInfo:[self mediaInfoWithoutSubtitle]
                               shouldContain:NO
                              secTagWithName:tagName];
}

- (void)checkPlayVideoRequestWithMediaInfo:(MediaInfo *)mediaInfo
                             shouldContain:(BOOL)shouldContain
                            secTagWithName:(NSString *)tagName {
    [self checkPlayVideoRequestWithMediaInfo:mediaInfo
                               shouldContain:shouldContain
                              secTagWithName:tagName
                                 andFileType:@"srt"];
}

- (void)checkPlayVideoRequestWithMediaInfo:(MediaInfo *)mediaInfo
                             shouldContain:(BOOL)shouldContain
                            secTagWithName:(NSString *)tagName
                               andFileType:(NSString *)fileType {
    [self checkPlayVideoWithSubtitles:mediaInfo
            DIDLRequestShouldPassTest:^(NSDictionary *didl) {
                NSDictionary *captionInfo = didl[@"item"][tagName];

                if (shouldContain) {
                    XCTAssertEqualObjects(didl[@"xmlns:sec"],
                                          @"http://www.sec.co.kr/");

                    XCTAssertEqualObjects(captionInfo[@"text"],
                                          mediaInfo.subtitleInfo.url.absoluteString);
                    XCTAssertEqualObjects(captionInfo[@"sec:type"], fileType);
                } else {
                    // NOTE: we don't check the "xmlns:sec" presence/absence,
                    // because it's not very important here
                    XCTAssertNil(captionInfo);
                }
            }];
}

- (void)checkPlayVideoRequestWithMediaInfo:(MediaInfo *)mediaInfo
         shouldContainPVSubtitleAttributes:(BOOL)shouldContain {
    [self checkPlayVideoRequestWithMediaInfo:mediaInfo
           shouldContainPVSubtitleAttributes:shouldContain
                                withFileType:@"srt"];
}

- (void)checkPlayVideoRequestWithMediaInfo:(MediaInfo *)mediaInfo
         shouldContainPVSubtitleAttributes:(BOOL)shouldContain
                              withFileType:(NSString *)fileType {
    [self checkPlayVideoWithSubtitles:mediaInfo
            DIDLRequestShouldPassTest:^(NSDictionary *didl) {
                id resources = [didl valueForKeyPath:@"item.res"];
                if (shouldContain) {
                    NSPredicate *mimeTypePredicate = [NSPredicate predicateWithFormat:@"protocolInfo CONTAINS %@",
                                                                                      mediaInfo.mimeType];
                    NSArray *mediaResource = [resources filteredArrayUsingPredicate:mimeTypePredicate];
                    XCTAssertEqual(mediaResource.count, 1);

                    NSDictionary *res = [mediaResource firstObject];
                    XCTAssertEqualObjects(res[@"xmlns:pv"], @"http://www.pv.com/pvns/");
                    XCTAssertEqualObjects(res[@"pv:subtitleFileUri"],
                                          mediaInfo.subtitleInfo.url.absoluteString);
                    XCTAssertEqualObjects(res[@"pv:subtitleFileType"], fileType);
                } else {
                    NSDictionary *res = resources;
                    XCTAssertNil(res[@"pv:subtitleFileUri"]);
                    XCTAssertNil(res[@"pv:subtitleFileType"]);
                }
            }];
}

- (void)checkPlayVideoRequestWithMediaInfo:(MediaInfo *)mediaInfo
shouldContainSecTagWithDefaultFileTypeAndName:(NSString *)name {
    [self checkPlayVideoRequestWithMediaInfo:mediaInfo
                               shouldContain:YES
                              secTagWithName:name
                                 andFileType:@"srt"];
}

- (MediaInfo *)mediaInfoWithSubtitle {
    NSURL *subtitleURL = [NSURL URLWithString:@"http://example.com/"];
    MediaInfo *mediaInfo = [self mediaInfoWithoutSubtitle];
    SubtitleInfo *info = [SubtitleInfo infoWithURL:subtitleURL
                                          andBlock:^(SubtitleInfoBuilder *builder) {
                                              builder.mimeType = @"text/srt";
                                          }];
    mediaInfo.subtitleInfo = info;

    return mediaInfo;
}

- (MediaInfo *)mediaInfoWithoutSubtitle {
    NSString *sampleURL = kDefaultURL;
    NSString *sampleMimeType = @"audio/ogg";
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:[NSURL URLWithString:sampleURL]
                                                 mimeType:sampleMimeType];

    return mediaInfo;
}

- (MediaInfo *)mediaInfoWithSubtitleWithWrongMimeType {
    MediaInfo *mediaInfo = [self mediaInfoWithoutSubtitle];
    mediaInfo.subtitleInfo = [SubtitleInfo infoWithURL:[NSURL URLWithString:@"http://example.com/"]
                                              andBlock:^(SubtitleInfoBuilder *builder) {
                                                  builder.mimeType = @"wrong!";
                                              }];
    return mediaInfo;
}

- (MediaInfo *)mediaInfoWithSubtitleWithoutMimeType {
    MediaInfo *mediaInfo = [self mediaInfoWithoutSubtitle];
    mediaInfo.subtitleInfo = [SubtitleInfo infoWithURL:[NSURL URLWithString:@"http://example.com/"]];
    return mediaInfo;
}

@end
