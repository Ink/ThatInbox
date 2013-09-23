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
//  GDataName.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"

@interface GDataNameElement : GDataObject

+ (id)nameElementWithString:(NSString *)str;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;

// an optional yomi attribute for pronunciation
- (void)setYomi:(NSString *)str;
- (NSString *)yomi;
@end

@interface GDataName : GDataObject <GDataExtension>

+ (GDataName *)name;
+ (GDataName *)nameWithFullNameString:(NSString *)str;
+ (GDataName *)nameWithPrefix:(NSString *)prefix
                  givenString:(NSString *)first
             additionalString:(NSString *)middle
                 familyString:(NSString *)last
                       suffix:(NSString *)suffix;

- (GDataNameElement *)additionalName;
- (void)setAdditionalName:(GDataNameElement *)obj;
- (void)setAdditionalNameWithString:(NSString *)str;

- (GDataNameElement *)familyName;
- (void)setFamilyName:(GDataNameElement *)obj;
- (void)setFamilyNameWithString:(NSString *)str;

- (GDataNameElement *)fullName;
- (void)setFullName:(GDataNameElement *)obj;
- (void)setFullNameWithString:(NSString *)str;

- (GDataNameElement *)givenName;
- (void)setGivenName:(GDataNameElement *)obj;
- (void)setGivenNameWithString:(NSString *)str;

- (NSString *)namePrefix;
- (void)setNamePrefix:(NSString *)str;

- (NSString *)nameSuffix;
- (void)setNameSuffix:(NSString *)str;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
