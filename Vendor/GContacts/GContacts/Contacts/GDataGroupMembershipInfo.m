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
//  GDataGroupMembershipInfo.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataGroupMembershipInfo.h" 
#import "GDataContactConstants.h"

static NSString* const kHrefAttr = @"href";
static NSString* const kDeletedAttr = @"deleted";

@implementation GDataGroupMembershipInfo 
//
// group membership info 
//
// <gContact:groupMembershipInfo href="http://..." />
//
// http://code.google.com/apis/contacts/reference.html#groupMembershipInfo

+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"groupMembershipInfo"; }

+ (GDataGroupMembershipInfo *)groupMembershipInfoWithHref:(NSString *)str {
  
  GDataGroupMembershipInfo *obj = [self object];
  [obj setHref:str];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:kHrefAttr, kDeletedAttr, nil];
  
  [self addLocalAttributeDeclarations:attrs];
}

#pragma mark -

- (NSString *)href {
  return [self stringValueForAttribute:kHrefAttr]; 
}

- (void)setHref:(NSString *)str {
  [self setStringValue:str forAttribute:kHrefAttr];
}

- (BOOL)isDeleted {
  return [self boolValueForAttribute:kDeletedAttr defaultValue:NO]; 
}

- (void)setIsDeleted:(BOOL)flag {
  [self setBoolValue:flag defaultValue:NO forAttribute:kDeletedAttr];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
