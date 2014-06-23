#Connect SDK iOS
Connect SDK is an open source framework that connects your mobile apps with multiple TV platforms. Because most TV platforms support a variety of protocols, Connect SDK integrates and abstracts the discovery and connectivity between all supported protocols.

For more information, visit our [website](http://www.connectsdk.com/).

* [General information about Connect SDK](http://www.connectsdk.com/discover/)
* [Platform documentation & FAQs](http://www.connectsdk.com/docs/ios/)
* [API documentation](http://www.connectsdk.com/apis/ios/)

##Dependencies
This project has the following dependencies.
- libicucore.dylib
- libz.dylib
- [GoogleCast.framework](https://developers.google.com/cast/docs/downloads)
- Other linker flags: -ObjC
- Automatic Reference Counting (ARC)

##Including Connect SDK in your app
###Using CocoaPods
1. Add `pod "ConnectSDK"` to your Podspec file
2. Run `pod install`
3. Open the workspace file and run your project
4. If you get any errors about the Google Cast framework, download the [latest framework](https://developers.google.com/cast/docs/downloads) and include it in your project's `Link Binary With Libraries` build phase

####Important note about google-cast-sdk CocoaPod
As of this writing, Google does not maintain the links for old versions of the Google Cast iOS sender framework files. This means that the google-cast-sdk CocoaPod will break upon each release of the Google Cast SDK. When this occurs, you will need to do either of the following.

- Check to see if the [google-cast-sdk](https://github.com/CocoaPods/Specs/tree/master/Specs/google-cast-sdk) CocoaPod has been updated
- Manually download and add/update the GoogleCast.framework file from [Google's site](https://developers.google.com/cast/docs/downloads)

###Without CocoaPods

1. Clone repository (or download & unzip)
2. Open your project in Xcode
3. Locate the Connect SDK Xcode project in the Finder
4. Drag the Connect SDK Xcode project into your project's Xcode library
5. Navigate to your project's settings screen, then navigate to the Build Phases tab
6. Add ConnectSDK as a Target Dependency
7. Add the following in the `Link Binary With Libraries` section
   - libConnectSDK.a
   - libz.dylib
   - libicucore.dylib
8. Navigate to the `Build Settings` tab and add `-ObjC` to your target's `Other Linker Flags`
9. Download the [Google Cast SDK iOS sender library file](https://developers.google.com/cast/docs/downloads)
10. Extract GoogleCast.framework and copy it to $(Connect SDK project directory)/ConnectSDK/Frameworks
11. Drag and drop GoogleCast.framework into your project's Frameworks folder

###Include Strings File for Localization (optional)
1. Locate the Connect SDK Xcode project in the Finder
2. Drag the ConnectSDKStrings folder into your project's library
3. You may make whatever changes you would like to the values and the SDK will use your strings file

##Contact
* Twitter: [@ConnectSDK](https://www.twitter.com/ConnectSDK)
* Ask a question with the "tv" tag on [Stack Overflow](http://stackoverflow.com/tags/tv)
* General Inquiries: info@connectsdk.com
* Developer Support: support@connectsdk.com
* Partnerships: partners@connectsdk.com

##Credits
Connect SDK for iOS makes use of the following projects, some of which are open-source.

* [Google Cast SDK](https://developers.google.com/cast/)
  - [Google Cast SDK Additional Developer Terms of Service](https://developers.google.com/cast/docs/terms)
  - [Google APIs Terms of Service](https://developers.google.com/terms/)
* [SocketRocket](https://github.com/Square/SocketRocket) (Apache License, Version 2.0)
  - modifications:
    - stability
    - self-signed certificate support
    - avoid potential namespace collisions
* [objc-guid](https://code.google.com/p/objc-guid/) (BSD 3-Clause revised)
* [GCDWebServer](https://github.com/swisspol/GCDWebServer) (MIT)
* [XMLReader](https://github.com/amarcadet/XMLReader) (MIT)
* [ASIHTTPRequest](https://github.com/pokeb/asi-http-request) (MIT)

##License
Copyright (c) 2013-2014 LG Electronics.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

> http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
