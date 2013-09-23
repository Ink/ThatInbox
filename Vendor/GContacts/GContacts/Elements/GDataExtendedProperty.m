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
//  GDataExtendedProperty.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CALENDAR_SERVICE \
  || GDATA_INCLUDE_CONTACTS_SERVICE

#define GDATAEXTENDEDPROPERTY_DEFINE_GLOBALS 1

#import "GDataExtendedProperty.h"

static NSString* const kNameAttr = @"name";
static NSString* const kValueAttr = @"value";
static NSString* const kRealmAttr = @"realm";

@implementation GDataExtendedProperty
// an element with a name="" and a value="" attribute, as in
//  <gd:extendedProperty name='X-MOZ-ALARM-LAST-ACK' value='2006-10-03T19:01:14Z'/>
//
// or an arbitrary XML blob, as in
//  <gd:extendedProperty name='com.myCompany.myProperties'> <myXMLBlob /> </gd:extendedProperty>
//
// Servers may impose additional restrictions on names or on the size
// or composition of the values.

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"extendedProperty"; }

- (void)addEmptyDefaultNamespace {

  // We don't want child XML lacking a prefix to be intepreted as being in the
  // atom namespace, so we'll specify that no default namespace applies.
  // This will add the attribute xmlns="" to the extendedProperty element.

  NSDictionary *defaultNS = [NSDictionary dictionaryWithObject:@""
                                                        forKey:@""];
  [self addNamespaces:defaultNS];
}

+ (id)propertyWithName:(NSString *)name
                 value:(NSString *)value {

  GDataExtendedProperty* obj = [self object];
  [obj setName:name];
  [obj setValue:value];
  [obj addEmptyDefaultNamespace];
  return obj;
}

- (id)init {
  self = [super init];
  if (self) {
    if ([[self namespaces] objectForKey:@""] == nil) {
      [self addEmptyDefaultNamespace];
    }
  }
  return self;
}

- (id)initWithXMLElement:(NSXMLElement *)element
                  parent:(GDataObject *)parent {
  self = [super initWithXMLElement:element
                            parent:parent];
  if (self) {
    if ([[self namespaces] objectForKey:@""] == nil) {
      [self addEmptyDefaultNamespace];
    }
  }
  return self;
}

- (void)addParseDeclarations {

  NSArray *attrs = [NSArray arrayWithObjects:
                    kNameAttr, kValueAttr, kRealmAttr, nil];

  [self addLocalAttributeDeclarations:attrs];

  [self addChildXMLElementsDeclaration];
}

- (NSString *)value {
  return [self stringValueForAttribute:kValueAttr];
}

- (void)setValue:(NSString *)str {
  [self setStringValue:str forAttribute:kValueAttr];
}

- (NSString *)name {
  return [self stringValueForAttribute:kNameAttr];
}

- (void)setName:(NSString *)str {
  [self setStringValue:str forAttribute:kNameAttr];
}

- (NSString *)realm {
  return [self stringValueForAttribute:kRealmAttr];
}

- (void)setRealm:(NSString *)str {
  [self setStringValue:str forAttribute:kRealmAttr];
}

- (NSArray *)XMLValues {
  return [super childXMLElements];
}

- (void)setXMLValues:(NSArray *)arr {
  [self setChildXMLElements:arr];
}

- (void)addXMLValue:(NSXMLNode *)node {
  [self addChildXMLElement:node];
}

#pragma mark -

- (void)setXMLValue:(NSString *)value forKey:(NSString *)key {

  // change or remove an entry in the values dictionary
  //
  // dict may be nil
  NSMutableDictionary *dict = [[[self XMLValuesDictionary] mutableCopy] autorelease];

  if (dict == nil && value != nil) {
    dict = [NSMutableDictionary dictionary];
  }
  [dict setValue:value forKey:key];

  [self setXMLValuesDictionary:dict];
}

- (NSString *)XMLValueForKey:(NSString *)key {

  NSDictionary *dict = [self XMLValuesDictionary];
  NSString *value = [dict valueForKey:key];
  return value;
}

- (NSDictionary *)XMLValuesDictionary {

  NSArray *xmlNodes = [self XMLValues];
  if (xmlNodes == nil) return nil;

  // step through all elements in the XML children and make a dictionary
  // entry for each
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  for (id xmlNode in xmlNodes) {

    NSString *qualifiedName = [xmlNode name];
    NSString *value = [xmlNode stringValue];

    [dict setValue:value forKey:qualifiedName];
  }
  return dict;
}

- (void)setXMLValuesDictionary:(NSDictionary *)dict {

  NSMutableArray *nodes = [NSMutableArray array];

  // replace the XML child elements with elements from the dictionary
  for (NSString *key in dict) {
    NSString *value = [dict objectForKey:key];
    NSXMLNode *node = [NSXMLNode elementWithName:key
                                     stringValue:value];
    [nodes addObject:node];
  }

  if ([nodes count] > 0) {
    [self setXMLValues:nodes];
  } else {
    [self setXMLValues:nil];
  }
}

@end

#endif // #if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_*_SERVICE
