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
//  GDataWhere.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE \
  || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATAWHERE_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

// rel values
_EXTERN NSString* const kGDataEventWhereEventLocation _INITIALIZE_AS(nil); // use the enclosing event's location
_EXTERN NSString* const kGDataEventWhereAlternate _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.alternate");
_EXTERN NSString* const kGDataEventWhereParking _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.parking");

@class GDataEntryLink;

// where element, as in
// <gd:where rel="http://schemas.google.com/g/2005#event" valueString="Joe's Pub">
//    <gd:entryLink href="http://local.example.com/10018/JoesPub">
// </gd:where>
//
// http://code.google.com/apis/gdata/common-elements.html#gdWhere

@interface GDataWhere : GDataObject <GDataExtension>

+ (GDataWhere *)whereWithString:(NSString *)str;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (NSString *)label;
- (void)setLabel:(NSString *)str;

- (NSString *)stringValue; // gets the "valueString" XML attribute
- (void)setStringValue:(NSString *)str; // sets the "valueString" XML attribute

- (GDataEntryLink *)entryLink;
- (void)setEntryLink:(GDataEntryLink *)entryLink;
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_*_SERVICE
