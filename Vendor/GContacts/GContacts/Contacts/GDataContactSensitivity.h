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
//  GDataContactSensitivity.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATACONTACTSENSITIVITY_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

// rel values
_EXTERN NSString* kGDataContactSensitivityConfidential _INITIALIZE_AS(@"confidential");
_EXTERN NSString* kGDataContactSensitivityNormal       _INITIALIZE_AS(@"normal");
_EXTERN NSString* kGDataContactSensitivityPersonal     _INITIALIZE_AS(@"personal");
_EXTERN NSString* kGDataContactSensitivityPrivate      _INITIALIZE_AS(@"private");

@interface GDataContactSensitivity : GDataObject <GDataExtension>

+ (id)sensitivityWithRel:(NSString *)rel;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
