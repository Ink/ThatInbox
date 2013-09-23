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
//  GDataStructuredPostalAddress.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE \
  || GDATA_INCLUDE_MAPS_SERVICE

#define GDATASTRUCTUREDPOSTALADDRESS_DEFINE_GLOBALS 1
#import "GDataStructuredPostalAddress.h"

#import "GDataValueConstruct.h"

//
// GDataStructuredPostalAddress private classes
//

@interface GDataPostalAddressAgent : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPostalAddressAgent
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"agent"; }
@end

@interface GDataPostalAddressCity : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPostalAddressCity
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"city"; }
@end

@interface GDataPostalAddressCountry : GDataValueElementConstruct <GDataExtension>
- (NSString *)code;
- (void)setCode:(NSString *)str;
@end

@implementation GDataPostalAddressCountry

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"country"; }

static NSString* const kCodeAttr = @"code";

- (void)addParseDeclarations {

  // this is a subclass of GDataValueElementConstruct, which has its own parse
  // declarations
  [super addParseDeclarations];

  NSArray *attrs = [NSArray arrayWithObject:kCodeAttr];
  [self addLocalAttributeDeclarations:attrs];

  [self addContentValueDeclaration];
}

- (NSString *)code {
  return [self stringValueForAttribute:kCodeAttr];
}

- (void)setCode:(NSString *)str {
  [self setStringValue:str forAttribute:kCodeAttr];
}
@end

@interface GDataPostalAddressFormattedAddress : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPostalAddressFormattedAddress
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"formattedAddress"; }
@end

@interface GDataPostalAddressHouseName : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPostalAddressHouseName
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"housename"; }
@end

@interface GDataPostalAddressNeighborhood : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPostalAddressNeighborhood
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"neighborhood"; }
@end

@interface GDataPostalAddressPOBox : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPostalAddressPOBox
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"pobox"; }
@end

@interface GDataPostalAddressPostCode : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPostalAddressPostCode
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"postcode"; }
@end

@interface GDataPostalAddressRegion : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPostalAddressRegion
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"region"; }
@end

@interface GDataPostalAddressStreet : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPostalAddressStreet
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"street"; }
@end

@interface GDataPostalAddressSubregion : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPostalAddressSubregion
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"subregion"; }
@end


//
// GDataStructuredPostalAddress
//

// attributes
static NSString* const kLabelAttr = @"label";
static NSString* const kMailClassAttr = @"mailClass";
static NSString* const kPrimaryAttr = @"primary";
static NSString* const kRelAttr = @"rel";
static NSString* const kUsageAttr = @"usage";

@implementation GDataStructuredPostalAddress

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"structuredPostalAddress"; }

+ (id)structuredPostalAddress {
  GDataStructuredPostalAddress *obj = [self object];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:
                    kLabelAttr, kMailClassAttr, kPrimaryAttr, kRelAttr,
                    kUsageAttr, nil];
  [self addLocalAttributeDeclarations:attrs];
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  [self addExtensionDeclarationForParentClass:[self class]
                                   childClasses:
   [GDataPostalAddressAgent class],
   [GDataPostalAddressCity class],
   [GDataPostalAddressCountry class],
   [GDataPostalAddressFormattedAddress class],
   [GDataPostalAddressHouseName class],
   [GDataPostalAddressNeighborhood class],
   [GDataPostalAddressPOBox class],
   [GDataPostalAddressPostCode class],
   [GDataPostalAddressRegion class],
   [GDataPostalAddressStreet class],
   [GDataPostalAddressSubregion class],
   nil];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {

  static struct GDataDescriptionRecord descRecs[] = {
    { @"agent",        @"agent",            kGDataDescValueLabeled },
    { @"city",         @"city",             kGDataDescValueLabeled },
    { @"country",      @"countryName",      kGDataDescValueLabeled },
    { @"countryCode",  @"countryCode",      kGDataDescValueLabeled },
    { @"fmtAddr",      @"formattedAddress", kGDataDescValueLabeled },
    { @"house",        @"houseName",        kGDataDescValueLabeled },
    { @"neighborhood", @"neighborhood",     kGDataDescValueLabeled },
    { @"pobox",        @"POBox",            kGDataDescValueLabeled },
    { @"postCode",     @"postCode",         kGDataDescValueLabeled },
    { @"region",       @"region",           kGDataDescValueLabeled },
    { @"street",       @"street",           kGDataDescValueLabeled },
    { @"subregion",    @"subregion",        kGDataDescValueLabeled },
    { nil, nil, (GDataDescRecTypes)0 }
  };

  NSMutableArray *items = [super itemsForDescription];
  [self addDescriptionRecords:descRecs toItems:items];
  return items;
}
#endif

#pragma mark -

// extensions

- (NSString *)agent {
  GDataPostalAddressAgent *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressAgent class]];
  return [obj stringValue];
}

- (void)setAgent:(NSString *)str {
  GDataPostalAddressAgent *obj;

  obj = [GDataPostalAddressAgent valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPostalAddressAgent class]];
}

- (NSString *)city {
  GDataPostalAddressCity *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressCity class]];
  return [obj stringValue];
}

- (void)setCity:(NSString *)str {
  GDataPostalAddressCity *obj;

  obj = [GDataPostalAddressCity valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPostalAddressCity class]];
}

// country name and code are in the same element, but we'll expose them
// as if they're independent to keep the interface simpler & KVC-compliant
- (NSString *)countryName {
  GDataPostalAddressCountry *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressCountry class]];
  return [obj stringValue];
}

- (void)setCountryName:(NSString *)str {

  GDataPostalAddressCountry *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressCountry class]];

  if (obj == nil && str != nil) {
    // lacked the element; create one only if we're really setting a value
    obj = [GDataPostalAddressCountry valueWithString:str];
    [self setObject:obj forExtensionClass:[GDataPostalAddressCountry class]];
  }
  [obj setStringValue:str];
}

- (NSString *)countryCode {
  GDataPostalAddressCountry *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressCountry class]];
  return [obj code];
}

- (void)setCountryCode:(NSString *)str {
  GDataPostalAddressCountry *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressCountry class]];

  if (obj == nil && str != nil) {
    // lacked the element; create one only if we're really setting a value
    obj = [GDataPostalAddressCountry valueWithString:nil];
    [self setObject:obj forExtensionClass:[GDataPostalAddressCountry class]];
  }
  [obj setCode:str];
}

- (NSString *)formattedAddress {
  GDataPostalAddressFormattedAddress *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressFormattedAddress class]];
  return [obj stringValue];
}

- (void)setFormattedAddress:(NSString *)str {
  GDataPostalAddressFormattedAddress *obj;

  obj = [GDataPostalAddressFormattedAddress valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPostalAddressFormattedAddress class]];
}

- (NSString *)houseName {
  GDataPostalAddressHouseName *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressHouseName class]];
  return [obj stringValue];
}

- (void)setHouseName:(NSString *)str {
  GDataPostalAddressHouseName *obj;

  obj = [GDataPostalAddressHouseName valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPostalAddressHouseName class]];
}

- (NSString *)neighborhood {
  GDataPostalAddressNeighborhood *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressNeighborhood class]];
  return [obj stringValue];
}

- (void)setNeighborhood:(NSString *)str {
  GDataPostalAddressNeighborhood *obj;

  obj = [GDataPostalAddressNeighborhood valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPostalAddressNeighborhood class]];
}

- (NSString *)POBox {
  GDataPostalAddressPOBox *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressPOBox class]];
  return [obj stringValue];
}

- (void)setPOBox:(NSString *)str {
  GDataPostalAddressPOBox *obj;

  obj = [GDataPostalAddressPOBox valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPostalAddressPOBox class]];
}

- (NSString *)postCode {
  GDataPostalAddressPostCode *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressPostCode class]];
  return [obj stringValue];
}

- (void)setPostCode:(NSString *)str {
  GDataPostalAddressPostCode *obj;

  obj = [GDataPostalAddressPostCode valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPostalAddressPostCode class]];
}

- (NSString *)region {
  GDataPostalAddressRegion *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressRegion class]];
  return [obj stringValue];
}

- (void)setRegion:(NSString *)str {
  GDataPostalAddressRegion *obj;

  obj = [GDataPostalAddressRegion valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPostalAddressRegion class]];
}

- (NSString *)street {
  GDataPostalAddressStreet *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressStreet class]];
  return [obj stringValue];
}

- (void)setStreet:(NSString *)str {
  GDataPostalAddressStreet *obj;

  obj = [GDataPostalAddressStreet valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPostalAddressStreet class]];
}

- (NSString *)subregion {
  GDataPostalAddressSubregion *obj;

  obj = [self objectForExtensionClass:[GDataPostalAddressSubregion class]];
  return [obj stringValue];
}

- (void)setSubregion:(NSString *)str {
  GDataPostalAddressSubregion *obj;

  obj = [GDataPostalAddressSubregion valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPostalAddressSubregion class]];
}

// attributes

- (NSString *)label {
  return [self stringValueForAttribute:kLabelAttr];
}

- (void)setLabel:(NSString *)str {
  [self setStringValue:str forAttribute:kLabelAttr];
}

- (NSString *)mailClass {
  return [self stringValueForAttribute:kMailClassAttr];
}

- (void)setMailClass:(NSString *)str {
  [self setStringValue:str forAttribute:kMailClassAttr];
}

- (BOOL)isPrimary {
  return [self boolValueForAttribute:kPrimaryAttr defaultValue:NO];
}

- (void)setIsPrimary:(BOOL)flag {
  [self setBoolValue:flag defaultValue:NO forAttribute:kPrimaryAttr];
}

- (NSString *)rel {
  return [self stringValueForAttribute:kRelAttr];
}

- (void)setRel:(NSString *)str {
  [self setStringValue:str forAttribute:kRelAttr];
}

- (NSString *)usage {
  return [self stringValueForAttribute:kUsageAttr];
}

- (void)setUsage:(NSString *)str {
  [self setStringValue:str forAttribute:kUsageAttr];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_*_SERVICE
