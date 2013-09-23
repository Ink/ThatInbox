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
// GDataEntryBase.h
//
// This is the base class for all standard GData feed entries.
//

#import "GDataDateTime.h"
#import "GDataTextConstruct.h"
#import "GDataEntryContent.h"
#import "GDataPerson.h"
#import "GDataCategory.h"
#import "GDataDeleted.h"
#import "GDataBatchOperation.h"
#import "GDataBatchID.h"
#import "GDataBatchStatus.h"
#import "GDataBatchInterrupted.h"
#import "GDataAtomPubControl.h"
#import "GDataLink.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATAENTRYBASE_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataCategoryScheme _INITIALIZE_AS(@"http://schemas.google.com/g/2005#kind");


@interface GDataEntryBase : GDataObject <NSCopying> {
  // either uploadData_ or uploadFileHandle_ may be set, but not both
  NSData *uploadData_;
  NSFileHandle *uploadFileHandle_;
  NSURL *uploadLocationURL_; // requires uploadFileHandle be set
  NSString *uploadMIMEType_;
  NSString *uploadSlug_; // for http slug (filename) header when uploading
  BOOL shouldUploadDataOnly_;
}

+ (NSDictionary *)baseGDataNamespaces;

+ (id)entry;

// basic entry fields
- (NSString *)identifier;
- (void)setIdentifier:(NSString *)theIdString;

- (GDataDateTime *)publishedDate;
- (void)setPublishedDate:(GDataDateTime *)thePublishedDate;

- (GDataDateTime *)updatedDate;
- (void)setUpdatedDate:(GDataDateTime *)theUpdatedDate;

- (GDataDateTime *)editedDate;
- (void)setEditedDate:(GDataDateTime *)theEditedDate;

- (NSString *)ETag;
- (void)setETag:(NSString *)str;

- (NSString *)fieldSelection;
- (void)setFieldSelection:(NSString *)str;

- (NSString *)kind;
- (void)setKind:(NSString *)str;

- (NSString *)resourceID;
- (void)setResourceID:(NSString *)str;

- (GDataTextConstruct *)title;
- (void)setTitle:(GDataTextConstruct *)theTitle;
- (void)setTitleWithString:(NSString *)str;

- (GDataTextConstruct *)summary;
- (void)setSummary:(GDataTextConstruct *)theSummary;
- (void)setSummaryWithString:(NSString *)str;

- (GDataEntryContent *)content;
- (void)setContent:(GDataEntryContent *)theContent;
- (void)setContentWithString:(NSString *)str;

- (GDataTextConstruct *)rightsString;
- (void)setRightsString:(GDataTextConstruct *)theRightsString;
- (void)setRightsStringWithString:(NSString *)str;

- (NSArray *)links;
- (void)setLinks:(NSArray *)links;
- (void)addLink:(GDataLink *)link;

- (NSArray *)authors;
- (void)setAuthors:(NSArray *)authors;
- (void)addAuthor:(GDataPerson *)authorElement;

- (NSArray *)contributors;
- (void)setContributors:(NSArray *)array;
- (void)addContributor:(GDataPerson *)obj;

- (NSArray *)categories;
- (void)setCategories:(NSArray *)categories;
- (void)addCategory:(GDataCategory *)category;
- (void)removeCategory:(GDataCategory *)category;

// File upload
//
// Either uploadData or uploadFileHandle should be set, but not both
- (NSData *)uploadData;
- (void)setUploadData:(NSData *)data;

- (NSFileHandle *)uploadFileHandle;
- (void)setUploadFileHandle:(NSFileHandle *)fileHandle;

// The location URL is used to restart upload of a file handle
- (NSURL *)uploadLocationURL;
- (void)setUploadLocationURL:(NSURL *)url;

- (NSString *)uploadMIMEType;
- (void)setUploadMIMEType:(NSString *)str;

// support for uploading media data without the XML from the GDataObject
- (BOOL)shouldUploadDataOnly;
- (void)setShouldUploadDataOnly:(BOOL)flag;

// http slug (filename) header when uploading
- (NSString *)uploadSlug;
- (void)setUploadSlug:(NSString *)str;

// extension for entries which may include deleted elements
- (BOOL)isDeleted;
- (void)setIsDeleted:(BOOL)isDeleted;

// extensions for Atom publishing control
- (GDataAtomPubControl *)atomPubControl;
- (void)setAtomPubControl:(GDataAtomPubControl *)obj;

// batch support
+ (NSDictionary *)batchNamespaces;

- (GDataBatchOperation *)batchOperation;
- (void)setBatchOperation:(GDataBatchOperation *)obj;

// the batch ID is an arbitrary string defined by clients, and present in the
// batch response feed to let the client match each entry's response to
// the entry
- (GDataBatchID *)batchID;
- (void)setBatchID:(GDataBatchID *)obj;
- (void)setBatchIDWithString:(NSString *)str;

- (GDataBatchStatus *)batchStatus;
- (void)setBatchStatus:(GDataBatchStatus *)obj;

- (GDataBatchInterrupted *)batchInterrupted;
- (void)setBatchInterrupted:(GDataBatchInterrupted *)obj;

// convenience accessors

- (NSArray *)categoriesWithScheme:(NSString *)scheme;

// most entries have a category element with scheme kGDataCategoryScheme
// that indicates the kind of entry
- (GDataCategory *)kindCategory;

- (NSArray *)linksWithRelAttributeValue:(NSString *)relValue;

- (GDataLink *)linkWithRelAttributeValue:(NSString *)relValue;
- (GDataLink *)linkWithRelAttributeValue:(NSString *)rel
                                    type:(NSString *)type;

- (GDataLink *)feedLink;
- (GDataLink *)editLink;
- (GDataLink *)editMediaLink;
- (GDataLink *)alternateLink;
- (GDataLink *)relatedLink;
- (GDataLink *)postLink;
- (GDataLink *)selfLink;
- (GDataLink *)HTMLLink;
- (GDataLink *)uploadEditLink;

- (BOOL)canEdit;

///////////////////////////////////////////////////////////////////////////////
//
//  Protected methods
//
//  All remaining methods are intended for use only by subclasses
//  of GDataEntryBase.
//

// subclasses call registerEntryClass to register their standardEntryKind
+ (void)registerEntryClass;

+ (Class)entryClassForCategoryWithScheme:(NSString *)scheme
                                    term:(NSString *)term;
+ (Class)entryClassForKindAttributeValue:(NSString *)kind;

// temporary bridge method
+ (void)registerEntryClass:(Class)theClass
     forCategoryWithScheme:(NSString *)scheme
                      term:(NSString *)term;


// subclasses override standardEntryKind to provide the term string for the
// kind attribute of their kind category element, if any
+ (NSString *)standardEntryKind;

@end
