//
//  MSFKDeviceManager.h
//
//  Created by Jiang Lu on 14-3-30.
//  Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
//

@class MSFKFlintChannel;
@class MSFKDevice;
@class MSFKApplicationMetadata;
@class MSFKHeartbeatChannel;

@protocol MSFKDeviceManagerDelegate;

@interface MSFKDeviceManager :  NSObject


#pragma mark Initializer

/**
 * True if the device manager has established a connection to the device.
 */
@property(nonatomic) BOOL isConnected;

@property(nonatomic) BOOL isConnecting;

/**
 * True if the device manager has established a connection to an application on the device.
 */
@property(nonatomic) BOOL isConnectedToApp;

/**
 * True if the device manager is disconnected due to a potentially transient event (e.g. the app is
 * backgrounded, or there was a network error which might be solved by reconnecting). Note that the
 * disconnection/connection callbacks will not be called while the device manager attemps to
 * reconnect after a potentially transient event, but the properties will always reflect the
 * actual current state and can be observed.
 */
@property(nonatomic) BOOL isReconnecting;

/**
 * Reconnection will be attempted for this long in the event that the socket disconnects with a
 * potentially transient error.
 *
 * The default timeout is 10s.
 */
@property(nonatomic) NSTimeInterval reconnectTimeout;

@property(nonatomic) MSFKDevice *device;

@property(nonatomic, weak) id <MSFKDeviceManagerDelegate> delegate;

/**
 * The current volume of the device, if known; otherwise <code>0</code>.
 */
@property(nonatomic, assign, readonly) float deviceVolume;

/**
 * The current mute state of the device, if known; otherwise <code>NO</code>.
 */
@property(nonatomic, assign, readonly) BOOL deviceMuted;


@property(nonatomic, copy) NSString* appId;


- (id)init;

/**
 * Designated initializer. Constructs a new MSFKDeviceManager with the given device.
 *
 * @param device The device to control.
 * @param clientPackageName The client package name.
 */
- (id)initWithDevice:(MSFKDevice *)device clientPackageName:(NSString *)clientPackageName;

#pragma mark Utils


#pragma mark Device connection

/**
 * Connects to the device.
 */
- (void)connect;

/**
 * Disconnects from the device.
 */
- (void)disconnect;


#pragma mark Channels

/**
 * Adds a channel which can send and receive messages for this device on a particular
 * namespace.
 *
 * @param channel The channel.
 * @return YES if the channel was added, NO if it was not added because there was already
 * a channel attached for that namespace.
 */
- (BOOL)addChannel:(MSFKFlintChannel *)channel;

/**
 * Removes a previously added channel.
 *
 * @param channel The channel.
 * @return YES if the channel was removed, NO if it was not removed because the given
 * channel was not previously attached.
 */
- (BOOL)removeChannel:(MSFKFlintChannel *)channel;

#pragma mark Applications

/**
 * Launches an application.
 *
 * @param applicationURL The application url.
 * @return NO if the message could not be sent.
 */
- (BOOL)launchApplication:(NSString *)applicationURL;

/**
 * Launches an application, optionally relaunching it if it is already running.
 *
 * @param applicationURL The application url.
 * @param relaunchIfRunning If YES, relaunches the application if it is already running instead of
 * joining the running applicaiton.
 * @return NO if the message could not be sent.
 */
- (BOOL)launchApplication:(NSString *)applicationURL
        relaunchIfRunning:(BOOL)relaunchIfRunning;

/**
 * Launches an application, optionally relaunching it if it is already running.
 *
 * @param applicationURL The application url.
 * @param relaunchIfRunning If YES, relaunches the application if it is already running instead of
 * joining the running applicaiton.
 * @param useIpc If YES, sender and receiver apps use WebSocket
 * @return NO if the message could not be sent.
 */
- (BOOL)launchApplication:(NSString *)applicationURL
        relaunchIfRunning:(BOOL)relaunchIfRunning
                   useIpc:(BOOL)useIpc;

/**
 * Joins an application.
 *
 * @param applicationURL The application url.
 * @return NO if the message could not be sent.
 */
- (BOOL)joinApplication:(NSString *)applicationURL;

/**
 * Leaves the current application.
 *
 * @return NO if the message could not be sent.
 */
- (BOOL)leaveApplication;

/**
 * Stops any running application(s).
 *
 * @return NO if the message could not be sent.
 */
- (BOOL)stopApplication;

/**
 * Sets the system volume.
 *
 * @param volume The new volume, in the range [0.0, 1.0]. Out of range values will be silently
 * clipped.
 * @return NO if the message could not be sent.
 */
- (BOOL)setVolume:(float)volume;

/**
 * Turns muting on or off.
 *
 * @param muted Whether audio should be muted or unmuted.
 * @return NO if the message could not be sent.
 */
- (BOOL)setMuted:(BOOL)muted;

/**
 * Requests the device's current status. This may cause an application status callback, if
 * currently connected to an application, and may cause a device volume callback, if the
 * device volume has changed.
 *
 * @return The request ID, or <code>kMSFKInvalidRequestID</code> if the request could not be sent.
 */
- (NSInteger)requestDeviceStatus;

@end

#pragma mark -

/**
 * The delegate for MSFKDeviceManager notifications.
 *
 * @ingroup DeviceControl
 */
@protocol MSFKDeviceManagerDelegate <NSObject>

@optional

#pragma mark Device connection callbacks

/**
 * Called when a connection has been established to the device.
 *
 * @param deviceManager The device manager.
 */
- (void)deviceManagerDidConnect:(MSFKDeviceManager *)deviceManager;

/**
 * Called when the connection to the device has failed.
 *
 * @param deviceManager The device manager.
 * @param error The error that caused the connection to fail.
 */
- (void)    deviceManager:(MSFKDeviceManager *)deviceManager
didFailToConnectWithError:(NSError *)error;

/**
 * Called when the connection to the device has been terminated.
 *
 * @param deviceManager The device manager.
 * @param error The error that caused the disconnection; nil if there was no error (e.g. intentional
 * disconnection).
 */
- (void) deviceManager:(MSFKDeviceManager *)deviceManager
didDisconnectWithError:(NSError *)error;

#pragma mark Application connection callbacks

/**
 * Called when an application has been launched or joined.
 *
 * @param applicationMetadata Metadata about the application.
 * @param launchedApplication YES if the application was launched as part of the connection, or NO
 * if the application was already running and was joined.
 */
- (void)      deviceManager:(MSFKDeviceManager *)deviceManager
didConnectToFlintApplication:(MSFKApplicationMetadata *)applicationMetadata
        launchedApplication:(BOOL)launchedApplication;

/**
 * Called when connecting to an application fails.
 *
 * @param deviceManager The device manager.
 * @param error The error that caused the failure.
 */
- (void)                 deviceManager:(MSFKDeviceManager *)deviceManager
didFailToConnectToApplicationWithError:(NSError *)error;

/**
 * Called when disconnected from the current application.
 */
- (void)                deviceManager:(MSFKDeviceManager *)deviceManager
didDisconnectFromApplicationWithError:(NSError *)error;

/**
 * Called when a stop application request fails.
 *
 * @param deviceManager The device manager.
 * @param error The error that caused the failure.
 */
- (void)            deviceManager:(MSFKDeviceManager *)deviceManager
didFailToStopApplicationWithError:(NSError *)error;

#pragma mark Device status callbacks

/**
 * Called whenever the volume changes.
 *
 * @param volumeLevel The current device volume level.
 * @param isMuted The current device mute state.
 */
- (void) deviceManager:(MSFKDeviceManager *)deviceManager
volumeDidChangeToLevel:(float)volumeLevel
               isMuted:(BOOL)isMuted;


@end

