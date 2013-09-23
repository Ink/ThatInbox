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
//  GDataComment.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_BOOKS_SERVICE \
  || GDATA_INCLUDE_CALENDAR_SERVICE || GDATA_INCLUDE_YOUTUBE_SERVICE

#import "GDataComment.h"

static NSString* const kRelAttr = @"rel";

@implementation GDataComment
// a commments entry, as in
// <gd:comments>
//    <gd:feedLink href="http://www.google.com/calendar/feeds/t..."/>
// </gd:comments>
//
// http://code.google.com/apis/gdata/common-elements.html#gdComments

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"comments"; }

+ (GDataComment *)commentWithFeedLink:(GDataFeedLink *)feedLink {
  GDataComment *obj = [self object];
  [obj setFeedLink:feedLink];
  return obj;
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  [self addExtensionDeclarationForParentClass:[self class]
                                   childClass:[GDataFeedLink class]];
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObject:kRelAttr];

  [self addLocalAttributeDeclarations:attrs];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {
  NSMutableArray *items = [super itemsForDescription];

  [self addToArray:items objectDescriptionIfNonNil:[self feedLink] withName:@"feedLink"];

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

- (GDataFeedLink *)feedLink {
  return [self objectForExtensionClass:[GDataFeedLink class]];
}

- (void)setFeedLink:(GDataFeedLink *)feedLink {
  [self setObject:feedLink forExtensionClass:[GDataFeedLink class]];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_*_SERVICE
