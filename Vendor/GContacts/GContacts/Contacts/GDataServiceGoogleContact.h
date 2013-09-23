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
//  GDataServiceGoogleContact.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE

#import "GDataServiceGoogle.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATASERVICEGOOGLECONTACT_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

// GDataXML contacts for the authenticated user
//
// Full feeds include all extendedProperties, which must be preserved
// when updating entries; thin feeds include no extendedProperties.
//
// For a feed that includes only extendedProperties with a specific
// property name, use contactFeedURLForPropertyName:
// or contactGroupFeedURLForPropertyName:
//
// Google Contacts limits contacts to one extended property per property
// name.  Requesting a feed for a specific property name avoids the need
// to preserve other applications' property names when updating entries.

// AllContacts includes actual and suggested contacts
// Groups is for group feeds
_EXTERN NSString* const kGDataGoogleContactAllContactsFeedName _INITIALIZE_AS(@"contacts");
_EXTERN NSString* const kGDataGoogleContactGroupsFeedName      _INITIALIZE_AS(@"groups");

// Projections - full (include all extended properties) or thin (exclude
//               extended properties)
_EXTERN NSString* const kGDataGoogleContactFullProjection _INITIALIZE_AS(@"full");
_EXTERN NSString* const kGDataGoogleContactThinProjection _INITIALIZE_AS(@"thin");

_EXTERN NSString* kGDataGoogleContactDefaultThinFeed _INITIALIZE_AS(@"https://www.google.com/m8/feeds/contacts/default/thin");
_EXTERN NSString* kGDataGoogleContactDefaultFullFeed _INITIALIZE_AS(@"https://www.google.com/m8/feeds/contacts/default/full");

_EXTERN NSString* kGDataGoogleContactGroupDefaultThinFeed _INITIALIZE_AS(@"https://www.google.com/m8/feeds/groups/default/thin");
_EXTERN NSString* kGDataGoogleContactGroupDefaultFullFeed _INITIALIZE_AS(@"https://www.google.com/m8/feeds/groups/default/full");


@interface GDataServiceGoogleContact : GDataServiceGoogle

+ (NSURL *)contactURLForFeedName:(NSString *)feedName
                          userID:(NSString *)userID
                      projection:(NSString *)projection;

// convenience URL generators for contacts feed
//
// Use kGDataServiceDefaultUser as the username to specify the authenticated
// user

+ (NSURL *)contactFeedURLForUserID:(NSString *)userID;
+ (NSURL *)groupFeedURLForUserID:(NSString *)userID;

+ (NSURL *)contactFeedURLForUserID:(NSString *)userID
                        projection:(NSString *)projection;

+ (NSURL *)contactFeedURLForPropertyName:(NSString *)property;
+ (NSURL *)contactGroupFeedURLForPropertyName:(NSString *)property;

- (GDataServiceTicket *)fetchContactFeedForUsername:(NSString *)username
                                           delegate:(id)delegate
                                  didFinishSelector:(SEL)finishedSelector;

// clients may use these fetch methods of GDataServiceGoogle
//
//  - (GDataServiceTicket *)fetchFeedWithURL:(NSURL *)feedURL delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//  - (GDataServiceTicket *)fetchFeedWithQuery:(GDataQuery *)query delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//  - (GDataServiceTicket *)fetchEntryWithURL:(NSURL *)entryURL delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//  - (GDataServiceTicket *)fetchEntryByInsertingEntry:(GDataEntryBase *)entryToInsert forFeedURL:(NSURL *)feedURL delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//  - (GDataServiceTicket *)fetchEntryByUpdatingEntry:(GDataEntryBase *)entryToUpdate delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//  - (GDataServiceTicket *)deleteEntry:(GDataEntryBase *)entryToDelete delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//  - (GDataServiceTicket *)deleteResourceURL:(NSURL *)resourceEditURL ETag:(NSString *)etag delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//  - (GDataServiceTicket *)fetchFeedWithBatchFeed:(GDataFeedBase *)batchFeed forBatchFeedURL:(NSURL *)feedURL delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//
// finishedSelector has a signature like this for feed fetches:
// - (void)serviceTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedBase *)feed error:(NSError *)error;
//
// or this for entry fetches:
// - (void)serviceTicket:(GDataServiceTicket *)ticket finishedWithEntry:(GDataEntryBase *)entry error:(NSError *)error;
//
// The class of the returned feed or entry is determined by the URL fetched.

+ (NSString *)serviceRootURLString;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_CONTACTS_SERVICE
