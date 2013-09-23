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
//  GDataContactExternalID.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATACONTACTEXTERNALID_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

// rel values
_EXTERN NSString* kGDataContactExternalIDAccount      _INITIALIZE_AS(@"account");
_EXTERN NSString* kGDataContactExternalIDCustomer     _INITIALIZE_AS(@"customer");
_EXTERN NSString* kGDataContactExternalIDNetwork      _INITIALIZE_AS(@"network");
_EXTERN NSString* kGDataContactExternalIDOrganization _INITIALIZE_AS(@"organization");

// TODO - XML example snippet

@interface GDataContactExternalID : GDataObject <GDataExtension>

+ (id)externalIDWithRel:(NSString *)rel
                  label:(NSString *)label
                  value:(NSString *)value;

- (NSString *)label;
- (void)setLabel:(NSString *)str;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
