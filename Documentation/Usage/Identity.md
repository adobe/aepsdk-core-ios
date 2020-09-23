# Identity API Usage

This document details all the APIs provided by Identity, along with sample code snippets on how to properly use the APIs.

For more in-depth information about the Identity extension, visit the [offical SDK documentation on Identity](https://aep-sdks.gitbook.io/docs/using-mobile-extensions/mobile-core/identity).

## API Usage

##### Append visitor data to a URL:

###### Swift

```swift
Identity.appendTo(url: URL(string: "yourUrl.com")) { (url, error) in
    // handle completion
}
```

###### Objective-C

```objective-c
[AEPMobileIdentity appendToUrl:[NSURL URLWithString:@"yourUrl.com"] completion:^(NSURL * _Nullable url, enum AEPError error) {
    // handle completion
}];
```

##### Get URL Variables:

###### Swift

```swift
Identity.getUrlVariables { (vars, error) in
    // handle completion
}
```

###### Objective-C

```objective-c
[AEPMobileIdentity getUrlVariables:^(NSString * _Nullable vars, enum AEPError error) {
    // handle completion
}];
```

##### Get Identifiers:

###### Swift

```swift
Identity.getIdentifiers { (ids, error) in
    // handle completion
}
```

###### Objective-C

```objective-c
[AEPMobileIdentity getIdentifiers:^(NSArray<id<AEPIdentifiable>> * _Nullable ids, enum AEPError error) {
    // handle completion
}];
```

##### Get Experience Cloud ID:

###### Swift

```swift
Identity.getExperienceCloudId { (exCloudId) in
    // handle completion
}
```

###### Objective-C

```objective-c
[AEPMobileIdentity getExperienceCloudId:^(NSString * _Nullable exCloudId) {
   // handle completion
}];
```

##### Sync Identifier:

###### Swift

```swift
Identity.syncIdentifier(identifierType: "id-type", identifier: "id", authenticationState: .authenticated)
```

###### Objective-C

```objective-c
[AEPMobileIdentity syncIdentifierWithType:@"id-type" identifier:@"id" authenticationState:AEPMobileVisitorAuthStateAuthenticated];
```

##### Sync Identifiers:

###### Swift

```swift
let identifiers : [String: String] = ["idType1":"idValue1",
                                      "idType2":"idValue2",
                                      "idType3":"idValue3"];
Identity.syncIdentifiers(identifiers: identifiers)
```

###### Objective-C

```objective-c
NSDictionary *identifiers = @{@"idType1":@"idValue1", 
                      @"idType2":@"idValue2", 
                      @"idType3":@"idValue3"};
[AEPMobileIdentity syncIdentifiers:identifiers];
```

##### Sync Identifiers with Authentication State:

###### Swift

```swift
let identifiers : [String: String] = ["idType1":"idValue1",
                                      "idType2":"idValue2",
                                      "idType3":"idValue3"];
Identity.syncIdentifiers(identifiers: identifiers, authenticationState: .authenticated)
```

###### Objective-C

```objective-c
NSDictionary *identifiers = @{@"idType1":@"idValue1", 
                      @"idType2":@"idValue2", 
                      @"idType3":@"idValue3"};
[AEPMobileIdentity syncIdentifiers:identifiers authenticationState:AEPMobileVisitorAuthStateAuthenticated];
```

##### 