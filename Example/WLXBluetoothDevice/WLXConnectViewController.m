//
//  WLXConnectViewController.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/6/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import "WLXConnectViewController.h"

#import "WLXDiscoverViewController.h"
#import "WLXApplication.h"
#import "WLXServiceViewController.h"
#import "WLXDummyService.h"

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
    if ([self isTestMode]) {
        return;
    }
    self.notificationCenter = [NSNotificationCenter defaultCenter];
    self.deviceManager = [WLXApplication sharedInstance].bluetoothDeviceManager;
    self.deviceRegistry = [WLXApplication sharedInstance].bluetoothDeviceRegistry;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    self.deviceRegistry.enabled = self.remeberDeviceSwitch.on;
    self.servicesButton.layer.borderWidth = 1.0f;
    self.servicesButton.layer.borderColor = [UIColor blackColor].CGColor;
}

- (void)viewWillAppear:(BOOL)animated {
    if ([self isTestMode]) {
        return;
    }
    [self reloadUI];
    [self registerNotificationHandlers];
}

- (void)viewWillDisappear:(BOOL)animated {
    if ([self isTestMode]) {
        return;
    }
    [self unregisterNotificationHandlers];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"DiscoverDevicesSegue"]) {
        WLXDiscoverViewController * discoverViewController = segue.destinationViewController;
        discoverViewController.discoverer = self.deviceManager.discoverer;
        discoverViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"ShowServiceSegue"]) {
        WLXServiceViewController * controller = segue.destinationViewController;
        WLXServiceManager * serviceManager = [self.connectionManager.servicesManager managerForService:[WLXDummyService serviceUUID]];
        controller.service = [[WLXDummyService alloc] initWithServiceManager:serviceManager];
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
    self.servicesButton.enabled = NO;
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
    self.deviceNameLabel.text = self.connectionManager.peripheral.name;
    self.deviceUUIDLabel.text = self.connectionManager.peripheralUUID;
    self.reconnectSwitch.enabled = NO;
    self.servicesButton.enabled = NO;
    if (self.connectionManager.servicesManager.servicesDiscovered) {
        self.statusLabel.text = @"Ready";
        CBUUID * UUID = [WLXDummyService serviceUUID];
        WLXServiceManager * serviceManager = [self.connectionManager.servicesManager managerForService:UUID];
        if (serviceManager == nil) {
            NSLog(@"ERROR: Dummy service %@ is not available", UUID.UUIDString);
        } else {
            self.servicesButton.enabled = YES;
        }
    } else if (self.connectionManager.servicesManager.discovering) {
        self.statusLabel.text = @"Discovering services ...";
    } else {
        self.statusLabel.text = @"Connected";
    }
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
    __block typeof(self) this = self;
    [self.connectionManager connectAndDiscoverServicesWithTimeout:CONNECTION_TIMEOUT usingBlock:^(NSError * error) {
        if (error) {
            [this showConnectionErrorAlert:error];
        } else {
            [self reloadUIOnMainThread];
        }
    }];
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

- (void)showServiceDiscoveryErrorAlert:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Services discovery error"
                                message:[NSString stringWithFormat:@"There was an error discovering the services: %@", error]
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (BOOL)isTestMode {
    NSDictionary* environment = [[NSProcessInfo processInfo] environment];
    return [environment objectForKey:@"TEST"] != nil;
}


@end
