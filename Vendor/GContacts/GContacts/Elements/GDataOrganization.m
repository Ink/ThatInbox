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
//  GDataOrganization.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataOrganization.h"
#import "GDataOrganizationName.h"
#import "GDataWhere.h"

static NSString* const kRelAttr = @"rel";
static NSString* const kLabelAttr = @"label";
static NSString* const kPrimaryAttr = @"primary";

static NSString* StringOrNilIfBlank(NSString *str) {
  // return nil if the string only has whitespace
  NSCharacterSet *wsSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSString *trimmed = [str stringByTrimmingCharactersInSet:wsSet];
  if ([trimmed length] == 0) return nil;

  return str;
}


@interface GDataOrgDepartment : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataOrgDepartment
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData;       }
+ (NSString *)extensionElementLocalName { return @"orgDepartment";           }
@end

@interface GDataOrgJobDescription : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataOrgJobDescription
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData;       }
+ (NSString *)extensionElementLocalName { return @"orgJobDescription";       }
@end

@interface GDataOrgSymbol : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataOrgSymbol
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData;       }
+ (NSString *)extensionElementLocalName { return @"orgSymbol";               }
@end

@interface GDataOrgTitle : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataOrgTitle
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData;       }
+ (NSString *)extensionElementLocalName { return @"orgTitle";                }
@end


@implementation GDataOrganization
// organization, as in
//  <gd:organization primary="true" rel="http://schemas.google.com/g/2005#work">
//    <gd:orgName yomi="Ak Me">Acme Corp</gd:orgName>
//    <gd:orgTitle>Prezident</gd:orgTitle>
//  </gd:organization>

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"organization"; }

+ (GDataOrganization *)organizationWithName:(NSString *)str {
  GDataOrganization *obj = [self object];
  [obj setOrgName:str];
  return obj;
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  Class elementClass = [self class];

  [self addExtensionDeclarationForParentClass:elementClass
                                 childClasses:
   [GDataOrgDepartment class],
   [GDataOrgJobDescription class],
   [GDataOrgSymbol class],
   [GDataOrgTitle class],
   [GDataOrganizationName class],
   [GDataWhere class],
   nil];
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:
                    kLabelAttr, kRelAttr, kPrimaryAttr, nil];

  [self addLocalAttributeDeclarations:attrs];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {
  static struct GDataDescriptionRecord descRecs[] = {
    { @"name",        @"orgName",           kGDataDescValueLabeled   },
    { @"orgNameYomi", @"orgNameYomi",       kGDataDescValueLabeled   },
    { @"title",       @"orgTitle",          kGDataDescValueLabeled   },
    { @"dept",        @"orgDepartment",     kGDataDescValueLabeled   },
    { @"jobDesc",     @"orgJobDescription", kGDataDescValueLabeled   },
    { @"symbol",      @"orgSymbol",         kGDataDescValueLabeled   },
    { @"where",       @"where",             kGDataDescValueLabeled   },
    { @"rel",         @"rel",               kGDataDescValueLabeled   },
    { @"label",       @"label",             kGDataDescValueLabeled   },
    { @"primary",     @"isPrimary",         kGDataDescBooleanPresent },
    { nil, nil, (GDataDescRecTypes)0 }
  };

  NSMutableArray *items = [super itemsForDescription];
  [self addDescriptionRecords:descRecs toItems:items];
  return items;
}
#endif

#pragma mark -

- (NSString *)rel {
  return [self stringValueForAttribute:kRelAttr];
}

- (void)setRel:(NSString *)str {
  [self setStringValue:str forAttribute:kRelAttr];
}

- (NSString *)label {
  return [self stringValueForAttribute:kLabelAttr];
}

- (void)setLabel:(NSString *)str {
  [self setStringValue:str forAttribute:kLabelAttr];
}

- (BOOL)isPrimary {
  return [self boolValueForAttribute:kPrimaryAttr defaultValue:NO];
}

- (void)setIsPrimary:(BOOL)flag {
  [self setBoolValue:flag defaultValue:NO forAttribute:kPrimaryAttr];
}

// orgName and orgNameYomi are both inside the GDataOrganizationName extension
// element
- (NSString *)orgName {
  GDataOrganizationName *obj;

  obj = [self objectForExtensionClass:[GDataOrganizationName class]];
  return [obj stringValue];
}

- (void)setOrgName:(NSString *)str {
  GDataOrganizationName *obj;

  obj = [self objectForExtensionClass:[GDataOrganizationName class]];
  if (obj == nil && str != nil) {
    // lacked the element; create one only if we're really setting a value
    obj = [GDataOrganizationName organizationNameWithString:nil];
    [self setObject:obj forExtensionClass:[GDataOrganizationName class]];
  }
  [obj setStringValue:StringOrNilIfBlank(str)];
}

- (NSString *)orgNameYomi {
  GDataOrganizationName *obj;

  obj = [self objectForExtensionClass:[GDataOrganizationName class]];
  return [obj yomi];
}

- (void)setOrgNameYomi:(NSString *)str {
  GDataOrganizationName *obj;

  obj = [self objectForExtensionClass:[GDataOrganizationName class]];
  if (obj == nil && str != nil) {
    // lacked the element; create one only if we're really setting a value
    obj = [GDataOrganizationName organizationNameWithString:nil];
    [self setObject:obj forExtensionClass:[GDataOrganizationName class]];
  }
  [obj setYomi:str];
}

- (NSString *)orgDepartment {
  GDataOrgDepartment *obj;

  obj = [self objectForExtensionClass:[GDataOrgDepartment class]];
  return [obj stringValue];
}

- (void)setOrgDepartment:(NSString *)str {
  GDataOrgDepartment *obj;

  obj = [GDataOrgDepartment valueWithString:StringOrNilIfBlank(str)];
  [self setObject:obj forExtensionClass:[GDataOrgDepartment class]];
}

- (NSString *)orgJobDescription {
  GDataOrgJobDescription *obj;

  obj = [self objectForExtensionClass:[GDataOrgJobDescription class]];
  return [obj stringValue];
}

- (void)setOrgJobDescription:(NSString *)str {
  GDataOrgJobDescription *obj;

  obj = [GDataOrgJobDescription valueWithString:StringOrNilIfBlank(str)];
  [self setObject:obj forExtensionClass:[GDataOrgJobDescription class]];
}

- (NSString *)orgSymbol {
  GDataOrgSymbol *obj;

  obj = [self objectForExtensionClass:[GDataOrgSymbol class]];
  return [obj stringValue];
}

- (void)setOrgSymbol:(NSString *)str {
  GDataOrgSymbol *obj;

  obj = [GDataOrgSymbol valueWithString:StringOrNilIfBlank(str)];
  [self setObject:obj forExtensionClass:[GDataOrgSymbol class]];
}

- (NSString *)orgTitle {
  GDataOrgTitle *obj = [self objectForExtensionClass:[GDataOrgTitle class]];
  return [obj stringValue];
}

- (void)setOrgTitle:(NSString *)str {
  GDataOrgTitle *obj = [GDataOrgTitle valueWithString:StringOrNilIfBlank(str)];
  [self setObject:obj forExtensionClass:[GDataOrgTitle class]];
}

- (GDataWhere *)where {
  return [self objectForExtensionClass:[GDataWhere class]];
}

- (void)setWhere:(GDataWhere *)obj {
  [self setObject:obj forExtensionClass:[GDataWhere class]];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
