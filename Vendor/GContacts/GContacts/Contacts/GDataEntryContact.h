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
//  GDataEntryContact.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataEntryContactBase.h"
#import "GDataGroupMembershipInfo.h"


@interface GDataEntryContact : GDataEntryContactBase

+ (GDataEntryContact *)contactEntryWithName:(GDataName *)obj;
+ (GDataEntryContact *)contactEntryWithFullNameString:(NSString *)str;

// contactEntryWithTitle is deprecated under version 3 of the contacts API
// because the unstructured "title" field has become read-only
+ (GDataEntryContact *)contactEntryWithTitle:(NSString *)title;

- (NSArray *)groupMembershipInfos;
- (void)setGroupMembershipInfos:(NSArray *)arr;
- (void)addGroupMembershipInfo:(GDataGroupMembershipInfo *)obj;
- (void)removeGroupMembershipInfo:(GDataGroupMembershipInfo *)obj;

- (GDataGroupMembershipInfo *)groupMembershipInfoWithHref:(NSString *)href;

// phonetic name - version 3 only
- (NSString *)yomi;
- (void)setYomi:(NSString *)str;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
