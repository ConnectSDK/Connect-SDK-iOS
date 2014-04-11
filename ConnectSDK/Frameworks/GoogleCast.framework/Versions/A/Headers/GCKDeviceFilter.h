// Copyright 2013 Google Inc.
// Author: sdykeman@google.com (Sean Dykeman)

@protocol GCKDeviceFilterListener;
@class GCKDevice;
@class GCKDeviceScanner;
@class GCKFilterCriteria;

/**
 * Filters device scanner results to return only those devices which support or are running
 * applications which meet some given critera. Note that using this class will have no effect on
 * the results from the GCKDeviceScanner; use the device list and delegate callbacks for this object
 * instead of for the device scanner to be notified about only the filtered devices.
 *
 * Multiple device filters can use a single source device scanner.
 */
@interface GCKDeviceFilter : NSObject

@property(nonatomic, readonly, copy) NSArray *devices;

/**
 * Designated initializer. Creates a device filter which will filter devices based on the given
 * criteria.
 *
 * @param scanner The source device scanner which provides the devices to be filtered.
 * @param criteria The criteria by which the filter will filter devices.
 */
- (id)initWithDeviceScanner:(GCKDeviceScanner *)scanner criteria:(GCKFilterCriteria *)criteria;

/**
 * Adds a new listener for filtered devices.
 * @param listener The listener to add.
 */
- (void)addDeviceFilterListener:(id<GCKDeviceFilterListener>)listener;

/**
 * Removes a listener for filtered devices.
 * @param listener The listener to remove.
 */
- (void)removeDeviceFilterListener:(id<GCKDeviceFilterListener>)listener;

@end

/**
 * The listener interface for GCKDeviceFilter notifications. Use this protocol instead of
 * GCKDeviceScannerListener if you are only interested in notifications which meet this filter's
 * criteria.
 */
@protocol GCKDeviceFilterListener <NSObject>

/**
 * Called when a supported device has come online.
 *
 * @param device The device.
 */
- (void)deviceDidComeOnline:(GCKDevice *)device
            forDeviceFilter:(GCKDeviceFilter *)deviceFilter;

/**
 * Called when a supported device has gone offline.
 *
 * @param device The device.
 */
- (void)deviceDidGoOffline:(GCKDevice *)device
           forDeviceFilter:(GCKDeviceFilter *)deviceFilter;

@end
