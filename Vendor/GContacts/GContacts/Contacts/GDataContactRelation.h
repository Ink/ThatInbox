/* Copyright (c) 2008 Google Inc.
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
//  GDataContactRelation.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATACONTACTRELATION_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

// rel values
_EXTERN NSString* kGDataContactRelationAssistant        _INITIALIZE_AS(@"assistant");
_EXTERN NSString* kGDataContactRelationBrother          _INITIALIZE_AS(@"brother");
_EXTERN NSString* kGDataContactRelationChild            _INITIALIZE_AS(@"child");
_EXTERN NSString* kGDataContactRelationDomesticPartner  _INITIALIZE_AS(@"domestic-partner");
_EXTERN NSString* kGDataContactRelationFather           _INITIALIZE_AS(@"father");
_EXTERN NSString* kGDataContactRelationFriend           _INITIALIZE_AS(@"friend");
_EXTERN NSString* kGDataContactRelationManager          _INITIALIZE_AS(@"manager");
_EXTERN NSString* kGDataContactRelationMother           _INITIALIZE_AS(@"mother");
_EXTERN NSString* kGDataContactRelationParent           _INITIALIZE_AS(@"parent");
_EXTERN NSString* kGDataContactRelationPartner          _INITIALIZE_AS(@"partner");
_EXTERN NSString* kGDataContactRelationReferredBy       _INITIALIZE_AS(@"referred-by");
_EXTERN NSString* kGDataContactRelationRelative         _INITIALIZE_AS(@"relative");
_EXTERN NSString* kGDataContactRelationSister           _INITIALIZE_AS(@"sister");
_EXTERN NSString* kGDataContactRelationSpouse           _INITIALIZE_AS(@"spouse");

@interface GDataContactRelation : GDataObject <GDataExtension>

+ (id)relationWithRel:(NSString *)rel
                label:(NSString *)label
                value:(NSString *)value;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (NSString *)label;
- (void)setLabel:(NSString *)str;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
