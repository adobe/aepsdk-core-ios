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
@import AEPServices;

/// Minimal custom `AEPNetworkAvailabilityProviding` conformer, used to exercise
/// `+[AEPMobileCore setNetworkAvailabilityProvider:]` from Objective-C.
@interface ODCCustomNetworkAvailabilityProvider : NSObject <AEPNetworkAvailabilityProviding>
@end

@implementation ODCCustomNetworkAvailabilityProvider

@synthesize configuration;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.configuration = [[AEPNetworkAvailabilityConfiguration alloc] init];
    }
    return self;
}

- (BOOL)isNetworkAvailable {
    return YES;
}

- (void)checkNetworkAvailabilityWithCompletion:(void (^)(AEPNetworkAvailabilityResult * _Nonnull))completion {
    completion([[AEPNetworkAvailabilityResult alloc] initWithStatus:AEPNetworkAvailabilityStatusPathOnly]);
}

- (void)setPathProvider:(id<AEPNetworkPathAvailabilityProviding>)provider {
}

- (void)setHealthCheckProvider:(id<AEPNetworkHealthCheckProviding> _Nullable)provider {
}

- (void)resetToDefaults {
}

@end

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

/// Exercises every Network Availability API exposed to Objective-C.
- (void)exerciseNetworkAvailabilityAPIs {
    // 1. Synchronous check.
    BOOL isAvailable = [AEPMobileCore isNetworkAvailable];
    NSLog(@"[NetworkAvailability][ObjC] isNetworkAvailable = %d", isAvailable);

    // 2. Configure an optional remote health check (e.g. google.com).
    AEPNetworkHealthCheckConfiguration *healthCheck =
        [[AEPNetworkHealthCheckConfiguration alloc] initWithEndpoint:[NSURL URLWithString:@"https://www.google.com"]
                                                              timeout:3
                                                             cacheTTL:30
                                                  expectedStatusCodes:@[@200, @204]];
    AEPNetworkAvailabilityConfiguration *configuration =
        [[AEPNetworkAvailabilityConfiguration alloc] initWithHealthCheck:healthCheck
                                        requireHealthCheckWhenConfigured:YES];
    [AEPMobileCore setNetworkAvailabilityConfiguration:configuration];

    // 3. Asynchronous check with completion block.
    [AEPMobileCore checkNetworkAvailabilityWithCompletion:^(AEPNetworkAvailabilityResult * _Nonnull result) {
        NSLog(@"[NetworkAvailability][ObjC] checkNetworkAvailability status = %ld, isAvailable = %d",
              (long)result.status, result.isAvailable);
    }];

    // 4. Advanced: swap in a fully custom provider, then restore the default.
    ODCCustomNetworkAvailabilityProvider *customProvider = [[ODCCustomNetworkAvailabilityProvider alloc] init];
    [AEPMobileCore setNetworkAvailabilityProvider:customProvider];
    [AEPMobileCore resetNetworkAvailabilityProvider];
}

@end
