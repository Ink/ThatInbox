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
//  GDataEntryContent.h
//

#import "GDataObject.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATAENTRYCONTENT_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataContentTypeKML _INITIALIZE_AS(@"application/vnd.google-earth.kml+xml");


// per http://www.atomenabled.org/developers/syndication/atom-format-spec.php#element.content
//
// For typed content, like <content type="text">Here go the ferrets</content>
//
// or media content with a source URI specified,
//  <content src="http://lh.google.com/image/Car.jpg" type="image/jpeg"/>
//
// or a child feed or entry, like
//  <content type="application/atom+xml;feed"> <feed>...</feed> </content>
//
// Text type can be text, text/plain, html, text/html, xhtml, text/xhtml

@interface GDataEntryContent : GDataObject {
  GDataObject *childObject_;
}

+ (id)contentWithString:(NSString *)str;

+ (id)contentWithSourceURI:(NSString *)str type:(NSString *)type;

+ (id)contentWithXMLValue:(NSXMLNode *)node type:(NSString *)type;

+ (id)textConstructWithString:(NSString *)str; // deprecated

- (NSString *)lang;
- (void)setLang:(NSString *)str;

- (NSString *)type;
- (void)setType:(NSString *)str;

- (NSString *)sourceURI;
- (void)setSourceURI:(NSString *)str;
- (NSURL *)sourceURL;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;

- (GDataObject *)childObject;
- (void)setChildObject:(GDataObject *)obj;

- (NSArray *)XMLValues;
- (void)setXMLValues:(NSArray *)arr;
- (void)addXMLValue:(NSXMLNode *)node;

@end
