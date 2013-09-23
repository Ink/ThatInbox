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
//  GDataRating.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_BOOKS_SERVICE \
  || GDATA_INCLUDE_CALENDAR_SERVICE || GDATA_INCLUDE_YOUTUBE_SERVICE

#define GDATARATING_DEFINE_GLOBALS 1
#import "GDataRating.h"

static NSString* const kRelAttr = @"rel";
static NSString* const kValueAttr = @"value";
static NSString* const kMaxAttr = @"max";
static NSString* const kMinAttr = @"min";
static NSString* const kAverageAttr = @"average";
static NSString* const kNumRatersAttr = @"numRaters";

@implementation GDataRating
// rating, as in
//  <gd:rating rel="http://schemas.google.com/g/2005#price" value="5" min="1" max="5"/>
//
// http://code.google.com/apis/gdata/common-elements.html#gdRating

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"rating"; }

+ (GDataRating *)ratingWithValue:(NSInteger)value
                             max:(NSInteger)max
                             min:(NSInteger)min {
  GDataRating *obj = [self object];
  [obj setValue:[NSNumber numberWithInt:(int)value]];
  [obj setMax:[NSNumber numberWithInt:(int)max]];
  [obj setMin:[NSNumber numberWithInt:(int)min]];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:
                    kRelAttr, kValueAttr, kMaxAttr, kMinAttr,
                    kAverageAttr, kNumRatersAttr, nil];

  [self addLocalAttributeDeclarations:attrs];
}

#pragma mark -

- (NSString *)rel {
  return [self stringValueForAttribute:kRelAttr];
}

- (void)setRel:(NSString *)str {
  [self setStringValue:str forAttribute:kRelAttr];
}

- (NSNumber *)value {
  return [self intNumberForAttribute:kValueAttr];
}

- (void)setValue:(NSNumber *)num {
  [self setStringValue:[num stringValue] forAttribute:kValueAttr];
}

- (NSNumber *)max {
  return [self intNumberForAttribute:kMaxAttr];
}

- (void)setMax:(NSNumber *)num {
  [self setStringValue:[num stringValue] forAttribute:kMaxAttr];
}

- (NSNumber *)min {
  return [self intNumberForAttribute:kMinAttr];
}

- (void)setMin:(NSNumber *)num {
  [self setStringValue:[num stringValue] forAttribute:kMinAttr];
}

- (NSNumber *)average {
  return [self doubleNumberForAttribute:kAverageAttr];
}

- (void)setAverage:(NSNumber *)num {
  [self setStringValue:[num stringValue] forAttribute:kAverageAttr];
}

- (NSNumber *)numberOfRaters {
  return [self intNumberForAttribute:kNumRatersAttr];
}

- (void)setNumberOfRaters:(NSNumber *)num {
  [self setStringValue:[num stringValue] forAttribute:kNumRatersAttr];
}

@end

#endif // #if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_*_SERVICE
