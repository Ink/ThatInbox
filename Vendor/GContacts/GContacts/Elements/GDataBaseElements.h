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
// GDataBaseElements.h
//
// Elements used by the GDataEntryBase and GDataFeedBase classes
//

#import "GDataCategory.h"
#import "GDataPerson.h"
#import "GDataTextConstruct.h"
#import "GDataValueConstruct.h"
#import "GDataEntryContent.h"

// GData

@interface GDataResourceID : GDataValueElementConstruct <GDataExtension>
@end

// Atom

@interface GDataAtomID : GDataValueElementConstruct <GDataExtension>
@end

@interface GDataAtomPublishedDate : GDataValueElementConstruct <GDataExtension>
@end

@interface GDataAtomUpdatedDate : GDataValueElementConstruct <GDataExtension>
@end

@interface GDataAtomTitle : GDataTextConstruct <GDataExtension>
@end

@interface GDataAtomSubtitle : GDataTextConstruct <GDataExtension>
@end

@interface GDataAtomSummary : GDataTextConstruct <GDataExtension>
@end

@interface GDataAtomContent : GDataEntryContent <GDataExtension>
@end

@interface GDataAtomRights : GDataTextConstruct <GDataExtension>
@end

@interface GDataAtomAuthor : GDataPerson <GDataExtension>
@end

@interface GDataAtomContributor : GDataPerson <GDataExtension>
@end

@interface GDataAtomIcon : GDataValueElementConstruct <GDataExtension>
@end

@interface GDataAtomLogo : GDataValueElementConstruct <GDataExtension>
@end

// AtomPub

@interface GDataAtomPubEditedDate : GDataValueElementConstruct <GDataExtension>
@end

// OpenSearch 1.1, adopted for GData version 2

@interface GDataOpenSearchTotalResults : GDataValueElementConstruct <GDataExtension>
@end

@interface GDataOpenSearchStartIndex : GDataValueElementConstruct <GDataExtension>
@end

@interface GDataOpenSearchItemsPerPage : GDataValueElementConstruct <GDataExtension>
@end

// Attributes
@interface GDataETagAttribute : GDataAttribute <GDataExtension>
@end

@interface GDataFieldsAttribute : GDataAttribute <GDataExtension>
@end

@interface GDataKindAttribute : GDataAttribute <GDataExtension>
@end
