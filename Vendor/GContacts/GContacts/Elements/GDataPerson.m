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
//  GDataPerson.m
//

#import "GDataPerson.h"
#import "GDataValueConstruct.h"

static NSString *const kLangAttr = @"xml:lang";

// name, like <atom:name>Fred Flintstone<atom:name>
@interface GDataPersonName : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPersonName
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"name"; }
@end

// email, like <atom:email>fred@flintstone.com<atom:email>
@interface GDataPersonEmail : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPersonEmail
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"email"; }
@end

// URI, like <atom:uri>http://flintstone.com/resource<atom:uri>
@interface GDataPersonURI : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataPersonURI
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"uri"; }
@end

@implementation GDataPerson
// a person, as in
// <author>
//   <name>Fred Flintstone</name>
//   <email>fred@flintstone.com</email>
// </author>

+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"author"; }

+ (GDataPerson *)personWithName:(NSString *)name email:(NSString *)email {
  GDataPerson* obj = [self object];
  [obj setName:name];
  [obj setEmail:email];
  return obj;
}

- (void)addParseDeclarations {
  [self addLocalAttributeDeclarations:[NSArray arrayWithObject:kLangAttr]];
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  [self addExtensionDeclarationForParentClass:[self class]
                                 childClasses:
   [GDataPersonName class],
   [GDataPersonEmail class],
   [GDataPersonURI class],
   nil];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {
  NSMutableArray *items = [super itemsForDescription];

  [self addToArray:items objectDescriptionIfNonNil:[self name] withName:@"name"];
  [self addToArray:items objectDescriptionIfNonNil:[self URI] withName:@"URI"];
  [self addToArray:items objectDescriptionIfNonNil:[self email] withName:@"email"];

  return items;
}
#endif

- (NSString *)name {
  GDataPersonName *obj = [self objectForExtensionClass:[GDataPersonName class]];
  return [obj stringValue];
}

- (void)setName:(NSString *)str {
  GDataPersonName *obj = [GDataPersonName valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPersonName class]];
}

- (NSString *)nameLang {
  return [self stringValueForAttribute:kLangAttr];
}

- (void)setNameLang:(NSString *)str {
  [self setStringValue:str forAttribute:kLangAttr];
}

- (NSString *)URI {
  GDataPersonURI *obj = [self objectForExtensionClass:[GDataPersonURI class]];
  return [obj stringValue];
}

- (void)setURI:(NSString *)str {
  GDataPersonURI *obj = [GDataPersonURI valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPersonURI class]];
}

- (NSString *)email {
  GDataPersonEmail *obj = [self objectForExtensionClass:[GDataPersonEmail class]];
  return [obj stringValue];
}

- (void)setEmail:(NSString *)str {
  GDataPersonEmail *obj = [GDataPersonEmail valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataPersonEmail class]];
}
@end
