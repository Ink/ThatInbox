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
//  GDataEntryContactBase.h
//
//  base class for GDataEntryContact and GDataEntryContactProfile
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataEntryBase.h"
#import "GDataContactElements.h"
#import "GDataOrganization.h"
#import "GDataEmail.h"
#import "GDataIM.h"
#import "GDataPhoneNumber.h"
#import "GDataPostalAddress.h"
#import "GDataCategory.h"
#import "GDataExtendedProperty.h"
#import "GDataWhere.h"
#import "GDataName.h"
#import "GDataContactLink.h"
#import "GDataContactEvent.h"
#import "GDataContactExternalID.h"
#import "GDataContactJot.h"
#import "GDataContactLanguage.h"
#import "GDataContactPriority.h"
#import "GDataContactRelation.h"
#import "GDataContactSensitivity.h"
#import "GDataStructuredPostalAddress.h"
#import "GDataContactUserDefinedField.h"

@interface GDataEntryContactBase : GDataEntryBase

// many types of contact data include convenience methods for getting or
// setting a primary element.

- (NSArray *)organizations;
- (void)setOrganizations:(NSArray *)array;
- (void)addOrganization:(GDataOrganization *)obj;
- (void)removeOrganization:(GDataOrganization *)obj;

- (GDataOrganization *)primaryOrganization;
- (void)setPrimaryOrganization:(GDataOrganization *)obj;

- (NSArray *)emailAddresses;
- (void)setEmailAddresses:(NSArray *)array;
- (void)addEmailAddress:(GDataEmail *)obj;
- (void)removeEmailAddress:(GDataEmail *)obj;

- (GDataEmail *)primaryEmailAddress;
- (void)setPrimaryEmailAddress:(GDataEmail *)obj;

- (NSArray *)IMAddresses;
- (void)setIMAddresses:(NSArray *)array;
- (void)addIMAddress:(GDataIM *)obj;
- (void)removeIMAddress:(GDataIM *)obj;

- (GDataIM *)primaryIMAddress;
- (void)setPrimaryIMAddress:(GDataIM *)obj;

- (NSArray *)phoneNumbers;
- (void)setPhoneNumbers:(NSArray *)array;
- (void)addPhoneNumber:(GDataPhoneNumber *)obj;
- (void)removePhoneNumber:(GDataPhoneNumber *)obj;

- (GDataPhoneNumber *)primaryPhoneNumber;
- (void)setPrimaryPhoneNumber:(GDataPhoneNumber *)obj;

// postalAddress methods are deprecated in V3 of the Contacts API;
// use structuredPostalAddress instead
- (NSArray *)postalAddresses;
- (void)setPostalAddresses:(NSArray *)array;
- (void)addPostalAddress:(GDataPostalAddress *)obj;
- (void)removePostalAddress:(GDataPostalAddress *)obj;

- (GDataPostalAddress *)primaryPostalAddress;
- (void)setPrimaryPostalAddress:(GDataPostalAddress *)obj;

- (NSArray *)extendedProperties;
- (void)setExtendedProperties:(NSArray *)arr;
- (void)addExtendedProperty:(GDataExtendedProperty *)obj;
- (void)removeExtendedProperty:(GDataExtendedProperty *)obj;

//
// version 3 elements
//

- (NSString *)billingInformation;
- (void)setBillingInformation:(NSString *)str;

// birthday should be in format YYYY-MM-DD or --MM-DD
- (NSString *)birthday;
- (void)setBirthday:(NSString *)str;

// convenience birthday methods; the "undefined" year is considered year 1804
- (NSDate *)birthdayDate;
- (void)setBirthdayWithDate:(NSDate *)date;

- (NSArray *)calendarLinks;
- (void)setCalendarLinks:(NSArray *)array;
- (void)addCalendarLink:(GDataContactCalendarLink *)obj;
- (void)removeCalendarLink:(GDataContactCalendarLink *)obj;

- (GDataContactCalendarLink *)primaryCalendarLink;
- (void)setPrimaryCalendarLink:(GDataContactCalendarLink *)obj;

- (NSString *)directoryServer;
- (void)setDirectoryServer:(NSString *)str;

- (NSArray *)events;
- (void)setEvents:(NSArray *)array;
- (void)addEvent:(GDataContactEvent *)obj;

- (NSArray *)externalIDs;
- (void)setExternalIDs:(NSArray *)array;
- (void)addExternalID:(GDataContactExternalID *)obj;

- (NSString *)gender;
- (void)setGender:(NSString *)str;

- (NSArray *)hobbies;
- (void)setHobbies:(NSArray *)array;
- (void)addHobby:(GDataContactHobby *)obj;

- (NSString *)initials;
- (void)setInitials:(NSString *)str;

// jots are free-form user-defined notes about the contact
- (NSArray *)jots;
- (void)setJots:(NSArray *)array;
- (void)addJot:(GDataContactJot *)obj;

- (NSArray *)languages;
- (void)setLanguages:(NSArray *)array;
- (void)addLanguage:(GDataContactLanguage *)obj;

- (NSString *)maidenName;
- (void)setMaidenName:(NSString *)str;

- (NSString *)mileage;
- (void)setMileage:(NSString *)str;

- (GDataName *)name;
- (void)setName:(GDataName *)obj;

- (NSString *)nickname;
- (void)setNickname:(NSString *)str;

- (NSString *)occupation;
- (void)setOccupation:(NSString *)str;

- (NSString *)priority;
- (void)setPriority:(NSString *)str;

- (NSArray *)relations;
- (void)setRelations:(NSArray *)array;
- (void)addRelation:(GDataContactRelation *)obj;

- (NSString *)sensitivity;
- (void)setSensitivity:(NSString *)str;

- (NSString *)shortName;
- (void)setShortName:(NSString *)str;

- (NSArray *)structuredPostalAddresses;
- (void)setStructuredPostalAddresses:(NSArray *)arr;
- (void)addStructuredPostalAddress:(GDataStructuredPostalAddress *)obj;
- (void)removeStructuredPostalAddress:(GDataStructuredPostalAddress *)obj;

- (GDataStructuredPostalAddress *)primaryStructuredPostalAddress;
- (void)setPrimaryStructuredPostalAddress:(GDataStructuredPostalAddress *)obj;

- (NSString *)subject;
- (void)setSubject:(NSString *)str;

- (NSArray *)userDefinedFields;
- (void)setUserDefinedFields:(NSArray *)arr;
- (void)addUserDefinedField:(GDataContactUserDefinedField *)obj;
- (void)removeUserDefinedField:(GDataContactUserDefinedField *)obj;

- (NSArray *)websiteLinks;
- (void)setWebsiteLinks:(NSArray *)array;
- (void)addWebsiteLink:(GDataContactWebsiteLink *)obj;
- (void)removeWebsiteLink:(GDataContactWebsiteLink *)obj;

- (GDataWhere *)where;
- (void)setWhere:(GDataWhere *)obj;

// convenience accessors
- (GDataExtendedProperty *)extendedPropertyForName:(NSString *)name;

- (GDataLink *)photoLink;

// protected methods - for subclasses only
- (GDataObject *)primaryObjectForExtensionClass:(Class)extensionClass;
- (void)setPrimaryObject:(GDataObject *)newPrimaryObj
       forExtensionClass:(Class)extensionClass;
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
