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
//  GDataCategory.m
//

#define GDATACATEGORY_DEFINE_GLOBALS 1
#import "GDataCategory.h"

static NSString* const kSchemeAttr = @"scheme";
static NSString* const kTermAttr = @"term";
static NSString* const kLabelAttr = @"label";
static NSString* const kLangAttr = @"xml:lang";

@implementation GDataCategory
// for categories, like
//  <category scheme="http://schemas.google.com/g/2005#kind"
//        term="http://schemas.google.com/g/2005#event"/>

+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"category"; }

+ (GDataCategory *)categoryWithScheme:(NSString *)scheme
                                 term:(NSString *)term {
  GDataCategory* obj = [self object];
  [obj setScheme:scheme];
  [obj setTerm:term];
  return obj;
}

+ (GDataCategory *)categoryWithLabel:(NSString *)label {

  NSString *term = [NSString stringWithFormat:@"%@#%@",
    kGDataCategoryLabelScheme, label];

  GDataCategory *obj = [self categoryWithScheme:kGDataCategoryLabelScheme
                                           term:term];
  [obj setLabel:label];
  return obj;
}

- (void)addParseDeclarations {

  NSArray *attrs = [NSArray arrayWithObjects:
                    kSchemeAttr, kTermAttr, kLabelAttr, kLangAttr, nil];

  [self addLocalAttributeDeclarations:attrs];
}

- (NSArray *)attributesIgnoredForEquality {

  // per Category.java: this should exclude label and labelLang,
  // but the GMail provider is generating categories which
  // have identical terms but unique labels, so we need to compare
  // label values as well, though not xml:lang

  return [NSArray arrayWithObject:kLangAttr];
}

// should we override hash function like Java does?

- (NSString *)scheme {
  return [self stringValueForAttribute:kSchemeAttr];
}

- (void)setScheme:(NSString *)str {
  [self setStringValue:str forAttribute:kSchemeAttr];
}

- (NSString *)term {
  return [self stringValueForAttribute:kTermAttr];
}

- (void)setTerm:(NSString *)str {
  [self setStringValue:str forAttribute:kTermAttr];
}

- (NSString *)label {
  return [self stringValueForAttribute:kLabelAttr];
}

- (void)setLabel:(NSString *)str {
  [self setStringValue:str forAttribute:kLabelAttr];
}

- (NSString *)labelLang {
  return [self stringValueForAttribute:kLangAttr];
}

- (void)setLabelLang:(NSString *)str {
  [self setStringValue:str forAttribute:kLangAttr];
}

#pragma mark Utilities

// return all categories with the specified scheme
+ (NSArray *)categoriesWithScheme:(NSString *)scheme
                   fromCategories:(NSArray *)array {

  NSArray *cats = [GDataUtilities objectsFromArray:array
                                         withValue:scheme
                                        forKeyPath:@"scheme"];
  return cats;
}

// return all categories whose schemes have the specified prefix
+ (NSArray *)categoriesWithSchemePrefix:(NSString *)prefix
                         fromCategories:(NSArray *)array {
  NSMutableArray *matches = [NSMutableArray array];

  for (GDataCategory *category in array) {
    NSString *scheme = [category scheme];
    if (scheme != nil && [scheme hasPrefix:prefix]) {
      [matches addObject:category];
    }
  }
  return matches;
}

+ (NSArray *)categoryLabelsFromCategories:(NSArray *)array {

  NSMutableArray *labels = [NSMutableArray array];

  for (GDataCategory *category in array) {
    NSString *label = [category label];
    if (label != nil && ![labels containsObject:label]) {
      [labels addObject:label];
    }
  }
  return labels;
}

+ (BOOL)categories:(NSArray *)array
containsCategoryWithScheme:(NSString *)scheme
              term:(NSString *)term
             label:(NSString *)label {
  // nil argument means "don't care"
  for (GDataCategory *category in array) {
    if ((scheme == nil || AreEqualOrBothNil([category scheme], scheme))
        && (term == nil || AreEqualOrBothNil([category term], term))
        && (label == nil || AreEqualOrBothNil([category label], label))) {
      return YES;
    }
  }
  return NO;
}

+ (BOOL)categories:(NSArray *)array containsCategoryWithLabel:(NSString *)label {
  // to be rigorous, we'd construct a term string for comparison as done
  // above in +categoryWithLabel: but that would make this a much more
  // expensive routine to call
  BOOL flag = [self categories:array
    containsCategoryWithScheme:kGDataCategoryLabelScheme
                          term:nil
                         label:label];
  return flag;
}
@end
