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
//  GDataFeedLink.h
//

#import "GDataObject.h"

@class GDataFeedBase;

// a link to a feed, like
// <gd:feedLink href="http://example.com/Jo/posts/MyFirstPost/comments" countHint="10">

@interface GDataFeedLink : GDataObject <NSCopying, GDataExtension> {
  GDataFeedBase *feed_;
}

+ (id)feedLinkWithHref:(NSString *)href
            isReadOnly:(BOOL)isReadOnly;

- (id)initWithXMLElement:(NSXMLElement *)element
                  parent:(GDataObject *)parent;

- (NSXMLElement *)XMLElement;

- (NSString *)href;
- (void)setHref:(NSString *)str;

- (BOOL)isReadOnly;
- (void)setIsReadOnly:(BOOL)isReadOnly;

- (NSNumber *)countHint;
- (void)setCountHint:(NSNumber *)val;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (GDataFeedBase *)feed;
- (void)setFeed:(GDataFeedBase *)feed;

// convert the href string into an URL
- (NSURL *)URL;
@end
