/* Copyright (c) 2008 Google Inc.
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
//  GDataOrganization.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataObject.h"
#import "GDataValueConstruct.h"

@class GDataWhere;

// organization, as in
//
// <gd:organization rel="http://schemas.google.com/g/2005#work" label="Work" primary="true"/>
//   <gd:orgName>Google</gd:orgName>
//   <gd:orgTitle>Tech Writer</gd:orgTitle>
//   <gd:orgJobDescription>Writes documentation</gd:orgJobDescription>
//   <gd:orgDepartment>Software Development</gd:orgDepartment>
//   <gd:orgSymbol>GOOG</gd:orgSymbol>
// </gd:organization>

@interface GDataOrganization : GDataObject <GDataExtension>

+ (GDataOrganization *)organizationWithName:(NSString *)str;

- (NSString *)rel;
- (void)setRel:(NSString *)str;

- (NSString *)label;
- (void)setLabel:(NSString *)str;

- (BOOL)isPrimary;
- (void)setIsPrimary:(BOOL)flag;

- (NSString *)orgName;
- (void)setOrgName:(NSString *)str;

- (NSString *)orgNameYomi;
- (void)setOrgNameYomi:(NSString *)str;

- (NSString *)orgTitle;
- (void)setOrgTitle:(NSString *)str;

- (NSString *)orgDepartment;
- (void)setOrgDepartment:(NSString *)str;

- (NSString *)orgJobDescription;
- (void)setOrgJobDescription:(NSString *)str;

- (NSString *)orgSymbol;
- (void)setOrgSymbol:(NSString *)str;

- (GDataWhere *)where;
- (void)setWhere:(GDataWhere *)obj;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
