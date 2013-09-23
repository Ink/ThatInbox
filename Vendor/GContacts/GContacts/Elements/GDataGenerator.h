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
//  GDataGenerator.h
//

#import "GDataObject.h"

// Feed generator element, as in
//   <generator version='1.0' uri='http://www.google.com/calendar/'>CL2</generator>
@interface GDataGenerator : GDataObject <GDataExtension> {
}
+ (GDataGenerator *)generatorWithName:(NSString *)name
                              version:(NSString *)version
                                  URI:(NSString *)uri;

- (NSString *)name;
- (void)setName:(NSString *)str;

- (NSString *)version;
- (void)setVersion:(NSString *)str;

- (NSString *)URI;
- (void)setURI:(NSString *)str;

@end
