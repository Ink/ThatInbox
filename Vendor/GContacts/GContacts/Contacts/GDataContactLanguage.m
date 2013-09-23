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
//  GDataContactLanguage.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataContactLanguage.h"

#import "GDataContactConstants.h"

static NSString* const kLabelAttr = @"label";
static NSString *const kCodeAttr = @"code";

@implementation GDataContactLanguage

+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"language"; }

+ (id)languageWithCode:(NSString *)code
                 label:(NSString *)label {
  
  GDataContactLanguage *obj = [self object];
  [obj setLabel:label];
  [obj setCode:code];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:kLabelAttr, kCodeAttr, nil];
  
  [self addLocalAttributeDeclarations:attrs];
}

#pragma mark -

- (NSString *)label {
  return [self stringValueForAttribute:kLabelAttr];
}

- (void)setLabel:(NSString *)str {
  [self setStringValue:str forAttribute:kLabelAttr];
}

- (NSString *)code {
  return [self stringValueForAttribute:kCodeAttr];
}

- (void)setCode:(NSString *)str {
  [self setStringValue:str forAttribute:kCodeAttr];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
