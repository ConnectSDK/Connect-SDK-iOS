# Connect SDK iOS Changelog

## 1.3.0 - 23 June 2014

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

## 1.2.1 - 14 May 2014

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
