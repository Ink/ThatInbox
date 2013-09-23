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
//  GDataExtendedProperty.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE \
   || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATAEXTENDEDPROPERTY_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataExtendedPropertyRealmShared _INITIALIZE_AS(@"http://schemas.google.com/g/2005#shared");


// an element with a name="" and a value="" attribute, as in
//  <gd:extendedProperty name='X-MOZ-ALARM-LAST-ACK' value='2006-10-03T19:01:14Z'/>
//
// or an arbitrary XML blob, as in
//  <gd:extendedProperty name='com.myCompany.myProperties'> <myXMLBlob /> </gd:extendedProperty>
//
// Servers may impose additional restrictions on names or on the size
// or composition of the values.

@interface GDataExtendedProperty : GDataObject <GDataExtension>

+ (id)propertyWithName:(NSString *)name
                 value:(NSString *)value;

- (NSString *)value;
- (void)setValue:(NSString *)str;

- (NSString *)name;
- (void)setName:(NSString *)str;

- (NSString *)realm;
- (void)setRealm:(NSString *)str;

- (NSArray *)XMLValues;
- (void)setXMLValues:(NSArray *)arr;
- (void)addXMLValue:(NSXMLNode *)node;

// Obj-C style interface to XML values storage
//
// keys are XMLValue node names, values are XMLValue node string values,
// as in
//   <key1>value1</key1>
//   <key2>value2</key2>
//
// Behavior is undefined if child nodes are in some other format.

- (void)setXMLValue:(NSString *)value forKey:(NSString *)key;
- (NSString *)XMLValueForKey:(NSString *)key;

- (NSDictionary *)XMLValuesDictionary;
- (void)setXMLValuesDictionary:(NSDictionary *)dict;

@end

#endif // #if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_*_SERVICE
