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
//  GDataFeedBase.h
//

#import "GDataObject.h"

#import "GDataGenerator.h"
#import "GDataTextConstruct.h"
#import "GDataLink.h"
#import "GDataEntryBase.h"
#import "GDataCategory.h"
#import "GDataPerson.h"
#import "GDataBatchOperation.h"
#import "GDataAtomPubControl.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATAFEEDBASE_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

// this constant, returned by a subclass implementation of -classForEntries,
// specifies that a feed's entry class should be determined by inspecting
// the XML for a "kind" category and looking at the registered entry classes
// for an appropriate match
_EXTERN Class const kUseRegisteredEntryClass _INITIALIZE_AS(nil);

@interface GDataFeedBase : GDataObject <NSFastEnumeration> {

  // generator is parsed manually to avoid comparison along with other
  // extensions
  GDataGenerator *generator_;

  NSMutableArray *entries_;
}

+ (id)feedWithXMLData:(NSData *)data;
- (id)initWithData:(NSData *)data;
- (id)initWithData:(NSData *)data
    serviceVersion:(NSString *)serviceVersion
shouldIgnoreUnknowns:(BOOL)shouldIgnoreUnknowns;

// subclasses override initFeed to set up their ivars
- (void)initFeedWithXMLElement:(NSXMLElement *)element;

// subclass may override this to specify an entry class or
// to return kUseRegisteredEntryClass
- (Class)classForEntries;

// subclasses may override this to specify a "generic" class for
// the feed's entries, if not GDataEntryBase, mainly for when there
// is no registered entry class found
+ (Class)defaultClassForEntries;

- (BOOL)canPost;

// getters and setters
- (GDataGenerator *)generator;
- (void)setGenerator:(GDataGenerator *)gen;

- (NSString *)identifier;
- (void)setIdentifier:(NSString *)theString;

- (GDataTextConstruct *)title;
- (void)setTitle:(GDataTextConstruct *)theTitle;
- (void)setTitleWithString:(NSString *)str;

- (GDataTextConstruct *)subtitle;
- (void)setSubtitle:(GDataTextConstruct *)theSubtitle;
- (void)setSubtitleWithString:(NSString *)str;

- (GDataTextConstruct *)rights;
- (void)setRights:(GDataTextConstruct *)theRights;
- (void)setRightsWithString:(NSString *)str;

- (NSString *)icon;
- (void)setIcon:(NSString *)theString;

- (NSString *)logo;
- (void)setLogo:(NSString *)theString;

- (NSArray *)links;
- (void)setLinks:(NSArray *)links;
- (void)addLink:(GDataLink *)obj;
- (void)removeLink:(GDataLink *)obj;

- (NSArray *)authors;
- (void)setAuthors:(NSArray *)authors;
- (void)addAuthor:(GDataPerson *)obj;

- (NSArray *)contributors;
- (void)setContributors:(NSArray *)array;
- (void)addContributor:(GDataPerson *)obj;

- (NSArray *)categories;
- (void)setCategories:(NSArray *)categories;
- (void)addCategory:(GDataCategory *)category;
- (void)removeCategory:(GDataCategory *)category;

- (GDataDateTime *)updatedDate;
- (void)setUpdatedDate:(GDataDateTime *)theDate;

- (NSString *)ETag;
- (void)setETag:(NSString *)str;

- (NSString *)fieldSelection;
- (void)setFieldSelection:(NSString *)str;

- (NSString *)kind;
- (void)setKind:(NSString *)str;

- (NSString *)resourceID;
- (void)setResourceID:(NSString *)str;

- (NSArray *)entries;

// setEntries: and addEntry: assert if the entries have other parents
// already set; use setEntriesWithEntries: and addEntryWithEntry: to copy
// entries that have other parents
- (void)setEntries:(NSArray *)entries;
- (void)addEntry:(GDataEntryBase *)obj;

- (void)setEntriesWithEntries:(NSArray *)entries;
- (void)addEntryWithEntry:(GDataEntryBase *)obj;

- (NSNumber *)totalResults;
- (void)setTotalResults:(NSNumber *)theString;

- (NSNumber *)startIndex;
- (void)setStartIndex:(NSNumber *)theString;

- (NSNumber *)itemsPerPage;
- (void)setItemsPerPage:(NSNumber *)theString;

// Atom publishing control
- (GDataAtomPubControl *)atomPubControl;
- (void)setAtomPubControl:(GDataAtomPubControl *)obj;

// Batch support
- (GDataBatchOperation *)batchOperation;
- (void)setBatchOperation:(GDataBatchOperation *)obj;

// convenience routines

- (GDataLink *)linkWithRelAttributeValue:(NSString *)rel;

- (GDataLink *)feedLink;
- (GDataLink *)alternateLink;
- (GDataLink *)relatedLink;
- (GDataLink *)postLink;
- (GDataLink *)uploadLink; // "resumable-create" link
- (GDataLink *)batchLink;
- (GDataLink *)selfLink;
- (GDataLink *)nextLink;
- (GDataLink *)previousLink;

// return the first entry, or nil if none
- (id)firstEntry;

// return the specified entry, or nil if index is out of bounds
// (does not throw an exception if index exceeds the size of the entry array)
- (id)entryAtIndex:(NSUInteger)index;

// find the entry with the given identifier, or nil if none found
- (id)entryForIdentifier:(NSString *)str;

// find all entries with a kind category for the specified term
//
// this is useful for feeds which contain various kinds of entries with
// distinct entry kind categories
- (NSArray *)entriesWithCategoryKind:(NSString *)term;

///////////////////////////////////////////////////////////////////////////////
//
//  Protected methods
//
//  All remaining methods are intended for use only by subclasses
//  of GDataFeedBase.
//

// subclasses call registerEntryClass to register their standardFeedKind
+ (void)registerFeedClass;

+ (Class)feedClassForCategoryWithScheme:(NSString *)scheme
                                   term:(NSString *)term;
+ (Class)feedClassForKindAttributeValue:(NSString *)kind;

// temporary bridge method
+ (void)registerFeedClass:(Class)theClass
    forCategoryWithScheme:(NSString *)scheme
                     term:(NSString *)term;

// subclasses override standardFeedKind to provide the term string for the
// term attribute of their "kind" category element, if any
+ (NSString *)standardFeedKind;

// subclasses override standardKindAttributeValue to provide the string for the
// kind attribute identifying their class (for core protocol v2.1 and later)
+ (NSString *)standardKindAttributeValue;

@end
