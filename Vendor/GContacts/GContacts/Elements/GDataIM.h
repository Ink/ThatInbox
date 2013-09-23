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
//  GDataIM.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATAIM_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataIMProtocolAIM        _INITIALIZE_AS(@"http://schemas.google.com/g/2005#AIM");
_EXTERN NSString* const kGDataIMProtocolGoogleTalk _INITIALIZE_AS(@"http://schemas.google.com/g/2005#GOOGLE_TALK");
_EXTERN NSString* const kGDataIMProtocolICQ        _INITIALIZE_AS(@"http://schemas.google.com/g/2005#ICQ");
_EXTERN NSString* const kGDataIMProtocolJabber     _INITIALIZE_AS(@"http://schemas.google.com/g/2005#JABBER");
_EXTERN NSString* const kGDataIMProtocolMSN        _INITIALIZE_AS(@"http://schemas.google.com/g/2005#MSN");
_EXTERN NSString* const kGDataIMProtocolNetMeeting _INITIALIZE_AS(@"http://schemas.google.com/g/2005#NETMEETING");
_EXTERN NSString* const kGDataIMProtocolQQ         _INITIALIZE_AS(@"http://schemas.google.com/g/2005#QQ");
_EXTERN NSString* const kGDataIMProtocolSkype      _INITIALIZE_AS(@"http://schemas.google.com/g/2005#SKYPE");
_EXTERN NSString* const kGDataIMProtocolYahoo      _INITIALIZE_AS(@"http://schemas.google.com/g/2005#YAHOO");

// IM element, as in
//   <gd:im protocol="http://schemas.google.com/g/2005#MSN"
//      address="foo@bar.example.com" label="Alternate"
//      rel="http://schemas.google.com/g/2005#other" >
//
// http://code.google.com/apis/gdata/common-elements.html#gdIm

@interface GDataIM : GDataObject <GDataExtension> {
}

+ (GDataIM *)IMWithProtocol:(NSString *)protocol
                        rel:(NSString *)rel
                      label:(NSString *)label
                    address:(NSString *)address;

- (NSString *)address;
- (void)setAddress:(NSString *)str;

- (NSString *)label;
- (void)setLabel:(NSString *)str;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (NSString *)protocol;
- (void)setProtocol:(NSString *)str;

- (BOOL)isPrimary;
- (void)setIsPrimary:(BOOL)flag;
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
