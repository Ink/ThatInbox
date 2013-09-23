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
//  GDataContactUserDefinedField.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataContactUserDefinedField.h"

#import "GDataContactConstants.h"

@implementation GDataContactUserDefinedField

+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"userDefinedField"; }

+ (id)userDefinedFieldWithKey:(NSString *)key
                        value:(NSString *)value {

  GDataContactUserDefinedField *obj;

  obj = [self object];
  [obj setKey:key];
  [obj setStringValue:value];
  return obj;
}

- (NSString *)nameAttributeName {
  return @"key";
}

#pragma mark -

- (NSString *)key {
  return [self name];
}

- (void)setKey:(NSString *)str {
  [self setName:str];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
