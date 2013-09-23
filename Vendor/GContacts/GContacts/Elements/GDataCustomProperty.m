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
//  GDataCustomProperty.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_MAPS_SERVICE

#import "GDataCustomProperty.h"

static NSString* const kNameAttr = @"name";
static NSString* const kTypeAttr = @"type";
static NSString* const kUnitAttr = @"unit";

@implementation GDataCustomProperty

// custom property element, like
//
//   <gd:customProperty name="milk" type="integer" unit="gallons">
//     5
//   </gd:customProperty>

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"customProperty"; }

+ (GDataCustomProperty *)customPropertyWithName:(NSString *)name
                                           type:(NSString *)type
                                          value:(NSString *)value
                                           unit:(NSString *)unit {

  GDataCustomProperty *obj = [self object];
  [obj setName:name];
  [obj setType:type];
  [obj setUnit:unit];
  [obj setValue:value];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:
                    kNameAttr, kTypeAttr, kUnitAttr, nil];
  [self addLocalAttributeDeclarations:attrs];

  [self addContentValueDeclaration];
}

#pragma mark -

- (NSString *)name {
  return [self stringValueForAttribute:kNameAttr];
}

- (void)setName:(NSString *)str {
  [self setStringValue:str forAttribute:kNameAttr];
}

- (NSString *)type {
  return [self stringValueForAttribute:kTypeAttr];
}

- (void)setType:(NSString *)str {
  [self setStringValue:str forAttribute:kTypeAttr];
}

- (NSString *)unit {
  return [self stringValueForAttribute:kUnitAttr];
}

- (void)setUnit:(NSString *)str {
  [self setStringValue:str forAttribute:kUnitAttr];
}

- (NSString *)value {
  return [self contentStringValue];
}

- (void)setValue:(NSString *)str {
  [self setContentStringValue:str];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_MAPS_SERVICE
