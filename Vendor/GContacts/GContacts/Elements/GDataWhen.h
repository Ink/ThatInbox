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
//  GDataWhen.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE \
   || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"

#import "GDataDateTime.h"

// when element, as in
// <gd:when startTime="2005-06-06" endTime="2005-06-07" valueString="This weekend"/>
//
// http://code.google.com/apis/gdata/common-elements.html#gdWhen

@interface GDataWhen : GDataObject <GDataExtension> {
}

+ (GDataWhen *)whenWithStartTime:(GDataDateTime *)startTime
                         endTime:(GDataDateTime *)endTime;

- (GDataDateTime *)startTime;
- (void)setStartTime:(GDataDateTime *)cdate;

- (GDataDateTime *)endTime;
- (void)setEndTime:(GDataDateTime *)cdate;

- (NSString *)value;
- (void)setValue:(NSString *)str;
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE
