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
//  GDataName.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataName.h"
#import "GDataValueConstruct.h"

//
// private internal classes used as extensions by GDataName
//

@interface GDataNameAdditional : GDataNameElement <GDataExtension>
@end

@implementation GDataNameAdditional;
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"additionalName"; }
@end

@interface GDataNameFamily : GDataNameElement <GDataExtension>
@end

@implementation GDataNameFamily;
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"familyName"; }
@end

@interface GDataNameFull : GDataNameElement <GDataExtension>
@end

@implementation GDataNameFull;
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"fullName"; }
@end

@interface GDataNameGiven : GDataNameElement <GDataExtension>
@end

@implementation GDataNameGiven;
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"givenName"; }
@end

@interface GDataNamePrefix : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataNamePrefix;
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"namePrefix"; }
@end

@interface GDataNameSuffix : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataNameSuffix;
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"nameSuffix"; }
@end

//
// GDataNameElement is the base class for the full, given, family, and
// additional name elements.  Each name element has a string value and
// an optional yomi attribute for pronunciation.
//

@implementation GDataNameElement

static NSString* const kYomiAttr = @"yomi";

+ (id)nameElementWithString:(NSString *)str {
  // the contacts API does not want empty name elements
  if ([str length] == 0) return nil;
  
  GDataNameElement *obj = [self object];
  [obj setStringValue:str];
  return obj;
}

// internal method for converting name element types, since the setters below
// take a generic GDataNameElement argument, but those don't have the extension
// methods specifying localName, etc

+ (id)nameElementWithNameElement:(GDataNameElement *)source {
  GDataNameElement *obj = [self object];
  [obj setStringValue:[source stringValue]];
  [obj setYomi:[source yomi]];
  return obj;
}

- (void)addParseDeclarations {

  [self addLocalAttributeDeclarations:[NSArray arrayWithObject:kYomiAttr]];

  [self addContentValueDeclaration];
}

- (NSString *)stringValue {
  return [self contentStringValue];
}

- (void)setStringValue:(NSString *)str {
  [self setContentStringValue:str];
}

- (NSString *)yomi {
  return [self stringValueForAttribute:kYomiAttr];
}

- (void)setYomi:(NSString *)str {
  // the contacts API does not want empty name elements
  if ([str length] == 0) str = nil;

  [self setStringValue:str forAttribute:kYomiAttr];
}

@end


//
// GDataName class
//

@implementation GDataName

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"name"; }

+ (GDataName *)name {
  GDataName* obj = [self object];
  return obj;
}

+ (GDataName *)nameWithFullNameString:(NSString *)str {
  GDataName* obj = [self object];
  [obj setFullNameWithString:str];
  return obj;
}

+ (GDataName *)nameWithPrefix:(NSString *)prefix
                  givenString:(NSString *)first
             additionalString:(NSString *)middle
                 familyString:(NSString *)last
                       suffix:(NSString *)suffix {
  GDataName* obj = [self object];

  [obj setNamePrefix:prefix];
  [obj setGivenNameWithString:first];
  [obj setAdditionalNameWithString:middle];
  [obj setFamilyNameWithString:last];
  [obj setNameSuffix:suffix];
  return obj;
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  [self addExtensionDeclarationForParentClass:[self class]
                                 childClasses:
   [GDataNameAdditional class],
   [GDataNameFamily class],
   [GDataNameFull class],
   [GDataNameGiven class],
   [GDataNamePrefix class],
   [GDataNameSuffix class],
   nil];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {

  static struct GDataDescriptionRecord descRecs[] = {
    { @"prefix",     @"namePrefix",                 kGDataDescValueLabeled },
    { @"given",      @"givenName.stringValue",      kGDataDescValueLabeled },
    { @"additional", @"additionalName.stringValue", kGDataDescValueLabeled },
    { @"family",     @"familyName.stringValue",     kGDataDescValueLabeled },
    { @"suffix",     @"nameSuffix",                 kGDataDescValueLabeled },
    { @"full",       @"fullName.stringValue",       kGDataDescValueLabeled },
    { nil, nil, (GDataDescRecTypes)0 }
  };

  NSMutableArray *items = [super itemsForDescription];
  [self addDescriptionRecords:descRecs toItems:items];
  return items;
}
#endif

#pragma mark -

- (GDataNameElement *)additionalName {
  GDataNameAdditional *obj;

  obj = [self objectForExtensionClass:[GDataNameAdditional class]];
  return obj;
}

- (void)setAdditionalName:(GDataNameElement *)obj {
  GDataNameAdditional *typedObj = [GDataNameAdditional nameElementWithNameElement:obj];
  [self setObject:typedObj forExtensionClass:[GDataNameAdditional class]];
}

- (void)setAdditionalNameWithString:(NSString *)str {
  GDataNameAdditional *obj = [GDataNameAdditional nameElementWithString:str];
  [self setObject:obj forExtensionClass:[GDataNameAdditional class]];
}


- (GDataNameElement *)familyName {
  GDataNameFamily *obj;

  obj = [self objectForExtensionClass:[GDataNameFamily class]];
  return obj;
}

- (void)setFamilyName:(GDataNameElement *)obj {
  GDataNameFamily *typedObj = [GDataNameFamily nameElementWithNameElement:obj];
  [self setObject:typedObj forExtensionClass:[GDataNameFamily class]];
}

- (void)setFamilyNameWithString:(NSString *)str {
  GDataNameFamily *obj = [GDataNameFamily nameElementWithString:str];
  [self setObject:obj forExtensionClass:[GDataNameFamily class]];
}


- (GDataNameElement *)fullName {
  GDataNameFull *obj;

  obj = [self objectForExtensionClass:[GDataNameFull class]];
  return obj;
}

- (void)setFullName:(GDataNameElement *)obj {
  GDataNameFull *typedObj = [GDataNameFull nameElementWithNameElement:obj];
  [self setObject:typedObj forExtensionClass:[GDataNameFull class]];
}

- (void)setFullNameWithString:(NSString *)str {
  GDataNameFull *obj = [GDataNameFull nameElementWithString:str];
  [self setObject:obj forExtensionClass:[GDataNameFull class]];
}


- (GDataNameElement *)givenName {
  GDataNameGiven *obj;

  obj = [self objectForExtensionClass:[GDataNameGiven class]];
  return obj;
}

- (void)setGivenName:(GDataNameElement *)obj {
  GDataNameGiven *typedObj = [GDataNameGiven nameElementWithNameElement:obj];
  [self setObject:typedObj forExtensionClass:[GDataNameGiven class]];
}

- (void)setGivenNameWithString:(NSString *)str {
  GDataNameGiven *obj = [GDataNameGiven nameElementWithString:str];
  [self setObject:obj forExtensionClass:[GDataNameGiven class]];
}


- (NSString *)namePrefix {
  GDataNamePrefix *obj;

  obj = [self objectForExtensionClass:[GDataNamePrefix class]];
  return [obj stringValue];
}

- (void)setNamePrefix:(NSString *)str {
  // the contacts API does not want empty name elements
  if ([str length] == 0) str = nil;

  GDataNamePrefix *obj = [GDataNamePrefix valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataNamePrefix class]];
}


- (NSString *)nameSuffix {
  GDataNameSuffix *obj;

  obj = [self objectForExtensionClass:[GDataNameSuffix class]];
  return [obj stringValue];
}

- (void)setNameSuffix:(NSString *)str {
  // the contacts API does not want empty name elements
  if ([str length] == 0) str = nil;

  GDataNameSuffix *obj = [GDataNameSuffix valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataNameSuffix class]];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
