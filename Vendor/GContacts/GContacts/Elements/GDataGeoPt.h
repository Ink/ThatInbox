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
//  GDataGeoPt.h
//
//  NOTE: As of July 2007, GDataGeoPt is deprecated.  Use GDataGeo instead.
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE

#import "GDataObject.h"

@class GDataDateTime;

// geoPt element, as in
//   <gd:geoPt lat="27.98778" lon="86.94444" elev="8850.0"/>
//
// http://code.google.com/apis/gdata/common-elements.html#gdGeoPt


@interface GDataGeoPt : GDataObject <NSCopying, GDataExtension> {
  NSString *label_;
  NSNumber *lat_;
  NSNumber *lon_;
  NSNumber *elev_;
  GDataDateTime* time_;
}
+ (GDataGeoPt *)geoPtWithLabel:(NSString *)label
                           lat:(NSNumber *)lat
                           lon:(NSNumber *)lon
                          elev:(NSNumber *)elev
                          time:(GDataDateTime *)aTime;

- (id)initWithXMLElement:(NSXMLElement *)element
                  parent:(GDataObject *)parent;
- (NSXMLElement *)XMLElement;

- (NSString *)label;
- (void)setLabel:(NSString *)str;
- (NSNumber *)lat;
- (void)setLat:(NSNumber *)val;
- (NSNumber *)lon;
- (void)setLon:(NSNumber *)val;
- (NSNumber *)elev;
- (void)setElev:(NSNumber *)val;
- (GDataDateTime *)time;
- (void)setTime:(GDataDateTime *)cdate;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE
