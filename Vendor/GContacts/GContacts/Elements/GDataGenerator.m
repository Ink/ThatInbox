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
//  GDataGenerator.m
//

#import "GDataGenerator.h"

static NSString* const kVersionAttr = @"version";
static NSString* const kURIAttr = @"uri";

@implementation GDataGenerator
// Feed generator element, as in
//   <generator version='1.0' uri='http://www.google.com/calendar/'>CL2</generator>

+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"generator"; }

+ (GDataGenerator *)generatorWithName:(NSString *)name
                              version:(NSString *)version
                                  URI:(NSString *)uri {
  GDataGenerator *obj = [self object];
  [obj setName:name];
  [obj setVersion:version];
  [obj setURI:uri];
  return obj;
}

- (void)addParseDeclarations {

  NSArray *attrs = [NSArray arrayWithObjects:
                    kVersionAttr, kURIAttr, nil];

  [self addLocalAttributeDeclarations:attrs];

  [self addContentValueDeclaration];
}

- (NSString *)name {
  return [self contentStringValue];
}

- (void)setName:(NSString *)str {
  [self setContentStringValue:str];
}

- (NSString *)version {
  return [self stringValueForAttribute:kVersionAttr];
}

- (void)setVersion:(NSString *)str {
  [self setStringValue:str forAttribute:kVersionAttr];
}

- (NSString *)URI {
  return [self stringValueForAttribute:kURIAttr];
}

- (void)setURI:(NSString *)str {
  [self setStringValue:str forAttribute:kURIAttr];
}

@end



