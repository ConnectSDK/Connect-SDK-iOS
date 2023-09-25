//
//  DefaultConnectableDeviceStore.h
//  Connect SDK
//
//  Created by Jeremy White on 3/21/14.
//  Copyright (c) 2014 LG Electronics.
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

#import <Foundation/Foundation.h>
#import "ConnectableDeviceStore.h"


/*!
 * DefaultConnectableDeviceStore is an implementation of ConnectableDeviceStore provided by Connect SDK for your convenience. This class will be used by DiscoveryManager as the default ConnectableDeviceStore if no other ConnectableDeviceStore implementation is provided before calling startDiscovery.
 *
 * ###Privacy Considerations
 * As outlined in ConnectableDeviceStore, this class takes the following steps to ensure users' privacy.
 * - Only ConnectableDevices that have been connected to will be permanently stored
 * - On load & store, ConnectableDevices that have not been discovered within the maxStoreDuration will be removed from the ConnectableDeviceStore
 *
 * ###File Format
 * DefaultConnectableDeviceStore stores data in a JSON file named `Connect_SDK_Device_Store.json` in the documents directory.
 *
@code
{
    // necessary for migrations, if needed
    version: 1,
    created: 1395892958.220422,
    updated: 1395892958.220422,
    devices: {
        "12345678-5137-1358-1544-123456789012" : { // each ConnectableDevice is keyed against its id
            "id": "12345678-5137-1358-1544-123456789012",
            "friendlyName": "My TV",
            "lastKnownIPAddress": "192.168.1.107",
            "lastSeenOnWifi": "My WiFi Network",
            "lastConnected": 1395892958.220422,
            "lastDetection": 1395892958.220422,
            "services": {
                "66be8e5d-51be-b18f-f733-6c4dc8c97aca": { // each DeviceService discovered is keyed against its UUID
                    {
                        "class": "WebOSTVService", // DeviceService subclass name
                        "config": {
                            "class": "WebOSTVServiceConfig", // ServiceConfig subclass name
                            "UUID": "66be8e5d-51be-b18f-f733-6c4dc8c97aca",
                            "connected": false,
                            "wasConnected": false,
                            "lastDetection": 1395892958.220422,

                            // should be appropriate to the platform (in iOS this is an array)
                            "SSLCertificates": ...,
                            "clientKey": "..."
                        },
                        "description": {
                            "serviceId": "webOS TV",
                            "port": 3001,
                            "UUID": "66be8e5d-51be-b18f-f733-6c4dc8c97aca",
                            "type": "urn:lge-com:service:webos-second-screen:1",
                            "version": "4.1.0",
                            "friendlyName": "My TV",
                            "manufacturer": "LG Electronics",
                            "modelName": "LG Smart TV",
                            "modelDescription": "",
                            "modelNumber": "",
                            "commandURL": "http://192.168.1.107:1914/"
                        }
                    }
                }
            }
        },
        ...
    }
}
@endcode
 */
@interface DefaultConnectableDeviceStore : NSObject <ConnectableDeviceStore>

/*!
 * Max length of time for a ConnectableDevice to remain in the ConnectableDeviceStore without being discovered. Default is 3 days, and modifications to this value will trigger a scan for old devices. ConnectableDevices that have been connected to will never be removed from the device store unless `remove:` or `removeAll` are called.
 */
@property (nonatomic) double maxStoreDuration;

/*! Date (in seconds from 1970) that the ConnectableDeviceStore was created. */
@property (nonatomic, readonly) double created;

/*! Date (in seconds from 1970) that the ConnectableDeviceStore was last updated. */
@property (nonatomic, readonly) double updated;

/*! Current version of the ConnectableDeviceStore, may be necessary for migrations */
@property (nonatomic, readonly) int version;

@end
