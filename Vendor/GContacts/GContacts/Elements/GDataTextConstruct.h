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
//  GDataTextConstruct.h
//

#import "GDataObject.h"

// For typed text, like: <title type="text">Event title</title>
//
// type can be text, text/plain, html, text/html, xhtml, or other things
@interface GDataTextConstruct : GDataObject {
}

+ (id)textConstructWithString:(NSString *)str;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;
- (NSString *)lang;
- (void)setLang:(NSString *)str;
- (NSString *)type;
- (void)setType:(NSString *)str;

@end

