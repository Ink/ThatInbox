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
//  GDataServiceGoogleContact.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#define GDATASERVICEGOOGLECONTACT_DEFINE_GLOBALS 1

#import "GDataServiceGoogleContact.h"
#import "GDataQueryContact.h"
#import "GDataFeedContact.h"
#import "GDataContactConstants.h"

@implementation GDataServiceGoogleContact

// feed is contacts or groups; projection is thin, default, or property-<key>
+ (NSURL *)contactURLForFeedName:(NSString *)feedName
                          userID:(NSString *)userID
                      projection:(NSString *)projection {

  NSString *baseURLString = [self serviceRootURLString];

  NSString *const templateStr = @"%@%@/%@/%@";

  NSString *feedURLString = [NSString stringWithFormat:templateStr,
                             baseURLString,
                             [GDataUtilities stringByURLEncodingForURI:feedName],
                             [GDataUtilities stringByURLEncodingForURI:userID],
                             [GDataUtilities stringByURLEncodingForURI:projection]];

  NSURL *url = [NSURL URLWithString:feedURLString];

  return url;
}

+ (NSURL *)contactFeedURLForPropertyName:(NSString *)property {

  NSString *projection = [NSString stringWithFormat:@"property-%@", property];
  NSURL *url = [self contactURLForFeedName:kGDataGoogleContactAllContactsFeedName
                                    userID:kGDataServiceDefaultUser
                                projection:projection];
  return url;
}

+ (NSURL *)contactGroupFeedURLForPropertyName:(NSString *)property {

  NSString *projection = [NSString stringWithFormat:@"property-%@", property];
  NSURL *url = [self contactURLForFeedName:kGDataGoogleContactGroupsFeedName
                                    userID:kGDataServiceDefaultUser
                                projection:projection];
  return url;
}

+ (NSURL *)contactFeedURLForUserID:(NSString *)userID {

  NSURL *url = [self contactURLForFeedName:kGDataGoogleContactAllContactsFeedName
                                    userID:userID
                                projection:kGDataGoogleContactFullProjection];
  return url;
}

+ (NSURL *)groupFeedURLForUserID:(NSString *)userID {

  NSURL *url = [self contactURLForFeedName:kGDataGoogleContactGroupsFeedName
                                    userID:userID
                                projection:kGDataGoogleContactFullProjection];
  return url;
}

+ (NSURL *)contactFeedURLForUserID:(NSString *)userID
                        projection:(NSString *)projection {

  NSURL *url = [self contactURLForFeedName:kGDataGoogleContactAllContactsFeedName
                                    userID:userID
                                projection:projection];
  return url;
}

- (GDataServiceTicket *)fetchContactFeedForUsername:(NSString *)username
                                           delegate:(id)delegate
                                  didFinishSelector:(SEL)finishedSelector {

  NSURL *url = [[self class] contactFeedURLForUserID:username];

  return [self fetchFeedWithURL:url
                       delegate:delegate
              didFinishSelector:finishedSelector];
}


+ (NSString *)serviceID {
  return @"cp";
}

+ (NSString *)serviceRootURLString {
  return @"https://www.google.com/m8/feeds/";
}

+ (NSString *)defaultServiceVersion {
  return kGDataContactDefaultServiceVersion;
}

+ (NSDictionary *)standardServiceNamespaces {
  return [GDataContactConstants contactNamespaces];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
