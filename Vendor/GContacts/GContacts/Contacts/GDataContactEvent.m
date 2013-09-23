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
//  GDataContactEvent.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#define GDATACONTACTEVENT_DEFINE_GLOBALS 1
#import "GDataContactEvent.h"

#import "GDataContactConstants.h"

static NSString* const kRelAttr = @"rel";
static NSString* const kLabelAttr = @"label";

@implementation GDataContactEvent

+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"event"; }

+ (id)eventWithRel:(NSString *)rel
             label:(NSString *)label
              when:(GDataWhen *)when {

  GDataContactEvent *obj = [self object];
  [obj setRel:rel];
  [obj setLabel:label];
  [obj setWhen:when];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:
                    kLabelAttr, kRelAttr, nil];

  [self addLocalAttributeDeclarations:attrs];
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  [self addExtensionDeclarationForParentClass:[self class]
                                   childClass:[GDataWhen class]];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {

  NSMutableArray *items = [super itemsForDescription];

  [self addToArray:items objectDescriptionIfNonNil:[self when] withName:@"when"];

  return items;
}
#endif

#pragma mark -

- (NSString *)label {
  return [self stringValueForAttribute:kLabelAttr];
}

- (void)setLabel:(NSString *)str {
  [self setStringValue:str forAttribute:kLabelAttr];
}

- (NSString *)rel {
  return [self stringValueForAttribute:kRelAttr];
}

- (void)setRel:(NSString *)str {
  [self setStringValue:str forAttribute:kRelAttr];
}

- (GDataWhen *)when {
  return [self objectForExtensionClass:[GDataWhen class]];
}

- (void)setWhen:(GDataWhen *)obj {
  [self setObject:obj forExtensionClass:[GDataWhen class]];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
