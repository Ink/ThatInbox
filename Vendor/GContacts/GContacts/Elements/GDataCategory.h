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
//  GDataCategory.h
//

#import "GDataObject.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATACATEGORY_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataCategoryLabelScheme _INITIALIZE_AS(@"http://schemas.google.com/g/2005/labels");

_EXTERN NSString* const kGDataCategoryLabelStarred          _INITIALIZE_AS(@"starred");
_EXTERN NSString* const kGDataCategoryLabelTrashed          _INITIALIZE_AS(@"trashed");
_EXTERN NSString* const kGDataCategoryLabelPublished        _INITIALIZE_AS(@"published");
_EXTERN NSString* const kGDataCategoryLabelPrivate          _INITIALIZE_AS(@"private");
_EXTERN NSString* const kGDataCategoryLabelMine             _INITIALIZE_AS(@"mine");
_EXTERN NSString* const kGDataCategoryLabelSharedWithDomain _INITIALIZE_AS(@"shared-with-domain");
_EXTERN NSString* const kGDataCategoryLabelHidden           _INITIALIZE_AS(@"hidden");
_EXTERN NSString* const kGDataCategoryLabelViewed           _INITIALIZE_AS(@"viewed");
_EXTERN NSString* const kGDataCategoryLabelShared           _INITIALIZE_AS(@"shared");

// for categories, like
//  <category scheme="http://schemas.google.com/g/2005#kind"
//        term="http://schemas.google.com/g/2005#event"/>
@interface GDataCategory : GDataObject <GDataExtension>

+ (GDataCategory *)categoryWithScheme:(NSString *)scheme
                                 term:(NSString *)term;

+ (GDataCategory *)categoryWithLabel:(NSString *)label;

- (NSString *)scheme;
- (void)setScheme:(NSString *)str;
- (NSString *)term;
- (void)setTerm:(NSString *)str;
- (NSString *)label;
- (void)setLabel:(NSString *)str;
- (NSString *)labelLang;
- (void)setLabelLang:(NSString *)str;

#pragma mark -

// utilities for extracting a subset of categories
+ (NSArray *)categoriesWithScheme:(NSString *)scheme fromCategories:(NSArray *)array;
+ (NSArray *)categoriesWithSchemePrefix:(NSString *)prefix fromCategories:(NSArray *)array;

+ (NSArray *)categoryLabelsFromCategories:(NSArray *)array;
+ (BOOL)categories:(NSArray *)array containsCategoryWithLabel:(NSString *)label;

// this general search routine allows nil as "don't care" for scheme, term,
// and label
+ (BOOL)categories:(NSArray *)array
containsCategoryWithScheme:(NSString *)scheme
              term:(NSString *)term
             label:(NSString *)label;

@end
