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
//  GDataContactElements.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"
#import "GDataValueConstruct.h"
#import "GDataContactLink.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATACONTACTELEMENTS_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

// gender 
_EXTERN NSString* kGDataContactGenderFemale         _INITIALIZE_AS(@"female");
_EXTERN NSString* kGDataContactGenderMale           _INITIALIZE_AS(@"male");

// calendarLink rel
_EXTERN NSString* kGDataContactCalendarLinkHome     _INITIALIZE_AS(@"home");
_EXTERN NSString* kGDataContactCalendarLinkWork     _INITIALIZE_AS(@"work");
_EXTERN NSString* kGDataContactCalendarLinkFreeBusy _INITIALIZE_AS(@"free-busy");

// websiteLink rel
_EXTERN NSString* kGDataContactWebsiteLinkBlog     _INITIALIZE_AS(@"blog");
_EXTERN NSString* kGDataContactWebsiteLinkFTP      _INITIALIZE_AS(@"ftp");
_EXTERN NSString* kGDataContactWebsiteLinkHome     _INITIALIZE_AS(@"home");
_EXTERN NSString* kGDataContactWebsiteLinkHomePage _INITIALIZE_AS(@"home-page");
_EXTERN NSString* kGDataContactWebsiteLinkOther    _INITIALIZE_AS(@"other");
_EXTERN NSString* kGDataContactWebsiteLinkProfile  _INITIALIZE_AS(@"profile");
_EXTERN NSString* kGDataContactWebsiteLinkWork     _INITIALIZE_AS(@"work");

// billing, like <gContact:billingInformation>Blah</gContact:billingInformation>
@interface GDataContactBillingInformation : GDataValueElementConstruct <GDataExtension>
@end

// birthday, like <gContact:birthday when="1-Jan-1992" />
@interface GDataContactBirthday : GDataValueConstruct <GDataExtension>
@end

// related calendar link
@interface GDataContactCalendarLink : GDataContactLink <GDataExtension> 
@end

// directory server, like <gContact:directoryServer>directory.domain.com</gContact:directoryServer>
@interface GDataContactDirectoryServer : GDataValueElementConstruct <GDataExtension>
@end

// gender, like <gContact:gender value="female" />
@interface GDataContactGender : GDataValueConstruct <GDataExtension>
@end

// hobby, like <gContact:hobby>eating crackers</gContact:hobby> // TODO - sure it's an element, not an attribute?
@interface GDataContactHobby : GDataValueElementConstruct <GDataExtension>
@end

// initials, like <gContact:initials>I.M.</gContact:initials> // TODO - sure it's an element, not an attribute?
@interface GDataContactInitials : GDataValueElementConstruct <GDataExtension>
@end

// maiden name, like <gContact:maidenName>Sosnick</gContact:maidenName>
@interface GDataContactMaidenName : GDataValueElementConstruct <GDataExtension>
@end

// mileage, like <gContact:mileage>20 km/l</gContact:mileage>
@interface GDataContactMileage : GDataValueElementConstruct <GDataExtension>
@end

// nickname, like <gContact:nickname>Freddy</gContact:nickname>
@interface GDataContactNickname : GDataValueElementConstruct <GDataExtension>
@end

// occupation, like <gContact:occupation>Chef</gContact:occupation>
@interface GDataContactOccupation : GDataValueElementConstruct <GDataExtension>
@end

// short name, like <gContact:shortName>Fred</gContact:shortName>
@interface GDataContactShortName : GDataValueElementConstruct <GDataExtension>
@end

// subject, like <gContact:subject>data</gContact:subject>
@interface GDataContactSubject : GDataValueElementConstruct <GDataExtension>
@end

// related website link
@interface GDataContactWebsiteLink : GDataContactLink <GDataExtension> 
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
