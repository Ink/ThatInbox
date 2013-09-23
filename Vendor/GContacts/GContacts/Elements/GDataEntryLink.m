/* Copyright (c) 2007-2008 Google Inc.
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
//  GDataEntryLink.m
//

#import "GDataEntryLink.h"

#import "GDataEntryBase.h"

static NSString* const kHrefAttr = @"href";
static NSString* const kReadOnlyAttr = @"readOnly";
static NSString* const kRelAttr = @"rel";

@implementation GDataEntryLink
// used instead GDataWhere, a link to an entry, like
// <gd:entryLink href="http://gmail.com/jo/contacts/Jo">

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"entryLink"; }

+ (GDataEntryLink *)entryLinkWithHref:(NSString *)href
                           isReadOnly:(BOOL)isReadOnly {
  GDataEntryLink* entryLink = [self object];
  [entryLink setHref:href];
  [entryLink setIsReadOnly:isReadOnly];
  return entryLink;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:
                    kHrefAttr, kReadOnlyAttr, kRelAttr, nil];

  [self addLocalAttributeDeclarations:attrs];
}


- (id)initWithXMLElement:(NSXMLElement *)element
                  parent:(GDataObject *)parent {
  self = [super initWithXMLElement:element
                            parent:parent];
  if (self) {
    // GDataEntryBase, the base class for entries, is not an extension,
    // so we parse it manually
    [self setEntry:[self objectForChildOfElement:element
                                   qualifiedName:@"entry"
                                    namespaceURI:kGDataNamespaceAtom
                                     objectClass:nil]];
  }
  return self;
}

- (void)dealloc {
  [entry_ release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
  GDataEntryLink* newLink = [super copyWithZone:zone];
  [newLink setEntry:[[[self entry] copyWithZone:zone] autorelease]];
  return newLink;
}

- (BOOL)isEqual:(GDataEntryLink *)other {
  if (self == other) return YES;
  if (![other isKindOfClass:[GDataEntryLink class]]) return NO;

  return [super isEqual:other]
    && (AreEqualOrBothNil([self entry], [other entry]));
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {
  NSMutableArray *items = [super itemsForDescription];

  [self addToArray:items objectDescriptionIfNonNil:entry_ withName:@"entry"];

  return items;
}
#endif

- (NSXMLElement *)XMLElement {

  NSXMLElement *element = [self XMLElementWithExtensionsAndDefaultName:nil];

  if ([self entry]) {
    [element addChild:[entry_ XMLElement]];
  }
  return element;
}

#pragma mark -

- (NSString *)href {
  return [self stringValueForAttribute:kHrefAttr];
}

- (void)setHref:(NSString *)str {
  [self setStringValue:str forAttribute:kHrefAttr];
}

- (BOOL)isReadOnly {
  return [self boolValueForAttribute:kReadOnlyAttr defaultValue:NO];
}

- (void)setIsReadOnly:(BOOL)isReadOnly {
  [self setBoolValue:isReadOnly defaultValue:NO forAttribute:kReadOnlyAttr];
}

- (NSString *)rel {
  return [self stringValueForAttribute:kRelAttr];
}

- (void)setRel:(NSString *)str {
  [self setStringValue:str forAttribute:kRelAttr];
}

- (GDataEntryBase *)entry {
  return entry_;
}

- (void)setEntry:(GDataEntryBase *)entry {
  [entry_ autorelease];
  entry_ = [entry retain];
}

@end

