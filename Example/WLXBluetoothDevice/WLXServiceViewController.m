//
//  WLXServiceViewController.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 11/12/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import "WLXServiceViewController.h"

@interface WLXServiceViewController ()

@property (nonatomic) BOOL notificationsEnabled;
@property (nonatomic) id observer;
@property (nonatomic) NSUInteger value;

@end

@implementation WLXServiceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.logTextView.text = @"";
    [self.notificationsButton setTitle:@"Enable notifications" forState:UIControlStateNormal];
    self.notificationsEnabled = NO;
    self.value = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    __block typeof(self) this = self;
    self.observer = [self.service addObserverUsingBlock:^(NSError * error, NSUInteger value) {
        NSString * message;
        if (error) {
            message = [NSString stringWithFormat:@"Error reading notified value: %@\n", error];
        } else {
            message = [NSString stringWithFormat:@"Notified value: %lu\n", (unsigned long)value];
            this.value = value;
        }
        [this logMessage:message];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.service removeObserver:self.observer];
}

- (IBAction)notificationsButtonPressed:(id)sender {
    __block typeof(self) this = self;
    if (self.notificationsEnabled) {
        self.notificationsEnabled = NO;
        [self.notificationsButton setTitle:@"Enable notifications" forState:UIControlStateNormal];
        [self.service disableNotificationsUsingBlock:^(NSError * error) {
            if (error) {
                NSString * message = [NSString stringWithFormat:@"Error disabling notifications: %@\n", error];
                [this logMessage:message];
            }
        }];
    } else {
        self.notificationsEnabled = YES;
        [self.notificationsButton setTitle:@"Disable notifications" forState:UIControlStateNormal];
        [self.service enableNotificationsUsingBlock:^(NSError * error) {
            if (error) {
                NSString * message = [NSString stringWithFormat:@"Error enabling notifications: %@\n", error];
                [this logMessage:message];
            }
        }];
    }
}

- (IBAction)readButtonPressed:(id)sender {
    __block typeof(self) this = self;
    [self.service readValueUsingBlock:^(NSError * error, NSUInteger value) {
        NSString * message;
        if (error) {
            message = [NSString stringWithFormat:@"Error reading value: %@\n", error];
        } else {
            message = [NSString stringWithFormat:@"Read value: %lu\n", (unsigned long)value];
            this.value = value;
        }
        [this logMessage:message];
    }];
}

- (IBAction)writeButtonPressed:(id)sender {
    __block typeof(self) this = self;
    [self.service writeValue:++self.value usingBlock:^(NSError * error) {
        NSString * message;
        if (error) {
            message = [NSString stringWithFormat:@"Error writing value: %@\n", error];
        } else {
            message = [NSString stringWithFormat:@"Value %lu successfully written\n", (unsigned long)self.value];
        }
        [this logMessage:message];
    }];
}

#pragma mark - Private methods 

- (void)logMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logTextView.text = [self.logTextView.text stringByAppendingString:message];
    });
}

@end
