//
//  WLXConnectViewController.h
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/6/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLXConnectViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceUUIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastConnectionDateLabel;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UISwitch *reconnectSwitch;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *discoverButton;
@property (weak, nonatomic) IBOutlet UISwitch *remeberDeviceSwitch;

- (IBAction)connectButtonPressed:(id)sender;

@end
