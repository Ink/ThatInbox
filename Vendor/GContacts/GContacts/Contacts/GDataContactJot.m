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
//  GDataContactJot.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#define GDATACONTACTJOT_DEFINE_GLOBALS 1
#import "GDataContactJot.h"

#import "GDataContactConstants.h"

static NSString* const kRelAttr = @"rel";

@implementation GDataContactJot

+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"jot"; }

+ (id)jotWithRel:(NSString *)rel
           value:(NSString *)value {
  
  GDataContactJot *obj = [self object];
  [obj setRel:rel];
  [obj setStringValue:value];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObject:kRelAttr]; 
  [self addLocalAttributeDeclarations:attrs];
  
  [self addContentValueDeclaration];
}

#pragma mark -

- (NSString *)rel {
  return [self stringValueForAttribute:kRelAttr]; 
}

- (void)setRel:(NSString *)str {
  [self setStringValue:str forAttribute:kRelAttr];
}

- (NSString *)stringValue {
  return [self contentStringValue]; 
}

- (void)setStringValue:(NSString *)str {
  [self setContentStringValue:str];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
