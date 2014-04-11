// Copyright 2013 Google Inc.

#import <Foundation/Foundation.h>

@class GCKDevice;
@protocol GCKDeviceScannerListener;

/**
 * A class that (asynchronously) scans for available devices and sends corresponding notifications
 * to its listener(s). This class is implicitly a singleton; since it does a network scan, it isn't
 * useful to have more than one instance of it in use.
 *
 * @ingroup Discovery
 */
@interface GCKDeviceScanner : NSObject

/** The array of discovered devices. */
@property(nonatomic, readonly, copy) NSArray *devices;

/** Whether the current/latest scan has discovered any devices. */
@property(nonatomic, readonly) BOOL hasDiscoveredDevices;

/** Whether a scan is currently in progress. */
@property(nonatomic, readonly) BOOL scanning;

/**
 * Designated initializer. Constructs a new GCKDeviceScanner.
 */
- (id)init;

/**
 * Starts a new device scan. The scan must eventually be stopped by calling
 * @link #stopScan @endlink.
 */
- (void)startScan;

/**
 * Stops any in-progress device scan. This method <b>must</b> be called at some point after
 * @link #startScan @endlink was called and before this object is released by its owner.
 */
- (void)stopScan;

/**
 * Adds a listener for receiving notifications.
 *
 * @param listener The listener to add.
 */
- (void)addListener:(id<GCKDeviceScannerListener>)listener;

/**
 * Removes a listener that was previously added with @link #addListener: @endlink.
 *
 * @param listener The listener to remove.
 */
- (void)removeListener:(id<GCKDeviceScannerListener>)listener;

@end

/**
 * The listener interface for GCKDeviceScanner notifications.
 *
 * @ingroup Discovery
 */
@protocol GCKDeviceScannerListener <NSObject>

@optional

/**
 * Called when a device has been discovered or has come online.
 *
 * @param device The device.
 */
- (void)deviceDidComeOnline:(GCKDevice *)device;

/**
 * Called when a device has gone offline.
 *
 * @param device The device.
 */
- (void)deviceDidGoOffline:(GCKDevice *)device;

@end
