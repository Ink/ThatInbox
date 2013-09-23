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
//  GDataQuery.h
//

#import "GDataCategory.h"
#import "GDataDateTime.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATAQUERY_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

// result formats
_EXTERN NSString* const kGDataQueryResultServiceDocument _INITIALIZE_AS(@"atom-service"); // service introspection

// categories within a filter are ORed; multiple filters in
// a query are ANDed

@interface GDataCategoryFilter : NSObject <NSCopying> {
  NSMutableArray *categories_;
  NSMutableArray *excludeCategories_;
}

+ (GDataCategoryFilter *)categoryFilter;

- (NSArray *)categories;
- (void)setCategories:(NSArray *)categories;
- (void)addCategory:(GDataCategory *)category;
- (void)addCategoryWithScheme:(NSString *)scheme term:(NSString *)term;

- (NSArray *)excludeCategories;
- (void)setExcludeCategories:(NSArray *)excludeCategories;
- (void)addExcludeCategory:(GDataCategory *)excludeCategory;
- (void)addExcludeCategoryWithScheme:(NSString *)scheme term:(NSString *)term;

- (NSString *)stringValue;
@end

@interface GDataQuery : NSObject <NSCopying> {
  NSURL *feedURL_;
  NSMutableArray *categoryFilters_;
  NSMutableDictionary *customParameters_;
}

+ (id)queryWithFeedURL:(NSURL *)feedURL;

- (id)initWithFeedURL:(NSURL *)feedURL;

- (NSURL *)URL;


- (NSURL *)feedURL;
- (void)setFeedURL:(NSURL *)feedURL;

// startIndex and maxResults use -1 to indicate parameter is not set
- (NSInteger)startIndex;
- (void)setStartIndex:(NSInteger)startIndex;

- (NSInteger)maxResults;
- (void)setMaxResults:(NSInteger)maxResults;

- (NSString *)fieldSelection;
- (void)setFieldSelection:(NSString *)str;

- (NSString *)fullTextQueryString;
- (void)setFullTextQueryString:(NSString *)str;

- (NSString *)author;
- (void)setAuthor:(NSString *)author;

- (NSString *)orderBy;
- (void)setOrderBy:(NSString *)author;

- (BOOL)isAscendingOrder;
- (void)setIsAscendingOrder:(BOOL)flag;

- (BOOL)shouldShowDeleted;
- (void)setShouldShowDeleted:(BOOL)flag;

- (BOOL)shouldRequireAllDeleted;
- (void)setShouldRequireAllDeleted:(BOOL)flag;

- (BOOL)shouldShowOnlyDeleted;
- (void)setShouldShowOnlyDeleted:(BOOL)flag;

- (BOOL)isStrict;
- (void)setIsStrict:(BOOL)flag;

- (BOOL)shouldPrettyPrint;
- (void)setShouldPrettyPrint:(BOOL)flag;

- (NSString *)protocolVersion;
- (void)setProtocolVersion:(NSString *)str;

- (NSString *)resultFormat;  // the "alt" parameter
- (void)setResultFormat:(NSString *)str;

- (NSString *)language;
- (void)setLanguage:(NSString *)str;

- (GDataDateTime *)publishedMinDateTime;
- (void)setPublishedMinDateTime:(GDataDateTime *)dateTime;

- (GDataDateTime *)publishedMaxDateTime;
- (void)setPublishedMaxDateTime:(GDataDateTime *)dateTime;

- (GDataDateTime *)updatedMinDateTime;
- (void)setUpdatedMinDateTime:(GDataDateTime *)dateTime;

- (GDataDateTime *)updatedMaxDateTime;
- (void)setUpdatedMaxDateTime:(GDataDateTime *)dateTime;

- (BOOL)shouldFormatErrorsAsXML;
- (void)setShouldFormatErrorsAsXML:(BOOL)flag;

- (NSArray *)categoryFilters;
- (void)setCategoryFilters:(NSArray *)filters;
- (void)addCategoryFilter:(GDataCategoryFilter *)filter;
- (void)addCategoryFilterWithCategory:(GDataCategory *)category;
- (void)addCategoryFilterWithScheme:(NSString *)scheme term:(NSString *)term;

- (NSDictionary *)customParameters;
- (void)setCustomParameters:(NSDictionary *)dict;


// adding a parameter with a value of nil will remove
// the parameter from the list
- (void)addCustomParameterWithName:(NSString *)name
                             value:(NSString *)value;
- (void)removeCustomParameterWithName:(NSString *)name;
- (NSString *)valueForParameterWithName:(NSString *)name;

// convenience methods for int parameters

// if val==invalidVal, the parameter is removed
- (void)addCustomParameterWithName:(NSString *)name
                          intValue:(NSInteger)val
                    removeForValue:(NSInteger)invalidVal;

// if the named parameter is not found, missingVal is returned
- (NSInteger)intValueForParameterWithName:(NSString *)name
                    missingParameterValue:(NSInteger)missingVal;

// convenience methods for boolean parameters
- (void)addCustomParameterWithName:(NSString *)name
                         boolValue:(BOOL)flag
                      defaultValue:(BOOL)defaultValue;

- (BOOL)boolValueForParameterWithName:(NSString *)name
                         defaultValue:(BOOL)defaultValue;

// convenience methods for dateTime parameters
- (void)addCustomParameterWithName:(NSString *)name
                          dateTime:(GDataDateTime *)dateTime;
- (GDataDateTime *)dateTimeForParameterWithName:(NSString *)name;
@end
