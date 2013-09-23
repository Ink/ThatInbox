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
//  GDataAtomPubControl.m
//

#import "GDataAtomPubControl.h"
#import "GDataValueConstruct.h"

// app:draft, like
//   <app:draft>yes<app:draft>

@interface GDataAtomPubDraft : GDataValueElementConstruct <GDataExtension>
@end

@implementation GDataAtomPubDraft
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtomPub; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPubPrefix; }
+ (NSString *)extensionElementLocalName { return @"draft"; }
@end

@implementation GDataAtomPubControl

// For app:control, like:
//   <app:control><app:draft>yes</app:draft></app:control>

+ (NSString *)extensionElementURI       { return kGDataNamespaceAtomPub; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPubPrefix; }
+ (NSString *)extensionElementLocalName { return @"control"; }

+ (GDataAtomPubControl *)atomPubControl {
  GDataAtomPubControl *obj = [self object];

  // add the "app" namespace
  NSString *nsURI = [[self class] extensionElementURI];
  NSDictionary *namespaceDict = [NSDictionary dictionaryWithObject:nsURI
                                                            forKey:kGDataNamespaceAtomPubPrefix];
  [obj setNamespaces:namespaceDict];

  return obj;
}

+ (GDataAtomPubControl *)atomPubControlWithIsDraft:(BOOL)isDraft {
  GDataAtomPubControl *obj = [self atomPubControl];
  [obj setIsDraft:isDraft];
  return obj;
}

+ (NSString *)defaultServiceVersion {
  return @"2.0";
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  [self addExtensionDeclarationForParentClass:[self class]
                                   childClass:[GDataAtomPubDraft class]];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {
  NSMutableArray *items = [NSMutableArray array];

  NSString *str = ([self isDraft] ? @"yes" : @"no");
  [self addToArray:items objectDescriptionIfNonNil:str
          withName:@"isDraft"];

  return items;
}
#endif

- (BOOL)isDraft {
  GDataValueElementConstruct *obj;
  obj = [self objectForExtensionClass:[GDataAtomPubDraft class]];

  NSString *str = [obj stringValue];
  BOOL isDraft = (str != nil
                  && [str caseInsensitiveCompare:@"yes"] == NSOrderedSame);
  return isDraft;
}

- (void)setIsDraft:(BOOL)isDraft {

  id obj = nil;
  if (isDraft) {
    obj = [GDataAtomPubDraft valueWithString:@"yes"];
  }

  [self setObject:obj forExtensionClass:[GDataAtomPubDraft class]];
}

@end


