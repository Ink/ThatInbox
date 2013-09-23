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
//  GDataLink.m
//

#define GDATALINK_DEFINE_GLOBALS 1

#import "GDataLink.h"
#import "GDataBaseElements.h"

static NSString *const kRelAttr = @"rel";
static NSString *const kTypeAttr = @"type";
static NSString *const kHrefAttr = @"href";
static NSString *const kHrefLangAttr = @"hrefLang";
static NSString *const kTitleAttr = @"title";
static NSString *const kLangAttr = @"xml:lang";
static NSString *const kLengthAttr = @"length";

@implementation GDataLink
// for links, like <link rel="alternate" type="text/html"
//     href="http://www.google.com/calendar/event?eid=b..." title="alternate"/>

+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"link"; }

+ (GDataLink *)linkWithRel:(NSString *)rel
                      type:(NSString *)type
                      href:(NSString *)href {
  GDataLink *dataLink = [self object];
  [dataLink setRel:rel];
  [dataLink setType:type];
  [dataLink setHref:href];
  return dataLink;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects:
                    kRelAttr, kTypeAttr, kHrefAttr, kHrefLangAttr,
                    kTitleAttr, kLangAttr, kLengthAttr, nil];

  [self addLocalAttributeDeclarations:attrs];
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  Class elementClass = [self class];

  [self addExtensionDeclarationForParentClass:elementClass
                                   childClass:[GDataAtomContent class]];

  [self addAttributeExtensionDeclarationForParentClass:elementClass
                                            childClass:[GDataETagAttribute class]];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {

  NSMutableArray *items = [super itemsForDescription];

  [self addToArray:items objectDescriptionIfNonNil:[self content] withName:@"content"];
  [self addToArray:items objectDescriptionIfNonNil:[self ETag] withName:@"etag"];

  return items;
}
#endif

#pragma mark -

- (NSString *)rel {
  NSString *str = [self stringValueForAttribute:kRelAttr];
  return [str length] > 0 ? str : @"alternate"; // per Link.java
}

- (void)setRel:(NSString *)str {
  [self setStringValue:str forAttribute:kRelAttr];
}

- (NSString *)type {
  return [self stringValueForAttribute:kTypeAttr];
}

- (void)setType:(NSString *)str {
  [self setStringValue:str forAttribute:kTypeAttr];
}

- (NSString *)href {
  return [self stringValueForAttribute:kHrefAttr];
}

- (void)setHref:(NSString *)str {
  [self setStringValue:str forAttribute:kHrefAttr];
}

- (NSString *)hrefLang {
  return [self stringValueForAttribute:kHrefLangAttr];
}

- (void)setHrefLang:(NSString *)str {
  [self setStringValue:str forAttribute:kHrefLangAttr];
}

- (NSString *)title {
  return [self stringValueForAttribute:kTitleAttr];
}

- (void)setTitle:(NSString *)str {
  [self setStringValue:str forAttribute:kTitleAttr];
}

- (NSString *)titleLang {
  return [self stringValueForAttribute:kLangAttr];
}

- (void)setTitleLang:(NSString *)str {
  [self setStringValue:str forAttribute:kLangAttr];
}

- (NSNumber *)resourceLength {
  return [self intNumberForAttribute:kLengthAttr];
}

- (void)setResourceLength:(NSNumber *)length {
  [self setStringValue:[length stringValue] forAttribute:kLengthAttr];
}

- (NSString *)ETag {
  NSString *str = [self attributeValueForExtensionClass:[GDataETagAttribute class]];
  return str;
}

- (void)setETag:(NSString *)str {
  [self setAttributeValue:str forExtensionClass:[GDataETagAttribute class]];
}

- (GDataAtomContent *)content {
  return [self objectForExtensionClass:[GDataAtomContent class]];
}

- (void)setContent:(GDataAtomContent *)obj {
  [self setObject:obj forExtensionClass:[GDataAtomContent class]];
}

// convenience method

- (NSURL *)URL {
  NSString *href = [self href];
  if ([href length] > 0) {
    return [NSURL URLWithString:href];
  }
  return nil;
}

// utility method

+ (NSArray *)linkNamesFromLinks:(NSArray *)links {
  // we'll make a list of short, readable link names
  // by grabbing the rel values, and removing anything before
  // the last pound sign if there is one

  NSMutableArray *names = nil;

  for (GDataLink *dataLink in links) {

    NSString *rel = [dataLink rel];
    NSString *displayName;

    NSRange range = [rel rangeOfString:@"#" options:NSBackwardsSearch];
    if (range.location != NSNotFound) {
      // the display name is the suffix of the link's rel string
      displayName = [rel substringFromIndex:(1 + range.location)];
    } else {
      displayName = rel;
    }

    if (names == nil) {
      names = [NSMutableArray array];
    }
    [names addObject:displayName];
  }
  return names;
}

#pragma mark Utilities

// Find the first link with the given rel and type values. Either argument
// may be nil, which means "match any value".
+ (GDataLink *)linkWithRel:(NSString *)relValue
                      type:(NSString *)typeValue
                 fromLinks:(NSArray *)array {

  for (GDataLink *dataLink in array) {

    NSString *foundRelValue = [dataLink rel];
    NSString *foundTypeValue = [dataLink type];

    if ((relValue == nil || AreEqualOrBothNil(relValue, foundRelValue))
        && (typeValue == nil || AreEqualOrBothNil(typeValue, foundTypeValue))) {
      return dataLink;
    }
  }
  return nil;
}

+ (GDataLink *)linkWithRelAttributeSuffix:(NSString *)relSuffix
                                fromLinks:(NSArray *)array {

  for (GDataLink *dataLink in array) {

    NSString *attrValue = [dataLink rel];
    if (attrValue && [attrValue hasSuffix:relSuffix]) {
      return dataLink;
    }
  }
  return nil;
}

@end
