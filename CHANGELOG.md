# Connect SDK iOS Changelog

## 1.6.0 -- 09 Sep 2015

- Added subtitles support for WebOS, Netcast, DLNA, Chromecast and FireTV
- Supports Android TV devices
- Fixed playing media on Roku 6.2
- Removed Rewind and FastForward capabilities from Netcast service because they are not supported
- Miscellaneous bug fixes
- [See commits between 1.5.0 and 1.6.0](https://github.com/ConnectSDK/Connect-SDK-iOS/compare/1.5.0...1.6.0)

[View files at version 1.6.0](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.6.0)

## 1.5.0 -- 09 Jul 2015

- Supports Amazon Fling SDK to play and control media on Fire TV devices
- Added playlist support for WebOS TVs
- Added media player loop capability for WebOS TVs
- Added feature to pin web apps on WebOS TVs
- Fixed photos not displaying on Apple TV with OS 7.2
- Fixed launching input picker for new versions of WebOS TVs
- Extended play state subscription to handle media playback errors on WebOS TVs
- Created a first set of integration and acceptance tests
- Miscellaneous bug fixes
- [See commits between 1.4.4 and 1.5.0](https://github.com/ConnectSDK/Connect-SDK-iOS/compare/1.4.4...1.5.0)

[View files at version 1.5.0](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.5.0)

## 1.4.4 -- 29 Apr 2015

- Allow to set pairing type for WebOS TVs
- Added LG Music Flow speaker support (Google Cast for Audio and DLNA)
- Support for Google Cast SDK 2.6.0
- Fixed a few DLNA issues
- Fixed compiler and static analyzer warnings
- Fixed immediate disconnect if Apple TV has an IPv6 address only
- Miscellaneous bug fixes
- [See commits between 1.4.3 and 1.4.4](https://github.com/ConnectSDK/Connect-SDK-iOS/compare/1.4.3...1.4.4)

[View files at version 1.4.4](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.4.4)

## 1.4.3 -- 23 Mar 2015

- Reverted Roku 6.1 fix for playing video as Roku has fixed its media player
- Added proper encoding of special characters for metadata XML in DLNAService
- Miscellaneous bug fixes
- [See commits between 1.4.2 and 1.4.3](https://github.com/ConnectSDK/Connect-SDK-iOS/compare/1.4.2...1.4.3)

[View files at version 1.4.3](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.4.3)

## 1.4.2 -- 10 Feb 2015

- Support for Xbox One console and Sonos speakers
- Added playlist support over DLNA
- Fixed video playing on Roku firmware 6.1
- Fixed SSDP discovery provider
- Miscellaneous bug fixes
- [See commits between 1.4.1 and 1.4.2](https://github.com/ConnectSDK/Connect-SDK-iOS/compare/1.4.1...1.4.2)

[View files at version 1.4.2](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.4.2)

## 1.4.1 -- 18 Dec 2014
- Added new API's to
  - Display image (`-[MediaPlayer displayImage:success:failure:]`)
  - Play media (`-[MediaPlayer playMedia:shouldLoop:success:failure:]`)
- Miscellaneous bug fixes
  - Upgraded GCDWebserver to v3.2.1 to fix a crash when the app comes back to foreground when playing media in Debug mode.
  - Fixed Airplay streaming issue for long Audio/Video.
- [See commits between 1.4.0 and 1.4.1](https://github.com/ConnectSDK/Connect-SDK-iOS/compare/1.4.0...1.4.1)

[View files at version 1.4.1](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.4.1)

## 1.4.0 -- 3 Dec 2014

- Modularized project to allow easy exclusion of modules that have heavy and/or external dependencies
- Improved support for DLNA devices
  - DLNA volume control subscriptions
  - DLNA play state subscriptions
  - DLNA media info
- Unit tests for the discovery services providers
- Miscellaneous bug fixes
- [See commits between 1.3.2 and 1.4.0](https://github.com/ConnectSDK/Connect-SDK-iOS/compare/1.3.2...1.4.0)

[View files at version 1.4.0](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.4.0)

## 1.3.2 -- 6 Aug 2014

- Added launchYouTube:startTime:success:failure: api to Launcher capability
- Added "CT" prefix to most bundled libraries
- Decoupled Netcast and DLNA services
- Miscellaneous bug fixes
- [See commits between 1.3.1 and 1.3.2](https://github.com/ConnectSDK/Connect-SDK-iOS/compare/1.3.1...1.3.2)

[View files at version 1.3.2](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.3.2)

## 1.3.1 -- 14 July 2014

- Added ability to prevent DeviceService disconnection on background state
- Miscellaneous bug fixes
- [See commits between 1.3.0 and 1.3.1](https://github.com/ConnectSDK/Connect-SDK-iOS/compare/1.3.0...1.3.1)

[View files at version 1.3.1](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.3.1)

## 1.3.0 -- 23 June 2014

- Added support for Apple TV
 + Supports web apps via AirPlay mirroring, extended display
 + Supports media playback & control via HTTP requests
- Added ZeroconfDiscoveryProvider for discovery of devices over mDNS/Bonjour/Zeroconf
 + Only used for AirPlay devices currently, but can be used for discovery of other devices over Zeroconf
- Improved stability of web app capabilities on webOS
- Improved support for different versions of LG webOS
- Significant improvement in discovery due to change in Connectable Device Store
- Miscellaneous bug fixes
- [See commits between 1.2.1 and 1.3.0](https://github.com/ConnectSDK/Connect-SDK-iOS/compare/1.2.1...1.3.0)

[View files at version 1.3.0](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.3.0)

## 1.2.1 -- 14 May 2014

- Fixed numerous issues with Connectable Device Store
- Added ability to probe for app presence on Roku & DIAL
 + Capability will be added to device named "Launcher.X", where X is your DIAL/Roku app name
- Fixed some issues with launching apps via DIAL on non-LG devices
- Resolved numerous crashing bugs
- Miscellaneous bug fixes
- [See commits between 1.2.0 and 1.2.1](https://github.com/ConnectSDK/Connect-SDK-iOS/compare/1.2.0...1.2.1)

[View files at version 1.2.1](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.2.1)

## 1.2.0 -- 17 Apr 2014

- Initial release, includes support for
 + Chromecast
 + DIAL
 + Roku
 + LG Smart TV with Netcast 3 & 4 (2012-13 models)
 + LG Smart TV with webOS (2014+ models)

[View files at version 1.2.0](https://github.com/ConnectSDK/Connect-SDK-iOS/tree/1.2.0)
