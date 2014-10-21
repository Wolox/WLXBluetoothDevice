//
//  WLXDiscoverViewController.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/6/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import "WLXDiscoverViewController.h"

#import <WLXBluetoothDevice/WLXBluetoothDeviceNotifications.h>

@import CoreBluetooth;

@interface WLXDiscoverViewController ()<UIAlertViewDelegate, WLXDeviceDiscovererDelegate>

@end

static NSUInteger DISCOVERY_TIMEOUT = 30000; //ms

@implementation WLXDiscoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    self.discoverer.delegate = self;
    [self discover];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.discoverer stopDiscoveringDevices];
}

#pragma mark - UI Events

- (IBAction)refreshButtonPressed:(id)sender {
    [self discover];
}

#pragma mark - WLXDeviceDiscovererDelegate methods

- (void)deviceDiscoverer:(id<WLXDeviceDiscoverer>)discoverer startDiscoveringDevicesWithTimeout:(NSUInteger)timeout {
    
}

- (void)deviceDiscoverer:(id<WLXDeviceDiscoverer>)discoverer discoveredDevice:(WLXDeviceDiscoveryData *)discoveryData {
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)deviceDiscovererStopDiscoveringDevices:(id<WLXDeviceDiscoverer>)discoverer {
    [self performSelectorOnMainThread:@selector(setReadyToDiscover) withObject:nil waitUntilDone:NO];
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBPeripheral * peripheral = [self peripheralForIndexPath:indexPath];
    [self.delegate discoverViewController:self didSelectPeripheral:peripheral];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.discoverer.discoveredDevices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    CBPeripheral * peripheral = [self peripheralForIndexPath:indexPath];
    cell.textLabel.text = peripheral.name;
    cell.detailTextLabel.text = peripheral.identifier.UUIDString;
    return cell;
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case 1:
            [self discover];
            break;
        default:
            break;
    }
}

#pragma mark - Private methods

- (void)discover {
    self.title = @"Discovering ...";
    [self.discoverer discoverDevicesNamed:nil withServices:nil andTimeout:DISCOVERY_TIMEOUT];
    self.refreshButton.enabled = NO;
}

- (CBPeripheral *)peripheralForIndexPath:(NSIndexPath *)indexPath {
    WLXDeviceDiscoveryData * discoveryData = self.discoverer.discoveredDevices[indexPath.row];
    return discoveryData.peripheral;
}

- (void)showRediscoverDevicesAlert {
    [[[UIAlertView alloc] initWithTitle:@"No visible devices"
                                message:@"There are no devices advertising. Do you want to discover again?"
                               delegate:self
                      cancelButtonTitle:@"NO"
                      otherButtonTitles:@"YES", nil] show];
}

- (void)setReadyToDiscover {
    self.title = @"Discover";
    self.refreshButton.enabled = YES;
}

@end
