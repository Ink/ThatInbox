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
// GDataBaseElements.m
//
// Elements used by the GDataEntryBase and GDataFeedBase classes
//

#import "GDataBaseElements.h"

#pragma mark gd

@implementation GDataResourceID
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"resourceId"; }
@end

#pragma mark Atom

@implementation GDataAtomID
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"id"; }
@end

@implementation GDataAtomPublishedDate
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"published"; }
@end

@implementation GDataAtomUpdatedDate
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"updated"; }
@end

@implementation GDataAtomTitle
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"title"; }
@end

@implementation GDataAtomSubtitle
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"subtitle"; }
@end

@implementation GDataAtomSummary
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"summary"; }
@end

@implementation GDataAtomContent
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"content"; }
@end

@implementation GDataAtomRights
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"rights"; }
@end

@implementation GDataAtomAuthor
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"author"; }
@end

@implementation GDataAtomContributor
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"contributor"; }
@end

@implementation GDataAtomIcon
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"icon"; }
@end

@implementation GDataAtomLogo
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtom; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPrefix; }
+ (NSString *)extensionElementLocalName { return @"logo"; }
@end

#pragma mark AtomPub

// standard AtomPub namespace
@implementation GDataAtomPubEditedDate
+ (NSString *)extensionElementURI       { return kGDataNamespaceAtomPub; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceAtomPubPrefix; }
+ (NSString *)extensionElementLocalName { return @"edited"; }
@end

#pragma mark OpenSearch

// OpenSearch 1.1, adopted for GData version 2
@implementation GDataOpenSearchTotalResults
+ (NSString *)extensionElementURI       { return kGDataNamespaceOpenSearch; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceOpenSearchPrefix; }
+ (NSString *)extensionElementLocalName { return @"totalResults"; }
@end

@implementation GDataOpenSearchStartIndex
+ (NSString *)extensionElementURI       { return kGDataNamespaceOpenSearch; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceOpenSearchPrefix; }
+ (NSString *)extensionElementLocalName { return @"startIndex"; }
@end

@implementation GDataOpenSearchItemsPerPage
+ (NSString *)extensionElementURI       { return kGDataNamespaceOpenSearch; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceOpenSearchPrefix; }
+ (NSString *)extensionElementLocalName { return @"itemsPerPage"; }
@end

// Attributes

@implementation GDataETagAttribute
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"etag"; }
@end

@implementation GDataFieldsAttribute
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"fields"; }
@end

@implementation GDataKindAttribute
+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"kind"; }
@end
