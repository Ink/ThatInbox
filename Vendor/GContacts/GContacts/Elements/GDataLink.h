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
//  GDataLink.h
//

#import "GDataObject.h"


#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATALINK_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataLinkRelFeed            _INITIALIZE_AS(@"http://schemas.google.com/g/2005#feed");
_EXTERN NSString* const kGDataLinkRelPost            _INITIALIZE_AS(@"http://schemas.google.com/g/2005#post");
_EXTERN NSString* const kGDataLinkRelBatch           _INITIALIZE_AS(@"http://schemas.google.com/g/2005#batch");
_EXTERN NSString* const kGDataLinkRelResumableCreate _INITIALIZE_AS(@"http://schemas.google.com/g/2005#resumable-create-media");
_EXTERN NSString* const kGDataLinkRelResumableEdit   _INITIALIZE_AS(@"http://schemas.google.com/g/2005#resumable-edit-media");

_EXTERN NSString* const kGDataLinkTypeAtom _INITIALIZE_AS(@"application/atom+xml");
_EXTERN NSString* const kGDataLinkTypeHTML _INITIALIZE_AS(@"text/html");

// for links, like
//
//  <link rel="alternate" type="text/html"
//        href="http://www.google.com/calendar/event?eid=b..." title="alternate">
//     <content type="application/atom+xml;feed"> <feed>...</feed> </content>
//  </link>
//

@class GDataAtomContent;

@interface GDataLink : GDataObject <GDataExtension>

+ (GDataLink *)linkWithRel:(NSString *)rel
                      type:(NSString *)type
                      href:(NSString *)href;  // parameters may be nil

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (NSString *)type;
- (void)setType:(NSString *)str;

- (NSString *)href;
- (void)setHref:(NSString *)str;

- (NSString *)hrefLang;
- (void)setHrefLang:(NSString *)str;

- (NSString *)title;
- (void)setTitle:(NSString *)str;

- (NSString *)titleLang;
- (void)setTitleLang:(NSString *)str;

- (NSNumber *)resourceLength;
- (void)setResourceLength:(NSNumber *)length;

- (NSString *)ETag;
- (void)setETag:(NSString *)str;

- (GDataAtomContent *)content;
- (void)setContent:(GDataAtomContent *)obj;

// convenience method

// convert the href string into an URL
- (NSURL *)URL;

// utility methods

// get a list of short names for links in the array
+ (NSArray *)linkNamesFromLinks:(NSArray *)links;

// utilities for extracting a GDataLink from an array of links

// to search by rel only, use nil type to match any type
+ (GDataLink *)linkWithRel:(NSString *)relValue type:(NSString *)typeValue fromLinks:(NSArray *)array;

+ (GDataLink *)linkWithRelAttributeSuffix:(NSString *)relSuffix fromLinks:(NSArray *)array;

@end
