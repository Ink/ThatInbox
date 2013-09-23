/* Copyright (c) 2007 Google Inc.
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
//  GDataIM.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#define GDATAIM_DEFINE_GLOBALS 1
#import "GDataIM.h"

static NSString* const kRelAttr = @"rel";
static NSString* const kLabelAttr = @"label";
static NSString* const kAddressAttr = @"address";
static NSString* const kProtocolAttr = @"protocol";
static NSString* const kPrimaryAttr = @"primary";

@implementation GDataIM
// IM element, as in
//   <gd:im protocol="http://schemas.google.com/g/2005#MSN"
//      address="foo@bar.example.com" label="Alternate"
//      rel="http://schemas.google.com/g/2005#other" >
//
// http://code.google.com/apis/gdata/common-elements.html#gdIm

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"im"; }

+ (GDataIM *)IMWithProtocol:(NSString *)protocol
                        rel:(NSString *)rel
                      label:(NSString *)label
                    address:(NSString *)address {

  GDataIM *obj = [self object];
  [obj setProtocol:protocol];
  [obj setRel:rel];
  [obj setLabel:label];
  [obj setAddress:address];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:
                    kAddressAttr, kProtocolAttr, kLabelAttr, kRelAttr,
                    kPrimaryAttr, nil];

  [self addLocalAttributeDeclarations:attrs];
}

- (NSArray *)attributesIgnoredForEquality {

  return [NSArray arrayWithObject:kPrimaryAttr];
}

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

- (NSString *)address {
  return [self stringValueForAttribute:kAddressAttr];
}

- (void)setAddress:(NSString *)str {
  [self setStringValue:str forAttribute:kAddressAttr];
}

- (NSString *)protocol {
  return [self stringValueForAttribute:kProtocolAttr];
}

- (void)setProtocol:(NSString *)str {
  [self setStringValue:str forAttribute:kProtocolAttr];
}

- (BOOL)isPrimary {
  return [self boolValueForAttribute:kPrimaryAttr defaultValue:NO];
}

- (void)setIsPrimary:(BOOL)flag {
  [self setBoolValue:flag defaultValue:NO forAttribute:kPrimaryAttr];
}
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
