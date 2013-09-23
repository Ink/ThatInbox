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
//  GDataEmail.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"


// email element
// <gd:email label="Personal" address="fubar@gmail.com"/>
//
// http://code.google.com/apis/gdata/common-elements.html#gdEmail

@interface GDataEmail : GDataObject <GDataExtension>

+ (GDataEmail *)emailWithLabel:(NSString *)label
                       address:(NSString *)address;

- (NSString *)label;
- (void)setLabel:(NSString *)str;

- (NSString *)address;
- (void)setAddress:(NSString *)str;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (BOOL)isPrimary;
- (void)setIsPrimary:(BOOL)flag;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
