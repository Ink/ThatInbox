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
//  GDataContactLink.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataContactLink.h"

#import "GDataEntryContact.h" // for namespace

static NSString* const kRelAttr = @"rel";
static NSString* const kLabelAttr = @"label";
static NSString* const kHrefAttr = @"href";
static NSString* const kPrimaryAttr = @"primary";

@implementation GDataContactLink

+ (id)linkWithRel:(NSString *)rel
            label:(NSString *)label
             href:(NSString *)href {
  
  GDataContactLink *obj = [self object];
  [obj setRel:rel];
  [obj setLabel:label];
  [obj setHref:href];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects: 
                    kHrefAttr, kLabelAttr, kRelAttr, kPrimaryAttr, nil];
  
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

- (NSString *)href {
  return [self stringValueForAttribute:kHrefAttr]; 
}

- (void)setHref:(NSString *)str {
  [self setStringValue:str forAttribute:kHrefAttr];
}

- (BOOL)isPrimary {
  return [self boolValueForAttribute:kPrimaryAttr defaultValue:NO]; 
}

- (void)setIsPrimary:(BOOL)flag {
  [self setBoolValue:flag defaultValue:NO forAttribute:kPrimaryAttr];
}
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
