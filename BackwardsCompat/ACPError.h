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

#ifndef ADOBEMOBILE_ACPERROR_H
#define ADOBEMOBILE_ACPERROR_H

#import <Foundation/Foundation.h>

extern NSString* _Nonnull const ACPErrorDomain;

/**
 * @brief Errors that can be returned by either any of the 3rd party extension APIs.
 */
typedef NS_ENUM(NSUInteger, ACPError) {
    ACPErrorUnexpected = 0,
    ACPErrorCallbackTimeout = 1,
    ACPErrorCallbackNil = 2,
    ACPErrorExtensionNotInitialized = 11,
};


#endif /* ADOBEMOBILE_ACPERROR_H */

