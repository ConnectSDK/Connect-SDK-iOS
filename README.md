#Connect SDK iOS

[![Build Status](https://travis-ci.org/ConnectSDK/Connect-SDK-iOS.svg)](https://travis-ci.org/ConnectSDK/Connect-SDK-iOS)
[![Code Coverage](https://img.shields.io/codecov/c/github/ConnectSDK/Connect-SDK-iOS/dev.svg)](https://codecov.io/github/ConnectSDK/Connect-SDK-iOS)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/ConnectSDK.svg)](https://cocoapods.org/pods/ConnectSDK)
[![Apache License, 2.0](https://img.shields.io/cocoapods/l/ConnectSDK.svg)](https://github.com/ConnectSDK/Connect-SDK-iOS/blob/master/LICENSE)
[![Platform: iOS](https://img.shields.io/cocoapods/p/ConnectSDK.svg)](http://cocoadocs.org/docsets/ConnectSDK/)
[![Twitter: @ConnectSDK](https://img.shields.io/badge/twitter-@ConnectSDK-blue.svg)](https://twitter.com/ConnectSDK)

Connect SDK is an open source framework that connects your mobile apps with multiple TV platforms. Because most TV platforms support a variety of protocols, Connect SDK integrates and abstracts the discovery and connectivity between all supported protocols.

For more information, visit our [website](http://www.connectsdk.com/).

* [General information about Connect SDK](http://www.connectsdk.com/discover/)
* [Platform documentation & FAQs](http://www.connectsdk.com/docs/ios/)
* [API documentation](http://www.connectsdk.com/apis/ios/)

##Dependencies
This project has the following dependencies, some of which require manual setup. If you would like to use a version of the SDK which has no manual setup, consider using the [lite version](https://github.com/ConnectSDK/Connect-SDK-iOS-Lite) of the SDK.

* `libicucore.dylib`
* `libz.dylib`
* Other linker flags: `-ObjC`
* Automatic Reference Counting (ARC)
* [Connect-SDK-iOS-Core](https://github.com/ConnectSDK/Connect-SDK-iOS-Core) submodule
* [Connect-SDK-iOS-Google-Cast](https://github.com/ConnectSDK/Connect-SDK-iOS-Google-Cast) submodule
  - Requires [`GoogleCast.framework`](https://developers.google.com/cast/docs/developers#libraries)
* [Connect-SDK-iOS-FireTV](https://github.com/ConnectSDK/Connect-SDK-iOS-FireTV) submodule
  - Requires [`AmazonFling.framework`](https://developer.amazon.com/public/apis/experience/fling/docs/amazon-fling-sdk-download)

##Including Connect SDK in your app
###Using CocoaPods
1. Add `pod "ConnectSDK"` to your `Podfile`
2. Run `pod install`
3. Open the workspace file and run your project

**Important**: Unfortunately, Amazon Fling SDK is not distributed via CocoaPods, so we cannot include its support in a subspec in an automated way. If you need it, please use the source ConnectSDK project directly.

You can use `pod "ConnectSDK/Core"` to get the [lite version](https://github.com/ConnectSDK/Connect-SDK-iOS-Lite).

###Without CocoaPods

1. Clone the repository (`git clone https://github.com/ConnectSDK/Connect-SDK-iOS.git`)
2. Set up the submodules by running the following command (in the `Connect-SDK-iOS/` directory in this example): `git submodule update --init`
3. Open your project in Xcode
4. Locate the Connect SDK Xcode project in Finder
5. Drag the Connect SDK Xcode project (`ConnectSDK.xcodeproj`) into your project's Xcode library
6. Navigate to your target's settings screen, then navigate to the "Build Phases" tab
7. Add the following in the "Link Binary With Libraries" section:
 - `libConnectSDK.a`
 - `libz.dylib`
 - `libicucore.dylib`
8. Navigate to the "Build Settings" tab and add `-ObjC` to your target's "Other Linker Flags"
9. Follow the setup instructions for the service submodules:
 - [Connect-SDK-iOS-Google-Cast](https://github.com/ConnectSDK/Connect-SDK-iOS-Google-Cast)
 - [Connect-SDK-iOS-FireTV](https://github.com/ConnectSDK/Connect-SDK-iOS-FireTV)

###Include Strings File for Localization (optional)
1. Locate the Connect SDK Xcode project in the Finder
2. Drag the ConnectSDKStrings folder into your project's library
3. You may make whatever changes you would like to the values and the SDK will use your strings file

## Tests

Connect SDK has tests for some parts of the code, and we are continuing to increase the test coverage. There are currently three types of tests:

Type | Target &amp; Scheme | Frameworks used | Uses network | Fast | Reliable
-----|---------------------|-----------------|:------------:|:----:|:-------:
Unit tests | `ConnectSDKTests` | `OCMock`, `OHHTTPStubs`, `XCTest` | **-** | **+** | **+**
Integration tests | `ConnectSDKIntegrationTests` | `Expecta`, `OCMock`, `Specta` | **-** | **+** | **+**
Acceptance (aka End-To-End) tests | `ConnectSDKAcceptanceTests` | `Expecta`, `OCMock`, `Specta` | **+** | **-** | **±**

* **Unit** tests are for small components and usually test one class/method. They use mocks to inject the dependencies.

* **Integration** tests verify the behavior of the whole Connect SDK, but without external environment (network and devices), so that they can be reliable and fast.

* **Acceptance** tests verify the end-to-end behavior of Connect SDK and real devices, so they won't work out of the box in a different environment. Some acceptance tests also expect certain properties of those devices, such as name or IP address, which should be altered to match your particular setup.

The required third-party test frameworks are already pre-built and included in the `core` submodule.

All of the test targets are compiled when the main `ConnectSDK` scheme is built, but only the unit tests are setup to run when testing the scheme. The other tests can be run by selecting the corresponding scheme.

##Limitations/Caveats

###Subtitles

- DLNA service supports `SRT` format only. Since there is no official specification for them, subtitles may not work on all DLNA-compatible devices. This feature has been tested and works on LG WebOS and Netcast TVs.
- Netcast service supports `SRT` format only, through DLNA.
- Google Cast service supports `WebVTT` format only. Servers providing subtitles and media files should support [CORS](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing) headers (unless they are of the same origin). The simplest change is to send this HTTP response header for your files: `Access-Control-Allow-Origin: *`. More information is here: [https://developers.google.com/cast/docs/ios_sender#cors-requirements](https://developers.google.com/cast/docs/ios_sender#cors-requirements).
- FireTV service supports `WebVTT` format only. Subtitles on Fire TV are hidden by default. To display them, the user should manually pick one in the media player (click the "Options" button on the remote). The Fling SDK doesn't provide any way to make them appear remotely.
- WebOS service supports `WebVTT` format only. Server providing subtitles should support CORS headers, similarly to Cast service's requirements.

##Contact
- Twitter: [@ConnectSDK](https://twitter.com/ConnectSDK)
- Ask a question on Stack Overflow with the [Connect-SDK tag](https://stackoverflow.com/tags/connect-sdk) (or [TV tag](https://stackoverflow.com/tags/tv))
- Developer Support: [support@connectsdk.com](mailto:support@connectsdk.com)
- Partnerships: [partners@connectsdk.com](mailto:partners@connectsdk.com)

##Credits
Connect SDK for iOS makes use of the following projects, some of which are open-source:

* [Google Cast SDK](https://developers.google.com/cast/)
  - [Google Cast SDK Additional Developer Terms of Service](https://developers.google.com/cast/docs/terms)
  - [Google APIs Terms of Service](https://developers.google.com/terms/)
* [Amazon Fling SDK](https://developer.amazon.com/fling)
  - [Amazon Fling SDK Terms of Service](https://developer.amazon.com/public/support/pml.html)
* [SocketRocket](https://github.com/Square/SocketRocket) (Apache License, Version 2.0)
  - modifications:
    - stability
    - self-signed certificate support
    - avoid potential namespace collisions
    - compiler warning fix
* [objc-guid](https://code.google.com/p/objc-guid/) (BSD 3-Clause revised)
* [GCDWebServer](https://github.com/swisspol/GCDWebServer) (MIT)
* [XMLReader](https://github.com/amarcadet/XMLReader) (MIT)
  - modifications:
    - properly return an error if XML parsing has failed
* [ASIHTTPRequest](https://github.com/pokeb/asi-http-request) (MIT)
  - modifications:
    - static analyzer warning fix
* [xswi](https://github.com/skjolber/xswi) (MIT)
  - modifications:
    - compiler warning fix

These projects are used in tests:

* [OCMock](http://ocmock.org/) (Apache License, Version 2.0)
* [OHHTTPStubs](https://github.com/AliSoftware/OHHTTPStubs/) (MIT)
* [Specta](https://github.com/specta/specta/) (MIT)
* [Expecta](https://github.com/specta/expecta/) (MIT)

This public domain image is used in tests: [The San Francisco peaks of flagstaff public domain image](http://www.public-domain-image.com/free-images/nature-landscapes/peaks/the-san-francisco-peaks-of-flagstaff).

##License
Copyright (c) 2013-2015 LG Electronics.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

> http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
