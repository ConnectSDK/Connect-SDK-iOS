//
// Created by Jiang Lu on 14-4-8.
// Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
//

#import <Foundation/Foundation.h>

@class MSFKDevice;
@protocol MSFKDeviceScannerListener;

/**
 * A class that (asynchronously) scans for available devices and sends corresponding notifications
 * to its listener(s). This class is implicitly a singleton; since it does a network scan, it isn't
 * useful to have more than one instance of it in use.
 *
 * @ingroup Discovery
 */
@interface MSFKDeviceScanner : NSObject

/** The array of discovered devices. */
@property(nonatomic, copy) NSArray *devices;

/** Whether the current/latest scan has discovered any devices. */
@property(nonatomic) BOOL hasDiscoveredDevices;

/** Whether a scan is currently in progress. */
@property(nonatomic) BOOL scanning;


/**
 * Designated initializer. Constructs a new MSFKDeviceScanner.
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
- (void)addListener:(id<MSFKDeviceScannerListener>)listener;

/**
 * Removes a listener that was previously added with @link #addListener: @endlink.
 *
 * @param listener The listener to remove.
 */
- (void)removeListener:(id<MSFKDeviceScannerListener>)listener;


@end

/**
 * The listener interface for MSFKDeviceManager notifications.
 *
 * @ingroup Discovery
 */
@protocol MSFKDeviceScannerListener <NSObject>

@optional

/**
 * Called when a device has been discovered or has come online.
 *
 * @param device The device.
 */
- (void)deviceDidComeOnline:(MSFKDevice *)device;

/**
 * Called when a device has gone offline.
 *
 * @param device The device.
 */
- (void)deviceDidGoOffline:(MSFKDevice *)device;

@end