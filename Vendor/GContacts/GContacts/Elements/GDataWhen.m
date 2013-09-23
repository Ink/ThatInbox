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
//  GDataWhen.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE \
  || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataWhen.h"

static NSString* const kValueAttr = @"valueString";
static NSString* const kStartTimeAttr = @"startTime";
static NSString* const kEndTimeAttr = @"endTime";

@implementation GDataWhen
// when element, as in
// <gd:when startTime="2005-06-06" endTime="2005-06-07" valueString="This weekend"/>
//
// http://code.google.com/apis/gdata/common-elements.html#gdWhen

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"when"; }

+ (GDataWhen *)whenWithStartTime:(GDataDateTime *)startTime
                         endTime:(GDataDateTime *)endTime {
  GDataWhen *obj = [self object];
  [obj setStartTime:startTime];
  [obj setEndTime:endTime];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:
                    kValueAttr, kStartTimeAttr, kEndTimeAttr, nil];
  [self addLocalAttributeDeclarations:attrs];
}

#pragma mark -

- (GDataDateTime *)startTime {
  return [self dateTimeForAttribute:kStartTimeAttr];
}

- (void)setStartTime:(GDataDateTime *)cdate {
  [self setDateTimeValue:cdate forAttribute:kStartTimeAttr];
}

- (GDataDateTime *)endTime {
  return [self dateTimeForAttribute:kEndTimeAttr];
}

- (void)setEndTime:(GDataDateTime *)cdate {
  [self setDateTimeValue:cdate forAttribute:kEndTimeAttr];
}

- (NSString *)value {
  return [self stringValueForAttribute:kValueAttr];
}

- (void)setValue:(NSString *)str {
  [self setStringValue:str forAttribute:kValueAttr];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE
