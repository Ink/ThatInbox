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
//  GDataContactEvent.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"
#import "GDataWhen.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATACONTACTEVENT_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* kGDataContactEventAnniversary _INITIALIZE_AS(@"anniversary");
_EXTERN NSString* kGDataContactEventOther       _INITIALIZE_AS(@"other");

@interface GDataContactEvent : GDataObject <GDataExtension>

+ (id)eventWithRel:(NSString *)rel
             label:(NSString *)label
              when:(GDataWhen *)when;
  
- (NSString *)label;
- (void)setLabel:(NSString *)str;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (GDataWhen *)when;
- (void)setWhen:(GDataWhen *)obj;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
