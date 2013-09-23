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
//  GDataFeedContact.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataFeedContact.h"

#import "GDataEntryContact.h"
#import "GDataWhere.h"
#import "GDataCategory.h"
#import "GDataContactConstants.h"

@implementation GDataFeedContact

+ (NSString *)coreProtocolVersionForServiceVersion:(NSString *)serviceVersion {
  return [GDataContactConstants coreProtocolVersionForServiceVersion:serviceVersion];
}

+ (NSString *)standardFeedKind {
  return kGDataCategoryContact;
}

+ (void)load {
  [self registerFeedClass];
}

+ (GDataFeedContact *)contactFeed {
  GDataFeedContact *obj = [self object];

  [obj setNamespaces:[GDataContactConstants contactNamespaces]];

  return obj;
}

- (void)addExtensionDeclarations {
  
  [super addExtensionDeclarations];
  
  Class feedClass = [self class];
  [self addExtensionDeclarationForParentClass:feedClass
                                   childClass:[GDataWhere class]];  
}

- (Class)classForEntries {
  return [GDataEntryContact class];
}

+ (NSString *)defaultServiceVersion {
  return kGDataContactDefaultServiceVersion;
}

#pragma mark -

- (NSArray *)entriesWithGroupHref:(NSString *)href {

  NSArray *entries = [self entries];
  NSMutableArray *array = [NSMutableArray array];

  for (GDataEntryContact *entry in entries) {

    if ([entry groupMembershipInfoWithHref:href] != nil) {
      [array addObject:entry];
    }
  }

  return array;
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
