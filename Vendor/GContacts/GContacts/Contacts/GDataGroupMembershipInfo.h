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
//  GDataGroupMembershipInfo.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"

//
// group membership info 
//
// <gContact:groupMembershipInfo href="http://..." />
//
// http://code.google.com/apis/contacts/reference.html#groupMembershipInfo

@interface GDataGroupMembershipInfo : GDataObject <GDataExtension> {
}

+ (GDataGroupMembershipInfo *)groupMembershipInfoWithHref:(NSString *)str;

- (NSString *)href;
- (void)setHref:(NSString *)str;

- (BOOL)isDeleted;
- (void)setIsDeleted:(BOOL)flag;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
