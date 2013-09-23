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
//  GDataFeedLink.m
//


#import "GDataFeedLink.h"
#import "GDataFeedBase.h"

static NSString *const kHrefAttr = @"href";
static NSString *const kRelAttr = @"rel";
static NSString *const KReadOnlyAttr = @"readOnly";
static NSString *const kCountHintAttr = @"countHint";

@implementation GDataFeedLink
// a link to a feed, like
// <gd:feedLink href="http://example.com/Jo/posts/MyFirstPost/comments" countHint="10">
//
// http://code.google.com/apis/gdata/common-elements.html#gdFeedLink

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"feedLink"; }

- (void)addParseDeclarations {

  NSArray *attrs = [NSArray arrayWithObjects:
                    kHrefAttr, kRelAttr, KReadOnlyAttr, kCountHintAttr, nil];

  [self addLocalAttributeDeclarations:attrs];
}

+ (id)feedLinkWithHref:(NSString *)href
            isReadOnly:(BOOL)isReadOnly {
  GDataFeedLink* feedLink = [self object];
  [feedLink setHref:href];
  [feedLink setIsReadOnly:isReadOnly];
  return feedLink;
}

- (id)initWithXMLElement:(NSXMLElement *)element
                  parent:(GDataObject *)parent {
  self = [super initWithXMLElement:element
                            parent:parent];
  if (self) {

    [self setFeed:[self objectForChildOfElement:element
                                  qualifiedName:@"feed"
                                   namespaceURI:kGDataNamespaceAtom
                                    objectClass:nil]];
  }
  return self;
}

- (void)dealloc {
  [feed_ release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
  GDataFeedLink* newLink = [super copyWithZone:zone];
  [newLink setFeed:[[[self feed] copyWithZone:zone] autorelease]];
  return newLink;
}

- (BOOL)isEqual:(GDataFeedLink *)other {
  if (self == other) return YES;
  if (![other isKindOfClass:[GDataFeedLink class]]) return NO;

  return [super isEqual:other]
    && AreEqualOrBothNil([self feed], [other feed]);
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {

  static struct GDataDescriptionRecord descRecs[] = {
    { @"href",      @"href",                  kGDataDescValueLabeled   },
    { @"readOnly",  @"isReadOnly",            kGDataDescBooleanPresent },
    { @"countHint", @"countHint.stringValue", kGDataDescValueLabeled   },
    { @"feed",      @"feed",                  kGDataDescValueLabeled   },
    { @"rel",       @"rel",                   kGDataDescValueLabeled   },
    { nil, nil, (GDataDescRecTypes)0 }
  };

  NSMutableArray *items = [super itemsForDescription];
  [self addDescriptionRecords:descRecs toItems:items];
  return items;
}
#endif

- (NSXMLElement *)XMLElement {

  NSXMLElement *element = [self XMLElementWithExtensionsAndDefaultName:nil];

  if ([self feed]) {
    [element addChild:[[self feed] XMLElement]];
  }
  return element;
}

- (NSString *)href {
  return [self stringValueForAttribute:kHrefAttr];
}

- (void)setHref:(NSString *)str {
  [self setStringValue:str forAttribute:kHrefAttr];
}

- (BOOL)isReadOnly {
  return [self boolValueForAttribute:KReadOnlyAttr defaultValue:NO];
}

- (void)setIsReadOnly:(BOOL)isReadOnly {
  [self setBoolValue:isReadOnly defaultValue:NO forAttribute:KReadOnlyAttr];
}

- (NSNumber *)countHint {
  return [self intNumberForAttribute:kCountHintAttr];
}

-(void)setCountHint:(NSNumber *)val {
  [self setStringValue:[val stringValue] forAttribute:kCountHintAttr];
}

- (NSString *)rel {
  return [self stringValueForAttribute:kRelAttr];
}

- (void)setRel:(NSString *)str {
  [self setStringValue:str forAttribute:kRelAttr];
}

- (GDataFeedBase *)feed {
  return feed_;
}

- (void)setFeed:(GDataFeedBase *)feed {
  [feed_ autorelease];
  feed_ = [feed retain];
}

// convenience method

- (NSURL *)URL {
  NSString *href = [self href];
  if ([href length] > 0) {
    return [NSURL URLWithString:href];
  }
  return nil;
}

@end

