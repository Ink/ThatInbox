/* Copyright (c) 2007-2008 Google Inc.
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
//  GDataWho.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE

#define GDATAWHO_DEFINE_GLOBALS 1
#import "GDataWho.h"

#import "GDataEntryLink.h"

@implementation GDataAttendeeStatus
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"attendeeStatus"; }
@end

@implementation GDataAttendeeType
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"attendeeType"; }
@end

static NSString* const kRelAttr = @"rel";
static NSString* const kValueStringAttr = @"valueString";
static NSString* const kEmailAttr = @"email";

@implementation GDataWho
// a who entry, as in
// <gd:who rel="http://schemas.google.com/g/2005#event.organizer" valueString="Fred Flintstone" email="fred@domain.com">
//   <gd:attendeeStatus value="http://schemas.google.com/g/2005#event.accepted"/>
// </gd:who>
//
// http://code.google.com/apis/gdata/common-elements.html#gdWho

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"who"; }

+ (GDataWho *)whoWithRel:(NSString *)rel
                    name:(NSString *)valueString
                   email:(NSString *)email {
  GDataWho *obj = [self object];
  [obj setRel:rel];
  [obj setStringValue:valueString];
  [obj setEmail:email];
  return obj;
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  Class elementClass = [self class];

  [self addExtensionDeclarationForParentClass:elementClass
                                   childClass:[GDataAttendeeType class]];
  [self addExtensionDeclarationForParentClass:elementClass
                                   childClass:[GDataAttendeeStatus class]];
  [self addExtensionDeclarationForParentClass:elementClass
                                   childClass:[GDataEntryLink class]];
}

- (void)addParseDeclarations {

  NSArray *attrs = [NSArray arrayWithObjects:
                    kRelAttr, kValueStringAttr, kEmailAttr, nil];

  [self addLocalAttributeDeclarations:attrs];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {
  NSMutableArray *items = [super itemsForDescription];

  // add extensions to the description
  [self addToArray:items objectDescriptionIfNonNil:[self attendeeType] withName:@"attendeeType"];
  [self addToArray:items objectDescriptionIfNonNil:[self attendeeStatus] withName:@"attendeeStatus"];
  [self addToArray:items objectDescriptionIfNonNil:[self entryLink] withName:@"entryLink"];

  return items;
}
#endif

#pragma mark -

- (NSString *)rel {
  return [self stringValueForAttribute:kRelAttr];
}

- (void)setRel:(NSString *)str {
  [self setStringValue:str forAttribute:kRelAttr];
}

- (NSString *)email {
  return [self stringValueForAttribute:kEmailAttr];
}

- (void)setEmail:(NSString *)str {
  [self setStringValue:str forAttribute:kEmailAttr];
}

- (NSString *)stringValue {
  return [self stringValueForAttribute:kValueStringAttr];
}

- (void)setStringValue:(NSString *)str {
  [self setStringValue:str forAttribute:kValueStringAttr];
}

- (GDataAttendeeType *)attendeeType {
  return [self objectForExtensionClass:[GDataAttendeeType class]];
}

- (void)setAttendeeType:(GDataAttendeeType *)val {
  [self setObject:val forExtensionClass:[GDataAttendeeType class]];
}

- (GDataAttendeeStatus *)attendeeStatus {
  return [self objectForExtensionClass:[GDataAttendeeStatus class]];
}

- (void)setAttendeeStatus:(GDataAttendeeStatus *)val {
  [self setObject:val forExtensionClass:[GDataAttendeeStatus class]];
}

- (GDataEntryLink *)entryLink {
  return [self objectForExtensionClass:[GDataEntryLink class]];
}

- (void)setEntryLink:(GDataEntryLink *)entryLink {
  [self setObject:entryLink forExtensionClass:[GDataEntryLink class]];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE
