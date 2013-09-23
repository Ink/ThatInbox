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
//  GDataValueConstruct.m
//

#import "GDataValueConstruct.h"

@implementation GDataValueConstruct
// an element with a value="" attribute, as in
// <gCal:timezone value="America/Los_Angeles"/>
// (subclasses may override the attribute name,
// or return nil for it to indicate the value is
// in the child node text)


// convenience functions
//
// subclasses may re-use call into these convenience functions
// and coerce the return type appropriately

+ (id)valueWithString:(NSString *)str {
  if (str == nil) return nil;

  GDataValueConstruct* obj = [self object];
  [obj setStringValue:str];
  return obj;
}

+ (id)valueWithNumber:(NSNumber *)num {
  if (num == nil) return nil;

  GDataValueConstruct* obj = [self object];
  [obj setStringValue:[num stringValue]];
  return obj;
}

+ (id)valueWithInt:(int)val {
  GDataValueConstruct* obj = [self object];
  [obj setIntValue:val];
  return obj;
}

+ (id)valueWithLongLong:(long long)val {
  GDataValueConstruct* obj = [self object];
  [obj setLongLongValue:val];
  return obj;
}

+ (id)valueWithDouble:(double)val {
  GDataValueConstruct* obj = [self object];
  [obj setDoubleValue:val];
  return obj;
}

+ (id)valueWithBool:(BOOL)flag {
  GDataValueConstruct* obj = [self object];
  [obj setBoolValue:flag];
  return obj;
}

+ (id)valueWithDateTime:(GDataDateTime *)dateTime {
  if (dateTime == nil) return nil;

  GDataValueConstruct* obj = [self object];
  [obj setDateTimeValue:dateTime];
  return obj;
}


#pragma mark -

- (void)addParseDeclarations {

  NSString *attrName = [self attributeName];
  if (attrName) {
    // there's a value attribute
    NSArray *attr = [NSArray arrayWithObject:attrName];
    [self addLocalAttributeDeclarations:attr];

  } else {
    // no named attribute; use the element's child text as the value
    [self addContentValueDeclaration];
  }
}

- (NSString *)stringValue {
  NSString *attrName = [self attributeName];
  if (attrName != nil) {
    return [self stringValueForAttribute:attrName];
  } else {
    return [self contentStringValue];
  }
}

- (void)setStringValue:(NSString *)str {
  NSString *attrName = [self attributeName];
  if (attrName != nil) {
    [self setStringValue:str forAttribute:attrName];
  } else {
    [self setContentStringValue:str];
  }
}

- (NSString *)attributeName {
  // subclasses can override if they store their value under a different
  // attribute name, or can return nil to indicate the value is in the child
  // node text (or just use GDataValueElementConstruct which returns nil
  // for this method)
  return @"value";
}

// subclass value utilities

- (int)intValue {
  NSString *str = [self stringValue];
  if (str) {
    int result;
    NSScanner *scanner = [NSScanner scannerWithString:str];
    if ([scanner scanInt:&result]) {
      return result;
    }
  }
  return 0;
}

- (NSNumber *)intNumberValue {
  return [NSNumber numberWithInt:[self intValue]];
}

- (void)setIntValue:(int)val {
  NSString *str = [[NSNumber numberWithInt:val] stringValue];
  [self setStringValue:str];
}

- (long long)longLongValue {
  NSString *str = [self stringValue];
  if (str) {
    long long result;
    NSScanner *scanner = [NSScanner scannerWithString:str];
    if ([scanner scanLongLong:&result]) {
      return result;
    }
  }
  return 0;
}

- (NSNumber *)longLongNumberValue {
  return [NSNumber numberWithLongLong:[self longLongValue]];
}

- (void)setLongLongValue:(long long)val {
  NSString *str = [[NSNumber numberWithLongLong:val] stringValue];
  [self setStringValue:str];
}

- (double)doubleValue {
  NSNumber *num = [self doubleNumberValue];
  double val = [num doubleValue];
  return val;
}

- (NSNumber *)doubleNumberValue {
  NSString *str = [self stringValue];
  NSNumber *num = [GDataUtilities doubleNumberOrInfForString:str];
  if (num != nil) return num;

  return [NSNumber numberWithDouble:0];
}

- (void)setDoubleValue:(double)val {
  NSString *str = [[NSNumber numberWithDouble:val] stringValue];
  [self setStringValue:str];
}

- (BOOL)boolValue {
  NSString *value = [self stringValue];
  if (value) {
    return ([value caseInsensitiveCompare:@"true"] == NSOrderedSame);
  }
  return NO;
}

- (NSNumber *)boolNumberValue {
  return [NSNumber numberWithBool:[self boolValue]];
}

- (void)setBoolValue:(BOOL)flag {
  [self setStringValue:(flag ? @"true" : @"false")];
}

- (GDataDateTime *)dateTimeValue {
  NSString *str = [self stringValue];
  if ([str length] > 0) {
    GDataDateTime *dateTime = [GDataDateTime dateTimeWithRFC3339String:str];
    return dateTime;
  }
  return nil;
}

- (void)setDateTimeValue:(GDataDateTime *)dateTime {
  NSString *str = [dateTime RFC3339String];
  [self setStringValue:str];
}

@end

@implementation GDataNameValueConstruct // derives from GDataValueConstruct
+ (id)valueWithName:(NSString *)name stringValue:(NSString *)value {
  if (name == nil && value == nil) return nil;

  GDataNameValueConstruct* obj = [self object];
  [obj setStringValue:value];
  [obj setName:name];
  return obj;
}

- (void)addParseDeclarations {
  [super addParseDeclarations];

  // add the name attribute
  NSString *nameAttrName = [self nameAttributeName];
  if (nameAttrName) {
    NSArray *attr = [NSArray arrayWithObject:nameAttrName];
    [self addLocalAttributeDeclarations:attr];
  }
}

- (NSString *)name {
  NSString *nameAttrName = [self nameAttributeName];
  if (nameAttrName) {
    return [self stringValueForAttribute:nameAttrName];
  }
  return nil;
}

- (void)setName:(NSString *)str {
  NSString *nameAttrName = [self nameAttributeName];
  if (nameAttrName) {
    [self setStringValue:str forAttribute:nameAttrName];
  }
}

- (NSString *)nameAttributeName {
  return @"name";
}
@end

@implementation GDataValueElementConstruct // derives from GDataValueConstruct
- (NSString *)attributeName {
  // return nil to indicate the value is contained in the child text nodes
  return nil;
}
@end

// GDataImplicitValueConstruct is for subclasses that want a fixed value
// because the element is merely present or absent, like <foo:bar/>
//
// This derives from GDataValueElementConstruct
@implementation GDataImplicitValueConstruct
+ (id)implicitValue {
  GDataImplicitValueConstruct* obj = [self object];
  return obj;
}

- (NSString *)stringValue {
  return nil;  // no body
}

@end

@implementation GDataBoolValueConstruct // derives from GDataValueConstruct

+ (id)boolValueWithBool:(BOOL)flag {
  return [super valueWithBool:flag];
}

@end

