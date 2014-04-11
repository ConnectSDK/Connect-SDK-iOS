//
//  DevicePicker.m
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "DevicePicker.h"
#import "DiscoveryProvider.h"

@implementation DevicePicker
{
    NSArray *_generatedDeviceList;
    NSArray *_actionSheetDeviceList;
    NSMutableDictionary *_devices;
    
    UINavigationController *_navigationController;
    UITableViewController *_tableViewController;
    UIPopoverController *_popover;
    UIActionSheet *_actionSheet;

    dispatch_queue_t _sortQueue;
}

- (instancetype) init
{
    self = [super init];

    if (self)
    {
        _sortQueue = dispatch_queue_create("Connect SDK Device Picker Sort", DISPATCH_QUEUE_SERIAL);
        _devices = [[NSMutableDictionary alloc] init];

        self.shouldAnimatePicker = YES;
    }

    return self;
}

- (void)setCurrentDevice:(ConnectableDevice *)currentDevice
{
    _currentDevice = currentDevice;

    [_tableViewController.tableView reloadData];
}

#pragma mark - Picker display methods

- (void) showPicker:(id)sender
{
    [self sortDevices];

    NSString *pickerTitle = NSLocalizedStringFromTable(@"Connect_SDK_Search_Title", @"ConnectSDKStrings", nil);

    _tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    _tableViewController.title = pickerTitle;
    _tableViewController.tableView.delegate = self;
    _tableViewController.tableView.dataSource = self;
    
    _navigationController = [[UINavigationController alloc] initWithRootViewController:_tableViewController];
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicator startAnimating];
    
    _tableViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        [self showPopover:sender];
    else
        [self showNavigation];
}

- (void) showPopover:(id)source
{
    _popover = [[UIPopoverController alloc] initWithContentViewController:_navigationController];
    _popover.delegate = self;
    
    if ([source isKindOfClass:[UIBarButtonItem class]])
    {
        [_popover presentPopoverFromBarButtonItem:source permittedArrowDirections:UIPopoverArrowDirectionAny animated:self.shouldAnimatePicker];
    } else if ([source isKindOfClass:[UIView class]])
    {
        UIView *sourceView = (UIView *)source;
        [_popover presentPopoverFromRect:sourceView.frame inView:sourceView.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:self.shouldAnimatePicker];
    } else
    {
        NSLog(@"DevicePicker::showPicker sender should be a subclass of either UIBarButtonItem or UIView");
        
        [self cleanupViews];
    }
}

- (void) showActionSheet:(id)sender
{
    NSString *pickerTitle = NSLocalizedStringFromTable(@"Connect_SDK_Search_Title", @"ConnectSDKStrings", nil);
    NSString *pickerCancel = NSLocalizedStringFromTable(@"Connect_SDK_Search_Cancel", @"ConnectSDKStrings", nil);

    _actionSheet = [[UIActionSheet alloc] initWithTitle:pickerTitle
                                                             delegate:self
                                                    cancelButtonTitle:pickerCancel
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];


    _actionSheetDeviceList = [_generatedDeviceList copy];

    [_actionSheetDeviceList enumerateObjectsUsingBlock:^(ConnectableDevice *device, NSUInteger idx, BOOL *stop)
    {
        [_actionSheet addButtonWithTitle:device.friendlyName];
    }];

    [_actionSheet showInView:sender];
}

- (void) showNavigation
{
    NSString *pickerCancel = NSLocalizedStringFromTable(@"Connect_SDK_Search_Cancel", @"ConnectSDKStrings", nil);

    _tableViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:pickerCancel style:UIBarButtonItemStylePlain target:self action:@selector(dismissPicker:)];
    
    UIWindow *mainWindow = [[UIApplication sharedApplication].windows firstObject];
    [mainWindow.rootViewController presentViewController:_navigationController animated:self.shouldAnimatePicker completion:nil];
}

- (void) dismissPicker:(id)sender
{
    if (_actionSheet)
    {
        [_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:YES];
    } else
    {
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
            [_popover dismissPopoverAnimated:_shouldAnimatePicker];
        else
            [_navigationController dismissViewControllerAnimated:_shouldAnimatePicker completion:nil];
    }

    [self cleanupViews];

    if (self.delegate && [self.delegate respondsToSelector:@selector(devicePicker:didCancelWithError:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate devicePicker:self didCancelWithError:nil];
        });
    }
}

#pragma mark - Helper methods

- (void) cleanupViews
{
    if (_tableViewController)
    {
        _tableViewController.tableView.delegate = nil;
        _tableViewController.tableView.dataSource = nil;
    }
    
    if (_popover)
        _popover.delegate = nil;

    if (_actionSheet)
        _actionSheet.delegate = nil;

    _actionSheet = nil;
    _actionSheetDeviceList = nil;
    _navigationController = nil;
    _tableViewController = nil;
    _popover = nil;
}

- (void) sortDevices
{
    dispatch_async(_sortQueue, ^{
        NSArray *devices = [_devices allValues];
    
        _generatedDeviceList = [devices sortedArrayUsingComparator:^NSComparisonResult(ConnectableDevice *device1, ConnectableDevice *device2) {
            NSString *device1Name = [[self nameForDevice:device1] lowercaseString];
            NSString *device2Name = [[self nameForDevice:device2] lowercaseString];

            return [device1Name compare:device2Name];
        }];
    });
}

- (NSString *) nameForDevice:(ConnectableDevice *)device
{
    NSString *name;
    
    if (device.serviceDescription.friendlyName && device.serviceDescription.friendlyName.length > 0)
        name = device.serviceDescription.friendlyName;
    else if (device.serviceDescription.address && device.serviceDescription.address.length > 0)
        name = device.serviceDescription.address;
    else
        name = NSLocalizedStringFromTable(@"Connect_SDK_Unnamed_Device", @"ConnectSDKStrings", nil);
    
    return name;
}

#pragma mark UIActionSheet methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;

    // Need to account for cancel button taking up the 0 index position
    NSUInteger realButtonIndex;

    if (actionSheet.cancelButtonIndex < _actionSheetDeviceList.count)
        realButtonIndex = (NSUInteger) (buttonIndex - 1);
    else
        realButtonIndex = (NSUInteger) buttonIndex;

    ConnectableDevice *device = [_actionSheetDeviceList objectAtIndex:realButtonIndex];

    if (![_generatedDeviceList containsObject:device])
    {
        NSLog(@"DevicePicker::actionSheet:clickedButtonAtIndex User selected a device that no longer exists");
        return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(devicePicker:didSelectDevice:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self.delegate devicePicker:self didSelectDevice:device];
        });
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self cleanupViews];
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
    [self dismissPicker:nil];
}

#pragma mark UITableViewDelegate methods

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ConnectableDevice *device = (ConnectableDevice *) [_generatedDeviceList objectAtIndex:indexPath.row];
    
    if (self.currentDevice)
    {
        if ([self.currentDevice.serviceDescription.address isEqualToString:device.serviceDescription.address])
            return;
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(devicePicker:didSelectDevice:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate devicePicker:self didSelectDevice:device];
        });
    }

    [self dismissPicker:self];
}

#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_generatedDeviceList)
        return _generatedDeviceList.count;
    else
        return 0;
}

static NSString *cellIdentifier = @"connectPickerCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];

    if ([_generatedDeviceList count] == 0)
        return cell;

    ConnectableDevice *device = (ConnectableDevice *) [_generatedDeviceList objectAtIndex:indexPath.row];
    NSString *deviceName = [self nameForDevice:device];
    [cell.textLabel setText:deviceName];
    [cell.detailTextLabel setText:[device connectedServiceNames]];
    
    if (self.currentDevice)
    {
        if ([self.currentDevice.serviceDescription.address isEqualToString:device.serviceDescription.address])
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        else
            [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    return cell;
}

#pragma mark - UIPopoverControllerDelegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(devicePicker:didCancelWithError:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate devicePicker:self didCancelWithError:nil];
        });
    }
    
    [self cleanupViews];
}

# pragma mark - DiscoveryManagerDelegate methods

- (void)discoveryManager:(DiscoveryManager *)manager didFindDevice:(ConnectableDevice *)device
{
    if (_devices)
    {
        [_devices setObject:device forKey:device.serviceDescription.UUID];

        [self sortDevices];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (_tableViewController)
                [_tableViewController.tableView reloadData];
        });
    }
}

- (void)discoveryManager:(DiscoveryManager *)manager didLoseDevice:(ConnectableDevice *)device
{
    if (_devices)
    {
        [_devices removeObjectForKey:device.serviceDescription.UUID];

        [self sortDevices];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (_tableViewController)
                [_tableViewController.tableView reloadData];
        });
    }
}

- (void)discoveryManager:(DiscoveryManager *)manager didUpdateDevice:(ConnectableDevice *)device
{
    if (_devices)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_tableViewController)
                [_tableViewController.tableView reloadData];
        });
    }
}

@end
