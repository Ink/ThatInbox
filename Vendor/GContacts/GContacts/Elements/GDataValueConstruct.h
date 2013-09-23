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
//  GDataValueConstruct.h
//

// GDataValueConstruct is meant to be subclassed for elements that
// store just a single string either as an attribute or as the
// element child text.
//
// See the examples with each subclass below.

#import "GDataObject.h"
#import "GDataDateTime.h"

// an element with a value="" attribute, as in
// <gCal:timezone value="America/Los_Angeles"/>
// (subclasses may override the attribute name)
@interface GDataValueConstruct : GDataObject

// convenience functions: subclasses may call into these and
// return the result, cast to the appropriate type
//
// if nil is passed in for pointer type args for these, nil is returned
+ (id)valueWithString:(NSString *)str;
+ (id)valueWithNumber:(NSNumber *)num;
+ (id)valueWithInt:(int)val;
+ (id)valueWithLongLong:(long long)val;
+ (id)valueWithDouble:(double)val;
+ (id)valueWithBool:(BOOL)flag;
+ (id)valueWithDateTime:(GDataDateTime *)dateTime;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;

- (NSString *)attributeName; // defaults to "value", subclasses can override

// subclass value utilities
- (NSNumber *)intNumberValue;
- (int)intValue;
- (void)setIntValue:(int)val;

- (NSNumber *)longLongNumberValue;
- (long long)longLongValue;
- (void)setLongLongValue:(long long)val;

- (NSNumber *)doubleNumberValue;
- (double)doubleValue;
- (void)setDoubleValue:(double)value;

- (NSNumber *)boolNumberValue;
- (BOOL)boolValue;
- (void)setBoolValue:(BOOL)flag;

- (GDataDateTime *)dateTimeValue;
- (void)setDateTimeValue:(GDataDateTime *)dateTime;

@end

// GDataValueElementConstruct is for subclasses that keep the value
// in the child text nodes, like <yt:books>Pride and Prejudice</yt:books>
@interface GDataValueElementConstruct : GDataValueConstruct
- (NSString *)attributeName; // returns nil
@end

// GDataImplicitValueConstruct is for subclasses that want a fixed value
// because the element is merely present or absent, like <gd:deleted/>
@interface GDataImplicitValueConstruct : GDataValueElementConstruct
+ (id)implicitValue;
- (NSString *)stringValue; // returns nil
@end

// an element with a value=true or false attribute, as in
//   <gCal:sendEventNotifications value="true"/>
@interface GDataBoolValueConstruct : GDataValueConstruct
+ (id)boolValueWithBool:(BOOL)flag;
@end

// GDataNameValueConstruct is for subclasses that have "name" and "value"
// attributes
@interface GDataNameValueConstruct : GDataValueConstruct
+ (id)valueWithName:(NSString *)name stringValue:(NSString *)value;

- (NSString *)name;
- (void)setName:(NSString *)str;

- (NSString *)nameAttributeName; // the default implementation returns @"name"
@end

