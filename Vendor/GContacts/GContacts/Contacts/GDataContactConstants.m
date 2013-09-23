/* Copyright (c) 2009 Google Inc.
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
//  GDataContactConstants.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#define GDATACONTACTCONSTANTS_DEFINE_GLOBALS 1
#import "GDataContactConstants.h"

#import "GDataUtilities.h"
#import "GDataEntryBase.h"

@implementation GDataContactConstants

+ (NSString *)coreProtocolVersionForServiceVersion:(NSString *)serviceVersion {
  // Contacts v1: core v1
  //          v2:      v2
  //          v3:      v2
  NSComparisonResult result = [GDataUtilities compareVersion:serviceVersion
                                                   toVersion:@"2.0"];
  if (result != NSOrderedAscending) {
    return @"2.0";
  }
  return @"1.0";
}

+ (NSDictionary *)contactNamespaces {
  NSMutableDictionary *namespaces;

  namespaces = [NSMutableDictionary dictionaryWithObject:kGDataNamespaceContact
                                                  forKey:kGDataNamespaceContactPrefix];

  [namespaces addEntriesFromDictionary:[GDataEntryBase baseGDataNamespaces]];

  return namespaces;
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
