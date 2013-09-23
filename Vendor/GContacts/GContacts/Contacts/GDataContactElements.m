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
//  GDataContactElements.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#define GDATACONTACTELEMENTS_DEFINE_GLOBALS 1
#import "GDataContactElements.h"

#import "GDataContactConstants.h"

// billing, like <gContact:billingInformation>Blah</gContact:billingInformation>
@implementation GDataContactBillingInformation
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"billingInformation"; }
@end

// birthday, like <gContact:birthday when="1-Jan-1992" />
@implementation GDataContactBirthday
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"birthday"; }

- (NSString *)attributeName { return @"when"; }
@end

// related calendar link
@implementation GDataContactCalendarLink
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"calendarLink"; }
@end

// directory server, like <gContact:directoryServer>directory.domain.com</gContact:directoryServer>
@implementation GDataContactDirectoryServer
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"directoryServer"; }
@end

// gender, like <gContact:gender value="female" />
@implementation GDataContactGender
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"gender"; }
@end

// hobby, like <gContact:hobby>eating crackers</gContact:hobby> // TODO - sure it's an element, not an attribute?
@implementation GDataContactHobby
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"hobby"; }
@end

// initials, like <gContact:initials>I.M.</gContact:initials> // TODO - sure it's an element, not an attribute?
@implementation GDataContactInitials
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"initials"; }
@end

// maiden name, like <gContact:maidenName>Sosnick</gContact:maidenName>
@implementation GDataContactMaidenName
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"maidenName"; }
@end

// mileage, like <gContact:mileage>20 km/l</gContact:mileage>
@implementation GDataContactMileage
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"mileage"; }
@end

// nickname, like <gContact:nickname>Freddy</gContact:nickname>
@implementation GDataContactNickname
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"nickname"; }
@end

// occupation, like <gContact:occupation>Chef</gContact:occupation>
@implementation GDataContactOccupation
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"occupation"; }
@end

// server, like <gContact:shortName>Fred</gContact:shortName>
@implementation GDataContactShortName
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"shortName"; }
@end

// server, like <gContact:subject>Nothing much</gContact:subject>
@implementation GDataContactSubject
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"subject"; }
@end

// related website link
@implementation GDataContactWebsiteLink
+ (NSString *)extensionElementURI       { return kGDataNamespaceContact; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceContactPrefix; }
+ (NSString *)extensionElementLocalName { return @"website"; }
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
