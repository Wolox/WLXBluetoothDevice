//
//  WLXConnectViewController.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/6/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import "WLXConnectViewController.h"

#import <WLXBluetoothDevice/WLXLinearReconnectionStrategy.h>
#import <WLXBluetoothDevice/WLXNullReconnectionStrategy.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceNotifications.h>

#import "WLXDiscoverViewController.h"
#import "WLXApplication.h"

static NSUInteger RECONNECTION_WAIT_TIME = 2000; //ms
static NSUInteger CONNECTION_TIMEOUT = 30000; //ms
static NSUInteger MAX_RECONNECTION_ATTEMPS = 3;

@interface WLXConnectViewController ()<WLXDiscoverViewControllerDelegate, WLXConnectionManagerDelegate>

@property (nonatomic) WLXBluetoothDeviceManager * deviceManager;
@property (nonatomic) id<WLXConnectionManager> connectionManager;
@property (nonatomic) WLXBluetoothDeviceRegistry * deviceRegistry;
@property (nonatomic) NSDateFormatter * dateFormatter;
@property (nonatomic) NSMutableArray * handlers;
@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) NSUInteger ramainingReconnectionAttemps;

@end

@implementation WLXConnectViewController

- (void)viewDidLoad {
    self.notificationCenter = [NSNotificationCenter defaultCenter];
    self.deviceManager = [WLXApplication sharedInstance].bluetoothDeviceManager;
    self.deviceRegistry = [WLXApplication sharedInstance].bluetoothDeviceRegistry;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    self.deviceRegistry.enabled = self.remeberDeviceSwitch.on;
}

- (void)viewWillAppear:(BOOL)animated {
    [self reloadUI];
    [self registerNotificationHandlers];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self unregisterNotificationHandlers];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"DiscoverDevicesSegue"]) {
        WLXDiscoverViewController * discoverViewController = segue.destinationViewController;
        discoverViewController.discoverer = self.deviceManager.discoverer;
        discoverViewController.delegate = self;
    }
}

#pragma mark - UI Events methods

- (IBAction)connectButtonPressed:(id)sender {
    if (self.connectionManager == nil && self.deviceRegistry.lastConnectedPeripheral != nil) {
        [self connectWithPeripheral:self.deviceRegistry.lastConnectedPeripheral];
    } else if (self.connectionManager.connected) {
        [self.connectionManager disconnect];
    } else {
        [self connect];
    }
}

#pragma mark - WLXDiscoverViewControllerDelegate methods

- (void)discoverViewController:(WLXDiscoverViewController *)viewController
           didSelectPeripheral:(CBPeripheral *)peripheral {
    [self.navigationController popViewControllerAnimated:YES];
    [self setConnectingStatus];
    [self connectWithPeripheral:peripheral];
}

#pragma mark - WLXConnectionManagerDelegate

- (void)connectionManagerDidConnect:(id<WLXConnectionManager>)connectionManager {
    [self reloadUIOnMainThread];
}

- (void)connectionManagerDidReconnect:(id<WLXConnectionManager>)connectionManager {
    [self reloadUIOnMainThread];
}

- (void)connectionManagerDidTerminateConnection:(id<WLXConnectionManager>)connectionManager {
    [self reloadUIOnMainThread];
}

- (void)connectionManager:(id<WLXConnectionManager>)connectionManager didFailToConnect:(NSError *)error {
    [self reloadUIOnMainThread];
    [self showConnectionErrorAlert:error];
}

- (void)connectionManager:(id<WLXConnectionManager>)connectionManager didLostConnection:(NSError *)error {
    [self reloadUIOnMainThread];
    [self showConnectionErrorAlert:error];
}

- (void)connectionManager:(id<WLXConnectionManager>)connectionManager willAttemptToReconnect:(NSUInteger)remainingReconnectionAttemps {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadUI];
        self.statusLabel.text = [NSString stringWithFormat:@"Reconnecting ... (%d/%d)",
                                 (int)remainingReconnectionAttemps, (int)MAX_RECONNECTION_ATTEMPS];
    });
}

#pragma mark - Private methods

- (void)reloadUIOnMainThread {
    [self performSelectorOnMainThread:@selector(reloadUI) withObject:nil waitUntilDone:NO];
}

- (void)setDisconnectedStatus {
    self.statusLabel.text = @"Disconnected";
    [self.connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    self.reconnectSwitch.enabled = YES;
    WLXBluetoothDeviceConnectionRecord * record = self.deviceRegistry.lastConnectionRecord;
    if (self.connectionManager || record) {
        self.connectButton.enabled = YES;
        [self.connectButton setBackgroundColor:[UIColor greenColor]];
        [self configureUIWithRecord:record];
    } else {
        self.connectButton.enabled = NO;
        [self.connectButton setBackgroundColor:[UIColor grayColor]];
    }
}

- (void)setConnectedStatus {
    self.connectButton.enabled = YES;
    [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    [self.connectButton setBackgroundColor:[UIColor redColor]];
    self.statusLabel.text = @"Connected";
    self.deviceNameLabel.text = self.connectionManager.peripheral.name;
    self.deviceUUIDLabel.text = self.connectionManager.peripheralUUID;
    self.reconnectSwitch.enabled = NO;
}

- (void)setConnectingStatus {
    [self setDisconnectedStatus];
    self.statusLabel.text = @"Connecting ...";
    // Show spinner with Connecting ...
}

- (void)configureUIWithRecord:(WLXBluetoothDeviceConnectionRecord *)record {
    self.deviceNameLabel.text = record.name;
    self.deviceUUIDLabel.text = record.UUID;
    self.lastConnectionDateLabel.text = [self.dateFormatter stringFromDate:record.connectionDate];
}

- (void)reloadUI {
    self.discoverButton.enabled = self.deviceManager.bluetoothOn;
    self.connectButton.enabled = self.deviceManager.bluetoothOn;
    if (self.connectionManager.connected) {
        [self setConnectedStatus];
    } else {
        [self setDisconnectedStatus];
    }
}

- (void)connectWithPeripheral:(CBPeripheral *)peripheral {
    self.connectionManager = [self.deviceManager connectionManagerForPeripheral:peripheral
                                                      usingReconnectionStrategy:[self newReconnectionStrategy]];
    self.connectionManager.delegate = self;
    [self connect];
}

- (id<WLXReconnectionStrategy>)newReconnectionStrategy {
    id<WLXReconnectionStrategy> reconnectionStrategy;
    if (self.reconnectSwitch.on) {
        reconnectionStrategy = [[WLXLinearReconnectionStrategy alloc] initWithWaitTime:RECONNECTION_WAIT_TIME
                                                               maxReconnectionAttempts:MAX_RECONNECTION_ATTEMPS
                                                                     connectionTimeout:3000
                                                                                 queue:self.deviceManager.queue];
    } else {
        reconnectionStrategy = [[WLXNullReconnectionStrategy alloc] init];
    }
    return reconnectionStrategy;
}

- (void)connect {
    self.deviceRegistry.enabled = self.remeberDeviceSwitch.on;
    [self.connectionManager connectWithTimeout:CONNECTION_TIMEOUT];
    [self reloadUI];
}

- (void)registerNotificationHandlers {
    __block typeof(self) this = self;
    id handler = [self.notificationCenter addObserverForName:WLXBluetoothDeviceBluetoothPowerStatusChanged
                                                      object:nil queue:nil usingBlock:^(NSNotification * notification){
        [this reloadUIOnMainThread];
    }];
    [self.handlers addObject:handler];
}


- (void)unregisterNotificationHandlers {
    for (id handler in self.handlers) {
        [self.notificationCenter removeObserver:handler];
    }
}

- (void)showConnectionErrorAlert:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Connection error"
                                message:[NSString stringWithFormat:@"There was an error with the connection: %@", error]
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

@end
