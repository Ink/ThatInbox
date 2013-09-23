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
//  GDataWhere.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE \
    || GDATA_INCLUDE_CONTACTS_SERVICE

#define GDATAWHERE_DEFINE_GLOBALS 1
#import "GDataWhere.h"

#import "GDataEntryLink.h"

static NSString* const kRelAttr = @"rel";
static NSString* const kValueStringAttr = @"valueString";
static NSString* const kLabelAttr = @"label";

@implementation GDataWhere
// where element, as in
// <gd:where rel="http://schemas.google.com/g/2005#event" valueString="Joe's Pub">
//    <gd:entryLink href="http://local.example.com/10018/JoesPub">
// </gd:where>
//
// http://code.google.com/apis/gdata/common-elements.html#gdWhere

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"where"; }

+ (GDataWhere *)whereWithString:(NSString *)str {
  GDataWhere* obj = [self object];
  [obj setStringValue:str];
  return obj;
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  [self addExtensionDeclarationForParentClass:[self class]
                                   childClass:[GDataEntryLink class]];
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:
                    kRelAttr, kValueStringAttr, kLabelAttr, nil];

  [self addLocalAttributeDeclarations:attrs];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {
  NSMutableArray *items = [super itemsForDescription];

  // add the entryLink extension to the description
  [self addToArray:items objectDescriptionIfNonNil:[self entryLink] withName:@"entryLink"];

  return items;
}
#endif

- (NSString *)rel {
  return [self stringValueForAttribute:kRelAttr];
}

- (void)setRel:(NSString *)str {
  [self setStringValue:str forAttribute:kRelAttr];
}

- (NSString *)label {
  return [self stringValueForAttribute:kLabelAttr];
}

- (void)setLabel:(NSString *)str {
  [self setStringValue:str forAttribute:kLabelAttr];
}

- (NSString *)stringValue {
  return [self stringValueForAttribute:kValueStringAttr];
}

- (void)setStringValue:(NSString *)str {
  [self setStringValue:str forAttribute:kValueStringAttr];
}

- (GDataEntryLink *)entryLink {
  return [self objectForExtensionClass:[GDataEntryLink class]];
}

- (void)setEntryLink:(GDataEntryLink *)entryLink {
  [self setObject:entryLink forExtensionClass:[GDataEntryLink class]];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_*_SERVICE
