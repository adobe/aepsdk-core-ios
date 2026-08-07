/*
Copyright 2020 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/


#import "ViewController.h"
@import AEPCore;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self exerciseNetworkAvailabilityAPIs];
}

- (IBAction)testButtonClicked:(id)sender {
    [AEPMobileCore setAdvertisingIdentifier:@"adid"];
}

/// Exercises the Network Availability API exposed to Objective-C. `isNetworkAvailable` is the only
/// dedicated MobileCore entry point. There is no dedicated configuration API — a custom availability
/// check (e.g. pinging your own backend) is implemented by overriding `Networking` in Swift and
/// registering it via `ServiceProvider.shared.networkService`; `ServiceProvider` is not bridged to
/// Objective-C, so that override point is Swift-only (see `TestApp_Swift/NetworkAvailabilityView.swift`).
- (void)exerciseNetworkAvailabilityAPIs {
    BOOL isAvailable = [AEPMobileCore isNetworkAvailable];
    NSLog(@"[NetworkAvailability][ObjC] isNetworkAvailable = %d", isAvailable);
}

@end
