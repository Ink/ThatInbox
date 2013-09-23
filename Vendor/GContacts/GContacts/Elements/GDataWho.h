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
//  GDataWho.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE

#import "GDataObject.h"
#import "GDataValueConstruct.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATAWHO_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataWhoEventAttendee  _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.attendee");
_EXTERN NSString* const kGDataWhoEventOrganizer _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.organizer");
_EXTERN NSString* const kGDataWhoEventSpeaker   _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.speaker");
_EXTERN NSString* const kGDataWhoEventPerformer _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.performer");

_EXTERN NSString* const kGDataWhoAttendeeTypeRequired     _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.required");
_EXTERN NSString* const kGDataWhoAttendeeTypeOptional     _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.optional");

_EXTERN NSString* const kGDataWhoAttendeeStatusInvited    _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.invited");
_EXTERN NSString* const kGDataWhoAttendeeStatusAccepted   _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.accepted");
_EXTERN NSString* const kGDataWhoAttendeeStatusTentative  _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.tentative");
_EXTERN NSString* const kGDataWhoAttendeeStatusDeclined   _INITIALIZE_AS(@"http://schemas.google.com/g/2005#event.declined");

_EXTERN NSString* const kGDataWhoTaskAssignedTo _INITIALIZE_AS(@"http://schemas.google.com/g/2005#task.assigned-to");

_EXTERN NSString* const kGDataWhoMessageFrom    _INITIALIZE_AS(@"http://schemas.google.com/g/2005#message.from");
_EXTERN NSString* const kGDataWhoMessageTo      _INITIALIZE_AS(@"http://schemas.google.com/g/2005#message.to");
_EXTERN NSString* const kGDataWhoMessageCC      _INITIALIZE_AS(@"http://schemas.google.com/g/2005#message.cc");
_EXTERN NSString* const kGDataWhoMessageBCC     _INITIALIZE_AS(@"http://schemas.google.com/g/2005#message.bcc");

@class GDataEntryLink;

@interface GDataAttendeeStatus : GDataValueConstruct <GDataExtension>
+ (NSString *)extensionElementURI;
+ (NSString *)extensionElementPrefix;
+ (NSString *)extensionElementLocalName;
@end

@interface GDataAttendeeType : GDataValueConstruct <GDataExtension>
+ (NSString *)extensionElementURI;
+ (NSString *)extensionElementPrefix;
+ (NSString *)extensionElementLocalName;
@end


// a who entry, as in
// <gd:who rel="http://schemas.google.com/g/2005#event.organizer" valueString="Fred Flintstone" email="fred@domain.com">
//   <gd:attendeeStatus value="http://schemas.google.com/g/2005#event.accepted"/>
// </gd:who>
//
// http://code.google.com/apis/gdata/common-elements.html#gdWho
@interface GDataWho : GDataObject <GDataExtension> {
}

+ (GDataWho *)whoWithRel:(NSString *)rel
                    name:(NSString *)valueString
                   email:(NSString *)email; // name and email may be nil

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (NSString *)email;
- (void)setEmail:(NSString *)str;

- (NSString *)stringValue; // gets the "valueString" XML attribute
- (void)setStringValue:(NSString *)str; // sets the "valueString" XML attribute

- (GDataAttendeeType *)attendeeType;
- (void)setAttendeeType:(GDataAttendeeType *)val;

- (GDataAttendeeStatus *)attendeeStatus;
- (void)setAttendeeStatus:(GDataAttendeeStatus *)val;

- (GDataEntryLink *)entryLink;
- (void)setEntryLink:(GDataEntryLink *)entryLink;
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE
