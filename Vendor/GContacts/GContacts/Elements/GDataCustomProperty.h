/* Copyright (c) 2009 Google Inc.
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
//  GDataCustomProperty.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_MAPS_SERVICE

#import "GDataObject.h"

// custom property element, like
//
//   <gd:customProperty name="milk" type="integer" unit="gallons">
//     5
//   </gd:customProperty>

@interface GDataCustomProperty : GDataObject <GDataExtension>

+ (GDataCustomProperty *)customPropertyWithName:(NSString *)name
                                           type:(NSString *)type
                                          value:(NSString *)value
                                           unit:(NSString *)unit;

- (NSString *)name;
- (void)setName:(NSString *)str;

- (NSString *)type;
- (void)setType:(NSString *)str;

- (NSString *)unit;
- (void)setUnit:(NSString *)str;

- (NSString *)value;
- (void)setValue:(NSString *)str;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_MAPS_SERVICE
