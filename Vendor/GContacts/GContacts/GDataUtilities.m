/* Copyright (c) 2008 Google Inc.
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

#import "GDataUtilities.h"

#include <math.h>

@implementation GDataUtilities

+ (NSString *)stringWithControlsFilteredForString:(NSString *)str {
  // Ensure that control characters are not present in the string, since they
  // would lead to XML that likely will make servers unhappy.  (Are control
  // characters ever legal in XML?)
  //
  // Why not assert on debug builds for the caller when the string has a control
  // character?  The characters may never be present in the data until the
  // program is deployed to users.  This filtering will make it less likely
  // that bad XML might be generated for users and sent to servers.
  //
  // Since we generate our XML directly from the elements with
  // XMLData, we won't later have a good chance to look for and clean out
  // the control characters.

  if (str == nil) return nil;

  static NSCharacterSet *filterChars = nil;

  @synchronized([GDataUtilities class]) {

    if (filterChars == nil) {
      // make a character set of control characters (but not whitespace/newline
      // characters), and keep a static immutable copy to use for filtering
      // strings
      NSCharacterSet *ctrlChars = [NSCharacterSet controlCharacterSet];
      NSCharacterSet *newlineWsChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
      NSCharacterSet *nonNewlineWsChars = [newlineWsChars invertedSet];

      NSMutableCharacterSet *mutableChars = [[ctrlChars mutableCopy] autorelease];
      [mutableChars formIntersectionWithCharacterSet:nonNewlineWsChars];

      [mutableChars addCharactersInRange:NSMakeRange(0x0B, 2)]; // filter vt, ff

      filterChars = [mutableChars copy];
    }
  }

  // look for any invalid characters
  NSRange range = [str rangeOfCharacterFromSet:filterChars];
  if (range.location != NSNotFound) {

    // copy the string to a mutable, and remove null and non-whitespace
    // control characters
    NSMutableString *mutableStr = [NSMutableString stringWithString:str];
    while (range.location != NSNotFound) {

#if DEBUG
      NSLog(@"GDataObject: Removing char 0x%lx from XML element string \"%@\"",
            (unsigned long) [mutableStr characterAtIndex:range.location], str);
#endif

      [mutableStr deleteCharactersInRange:range];

      range = [mutableStr rangeOfCharacterFromSet:filterChars];
    }

    return mutableStr;
  }

  return str;
}

+ (NSNumber *)doubleNumberOrInfForString:(NSString *)str {
  if ([str length] == 0) return nil;

  double val = [str doubleValue];
  NSNumber *number = [NSNumber numberWithDouble:val];

  // Incase fpclassify doesn't exist, default to always checking for INF.
  BOOL checkForINF = YES;
#if defined(fpclassify)
  checkForINF = (fpclassify(val) == FP_ZERO);
#endif

  if (checkForINF) {
    if ([str caseInsensitiveCompare:@"INF"] == NSOrderedSame) {
      number = [NSNumber numberWithDouble:HUGE_VAL];
    } else if ([str caseInsensitiveCompare:@"-INF"] == NSOrderedSame) {
      number = [NSNumber numberWithDouble:-HUGE_VAL];
    }
  }
  return number;
}

#pragma mark Copy method helpers

+ (NSArray *)arrayWithCopiesOfObjectsInArray:(NSArray *)source {
  if (source == nil) return nil;

  NSArray *result = [[[NSArray alloc] initWithArray:source
                                          copyItems:YES] autorelease];
  return result;
}

+ (NSMutableArray *)mutableArrayWithCopiesOfObjectsInArray:(NSArray *)source {

  if (source == nil) return nil;

  NSMutableArray *result;

  result = [[[NSMutableArray alloc] initWithArray:source
                                        copyItems:YES] autorelease];
  return result;
}

+ (NSDictionary *)dictionaryWithCopiesOfObjectsInDictionary:(NSDictionary *)source {
  if (source == nil) return nil;

  NSDictionary *result = [[[NSDictionary alloc] initWithDictionary:source
                                                         copyItems:YES] autorelease];
  return result;
}

+ (NSMutableDictionary *)mutableDictionaryWithCopiesOfObjectsInDictionary:(NSDictionary *)source {

  if (source == nil) return nil;

  NSMutableDictionary *result;

  result = [[[NSMutableDictionary alloc] initWithDictionary:source
                                                  copyItems:YES] autorelease];
  return result;
}

+ (NSDictionary *)dictionaryWithCopiesOfArraysInDictionary:(NSDictionary *)source {
  // we don't enforce return of an immutable for this
  return [self mutableDictionaryWithCopiesOfArraysInDictionary:source];
}

+ (NSMutableDictionary *)mutableDictionaryWithCopiesOfArraysInDictionary:(NSDictionary *)source {

  // Copy a dictionary that has arrays as its values
  //
  // We want to copy each object in each array.

  if (source == nil) return nil;

  Class arrayClass = [NSArray class];

  // Using CFPropertyListCreateDeepCopy would be nice, but it fails on non-plist
  // classes of objects

  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  for (id key in source) {

    id origObj = [source objectForKey:key];
    id copyObj;

    if ([origObj isKindOfClass:arrayClass]) {

      copyObj = [self mutableArrayWithCopiesOfObjectsInArray:origObj];
    } else {
      copyObj = [[origObj copy] autorelease];
    }
    [dict setObject:copyObj forKey:key];
  }

  return dict;
}

#pragma mark String encoding

// URL Encoding

+ (NSString *)stringByURLEncodingString:(NSString *)str {
  NSString *result = [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  return result;
}

// NSURL's stringByAddingPercentEscapesUsingEncoding: does not escape
// some characters that should be escaped in URL parameters, like / and ?;
// we'll use CFURL to force the encoding of those
//
// Reference: http://www.ietf.org/rfc/rfc3986.txt

static const CFStringRef kCharsToForceEscape = CFSTR("!*'();:@&=+$,/?%#[]");

+ (NSString *)stringByURLEncodingForURI:(NSString *)str {

  NSString *resultStr = str;

  CFStringRef originalString = (CFStringRef) str;
  CFStringRef leaveUnescaped = NULL;

  CFStringRef escapedStr;
  escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                       originalString,
                                                       leaveUnescaped,
                                                       kCharsToForceEscape,
                                                       kCFStringEncodingUTF8);
  if (escapedStr) {
    resultStr = [(id)CFMakeCollectable(escapedStr) autorelease];
  }
  return resultStr;
}

+ (NSString *)stringByURLEncodingStringParameter:(NSString *)str {

  // For parameters, we'll explicitly leave spaces unescaped now, and replace
  // them with +'s

  NSString *resultStr = str;

  CFStringRef originalString = (CFStringRef) str;
  CFStringRef leaveUnescaped = CFSTR(" ");

  CFStringRef escapedStr;
  escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                       originalString,
                                                       leaveUnescaped,
                                                       kCharsToForceEscape,
                                                       kCFStringEncodingUTF8);

  if (escapedStr) {
    NSMutableString *mutableStr = [NSMutableString stringWithString:(NSString *)escapedStr];
    CFRelease(escapedStr);

    // replace spaces with plusses
    [mutableStr replaceOccurrencesOfString:@" "
                                withString:@"+"
                                   options:0
                                     range:NSMakeRange(0, [mutableStr length])];
    resultStr = mutableStr;
  }
  return resultStr;
}

// percent-encoding UTF-8

+ (NSString *)stringByPercentEncodingUTF8ForString:(NSString *)inputStr {

  // encode per http://bitworking.org/projects/atom/rfc5023.html#rfc.section.9.7
  //
  // step through the string as UTF-8, and replace characters outside 20..7E
  // (and the percent symbol itself, 25) with percent-encodings
  //
  // we avoid creating an encoding string unless we encounter some characters
  // that require it

  const unsigned char* utf8 = (const unsigned char *)[inputStr UTF8String];
  if (utf8 == NULL) {
    return nil;
  }

  NSMutableString *encoded = nil;

  for (unsigned int idx = 0; utf8[idx] != '\0'; idx++) {

    unsigned char currChar = utf8[idx];
    if (currChar < 0x20 || currChar == 0x25 || currChar > 0x7E) {

      if (encoded == nil) {
        // start encoding and catch up on the character skipped so far
        encoded = [[[NSMutableString alloc] initWithBytes:utf8
                                                   length:idx
                                                 encoding:NSUTF8StringEncoding] autorelease];
      }

      // append this byte as a % and then uppercase hex
      [encoded appendFormat:@"%%%02X", currChar];

    } else {
      // this character does not need encoding
      //
      // encoded is nil here unless we've encountered a previous character
      // that needed encoding
      [encoded appendFormat:@"%c", currChar];
    }
  }

  if (encoded) {
    return encoded;
  }

  return inputStr;
}

#pragma mark Key-Value Coding Searches in an Array

+ (NSArray *)objectsFromArray:(NSArray *)sourceArray
                    withValue:(id)desiredValue
                   forKeyPath:(NSString *)keyPath {
  // step through all entries, get the value from
  // the key path, and see if it's equal to the
  // desired value
  NSMutableArray *results = [NSMutableArray array];

  for (id obj in sourceArray) {
    id val = [obj valueForKeyPath:keyPath];
    if (AreEqualOrBothNil(val, desiredValue)) {

      // found a match; add it to the results array
      [results addObject:obj];
    }
  }
  return results;
}

+ (id)firstObjectFromArray:(NSArray *)sourceArray
                 withValue:(id)desiredValue
                forKeyPath:(NSString *)keyPath {

  for (id obj in sourceArray) {
    id val = [obj valueForKeyPath:keyPath];
    if (AreEqualOrBothNil(val, desiredValue)) {

      // found a match; return it
      return obj;
    }
  }
  return nil;
}

#pragma mark Response-string helpers

// convert responses of the form "a=foo \n b=bar" to a dictionary
+ (NSDictionary *)dictionaryWithResponseString:(NSString *)str {

  if (str == nil) return nil;

  NSArray *allLines = [str componentsSeparatedByString:@"\n"];
  NSMutableDictionary *responseDict;

  responseDict = [NSMutableDictionary dictionaryWithCapacity:[allLines count]];

  for (NSString *line in allLines) {
    NSScanner *scanner = [NSScanner scannerWithString:line];
    NSString *key;
    NSString *value;

    if ([scanner scanUpToString:@"=" intoString:&key]
        && [scanner scanString:@"=" intoString:NULL]
        && [scanner scanUpToString:@"\n" intoString:&value]) {

      [responseDict setObject:value forKey:key];
    }
  }
  return responseDict;
}

+ (NSDictionary *)dictionaryWithResponseData:(NSData *)data {
  NSString *str = [[[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding] autorelease];
  return [self dictionaryWithResponseString:str];
}

#pragma mark Version helpers

// compareVersion compares two strings in 1.2.3.4 format
// missing fields are interpreted as zeros, so 1.2 = 1.2.0.0
+ (NSComparisonResult)compareVersion:(NSString *)ver1 toVersion:(NSString *)ver2 {

  static NSCharacterSet* dotSet = nil;
  if (dotSet == nil) {
    dotSet = [[NSCharacterSet characterSetWithCharactersInString:@"."] retain];
  }

  if (ver1 == nil) ver1 = @"";
  if (ver2 == nil) ver2 = @"";

  NSScanner* scanner1 = [NSScanner scannerWithString:ver1];
  NSScanner* scanner2 = [NSScanner scannerWithString:ver2];

  [scanner1 setCharactersToBeSkipped:dotSet];
  [scanner2 setCharactersToBeSkipped:dotSet];

  int partA1 = 0, partA2 = 0, partB1 = 0, partB2 = 0;
  int partC1 = 0, partC2 = 0, partD1 = 0, partD2 = 0;

  if ([scanner1 scanInt:&partA1] && [scanner1 scanInt:&partB1]
      && [scanner1 scanInt:&partC1] && [scanner1 scanInt:&partD1]) {
  }
  if ([scanner2 scanInt:&partA2] && [scanner2 scanInt:&partB2]
      && [scanner2 scanInt:&partC2] && [scanner2 scanInt:&partD2]) {
  }

  if (partA1 != partA2) return ((partA1 < partA2) ? NSOrderedAscending : NSOrderedDescending);
  if (partB1 != partB2) return ((partB1 < partB2) ? NSOrderedAscending : NSOrderedDescending);
  if (partC1 != partC2) return ((partC1 < partC2) ? NSOrderedAscending : NSOrderedDescending);
  if (partD1 != partD2) return ((partD1 < partD2) ? NSOrderedAscending : NSOrderedDescending);
  return NSOrderedSame;
}

#pragma mark File type helpers

// utility routine to convert a file path to the file's MIME type using
// Mac OS X's UTI database
+ (NSString *)MIMETypeForFileAtPath:(NSString *)path
                    defaultMIMEType:(NSString *)defaultType {
#ifndef GDATA_FOUNDATION_ONLY
  NSString *result = defaultType;
  NSString *extension = [path pathExtension];
  CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                          (CFStringRef)extension,
                                                          NULL);
  if (uti) {
    CFStringRef cfMIMEType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
    if (cfMIMEType) {
      result = [[(NSString *)cfMIMEType copy] autorelease];
      CFRelease(cfMIMEType);
    }
    CFRelease(uti);
  }
  return result;
#else // !GDATA_FOUNDATION_ONLY

  return defaultType;

#endif
}

@end

// isEqual: has the fatal flaw that it doesn't deal well with the receiver
// being nil. We'll use this utility instead.
BOOL AreEqualOrBothNil(id obj1, id obj2) {
  if (obj1 == obj2) {
    return YES;
  }
  if (obj1 && obj2) {
    BOOL areEqual = [obj1 isEqual:obj2];

    // the following commented-out lines are useful for finding out what
    // comparisons are failing when XML regeneration fails in unit tests

    //if (!areEqual) NSLog(@">>>\n%@\n  !=\n%@", obj1, obj2);

    return areEqual;
  } else {
    //NSLog(@">>>\n%@\n  !=\n%@", obj1, obj2);
  }
  return NO;
}

BOOL AreBoolsEqual(BOOL b1, BOOL b2) {
  // avoid comparison problems with boolean types by negating
  // both booleans
  return (!b1 == !b2);
}

