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
//  GDataComment.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_BOOKS_SERVICE \
  || GDATA_INCLUDE_CALENDAR_SERVICE || GDATA_INCLUDE_YOUTUBE_SERVICE

#import "GDataObject.h"
#import "GDataFeedLink.h"

// a commments entry, as in
// <gd:comments>
//    <gd:feedLink href="http://www.google.com/calendar/feeds/t..."/>
// </gd:comments>
//
// http://code.google.com/apis/gdata/common-elements.html#gdComments

@interface GDataComment : GDataObject <GDataExtension> {
}

+ (GDataComment *)commentWithFeedLink:(GDataFeedLink *)feedLink;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (GDataFeedLink *)feedLink;
- (void)setFeedLink:(GDataFeedLink *)feedLink;
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_*_SERVICE
