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
//  GDataPerson.h
//

#import "GDataObject.h"
// a person, as in
// <author>
//   <name>Fred Flintstone</name>
//   <email>test@domain.net</email>
// </author>
@interface GDataPerson : GDataObject <GDataExtension>

+ (GDataPerson *)personWithName:(NSString *)name email:(NSString *)email;

- (NSString *)name;
- (void)setName:(NSString *)str;

- (NSString *)nameLang;
- (void)setNameLang:(NSString *)str;

- (NSString *)URI;
- (void)setURI:(NSString *)str;

- (NSString *)email;
- (void)setEmail:(NSString *)str;
@end
