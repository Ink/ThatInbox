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
//  GDataOrganizationName.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataOrganizationName.h"

static NSString* const kYomiAttr = @"yomi";

@implementation GDataOrganizationName
// organization name
//    <gd:orgName yomi="Ak Me">Acme Corp</gd:orgName>

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"orgName"; }

+ (id)organizationNameWithString:(NSString *)str {
  GDataOrganizationName *obj = [self object];
  [obj setStringValue:str];
  return obj;
}

- (void)addParseDeclarations {

  NSArray *attrs = [NSArray arrayWithObject:kYomiAttr];
  [self addLocalAttributeDeclarations:attrs];

  [self addContentValueDeclaration];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {
  static struct GDataDescriptionRecord descRecs[] = {
    { @"value", @"stringValue", kGDataDescValueLabeled },
    { @"yomi",  @"yomi",        kGDataDescValueLabeled },
    { nil, nil, (GDataDescRecTypes)0 }
  };

  NSMutableArray *items = [super itemsForDescription];
  [self addDescriptionRecords:descRecs toItems:items];
  return items;
}
#endif

#pragma mark -

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
  [self setStringValue:str forAttribute:kYomiAttr];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
