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
//  GDataStructuredPostalAddress.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE \
  || GDATA_INCLUDE_MAPS_SERVICE

#import "GDataObject.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATASTRUCTUREDPOSTALADDRESS_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

// rel values
_EXTERN NSString* kGDataPostalAddressHome  _INITIALIZE_AS(@"http://schemas.google.com/g/2005#home");
_EXTERN NSString* kGDataPostalAddressWork  _INITIALIZE_AS(@"http://schemas.google.com/g/2005#work");
_EXTERN NSString* kGDataPostalAddressOther _INITIALIZE_AS(@"http://schemas.google.com/g/2005#other");

// mail class values
_EXTERN NSString* kGDataPostalAddressLetters _INITIALIZE_AS(@"http://schemas.google.com/g/2005#letters");
_EXTERN NSString* kGDataPostalAddressParcels _INITIALIZE_AS(@"http://schemas.google.com/g/2005#parcels");
_EXTERN NSString* kGDataPostalAddressNeither _INITIALIZE_AS(@"http://schemas.google.com/g/2005#neither");
_EXTERN NSString* kGDataPostalAddressBoth    _INITIALIZE_AS(@"http://schemas.google.com/g/2005#both");

// usage values
_EXTERN NSString* kGDataPostalAddressGeneral  _INITIALIZE_AS(@"http://schemas.google.com/g/2005#general");
_EXTERN NSString* kGDataPostalAddressLocal    _INITIALIZE_AS(@"http://schemas.google.com/g/2005#local");

@interface GDataStructuredPostalAddress : GDataObject <GDataExtension>

+ (id)structuredPostalAddress;

// receiver of mail, or in care of ("c/o")
- (NSString *)agent;
- (void)setAgent:(NSString *)str;

- (NSString *)city;
- (void)setCity:(NSString *)str;

// country name and code are in the same element, but we'll expose them
// here as if they're independent to keep the interface simpler & KVC-compliant
- (NSString *)countryName;
- (void)setCountryName:(NSString *)str;

// 3166-1 alpha-2 country codes
// http://www.iso.org/iso/english_country_names_and_code_elements
- (NSString *)countryCode;
- (void)setCountryCode:(NSString *)str;

// building name
- (NSString *)houseName;
- (void)setHouseName:(NSString *)str;

- (NSString *)neighborhood;
- (void)setNeighborhood:(NSString *)str;

- (NSString *)POBox;
- (void)setPOBox:(NSString *)str;

- (NSString *)postCode;
- (void)setPostCode:(NSString *)str;

// region is a state, province, county (in Ireland), Land (in Germany),
// departement (in France), or similar
- (NSString *)region;
- (void)setRegion:(NSString *)str;

- (NSString *)street;
- (void)setStreet:(NSString *)str;

// subregion is not intended for delivery addresses
- (NSString *)subregion;
- (void)setSubregion:(NSString *)str;


- (NSString *)formattedAddress;
- (void)setFormattedAddress:(NSString *)str;

// attributes

- (NSString *)label;
- (void)setLabel:(NSString *)str;

- (NSString *)mailClass;
- (void)setMailClass:(NSString *)str;

- (BOOL)isPrimary;
- (void)setIsPrimary:(BOOL)flag;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (NSString *)usage;
- (void)setUsage:(NSString *)str;
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_*_SERVICE
