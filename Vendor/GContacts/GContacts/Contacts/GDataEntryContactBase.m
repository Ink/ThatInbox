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
//  GDataEntryContact.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataEntryContactBase.h"
#import "GDataContactConstants.h"

@implementation GDataEntryContactBase

+ (NSString *)coreProtocolVersionForServiceVersion:(NSString *)serviceVersion {
  return [GDataContactConstants coreProtocolVersionForServiceVersion:serviceVersion];
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  Class entryClass = [self class];

  // ContactEntry extensions

  [self addExtensionDeclarationForParentClass:entryClass
                                 childClasses:
   [GDataOrganization class],
   [GDataEmail class],
   [GDataIM class],
   [GDataPhoneNumber class],
   [GDataPostalAddress class],
   [GDataExtendedProperty class],

   // version 3 extensions
   [GDataContactBillingInformation class],
   [GDataContactBirthday class],
   [GDataContactCalendarLink class],
   [GDataContactDirectoryServer class],
   [GDataContactEvent class],
   [GDataContactExternalID class],
   [GDataContactGender class],
   [GDataContactHobby class],
   [GDataContactInitials class],
   [GDataContactJot class],
   [GDataContactLanguage class],
   [GDataWhere class],
   [GDataContactMaidenName class],
   [GDataContactMileage class],
   [GDataName class],
   [GDataContactNickname class],
   [GDataContactOccupation class],
   [GDataContactPriority class],
   [GDataContactRelation class],
   [GDataContactSensitivity class],
   [GDataContactShortName class],
   [GDataStructuredPostalAddress class],
   [GDataContactSubject class],
   [GDataContactUserDefinedField class],
   [GDataContactWebsiteLink class],
   nil];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {
  static struct GDataDescriptionRecord descRecs[] = {
    { @"org",               @"organizations",      kGDataDescArrayDescs },
    { @"email",             @"emailAddresses",     kGDataDescArrayDescs },
    { @"phone",             @"phoneNumbers",       kGDataDescArrayDescs },
    { @"IM",                @"IMAddresses",        kGDataDescArrayDescs },
    { @"extProps",          @"extendedProperties", kGDataDescArrayDescs },
    { @"version<=2:postal", @"postalAddresses",    kGDataDescArrayDescs },
    { nil, nil, (GDataDescRecTypes)0 }
  };

  NSMutableArray *items = [super itemsForDescription];
  [self addDescriptionRecords:descRecs toItems:items];

  // description info for methods that assert prior to V3
  if ([self isServiceVersionAtLeast:kGDataContactServiceV3]) {
    static struct GDataDescriptionRecord descRecsV3[] = {
      // v3 extensions
      { @"name",         @"name",                      kGDataDescValueLabeled },
      { @"structPostal", @"structuredPostalAddresses", kGDataDescArrayDescs   },
      { @"billing",      @"billingInformation",        kGDataDescValueLabeled },
      { @"birthday",     @"birthday",                  kGDataDescValueLabeled },
      { @"calendar",     @"calendarLinks",             kGDataDescArrayDescs   },
      { @"dirServer",    @"directoryServer",           kGDataDescValueLabeled },
      { @"event",        @"events",                    kGDataDescArrayDescs   },
      { @"extID",        @"externalIDs",               kGDataDescArrayDescs   },
      { @"gender",       @"gender",                    kGDataDescValueLabeled },
      { @"hobby",        @"hobbies",                   kGDataDescArrayDescs   },
      { @"initials",     @"initials",                  kGDataDescValueLabeled },
      { @"jot",          @"jots",                      kGDataDescArrayDescs   },
      { @"lang",         @"languages",                 kGDataDescArrayDescs   },
      { @"where",        @"where",                     kGDataDescValueLabeled },
      { @"maidenName",   @"maidenName",                kGDataDescValueLabeled },
      { @"mileage",      @"mileage",                   kGDataDescValueLabeled },
      { @"nickname",     @"nickname",                  kGDataDescValueLabeled },
      { @"occupation",   @"occupation",                kGDataDescValueLabeled },
      { @"priority",     @"priority",                  kGDataDescValueLabeled },
      { @"relation",     @"relations",                 kGDataDescArrayDescs   },
      { @"sensitivity",  @"sensitivity",               kGDataDescValueLabeled },
      { @"shortName",    @"shortName",                 kGDataDescValueLabeled },
      { @"subject",      @"subject",                   kGDataDescValueLabeled },
      { @"userDefd",     @"userDefinedFields",         kGDataDescArrayDescs   },
      { @"website",      @"websiteLinks",              kGDataDescArrayDescs   },

      { nil, nil, (GDataDescRecTypes)0 }
    };

    [self addDescriptionRecords:descRecsV3 toItems:items];
  }
  return items;
}
#endif

#pragma mark -

// The Focus UI does not happily handle empty strings, so we'll force those
// to be nil
- (void)setTitle:(GDataTextConstruct *)theTitle {
  // title is read-only beginning in service version 3
  GDATA_DEBUG_ASSERT_MAX_SERVICE_VERSION(kGDataContactServiceV2);

  if ([[theTitle stringValue] length] == 0) {
    theTitle = nil;
  }
  [super setTitle:theTitle];
}

- (void)setTitleWithString:(NSString *)str {
  GDATA_DEBUG_ASSERT_MAX_SERVICE_VERSION(kGDataContactServiceV2);

  if ([str length] == 0) {
    [self setTitle:nil];
  } else {
    [super setTitleWithString:str];
  }
}

#pragma mark -

// routines to do the work for finding or setting the primary elements
// of the different extension classes

- (GDataObject *)primaryObjectForExtensionClass:(Class)theClass {

  NSArray *extns = [self objectsForExtensionClass:theClass];

  for (GDataObject *obj in extns) {
    if ([(id)obj isPrimary]) return obj;
  }
  return nil;
}

- (void)setPrimaryObject:(GDataObject *)newPrimaryObj
       forExtensionClass:(Class)theClass {
  NSArray *extns =  [self objectsForExtensionClass:theClass];

  BOOL foundIt = NO;
  for (GDataObject *obj in extns) {
    BOOL isPrimary = [newPrimaryObj isEqual:obj];
    [(id)obj setIsPrimary:isPrimary];

    if (isPrimary) foundIt = YES;
  }

  // if the object isn't already in the list, add it
  if (!foundIt && newPrimaryObj != nil) {
    [(id)newPrimaryObj setIsPrimary:YES];
    [self addObject:newPrimaryObj forExtensionClass:theClass];
  }
}

#pragma mark -

- (NSArray *)organizations {
  return [self objectsForExtensionClass:[GDataOrganization class]];
}

- (void)setOrganizations:(NSArray *)array {
  [self setObjects:array forExtensionClass:[GDataOrganization class]];
}

- (void)addOrganization:(GDataOrganization *)obj {
  [self addObject:obj forExtensionClass:[GDataOrganization class]];
}

- (void)removeOrganization:(GDataOrganization *)obj {
  [self removeObject:obj forExtensionClass:[GDataOrganization class]];
}

- (GDataOrganization *)primaryOrganization {
  id obj = [self primaryObjectForExtensionClass:[GDataOrganization class]];
  return obj;
}

- (void)setPrimaryOrganization:(GDataOrganization *)obj {
  [self setPrimaryObject:obj forExtensionClass:[GDataOrganization class]];
}


- (NSArray *)emailAddresses {
  return [self objectsForExtensionClass:[GDataEmail class]];
}

- (void)setEmailAddresses:(NSArray *)array {
  [self setObjects:array forExtensionClass:[GDataEmail class]];
}

- (void)addEmailAddress:(GDataEmail *)obj {
  [self addObject:obj forExtensionClass:[GDataEmail class]];
}

- (void)removeEmailAddress:(GDataEmail *)obj {
  [self removeObject:obj forExtensionClass:[GDataEmail class]];
}

- (GDataEmail *)primaryEmailAddress {
  id obj = [self primaryObjectForExtensionClass:[GDataEmail class]];
  return obj;
}

- (void)setPrimaryEmailAddress:(GDataEmail *)obj {
  [self setPrimaryObject:obj forExtensionClass:[GDataEmail class]];
}


- (NSArray *)IMAddresses {
  return [self objectsForExtensionClass:[GDataIM class]];
}

- (void)setIMAddresses:(NSArray *)array {
  [self setObjects:array forExtensionClass:[GDataIM class]];
}

- (GDataIM *)primaryIMAddress {
  id obj = [self primaryObjectForExtensionClass:[GDataIM class]];
  return obj;
}

- (void)setPrimaryIMAddress:(GDataIM *)obj {
  [self setPrimaryObject:obj forExtensionClass:[GDataIM class]];
}

- (void)addIMAddress:(GDataIM *)obj {
  [self addObject:obj forExtensionClass:[GDataIM class]];
}

- (void)removeIMAddress:(GDataIM *)obj {
  [self removeObject:obj forExtensionClass:[GDataIM class]];
}


- (NSArray *)phoneNumbers {
  return [self objectsForExtensionClass:[GDataPhoneNumber class]];
}

- (void)setPhoneNumbers:(NSArray *)array {
  [self setObjects:array forExtensionClass:[GDataPhoneNumber class]];
}

- (void)addPhoneNumber:(GDataPhoneNumber *)obj {
  [self addObject:obj forExtensionClass:[GDataPhoneNumber class]];
}

- (void)removePhoneNumber:(GDataPhoneNumber *)obj {
  [self removeObject:obj forExtensionClass:[GDataPhoneNumber class]];
}

- (GDataPhoneNumber *)primaryPhoneNumber {
  id obj = [self primaryObjectForExtensionClass:[GDataPhoneNumber class]];
  return obj;
}

- (void)setPrimaryPhoneNumber:(GDataPhoneNumber *)obj {
  [self setPrimaryObject:obj forExtensionClass:[GDataPhoneNumber class]];
}


- (NSArray *)postalAddresses {
  GDATA_DEBUG_ASSERT_MAX_SERVICE_VERSION(kGDataContactServiceV2);

  return [self objectsForExtensionClass:[GDataPostalAddress class]];
}

- (void)setPostalAddresses:(NSArray *)array {
  GDATA_DEBUG_ASSERT_MAX_SERVICE_VERSION(kGDataContactServiceV2);

  [self setObjects:array forExtensionClass:[GDataPostalAddress class]];
}

- (void)addPostalAddress:(GDataPostalAddress *)obj {
  GDATA_DEBUG_ASSERT_MAX_SERVICE_VERSION(kGDataContactServiceV2);

  [self addObject:obj forExtensionClass:[GDataPostalAddress class]];
}

- (void)removePostalAddress:(GDataPostalAddress *)obj {
  GDATA_DEBUG_ASSERT_MAX_SERVICE_VERSION(kGDataContactServiceV2);

  [self removeObject:obj forExtensionClass:[GDataPostalAddress class]];
}

- (GDataPostalAddress *)primaryPostalAddress {
  GDATA_DEBUG_ASSERT_MAX_SERVICE_VERSION(kGDataContactServiceV2);

  id obj = [self primaryObjectForExtensionClass:[GDataPostalAddress class]];
  return obj;
}

- (void)setPrimaryPostalAddress:(GDataPostalAddress *)obj {
  GDATA_DEBUG_ASSERT_MAX_SERVICE_VERSION(kGDataContactServiceV2);

  [self setPrimaryObject:obj forExtensionClass:[GDataPostalAddress class]];
}


- (NSArray *)extendedProperties {
  return [self objectsForExtensionClass:[GDataExtendedProperty class]];
}

- (void)setExtendedProperties:(NSArray *)arr {
  [self setObjects:arr forExtensionClass:[GDataExtendedProperty class]];
}

- (void)addExtendedProperty:(GDataExtendedProperty *)obj {
  [self addObject:obj forExtensionClass:[GDataExtendedProperty class]];
}

- (void)removeExtendedProperty:(GDataExtendedProperty *)obj {
  [self removeObject:obj forExtensionClass:[GDataExtendedProperty class]];
}

- (GDataExtendedProperty *)extendedPropertyForName:(NSString *)str {

  GDataExtendedProperty *extProp = nil;

  NSArray *array = [self extendedProperties];
  if (array != nil) {
    extProp = [GDataUtilities firstObjectFromArray:array
                                         withValue:str
                                        forKeyPath:@"name"];
  }
  return extProp;
}

// version 3 elements

- (NSString *)billingInformation {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactBillingInformation *obj;
  obj = [self objectForExtensionClass:[GDataContactBillingInformation class]];
  return [obj stringValue];
}

- (void)setBillingInformation:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  if ([str length] == 0) str = nil;

  GDataContactBillingInformation *obj;
  obj = [GDataContactBillingInformation valueWithString:str];

  [self setObject:obj forExtensionClass:[GDataContactBillingInformation class]];
}


- (NSString *)birthday {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactBirthday *obj;
  obj = [self objectForExtensionClass:[GDataContactBirthday class]];
  return [obj stringValue];
}

- (void)setBirthday:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  if ([str length] == 0) str = nil;

  GDataContactBirthday *obj;
  obj = [GDataContactBirthday valueWithString:str];

  [self setObject:obj forExtensionClass:[GDataContactBirthday class]];
}

// Google Contacts allows birthdates with undefined years, like "--12-25"
//
// http://code.google.com/apis/contacts/docs/3.0/reference.html#gcBirthday
//
// We'll use 1804 for the year, making an obvious "unset" value to display
// in Apple's UI

- (NSDate *)birthdayDate {
  // get the birthday string, like 1970-12-25 or --12-25
  NSString *str = [self birthday];

  // convert a leading "-" year to 1804, since that's a clearly invalid
  // year that allows February 29
  if ([str hasPrefix:@"--"] && [str length] > 2) {
    NSString *monthDayString = [str substringFromIndex:2];
    str = [NSString stringWithFormat:@"1804-%@", monthDayString];
  }

  // add a time string to make it noon UTC, avoiding the chance that
  // a different time zone rendering would change the date
  str = [str stringByAppendingString:@" 12:00:00 -0000"];

  static NSDateFormatter *formatter = nil;
  if (formatter == nil) {
    formatter = [[NSDateFormatter alloc] init];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"];
  }

  NSDate *date = [formatter dateFromString:str];
  return date;
}

- (void)setBirthdayWithDate:(NSDate *)date {
  static NSDateFormatter *formatter = nil;
  if (formatter == nil) {
    formatter = [[NSDateFormatter alloc] init];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"Universal"]];
  }

  NSString *str = [formatter stringFromDate:date];

  // convert a "1804" year to "-"
  if ([str hasPrefix:@"1804-"] && [str length] > 5) {
    NSString *monthDayString = [str substringFromIndex:5];
    str = [NSString stringWithFormat:@"--%@", monthDayString];
  }
  [self setBirthday:str];
}

- (NSArray *)calendarLinks {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  return [self objectsForExtensionClass:[GDataContactCalendarLink class]];
}

- (void)setCalendarLinks:(NSArray *)array {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObjects:array forExtensionClass:[GDataContactCalendarLink class]];
}

- (void)addCalendarLink:(GDataContactCalendarLink *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self addObject:obj forExtensionClass:[GDataContactCalendarLink class]];
}

- (void)removeCalendarLink:(GDataContactCalendarLink *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self removeObject:obj forExtensionClass:[GDataContactCalendarLink class]];
}

- (GDataContactCalendarLink *)primaryCalendarLink {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  id obj = [self primaryObjectForExtensionClass:[GDataContactCalendarLink class]];
  return obj;
}

- (void)setPrimaryCalendarLink:(GDataContactCalendarLink *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setPrimaryObject:obj forExtensionClass:[GDataContactCalendarLink class]];
}


- (NSString *)directoryServer {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactDirectoryServer *obj;
  obj = [self objectForExtensionClass:[GDataContactDirectoryServer class]];
  return [obj stringValue];
}

- (void)setDirectoryServer:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  if ([str length] == 0) str = nil;

  GDataContactDirectoryServer *obj;
  obj = [GDataContactDirectoryServer valueWithString:str];

  [self setObject:obj forExtensionClass:[GDataContactDirectoryServer class]];
}


- (NSArray *)events {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  return [self objectsForExtensionClass:[GDataContactEvent class]];
}

- (void)setEvents:(NSArray *)array {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObjects:array forExtensionClass:[GDataContactEvent class]];
}

- (void)addEvent:(GDataContactEvent *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self addObject:obj forExtensionClass:[GDataContactEvent class]];
}

- (NSArray *)externalIDs {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  return [self objectsForExtensionClass:[GDataContactExternalID class]];
}

- (void)setExternalIDs:(NSArray *)array {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObjects:array forExtensionClass:[GDataContactExternalID class]];
}

- (void)addExternalID:(GDataContactExternalID *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self addObject:obj forExtensionClass:[GDataContactExternalID class]];
}


- (NSString *)gender {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactGender *obj;
  obj = [self objectForExtensionClass:[GDataContactGender class]];
  return [obj stringValue];
}

- (void)setGender:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  if ([str length] == 0) str = nil;

  GDataContactGender *obj;
  obj = [GDataContactGender valueWithString:str];

  [self setObject:obj forExtensionClass:[GDataContactGender class]];
}


- (NSArray *)hobbies {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  return [self objectsForExtensionClass:[GDataContactHobby class]];
}

- (void)setHobbies:(NSArray *)array {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObjects:array forExtensionClass:[GDataContactHobby class]];
}

- (void)addHobby:(GDataContactHobby *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self addObject:obj forExtensionClass:[GDataContactHobby class]];
}


- (NSString *)initials {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactInitials *obj;
  obj = [self objectForExtensionClass:[GDataContactInitials class]];
  return [obj stringValue];
}

- (void)setInitials:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  if ([str length] == 0) str = nil;

  GDataContactInitials *obj;
  obj = [GDataContactInitials valueWithString:str];

  [self setObject:obj forExtensionClass:[GDataContactInitials class]];
}


- (NSArray *)jots {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  return [self objectsForExtensionClass:[GDataContactJot class]];
}

- (void)setJots:(NSArray *)array {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObjects:array forExtensionClass:[GDataContactJot class]];
}

- (void)addJot:(GDataContactJot *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self addObject:obj forExtensionClass:[GDataContactJot class]];
}


- (NSArray *)languages {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  return [self objectsForExtensionClass:[GDataContactLanguage class]];
}

- (void)setLanguages:(NSArray *)array {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObjects:array forExtensionClass:[GDataContactLanguage class]];
}

- (void)addLanguage:(GDataContactLanguage *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self addObject:obj forExtensionClass:[GDataContactLanguage class]];
}


- (GDataWhere *)where {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  return [self objectForExtensionClass:[GDataWhere class]];
}

- (void)setWhere:(GDataWhere *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObject:obj forExtensionClass:[GDataWhere class]];
}


- (NSString *)maidenName {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactMaidenName *obj;
  obj = [self objectForExtensionClass:[GDataContactMaidenName class]];
  return [obj stringValue];
}

- (void)setMaidenName:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  if ([str length] == 0) str = nil;

  GDataContactMaidenName *obj;
  obj = [GDataContactMaidenName valueWithString:str];

  [self setObject:obj forExtensionClass:[GDataContactMaidenName class]];
}


- (NSString *)mileage {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactMileage *obj;
  obj = [self objectForExtensionClass:[GDataContactMileage class]];
  return [obj stringValue];
}

- (void)setMileage:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  if ([str length] == 0) str = nil;

  GDataContactMileage *obj;
  obj = [GDataContactMileage valueWithString:str];

  [self setObject:obj forExtensionClass:[GDataContactMileage class]];
}


- (GDataName *)name {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataName *obj = [self objectForExtensionClass:[GDataName class]];
  return obj;
}

- (void)setName:(GDataName *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObject:obj forExtensionClass:[GDataName class]];
}

- (NSString *)nickname {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactNickname *obj;
  obj = [self objectForExtensionClass:[GDataContactNickname class]];
  return [obj stringValue];
}

- (void)setNickname:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  if ([str length] == 0) str = nil;

  GDataContactNickname *obj;
  obj = [GDataContactNickname valueWithString:str];

  [self setObject:obj forExtensionClass:[GDataContactNickname class]];
}


- (NSString *)occupation {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactOccupation *obj;
  obj = [self objectForExtensionClass:[GDataContactOccupation class]];
  return [obj stringValue];
}

- (void)setOccupation:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  if ([str length] == 0) str = nil;

  GDataContactOccupation *obj;
  obj = [GDataContactOccupation valueWithString:str];

  [self setObject:obj forExtensionClass:[GDataContactOccupation class]];
}


- (NSString *)priority {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactPriority *obj;
  obj = [self objectForExtensionClass:[GDataContactPriority class]];
  return [obj rel];
}

- (void)setPriority:(NSString *)str {

  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactPriority *obj;
  obj = [GDataContactPriority priorityWithRel:str];

  [self setObject:obj forExtensionClass:[GDataContactPriority class]];
}


- (NSArray *)relations {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  return [self objectsForExtensionClass:[GDataContactRelation class]];
}

- (void)setRelations:(NSArray *)array {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObjects:array forExtensionClass:[GDataContactRelation class]];
}

- (void)addRelation:(GDataContactRelation *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self addObject:obj forExtensionClass:[GDataContactRelation class]];
}


- (NSString *)sensitivity {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactSensitivity *obj;
  obj = [self objectForExtensionClass:[GDataContactSensitivity class]];
  return [obj rel];
}

- (void)setSensitivity:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactOccupation *obj;
  obj = [GDataContactSensitivity sensitivityWithRel:str];

  [self setObject:obj forExtensionClass:[GDataContactSensitivity class]];
}


- (NSString *)shortName {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactShortName *obj;
  obj = [self objectForExtensionClass:[GDataContactShortName class]];
  return [obj stringValue];
}

- (void)setShortName:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  if ([str length] == 0) str = nil;

  GDataContactShortName *obj;
  obj = [GDataContactShortName valueWithString:str];

  [self setObject:obj forExtensionClass:[GDataContactShortName class]];
}


- (NSArray *)structuredPostalAddresses {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  return [self objectsForExtensionClass:[GDataStructuredPostalAddress class]];
}

- (void)setStructuredPostalAddresses:(NSArray *)arr {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObjects:arr forExtensionClass:[GDataStructuredPostalAddress class]];
}

- (void)addStructuredPostalAddress:(GDataStructuredPostalAddress *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self addObject:obj forExtensionClass:[GDataStructuredPostalAddress class]];
}

- (void)removeStructuredPostalAddress:(GDataStructuredPostalAddress *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self removeObject:obj forExtensionClass:[GDataStructuredPostalAddress class]];
}

- (GDataStructuredPostalAddress *)primaryStructuredPostalAddress {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  id obj = [self primaryObjectForExtensionClass:[GDataStructuredPostalAddress class]];
  return obj;
}

- (void)setPrimaryStructuredPostalAddress:(GDataStructuredPostalAddress *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setPrimaryObject:obj forExtensionClass:[GDataStructuredPostalAddress class]];
}


- (NSString *)subject {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  GDataContactSubject *obj;
  obj = [self objectForExtensionClass:[GDataContactSubject class]];
  return [obj stringValue];
}

- (void)setSubject:(NSString *)str {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  if ([str length] == 0) str = nil;

  GDataContactSubject *obj;
  obj = [GDataContactSubject valueWithString:str];

  [self setObject:obj forExtensionClass:[GDataContactSubject class]];
}


- (NSArray *)userDefinedFields {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  return [self objectsForExtensionClass:[GDataContactUserDefinedField class]];
}

- (void)setUserDefinedFields:(NSArray *)arr {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObjects:arr forExtensionClass:[GDataContactUserDefinedField class]];
}

- (void)addUserDefinedField:(GDataContactUserDefinedField *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self addObject:obj forExtensionClass:[GDataContactUserDefinedField class]];
}

- (void)removeUserDefinedField:(GDataContactUserDefinedField *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self removeObject:obj forExtensionClass:[GDataContactUserDefinedField class]];
}


- (NSArray *)websiteLinks {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  return [self objectsForExtensionClass:[GDataContactWebsiteLink class]];
}

- (void)setWebsiteLinks:(NSArray *)array {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setObjects:array forExtensionClass:[GDataContactWebsiteLink class]];
}

- (void)addWebsiteLink:(GDataContactWebsiteLink *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self addObject:obj forExtensionClass:[GDataContactWebsiteLink class]];
}

- (void)removeWebsiteLink:(GDataContactWebsiteLink *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self removeObject:obj forExtensionClass:[GDataContactWebsiteLink class]];
}

- (GDataContactWebsiteLink *)primaryWebsiteLink {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  id obj = [self primaryObjectForExtensionClass:[GDataContactWebsiteLink class]];
  return obj;
}

- (void)setPrimaryWebsiteLink:(GDataContactWebsiteLink *)obj {
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(kGDataContactServiceV3);

  [self setPrimaryObject:obj forExtensionClass:[GDataContactWebsiteLink class]];
}

#pragma mark -

- (GDataLink *)photoLink {
  return [self linkWithRelAttributeValue:kGDataContactPhotoRel];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
