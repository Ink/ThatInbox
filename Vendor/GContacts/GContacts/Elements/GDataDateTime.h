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
//  GDataDateTime.h
//

#import <Foundation/Foundation.h>
#import "GDataDefines.h"

@interface GDataDateTime : NSObject <NSCopying> {
  NSDateComponents *dateComponents_;
  NSInteger offsetSeconds_; // may be NSUndefinedDateComponent
  BOOL isUniversalTime_; // preserves "Z"
  NSTimeZone *timeZone_; // specific time zone by name, if known
}

// Note: Nil can be passed for time zone arguments when the time zone is not
//       known.

+ (GDataDateTime *)dateTimeWithRFC3339String:(NSString *)str;
+ (GDataDateTime *)dateTimeWithDate:(NSDate *)date timeZone:(NSTimeZone *)tz;

- (id)initWithRFC3339String:(NSString *)str;
- (id)initWithDate:(NSDate *)date timeZone:(NSTimeZone *)tz;

- (void)setFromDate:(NSDate *)date timeZone:(NSTimeZone *)tz;
- (void)setFromRFC3339String:(NSString *)str;

- (NSDate *)date;
- (NSCalendar *)calendar;

- (NSTimeZone *)timeZone;
- (void)setTimeZone:(NSTimeZone *)timeZone;
- (void)setTimeZone:(NSTimeZone *)timeZone withOffsetSeconds:(NSInteger)val;

- (NSString *)RFC3339String;
- (NSString *)stringValue; // same as RFC3339String

- (BOOL)hasTime;
- (void)setHasTime:(BOOL)shouldHaveTime;

- (NSInteger)offsetSeconds;
- (void)setOffsetSeconds:(NSInteger)val;

- (BOOL)isUniversalTime;
- (void)setIsUniversalTime:(BOOL)flag;

- (NSDateComponents *)dateComponents;
- (void)setDateComponents:(NSDateComponents *)dateComponents;

@end
