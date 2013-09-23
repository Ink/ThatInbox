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

#import <Foundation/Foundation.h>

#ifndef SKIP_GDATA_DEFINES
  #import "GDataDefines.h"
#endif

// helper functions for implementing isEqual:
BOOL AreEqualOrBothNil(id obj1, id obj2);
BOOL AreBoolsEqual(BOOL b1, BOOL b2);

@interface GDataUtilities : NSObject

// utility for removing non-whitespace control characters
+ (NSString *)stringWithControlsFilteredForString:(NSString *)str;

// utility for converting NSNumber to/from string, including inf/-inf
//
// an empty string returns a nil NSNumber
+ (NSNumber *)doubleNumberOrInfForString:(NSString *)str;

//
// copy method helpers
//

// array with copies of the objects in the source array (1-deep)
+ (NSArray *)arrayWithCopiesOfObjectsInArray:(NSArray *)source;
+ (NSMutableArray *)mutableArrayWithCopiesOfObjectsInArray:(NSArray *)source;

// dicionary with copies of the objects in the source dictionary (1-deep)
+ (NSDictionary *)dictionaryWithCopiesOfObjectsInDictionary:(NSDictionary *)source;
+ (NSMutableDictionary *)mutableDictionaryWithCopiesOfObjectsInDictionary:(NSDictionary *)source;

// dictionary with 1-deep copies of the arrays which are the source dictionary's
// values (2-deep)
+ (NSDictionary *)dictionaryWithCopiesOfArraysInDictionary:(NSDictionary *)source;
+ (NSMutableDictionary *)mutableDictionaryWithCopiesOfArraysInDictionary:(NSDictionary *)source;

//
// string encoding
//

// URL encoding, different for parts of URLs and parts of URL parameters
//
// +stringByURLEncodingString just makes a string legal for a URL
//
// +stringByURLEncodingForURI also encodes some characters that are legal in
// URLs but should not be used in URIs,
// per http://bitworking.org/projects/atom/rfc5023.html#rfc.section.9.7
//
// +stringByURLEncodingStringParameter is like +stringByURLEncodingForURI but
// replaces space characters with + characters rather than percent-escaping them
//
+ (NSString *)stringByURLEncodingString:(NSString *)str;
+ (NSString *)stringByURLEncodingForURI:(NSString *)str;
+ (NSString *)stringByURLEncodingStringParameter:(NSString *)str;

// percent-encoded UTF-8
+ (NSString *)stringByPercentEncodingUTF8ForString:(NSString *)str;

//
// key-value coding searches in an array
//
// utilities to get from an array objects having a known value (or nil)
// at a keyPath

+ (NSArray *)objectsFromArray:(NSArray *)sourceArray
                    withValue:(id)desiredValue
                   forKeyPath:(NSString *)keyPath;

+ (id)firstObjectFromArray:(NSArray *)sourceArray
                 withValue:(id)desiredValue
                forKeyPath:(NSString *)keyPath;

//
// version helpers
//

+ (NSComparisonResult)compareVersion:(NSString *)ver1 toVersion:(NSString *)ver2;

//
// response string helpers
//

// convert responses of the form "a=foo \n b=bar"   to a dictionary
+ (NSDictionary *)dictionaryWithResponseString:(NSString *)str;
+ (NSDictionary *)dictionaryWithResponseData:(NSData *)data;

//
// file type helpers
//

// utility routine to convert a file name to the file's MIME type
+ (NSString *)MIMETypeForFileAtPath:(NSString *)filename
                    defaultMIMEType:(NSString *)defaultType;


@end
