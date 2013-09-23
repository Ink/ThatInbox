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
//  GDataPhoneNumber.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#define GDATAPHONENUMBER_DEFINE_GLOBALS 1
#import "GDataPhoneNumber.h"

static NSString* const kRelAttr = @"rel";
static NSString* const kLabelAttr = @"label";
static NSString* const kURIAttr = @"uri";
static NSString* const kPrimaryAttr = @"primary";

@implementation GDataPhoneNumber
// phone number, as in
//  <gd:phoneNumber rel="http://schemas.google.com/g/2005#work" uri="tel:+1-425-555-8080;ext=52585">
//    (425) 555-8080 ext. 52585
//  </gd:phoneNumber>
//
// http://code.google.com/apis/gdata/common-elements.html#gdPhoneNumber

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"phoneNumber"; }

+ (GDataPhoneNumber *)phoneNumberWithString:(NSString *)str {
  GDataPhoneNumber *obj = [self object];
  [obj setStringValue:str];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:
                    kLabelAttr, kRelAttr, kURIAttr, kPrimaryAttr, nil];

  [self addLocalAttributeDeclarations:attrs];

  [self addContentValueDeclaration];
}

- (NSArray *)attributesIgnoredForEquality {

  return [NSArray arrayWithObject:kPrimaryAttr];
}

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

- (NSString *)URI {
  return [self stringValueForAttribute:kURIAttr];
}

- (void)setURI:(NSString *)str {
  [self setStringValue:str forAttribute:kURIAttr];
}

- (NSString *)stringValue {
  return [self contentStringValue];
}

- (void)setStringValue:(NSString *)str {
  [self setContentStringValue:str];
}

- (BOOL)isPrimary {
  return [self boolValueForAttribute:kPrimaryAttr defaultValue:NO];
}

- (void)setIsPrimary:(BOOL)flag {
  [self setBoolValue:flag defaultValue:NO forAttribute:kPrimaryAttr];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
