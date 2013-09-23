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
//  GDataEntryLink.h
//

#import "GDataObject.h"

@class GDataEntryBase;

// used inside GDataWhere, a link to an entry, like
// <gd:entryLink href="http://gmail.com/jo/contacts/Jo">
@interface GDataEntryLink : GDataObject <GDataExtension> {
  GDataEntryBase *entry_;
}

+ (GDataEntryLink *)entryLinkWithHref:(NSString *)href
                           isReadOnly:(BOOL)isReadOnly;

- (id)initWithXMLElement:(NSXMLElement *)element
                  parent:(GDataObject *)parent;

- (NSXMLElement *)XMLElement;

- (NSString *)href;
- (void)setHref:(NSString *)str;

- (BOOL)isReadOnly;
- (void)setIsReadOnly:(BOOL)isReadOnly;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (GDataEntryBase *)entry;
- (void)setEntry:(GDataEntryBase *)entry;

@end
