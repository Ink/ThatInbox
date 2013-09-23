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
//  GDataEntryContact.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataEntryContact.h"
#import "GDataContactConstants.h"

// phonetic name
@interface GDataContactYomiName : GDataValueElementConstruct <GDataExtension>
@end
 
@implementation GDataContactYomiName
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"yomiName"; }
@end

@implementation GDataEntryContact

+ (GDataEntryContact *)contactEntryWithName:(GDataName *)name {

  GDataEntryContact *obj = [self object];
  [obj setNamespaces:[GDataContactConstants contactNamespaces]];
  [obj setName:name];
  return obj;
}

+ (GDataEntryContact *)contactEntryWithFullNameString:(NSString *)str {
  GDataName *name = [GDataName nameWithFullNameString:str];
  GDataEntryContact *obj = [self contactEntryWithName:name];
  return obj;
}

+ (GDataEntryContact *)contactEntryWithTitle:(NSString *)title {

  GDataEntryContact *obj = [self object];

  [obj setNamespaces:[GDataContactConstants contactNamespaces]];

  [obj setTitleWithString:title];
  return obj;
}

#pragma mark -

+ (NSString *)standardEntryKind {
  return kGDataCategoryContact;
}

+ (void)load {
  [self registerEntryClass];
}

- (void)addExtensionDeclarations {
  
  [super addExtensionDeclarations];

  // ContactEntry extensions

  Class entryClass = [self class];
  [self addExtensionDeclarationForParentClass:entryClass
                                 childClasses:
   [GDataGroupMembershipInfo class],
   nil];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {

  static struct GDataDescriptionRecord descRecs[] = {
    { @"group",           @"groupMembershipInfos", kGDataDescArrayDescs   },
    { @"version>=3:yomi", @"yomi",                 kGDataDescValueLabeled },
    { nil, nil, (GDataDescRecTypes)0 }
  };
  
  NSMutableArray *items = [super itemsForDescription];
  [self addDescriptionRecords:descRecs toItems:items];
  return items;
}
#endif

+ (NSString *)defaultServiceVersion {
  return kGDataContactDefaultServiceVersion;
}

#pragma mark -

- (NSString *)yomi {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactYomiName *obj = [self objectForExtensionClass:[GDataContactYomiName class]];
  return [obj stringValue];
}

- (void)setYomi:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactYomiName *obj = nil;
  if ([str length] > 0) {
    obj = [GDataContactYomiName valueWithString:str];
  }
  [self setObject:obj forExtensionClass:[GDataContactYomiName class]]; 
}


- (NSArray *)groupMembershipInfos {
  return [self objectsForExtensionClass:[GDataGroupMembershipInfo class]];
}

- (void)setGroupMembershipInfos:(NSArray *)arr {
  [self setObjects:arr forExtensionClass:[GDataGroupMembershipInfo class]];
}

- (void)addGroupMembershipInfo:(GDataGroupMembershipInfo *)obj {
  [self addObject:obj forExtensionClass:[GDataGroupMembershipInfo class]];
}

- (void)removeGroupMembershipInfo:(GDataGroupMembershipInfo *)obj {
  [self removeObject:obj forExtensionClass:[GDataGroupMembershipInfo class]];
}
#pragma mark -

- (GDataGroupMembershipInfo *)groupMembershipInfoWithHref:(NSString *)href {
  GDataGroupMembershipInfo *groupInfo;
  
  groupInfo = [GDataUtilities firstObjectFromArray:[self groupMembershipInfos]
                                         withValue:href
                                        forKeyPath:@"href"];
  return groupInfo;
}
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
