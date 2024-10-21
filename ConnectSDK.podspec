# There are two usage options of this podspec:
# * pod "ConnectSDK" will install the full ConnectSDK version (without Amazon
#   Fling SDK support; if you need it, please use the source ConnectSDK project
#   directly);
# * pod "ConnectSDK/Core" will install the core only (Lite version) without
#   external dependencies.
#
# Unfortunately, Amazon Fling SDK is not distributed via CocoaPods, so we
# cannot include its support in a subspec in an automated way.

Pod::Spec.new do |s|
  s.name         = "ConnectSDK"
  s.version      = "2.1.4"
  s.summary      = "Connect SDK is an open source framework that connects your mobile apps with multiple TV platforms."

  s.description  = <<-DESC
                    Connect SDK is an open source framework that connects your mobile apps with multiple TV platforms. Because most TV platforms support a variety of protocols, Connect SDK integrates and abstracts the discovery and connectivity between all supported protocols.

                    To discover supported platforms and protocols, Connect SDK uses SSDP to discover services such as DIAL, DLNA, UDAP, and Roku's External Control Guide (ECG). Connect SDK also supports ZeroConf to discover devices such as Chromecast and Apple TV. Even while supporting multiple discovery protocols, Connect SDK is able to generate one unified list of discovered devices from the same network.

                    To communicate with discovered devices, Connect SDK integrates support for protocols such as DLNA, DIAL, SSAP, ECG, AirPlay, Chromecast, UDAP, and webOS second screen protocol. Connect SDK intelligently picks which protocol to use depending on the feature being used.

                    For example, when connecting to a 2013 LG Smart TV, Connect SDK uses DLNA for media playback, DIAL for YouTube launching, and UDAP for system controls. On Roku, media playback and system controls are made available through ECG, and YouTube launching through DIAL. On Chromecast, media playback occurs through the Cast protocol and YouTube is launched via DIAL.

                    To support the aforementioned use case without Connect SDK, a developer would need to implement DIAL, ECG, Chromecast, and DLNA in their app. With Connect SDK, discovering the three devices is handled for you. Furthermore, the method calls between each protocol is abstracted. That means you can use one method call to beam a video to Roku, 3 generations of LG Smart TVs, Apple TV, and Chromecast.
                   DESC

  s.homepage     = "http://www.connectsdk.com/"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author             = { "Connect SDK" => "support@connectsdk.com" }
  s.social_media_url   = "http://twitter.com/ConnectSDK"
  s.platform     = :ios, "11.0"
  s.ios.deployment_target = "11.0"
  s.source       = { :git => "https://github.com/ConnectSDK/Connect-SDK-iOS.git",
                     :tag => s.version,
                     :submodules => true }

  s.xcconfig = {
      "OTHER_LDFLAGS" => "$(inherited) -ObjC"
  }

  s.requires_arc = true
  s.libraries = "z", "icucore"
  s.prefix_header_contents = <<-PREFIX
                                  //
                                  //  Prefix header
                                  //
                                  //  The contents of this file are implicitly included at the beginning of every source file.
                                  //
                                  //  Copyright (c) 2015 LG Electronics.
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

                                  #define CONNECT_SDK_VERSION @"#{s.version}"

                                  // Uncomment this line to enable SDK logging
                                  //#define CONNECT_SDK_ENABLE_LOG

                                  #ifndef kConnectSDKWirelessSSIDChanged
                                  #define kConnectSDKWirelessSSIDChanged @"Connect_SDK_Wireless_SSID_Changed"
                                  #endif

                                  #ifdef CONNECT_SDK_ENABLE_LOG
                                      // credit: http://stackoverflow.com/a/969291/2715
                                      #ifdef DEBUG
                                      #   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
                                      #else
                                      #   define DLog(...)
                                      #endif
                                  #else
                                      #   define DLog(...)
                                  #endif
                               PREFIX

  non_arc_files =
    "core/Frameworks/asi-http-request/External/Reachability/*.{h,m}",
    "core/Frameworks/asi-http-request/Classes/*.{h,m}"

  s.subspec 'Core' do |sp|
    sp.source_files  = "ConnectSDKDefaultPlatforms.h", "core/**/*.{h,m}"
    sp.exclude_files = (non_arc_files.dup << "core/ConnectSDK*Tests/**/*" << "core/Frameworks/LGCast/**/*.h")
    sp.private_header_files = "core/**/*_Private.h"
    sp.requires_arc = true

    sp.dependency 'ConnectSDK/no-arc'
    sp.ios.vendored_frameworks = 'core/Frameworks/LGCast/LGCast.xcframework', 'core/Frameworks/LGCast/GStreamerForLGCast.xcframework'
    sp.preserve_paths =  'core/Frameworks/LGCast/LGCast.xcframework', 'core/Frameworks/LGCast/GStreamerForLGCast.xcframework'
  end

  s.subspec 'no-arc' do |sp|
    sp.source_files = non_arc_files
    sp.requires_arc = false
    # disable all warnings from asi-http-request
    sp.compiler_flags = '-w'
  end

  s.subspec 'GoogleCast' do |sp|
    cast_dir = "modules/google-cast"

    sp.dependency 'ConnectSDK/Core'
    sp.source_files = "#{cast_dir}/**/*.{h,m}"
    sp.exclude_files = "#{cast_dir}/*Tests/**/*"
    sp.private_header_files = "#{cast_dir}/**/*_Private.h"

    cast_version = "2.7.1"
    sp.dependency "google-cast-sdk", cast_version
    sp.framework = "GoogleCast"
    sp.xcconfig = {
        "FRAMEWORK_SEARCH_PATHS" => "$(PODS_ROOT)/google-cast-sdk/GoogleCastSDK-#{cast_version}-Release",
    }
  end
end
