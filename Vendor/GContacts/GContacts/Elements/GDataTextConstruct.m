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
//  GDataTextConstruct.m
//

#import "GDataTextConstruct.h"

static NSString* const kLangAttr = @"xml:lang";
static NSString* const kTypeAttr = @"type";

@implementation GDataTextConstruct
// For typed text, like: <title type="text">Event title</title>

+ (id)textConstructWithString:(NSString *)str {
  GDataTextConstruct *obj = [self object];
  [obj setStringValue:str];
  return obj;
}

// RFC4287 Sec 3.1 says that omitted type attributes are assumed to be
// "text", so we don't need to explicitly set it
// [self setType:@"text"];

- (void)addParseDeclarations {

  NSArray *attrs = [NSArray arrayWithObjects:
                    kTypeAttr, kLangAttr, nil];

  [self addLocalAttributeDeclarations:attrs];

  [self addContentValueDeclaration];
}

- (NSArray *)attributesIgnoredForEquality {

  // ignore the "type" attribute since we test for it uniquely below
  return [NSArray arrayWithObject:kTypeAttr];
}


- (BOOL)isTypeEqualToText:(NSString *)str {
  // internal utility routine
  return (str == nil)
    || [str isEqual:@"text"]
    || [str isEqual:@"text/plain"];
}

- (BOOL)isEqual:(GDataTextConstruct *)other {

  // override isEqual: to allow nil types to be considered equal to "text"
  return [super isEqual:other]

    // a missing type attribute is equal to "text" per RFC 4287 3.1.1
    //
    // consider them equal if both are some flavor of "text"

    && (AreEqualOrBothNil([self type], [other type])
        || ([self isTypeEqualToText:[self type]]
            && [self isTypeEqualToText:[other type]]));
}


- (NSString *)stringValue {
  return [self contentStringValue];
}

- (void)setStringValue:(NSString *)str {
  [self setContentStringValue:str];
}

- (NSString *)lang {
  return [self stringValueForAttribute:kLangAttr];
}

- (void)setLang:(NSString *)str {
  [self setStringValue:str forAttribute:kLangAttr];
}

- (NSString *)type {
  return [self stringValueForAttribute:kTypeAttr];
}

- (void)setType:(NSString *)str {
  [self setStringValue:str forAttribute:kTypeAttr];
}

@end

