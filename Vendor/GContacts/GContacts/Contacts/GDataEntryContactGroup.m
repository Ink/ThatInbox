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
//  GDataEntryContactGroup.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#define GDATAENTRYCONTACTGROUP_DEFINE_GLOBALS 1
#import "GDataEntryContactGroup.h"

#import "GDataContactConstants.h"

// system group identifier, like <gContact:systemGroup id="Contacts"/>
@implementation GDataContactSystemGroup
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"systemGroup"; }

- (NSString *)attributeName {
  return @"id";
}

- (NSString *)identifier {
  return [self stringValue];
}

- (void)setIdentifier:(NSString *)str {
  [self setStringValue:str]; 
}
@end


@implementation GDataEntryContactGroup

+ (NSString *)coreProtocolVersionForServiceVersion:(NSString *)serviceVersion {
  return [GDataContactConstants coreProtocolVersionForServiceVersion:serviceVersion];
}

+ (GDataEntryContactGroup *)contactGroupEntryWithTitle:(NSString *)title {
  GDataEntryContactGroup *obj = [self object];
  
  [obj setNamespaces:[GDataContactConstants contactNamespaces]];
  
  [obj setTitleWithString:title];
  return obj;
}

#pragma mark -

+ (NSString *)standardEntryKind {
  return kGDataCategoryContactGroup;
}

+ (void)load {
  [self registerEntryClass];
}

- (void)addExtensionDeclarations {
  
  [super addExtensionDeclarations];
  
  Class entryClass = [self class];
  
  // ContactEntry extensions
  
  [self addExtensionDeclarationForParentClass:entryClass
                                 childClasses:
   [GDataExtendedProperty class],
   [GDataContactSystemGroup class],
   nil];  
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {
  
  static struct GDataDescriptionRecord descRecs[] = {
    { @"systemGroup", @"systemGroup.identifier", kGDataDescValueLabeled },
    { @"extProps",    @"extendedProperties",     kGDataDescArrayCount },
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

- (NSArray *)extendedProperties {
  return [self objectsForExtensionClass:[GDataExtendedProperty class]];
}

- (void)setExtendedProperties:(NSArray *)arr {
  [self setObjects:arr forExtensionClass:[GDataExtendedProperty class]];
}

- (void)addExtendedProperty:(GDataExtendedProperty *)obj {
  [self addObject:obj forExtensionClass:[GDataExtendedProperty class]];
}

- (GDataContactSystemGroup *)systemGroup {
  return [self objectForExtensionClass:[GDataContactSystemGroup class]];
}

- (void)setSystemGroup:(GDataContactSystemGroup *)obj {
  [self setObject:obj forExtensionClass:[GDataContactSystemGroup class]];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
