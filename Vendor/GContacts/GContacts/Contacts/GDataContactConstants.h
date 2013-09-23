/* Copyright (c) 2009 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  GDataContactConstants.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import <Foundation/Foundation.h>

#import "GDataDefines.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATACONTACTCONSTANTS_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataContactServiceV2 _INITIALIZE_AS(@"2.0");
_EXTERN NSString* const kGDataContactServiceV3 _INITIALIZE_AS(@"3.0");
_EXTERN NSString* const kGDataContactDefaultServiceVersion _INITIALIZE_AS(@"3.0");

_EXTERN NSString* const kGDataNamespaceContact       _INITIALIZE_AS(@"http://schemas.google.com/contact/2008");
_EXTERN NSString* const kGDataNamespaceContactPrefix _INITIALIZE_AS(@"gContact");

_EXTERN NSString* const kGDataCategoryContact        _INITIALIZE_AS(@"http://schemas.google.com/contact/2008#contact");
_EXTERN NSString* const kGDataCategoryContactGroup   _INITIALIZE_AS(@"http://schemas.google.com/contact/2008#group");
_EXTERN NSString* const kGDataCategoryContactProfile _INITIALIZE_AS(@"http://schemas.google.com/contact/2008#profile");

// rel values
_EXTERN NSString* const kGDataContactHome    _INITIALIZE_AS(@"http://schemas.google.com/g/2005#home");
_EXTERN NSString* const kGDataContactWork    _INITIALIZE_AS(@"http://schemas.google.com/g/2005#work");
_EXTERN NSString* const kGDataContactOther   _INITIALIZE_AS(@"http://schemas.google.com/g/2005#other");

// link rel values
_EXTERN NSString* const kGDataContactPhotoRel     _INITIALIZE_AS(@"http://schemas.google.com/contacts/2008/rel#photo");
_EXTERN NSString* const kGDataContactEditPhotoRel _INITIALIZE_AS(@"http://schemas.google.com/contacts/2008/rel#edit-photo"); // v1 only


@interface GDataContactConstants : NSObject

+ (NSString *)coreProtocolVersionForServiceVersion:(NSString *)serviceVersion;

+ (NSDictionary *)contactNamespaces;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
