//
//  WebOSWebAppSessionTests.m
//  ConnectSDK
//
//  Created by Ibrahim Adnan on 6/18/15.
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

#import "WebOSWebAppSession_Private.h"

#import "SubtitleInfo.h"

@interface WebOSWebAppSessionTests : XCTestCase

@property(nonatomic, strong) WebOSWebAppSession *session;
@property(nonatomic, strong) id socketMock;

@end

@implementation WebOSWebAppSessionTests

- (void)setUp {
    [super setUp];

    self.session = OCMPartialMock([WebOSWebAppSession new]);
    self.session.fullAppId = @"com.lgsmartplatform.redirect.MediaPlayer";

    self.socketMock = OCMClassMock([WebOSTVServiceSocketClient class]);
    OCMStub([self.session createSocketWithService:OCMOCK_ANY]).andReturn(self.socketMock);

    [self.session connectWithSuccess:nil failure:nil];
    OCMStub([self.session connected]).andReturn(YES);
}

#pragma mark - MediaPlayer Tests

- (void)testMediaPlayerErrorShouldCallFailureBlockInPlayStateSubscription{
    // Arrange
    XCTestExpectation *failureBlockCalledExpectation = [self expectationWithDescription:@"Failure block is called"];
    [self.session subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
        XCTFail(@"Success should not be called when Media player throws error");
    }                                   failure:^(NSError *error) {
        [failureBlockCalledExpectation fulfill];
    }];

    NSDictionary *errorPayload = @{
                                   @"from" : @"com.lgsmartplatform.redirect.MediaPlayer",
                                   @"payload" : @{
                                           @"contentType" : @"connectsdk.media-error",
                                           @"error" : @"The file cannot be recognized",
                                           },
                                   @"type" : @"p2p"
                                   };

    // Act
    [self.session socket:self.socketMock didReceiveMessage:errorPayload];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout handler:nil];
}

#pragma mark - Subtitles Support Tests

- (void)testPlayVideoWithSubtitlesShouldContainSubtitlesKey {
    [self checkPlayVideoWithSubtitles:[self mediaInfoWithSubtitle]
    shouldContainSubtitlesPassingTest:^(NSDictionary *subtitles) {
        XCTAssertNotNil(subtitles);
    }];
}

- (void)testPlayVideoWithSubtitlesShouldContainOneSubtitleTrack {
    [self checkPlayVideoWithSubtitles:[self mediaInfoWithSubtitle]
    shouldContainSubtitlesPassingTest:^(NSDictionary *subtitles) {
        NSArray *tracks = subtitles[@"tracks"];
        XCTAssertEqual(tracks.count, 1);
    }];
}

- (void)testPlayVideoWithSubtitlesShouldContainSubtitleSourceAsString {
    MediaInfo *const mediaInfo = [self mediaInfoWithSubtitle];
    [self checkPlayVideoWithSubtitles:mediaInfo
    shouldContainSubtitlesPassingTest:^(NSDictionary *subtitles) {
        NSDictionary *track = subtitles[@"tracks"][0];
        XCTAssertEqualObjects(track[@"source"], mediaInfo.subtitleInfo.url.absoluteString);
    }];
}

- (void)testPlayVideoWithSubtitlesShouldContainSubtitleLanguage {
    MediaInfo *const mediaInfo = [self mediaInfoWithSubtitle];
    [self checkPlayVideoWithSubtitles:mediaInfo
    shouldContainSubtitlesPassingTest:^(NSDictionary *subtitles) {
        NSDictionary *track = subtitles[@"tracks"][0];
        XCTAssertEqualObjects(track[@"language"], mediaInfo.subtitleInfo.language);
    }];
}

- (void)testPlayVideoWithSubtitlesShouldContainSubtitleLabel {
    MediaInfo *const mediaInfo = [self mediaInfoWithSubtitle];
    [self checkPlayVideoWithSubtitles:mediaInfo
    shouldContainSubtitlesPassingTest:^(NSDictionary *subtitles) {
        NSDictionary *track = subtitles[@"tracks"][0];
        XCTAssertEqualObjects(track[@"label"], mediaInfo.subtitleInfo.label);
    }];
}

- (void)testPlayVideoWithSubtitlesShouldContainStringSubtitleId {
    MediaInfo *const mediaInfo = [self mediaInfoWithSubtitle];
    [self checkPlayVideoWithSubtitles:mediaInfo
    shouldContainSubtitlesPassingTest:^(NSDictionary *subtitles) {
        NSDictionary *track = subtitles[@"tracks"][0];
        XCTAssertTrue([track[@"id"] isKindOfClass:[NSString class]]);
    }];
}

- (void)testPlayVideoWithSubtitlesShouldEnableTheSubtitles {
    MediaInfo *const mediaInfo = [self mediaInfoWithSubtitle];
    [self checkPlayVideoWithSubtitles:mediaInfo
    shouldContainSubtitlesPassingTest:^(NSDictionary *subtitles) {
        NSString *enabledId = subtitles[@"enabled"];
        NSString *trackId = subtitles[@"tracks"][0][@"id"];
        XCTAssertEqualObjects(enabledId, trackId);
    }];
}

- (void)testPlayVideoWithSubtitlesWithoutLanguageShouldNotContainSubtitleLanguage {
    MediaInfo *const mediaInfo = [self mediaInfoWithSubtitleLanguage:nil
                                                               label:@"label"];
    [self checkPlayVideoWithSubtitles:mediaInfo
    shouldContainSubtitlesPassingTest:^(NSDictionary *subtitles) {
        NSDictionary *track = subtitles[@"tracks"][0];
        XCTAssertNil(track[@"language"]);
    }];
}

- (void)testPlayVideoWithSubtitlesWithoutLabelShouldNotContainSubtitleLabel {
    MediaInfo *const mediaInfo = [self mediaInfoWithSubtitleLanguage:@"en"
                                                               label:nil];
    [self checkPlayVideoWithSubtitles:mediaInfo
    shouldContainSubtitlesPassingTest:^(NSDictionary *subtitles) {
        NSDictionary *track = subtitles[@"tracks"][0];
        XCTAssertNil(track[@"label"]);
    }];
}

- (void)testPlayVideoWithoutSubtitlesShouldNotContainSubtitlesKey {
    [self checkPlayVideoWithSubtitles:[self videoInfo]
    shouldContainSubtitlesPassingTest:^(NSDictionary *subtitles) {
        XCTAssertNil(subtitles);
    }];
}

#pragma mark - Helpers

- (void)checkPlayVideoWithSubtitles:(MediaInfo *)mediaInfo
  shouldContainSubtitlesPassingTest:(void (^)(NSDictionary *subtitles))checkBlock {
    OCMExpect([self.socketMock sendDictionaryOverSocket:
        [OCMArg checkWithBlock:^BOOL(NSDictionary *dict) {
            checkBlock([dict valueForKeyPath:@"payload.mediaCommand.subtitles"]);
            return YES;
        }]]);

    [self.session playMediaWithMediaInfo:mediaInfo
                              shouldLoop:NO
                                 success:nil
                                 failure:nil];

    OCMVerifyAll(self.socketMock);
}

- (MediaInfo *)mediaInfoWithSubtitle {
    return [self mediaInfoWithSubtitleLanguage:@"en" label:@"Test"];
}

- (MediaInfo *)mediaInfoWithSubtitleLanguage:(NSString *)language
                                       label:(NSString *)label {
    NSURL *subtitleURL = [NSURL URLWithString:@"http://example.com/"];
    SubtitleInfo *subtitleInfo = [SubtitleInfo infoWithURL:subtitleURL
                                                  andBlock:^(SubtitleInfoBuilder *builder) {
                                                      builder.language = language;
                                                      builder.label = label;
                                                  }];
    MediaInfo *mediaInfo = [self videoInfo];
    mediaInfo.subtitleInfo = subtitleInfo;

    return mediaInfo;
}

- (MediaInfo *)videoInfo {
    return [[MediaInfo alloc] initWithURL:[NSURL URLWithString:@"http://url"]
                                 mimeType:@"video/mp4"];
}

@end
