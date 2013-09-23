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
//  GDataRating.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_BOOKS_SERVICE \
  || GDATA_INCLUDE_CALENDAR_SERVICE || GDATA_INCLUDE_YOUTUBE_SERVICE

#import "GDataObject.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATARATING_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataRatingPrice   _INITIALIZE_AS(@"http://schemas.google.com/g/2005#price");
_EXTERN NSString* const kGDataRatingQuality _INITIALIZE_AS(@"http://schemas.google.com/g/2005#quality");

// rating, as in
//  <gd:rating rel="http://schemas.google.com/g/2005#price" value="5" min="1" max="5"/>
//
// http://code.google.com/apis/gdata/common-elements.html#gdRating

@interface GDataRating : GDataObject <GDataExtension>

+ (GDataRating *)ratingWithValue:(NSInteger)value
                             max:(NSInteger)max
                             min:(NSInteger)min;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (NSNumber *)value; // int
- (void)setValue:(NSNumber *)num;

- (NSNumber *)max; // int
- (void)setMax:(NSNumber *)num;

- (NSNumber *)min; // int
- (void)setMin:(NSNumber *)num;

- (NSNumber *)average; // double
- (void)setAverage:(NSNumber *)num;

- (NSNumber *)numberOfRaters; // int
- (void)setNumberOfRaters:(NSNumber *)num;
@end

#endif // #if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_*_SERVICE
