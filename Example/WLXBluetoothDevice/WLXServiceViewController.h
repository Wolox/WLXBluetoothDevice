//
//  WLXServiceViewController.h
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 11/12/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WLXDummyService.h"

@interface WLXServiceViewController : UIViewController

@property (nonatomic) WLXDummyService * service;

@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UIButton *notificationsButton;

- (IBAction)notificationsButtonPressed:(id)sender;

- (IBAction)readButtonPressed:(id)sender;

- (IBAction)writeButtonPressed:(id)sender;

@end
