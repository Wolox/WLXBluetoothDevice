//
//  WLXDiscoverViewController.h
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/6/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WLXDiscoverViewControllerDelegate.h"

@interface WLXDiscoverViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;

@property (nonatomic) id<WLXDeviceDiscoverer> discoverer;
@property (nonatomic) id<WLXDiscoverViewControllerDelegate> delegate;

- (IBAction)refreshButtonPressed:(id)sender;

@end
