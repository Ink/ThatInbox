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
//  GDataDateTime.m
//

#import "GDataDateTime.h"

static NSMutableDictionary *gCalendarsForTimeZones = nil;

@implementation GDataDateTime

+ (void)initialize {
  // Note that initialize is guaranteed by the runtime to be called in a
  // thread-safe manner.
  gCalendarsForTimeZones = [[NSMutableDictionary alloc] init];
}

+ (GDataDateTime *)dateTimeWithRFC3339String:(NSString *)str {
  return [[[GDataDateTime alloc] initWithRFC3339String:str] autorelease];
}

+ (GDataDateTime *)dateTimeWithDate:(NSDate *)date timeZone:(NSTimeZone *)tz {
 return [[[GDataDateTime alloc] initWithDate:date
                                    timeZone:tz] autorelease];
}

- (id)initWithRFC3339String:(NSString *)str {

  self = [super init];
  if (self) {
    [self setFromRFC3339String:str];
  }
  return self;
}

- (id)initWithDate:(NSDate *)date timeZone:(NSTimeZone *)tz {

  self = [super init];
  if (self) {
    [self setFromDate:date timeZone:tz];
  }
  return self;
}

- (void)dealloc {
  [dateComponents_ release];
  [timeZone_ release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {

  GDataDateTime *newObj = [[GDataDateTime alloc] init];

  [newObj setIsUniversalTime:[self isUniversalTime]];
  [newObj setTimeZone:[self timeZone] withOffsetSeconds:[self offsetSeconds]];

  NSDateComponents *newDateComponents;
  NSDateComponents *oldDateComponents = [self dateComponents];

// TODO: Experiments show it lies in 10.4.8 commented out for now.
  if (NO && [NSDateComponents conformsToProtocol:@protocol(NSCopying)]) {

    newDateComponents = [[oldDateComponents copyWithZone:zone] autorelease];

  } else {
    // NSDateComponents doesn't implement NSCopying in 10.4. We'll just retain
    // it, which is fine since we never set individual components
    // except after allocating a new NSDateCompoents instance.
    newDateComponents = oldDateComponents;
  }
  [newObj setDateComponents:newDateComponents];

  return newObj;
}

// until NSDateComponent implements isEqual, we'll use this
- (BOOL)doesDateComponents:(NSDateComponents *)dc1
       equalDateComponents:(NSDateComponents *)dc2 {

  return [dc1 era] == [dc2 era]
          && [dc1 year] == [dc2 year]
          && [dc1 month] == [dc2 month]
          && [dc1 day] == [dc2 day]
          && [dc1 hour] == [dc2 hour]
          && [dc1 minute] == [dc2 minute]
          && [dc1 second] == [dc2 second]
          && [dc1 week] == [dc2 week]
          && [dc1 weekday] == [dc2 weekday]
          && [dc1 weekdayOrdinal] == [dc2 weekdayOrdinal];
}

- (BOOL)isEqual:(GDataDateTime *)other {

  if (self == other) return YES;
  if (![other isKindOfClass:[GDataDateTime class]]) return NO;

  return [self offsetSeconds] == [other offsetSeconds]
    && [self isUniversalTime] == [other isUniversalTime]
    && [self timeZone] == [other timeZone]
    && [self doesDateComponents:[self dateComponents]
            equalDateComponents:[other dateComponents]];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@ %p: {%@}",
    [self class], self, [self RFC3339String]];
}

- (NSTimeZone *)timeZone {
  if (timeZone_) {
    return timeZone_;
  }

  if ([self isUniversalTime]) {
    NSTimeZone *ztz = [NSTimeZone timeZoneWithName:@"Universal"];
    return ztz;
  }

  NSInteger offsetSeconds = [self offsetSeconds];

  if (offsetSeconds != NSUndefinedDateComponent) {
    NSTimeZone *tz = [NSTimeZone timeZoneForSecondsFromGMT:offsetSeconds];
    return tz;
  }
  return nil;
}

- (void)setTimeZone:(NSTimeZone *)timeZone {
  [timeZone_ release];
  timeZone_ = [timeZone retain];

  if (timeZone) {
    NSInteger offsetSeconds = [timeZone secondsFromGMTForDate:[self date]];
    [self setOffsetSeconds:offsetSeconds];
  } else {
    [self setOffsetSeconds:NSUndefinedDateComponent];
  }
}

- (void)setTimeZone:(NSTimeZone *)timeZone withOffsetSeconds:(NSInteger)val {
  [timeZone_ release];
  timeZone_ = [timeZone retain];

  offsetSeconds_ = val;
}

- (NSCalendar *)calendarForTimeZone:(NSTimeZone *)tz {
  NSCalendar *cal = nil;
  @synchronized(gCalendarsForTimeZones) {
    id tzKey = (tz ? tz : [NSNull null]);
    cal = [gCalendarsForTimeZones objectForKey:tzKey];
    if (cal == nil) {
      cal = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
      if (tz) {
        [cal setTimeZone:tz];
      }
      [gCalendarsForTimeZones setObject:cal forKey:tzKey];
    }
  }
  return cal;
}

- (NSCalendar *)calendar {
  NSTimeZone *tz = self.timeZone;
  return [self calendarForTimeZone:tz];
}

- (NSDate *)date {
  NSDateComponents *dateComponents = [self dateComponents];
  NSCalendar *cal;

  if (![self hasTime]) {
    // we're not keeping track of a time, but NSDate always is based on
    // an absolute time. We want to avoid returning an NSDate where the
    // calendar date appears different from what was used to create our
    // date-time object.
    //
    // We'll make a copy of the date components, setting the time on our
    // copy to noon GMT, since that ensures the date renders correctly for
    // any time zone
    //
    // Note that on 10.4 NSDateComponents does not implement NSCopying, so we'll
    // assemble an NSDateComponents manually here
    NSDateComponents *noonDateComponents = [[[NSDateComponents alloc] init] autorelease];
    [noonDateComponents setYear:[dateComponents year]];
    [noonDateComponents setMonth:[dateComponents month]];
    [noonDateComponents setDay:[dateComponents day]];
    [noonDateComponents setHour:12];
    [noonDateComponents setMinute:0];
    [noonDateComponents setSecond:0];
    dateComponents = noonDateComponents;

    NSTimeZone *gmt = [NSTimeZone timeZoneWithName:@"Universal"];
    cal = [self calendarForTimeZone:gmt];
  } else {
    cal = self.calendar;
  }

  NSDate *date = [cal dateFromComponents:dateComponents];
  return date;
}

- (NSString *)stringValue {
  return [self RFC3339String];
}

- (NSString *)RFC3339String {
  NSDateComponents *dateComponents = [self dateComponents];
  NSInteger offset = [self offsetSeconds];

  NSString *timeString = @""; // timeString like "T15:10:46-08:00"

  if ([self hasTime]) {

    NSString *timeOffsetString; // timeOffsetString like "-08:00"

    if ([self isUniversalTime]) {
     timeOffsetString = @"Z";
    } else if (offset == NSUndefinedDateComponent) {
      // unknown offset is rendered as -00:00 per
      // http://www.ietf.org/rfc/rfc3339.txt section 4.3
      timeOffsetString = @"-00:00";
    } else {
      NSString *sign = @"+";
      if (offset < 0) {
        sign = @"-";
        offset = -offset;
      }
      timeOffsetString = [NSString stringWithFormat:@"%@%02ld:%02ld",
        sign, (long)(offset/(60*60)) % 24, (long)(offset / 60) % 60];
    }
    timeString = [NSString stringWithFormat:@"T%02ld:%02ld:%02ld%@",
      (long)[dateComponents hour], (long)[dateComponents minute],
      (long)[dateComponents second], timeOffsetString];
  }

  // full dateString like "2006-11-17T15:10:46-08:00"
  NSString *dateString = [NSString stringWithFormat:@"%04ld-%02ld-%02ld%@",
    (long)[dateComponents year], (long)[dateComponents month],
    (long)[dateComponents day], timeString];

  return dateString;
}

- (void)setFromDate:(NSDate *)date timeZone:(NSTimeZone *)tz {
  NSCalendar *cal = [self calendarForTimeZone:tz];
  if (tz) {
    [cal setTimeZone:tz];
  }

  NSUInteger const kComponentBits = (NSYearCalendarUnit | NSMonthCalendarUnit
    | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit
    | NSSecondCalendarUnit);

  NSDateComponents *components = [cal components:kComponentBits fromDate:date];
  [self setDateComponents:components];

  [self setIsUniversalTime:NO];

  NSInteger offset = NSUndefinedDateComponent;

  if (tz) {
    offset = [tz secondsFromGMTForDate:date];

    if (offset == 0 && [tz isEqualToTimeZone:[NSTimeZone timeZoneWithName:@"Universal"]]) {
      [self setIsUniversalTime:YES];
    }
  }
  [self setOffsetSeconds:offset];

  // though offset seconds are authoritative, we'll retain the time zone
  // since we can't regenerate it reliably from just the offset
  timeZone_ = [tz retain];
}

static inline BOOL ScanInteger(NSScanner *scanner, NSInteger *targetInteger) {
  return [scanner scanInteger:targetInteger];
}

- (void)setFromRFC3339String:(NSString *)str {

  NSInteger year = NSUndefinedDateComponent;
  NSInteger month = NSUndefinedDateComponent;
  NSInteger day = NSUndefinedDateComponent;
  NSInteger hour = NSUndefinedDateComponent;
  NSInteger minute = NSUndefinedDateComponent;
  NSInteger sec = NSUndefinedDateComponent;
  float secFloat = -1.0f;
  NSString* sign = nil;
  NSInteger offsetHour = 0;
  NSInteger offsetMinute = 0;

  NSScanner* scanner = [NSScanner scannerWithString:str];

  NSCharacterSet* dashSet = [NSCharacterSet characterSetWithCharactersInString:@"-"];
  NSCharacterSet* tSet = [NSCharacterSet characterSetWithCharactersInString:@"Tt "];
  NSCharacterSet* colonSet = [NSCharacterSet characterSetWithCharactersInString:@":"];
  NSCharacterSet* plusMinusZSet = [NSCharacterSet characterSetWithCharactersInString:@"+-zZ"];

  // for example, scan 2006-11-17T15:10:46-08:00
  //                or 2006-11-17T15:10:46Z
  if (// yyyy-mm-dd
      ScanInteger(scanner, &year) &&
      [scanner scanCharactersFromSet:dashSet intoString:NULL] &&
      ScanInteger(scanner, &month) &&
      [scanner scanCharactersFromSet:dashSet intoString:NULL] &&
      ScanInteger(scanner, &day) &&
      // Thh:mm:ss
      [scanner scanCharactersFromSet:tSet intoString:NULL] &&
      ScanInteger(scanner, &hour) &&
      [scanner scanCharactersFromSet:colonSet intoString:NULL] &&
      ScanInteger(scanner, &minute) &&
      [scanner scanCharactersFromSet:colonSet intoString:NULL] &&
      [scanner scanFloat:&secFloat] &&
      // Z or +hh:mm
      [scanner scanCharactersFromSet:plusMinusZSet intoString:&sign] &&
      ScanInteger(scanner, &offsetHour) &&
      [scanner scanCharactersFromSet:colonSet intoString:NULL] &&
      ScanInteger(scanner, &offsetMinute)) {
  }

  NSDateComponents *dateComponents = [[[NSDateComponents alloc] init] autorelease];
  [dateComponents setYear:year];
  [dateComponents setMonth:month];
  [dateComponents setDay:day];
  [dateComponents setHour:hour];
  [dateComponents setMinute:minute];

  if (secFloat < -1.0f || secFloat > -1.0f) sec = (NSInteger)secFloat;
  [dateComponents setSecond:sec];

  [self setDateComponents:dateComponents];

  // determine the offset, like from Z, or -08:00:00.0

  [self setTimeZone:nil];

  NSInteger totalOffset = NSUndefinedDateComponent;
  [self setIsUniversalTime:NO];

  if ([sign caseInsensitiveCompare:@"Z"] == NSOrderedSame) {

    [self setIsUniversalTime:YES];
    totalOffset = 0;

  } else if (sign != nil) {

    totalOffset = (60 * offsetMinute) + (60 * 60 * offsetHour);

    if ([sign isEqual:@"-"]) {

      if (totalOffset == 0) {
        // special case: offset of -0.00 means undefined offset
        totalOffset = NSUndefinedDateComponent;
      } else {
        totalOffset *= -1;
      }
    }
  }

  [self setOffsetSeconds:totalOffset];
}

- (BOOL)hasTime {
  NSDateComponents *dateComponents = [self dateComponents];

  BOOL hasTime = ([dateComponents hour] != NSUndefinedDateComponent
                  && [dateComponents minute] != NSUndefinedDateComponent);

  return hasTime;
}

- (void)setHasTime:(BOOL)shouldHaveTime {

  // we'll set time values to zero or NSUndefinedDateComponent as appropriate
  BOOL hadTime = [self hasTime];

  if (shouldHaveTime && !hadTime) {
    [dateComponents_ setHour:0];
    [dateComponents_ setMinute:0];
    [dateComponents_ setSecond:0];
    offsetSeconds_ = NSUndefinedDateComponent;
    isUniversalTime_ = NO;

  } else if (hadTime && !shouldHaveTime) {
    [dateComponents_ setHour:NSUndefinedDateComponent];
    [dateComponents_ setMinute:NSUndefinedDateComponent];
    [dateComponents_ setSecond:NSUndefinedDateComponent];
    offsetSeconds_ = NSUndefinedDateComponent;
    isUniversalTime_ = NO;
    [self setTimeZone:nil];
  }
}

- (NSInteger)offsetSeconds {
  return offsetSeconds_;
}

- (void)setOffsetSeconds:(NSInteger)val {
  offsetSeconds_ = val;
}

- (BOOL)isUniversalTime {
  return isUniversalTime_;
}

- (void)setIsUniversalTime:(BOOL)flag {
  isUniversalTime_ = flag;
}

- (NSDateComponents *)dateComponents {
  return dateComponents_;
}

- (void)setDateComponents:(NSDateComponents *)dateComponents {
  [dateComponents_ autorelease];
  dateComponents_ = [dateComponents retain]; // NSDateComponents doesn't implement NSCopying in 10.4
}
@end
