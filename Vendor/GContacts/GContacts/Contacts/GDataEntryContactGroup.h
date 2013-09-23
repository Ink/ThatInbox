/* Copyright (c) 2008 Google Inc.
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
//  GDataEntryContactGroup.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataEntryBase.h"
#import "GDataExtendedProperty.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATAENTRYCONTACTGROUP_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

// for a contact groups feed, use these constants with -entryForSystemGroupID
// to find a specific system group entry
_EXTERN NSString* const kGDataSystemGroupIDMyContacts _INITIALIZE_AS(@"Contacts");
_EXTERN NSString* const kGDataSystemGroupIDFriends    _INITIALIZE_AS(@"Friends");
_EXTERN NSString* const kGDataSystemGroupIDFamily     _INITIALIZE_AS(@"Family");
_EXTERN NSString* const kGDataSystemGroupIDCoworkers  _INITIALIZE_AS(@"Coworkers");


// system group identifier, like <gContact:systemGroup id="Contacts"/>
@interface GDataContactSystemGroup : GDataValueConstruct <GDataExtension>
- (NSString *)attributeName; // returns "id"

- (NSString *)identifier;
- (void)setIdentifier:(NSString *)str;
@end

@interface GDataEntryContactGroup : GDataEntryBase

+ (GDataEntryContactGroup *)contactGroupEntryWithTitle:(NSString *)title;

- (GDataContactSystemGroup *)systemGroup;
- (void)setSystemGroup:(GDataContactSystemGroup *)obj;

- (NSArray *)extendedProperties;
- (void)setExtendedProperties:(NSArray *)arr;
- (void)addExtendedProperty:(GDataExtendedProperty *)obj;

// note: support for gd:deleted is in GDataEntryBase

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
