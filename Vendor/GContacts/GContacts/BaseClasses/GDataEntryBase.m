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
// GDataEntryBase.m
//

#define GDATAENTRYBASE_DEFINE_GLOBALS 1

#import "GDataEntryBase.h"
#import "GDataBaseElements.h"
#import "GTMMIMEDocument.h"

@implementation GDataEntryBase

+ (NSString *)standardEntryKind {

  // overridden by entry subclasses
  //
  // Feeds and entries typically have a "kind" atom:category element
  // indicating their contents; see
  //    http://code.google.com/apis/gdata/elements.html#Introduction
  //
  // Subclasses may override this method with the "term" attribute string
  // for their kind category.  This is used in the plain -init method,
  // and from +registerEntryClass
  //

  return nil;
}

+ (NSString *)standardKindAttributeValue {

  // overridden by entry subclasses
  //
  // Feeds and entries in core v2.1 and later have a kind attribute rather than
  // kind categories
  //
  // Subclasses may override this method with the proper kind attribute string
  // used to identify this class
  //
  return nil;
}

+ (NSDictionary *)baseGDataNamespaces {
  NSDictionary *namespaces = [NSDictionary dictionaryWithObjectsAndKeys:
    kGDataNamespaceAtom, @"",
    kGDataNamespaceGData, kGDataNamespaceGDataPrefix,
    kGDataNamespaceAtomPub, kGDataNamespaceAtomPubPrefix,
    nil];
  return namespaces;
}

+ (id)entry {
  GDataEntryBase *entry = [self object];

  [entry setNamespaces:[GDataEntryBase baseGDataNamespaces]];
  return entry;
}

- (void)addExtensionDeclarations {

  [super addExtensionDeclarations];

  Class entryClass = [self class];

  [self addExtensionDeclarationForParentClass:entryClass
                                 childClasses:
   // GData extensions
   [GDataResourceID class],

   // Atom extensions
   [GDataAtomID class],
   [GDataAtomPublishedDate class],
   [GDataAtomUpdatedDate class],
   [GDataAtomTitle class],
   [GDataAtomSummary class],
   [GDataAtomContent class],
   [GDataAtomRights class],
   [GDataLink class],
   [GDataAtomAuthor class],
   [GDataAtomContributor class],
   [GDataCategory class],

   // deletion marking support
   [GDataDeleted class],

   // atom publishing control support
   [GDataAtomPubControl class],
   [GDataAtomPubEditedDate class],

   // batch support
   [GDataBatchOperation class], [GDataBatchID class],
   [GDataBatchStatus class], [GDataBatchInterrupted class],
   nil];

  [self addAttributeExtensionDeclarationForParentClass:entryClass
                                            childClass:[GDataETagAttribute class]];
  [self addAttributeExtensionDeclarationForParentClass:entryClass
                                            childClass:[GDataFieldsAttribute class]];
  [self addAttributeExtensionDeclarationForParentClass:entryClass
                                            childClass:[GDataKindAttribute class]];
}

- (id)init {
  self = [super init];
  if (self) {
    // if the subclass declares a kind, then add a category element or
    // a kind attribute
    NSString *categoryKind = [[self class] standardEntryKind];
    if (categoryKind) {
      GDataCategory *category;

      category = [GDataCategory categoryWithScheme:kGDataCategoryScheme
                                              term:categoryKind];
      [self addCategory:category];
    }

    NSString *attributeKind = [[self class] standardKindAttributeValue];
    if (attributeKind) {
      [self setKind:attributeKind];
    }
  }
  return self;
}

- (void)dealloc {
  [uploadData_ release];
  [uploadFileHandle_ release];
  [uploadLocationURL_ release];
  [uploadMIMEType_ release];
  [uploadSlug_ release];

  [super dealloc];
}

- (BOOL)isEqual:(GDataEntryBase *)other {
  if (self == other) return YES;
  if (![other isKindOfClass:[GDataEntryBase class]]) return NO;

  return [super isEqual:other]
    && AreEqualOrBothNil([self uploadData], [other uploadData])
    && AreEqualOrBothNil([self uploadMIMEType], [other uploadMIMEType])
    && AreEqualOrBothNil([self uploadSlug], [other uploadSlug])
    && AreBoolsEqual([self shouldUploadDataOnly], [other shouldUploadDataOnly]);
}

- (id)copyWithZone:(NSZone *)zone {
  GDataEntryBase* newEntry = [super copyWithZone:zone];

  [newEntry setUploadData:[self uploadData]];
  [newEntry setUploadFileHandle:[self uploadFileHandle]];
  [newEntry setUploadLocationURL:[self uploadLocationURL]];
  [newEntry setUploadMIMEType:[self uploadMIMEType]];
  [newEntry setUploadSlug:[self uploadSlug]];
  [newEntry setShouldUploadDataOnly:[self shouldUploadDataOnly]];

  return newEntry;
}

#if !GDATA_SIMPLE_DESCRIPTIONS

- (NSMutableArray *)itemsForDescription {

  // make a list of the interesting parts of links
  NSArray *linkNames = [GDataLink linkNamesFromLinks:[self links]];
  NSString *linksStr = [linkNames componentsJoinedByString:@","];

  struct GDataDescriptionRecord descRecs[] = {
    { @"v",                @"serviceVersion",           kGDataDescValueLabeled },
    { @"title",            @"title.stringValue",        kGDataDescValueLabeled },
    { @"summary",          @"summary.stringValue",      kGDataDescValueLabeled },
    { @"content",          @"content.stringValue",      kGDataDescValueLabeled },
    { @"contentSrc",       @"content.sourceURI",        kGDataDescValueLabeled },
    { @"etag",             @"ETag",                     kGDataDescValueLabeled },
    { @"kind",             @"kind",                     kGDataDescValueLabeled },
    { @"fields",           @"fieldSelection",           kGDataDescValueLabeled },
    { @"resourceID",       @"resourceID",               kGDataDescValueLabeled },
    { @"authors",          @"authors",                  kGDataDescArrayCount },
    { @"contributors",     @"contributors",             kGDataDescArrayCount },
    { @"categories",       @"categories",               kGDataDescArrayCount },
    { @"links",            linksStr,                    kGDataDescValueIsKeyPath },
    { @"edited",           @"editedDate.RFC3339String", kGDataDescValueLabeled },
    { @"id",               @"identifier",               kGDataDescValueLabeled },
    { @"app:control",      @"atomPubControl",           kGDataDescValueLabeled },
    { @"batchOp",          @"batchOperation.type",      kGDataDescValueLabeled },
    { @"batchID",          @"batchID.stringValue",      kGDataDescValueLabeled },
    { @"batchStatus",      @"batchStatus.code",         kGDataDescValueLabeled },
    { @"batchInterrupted", @"batchInterrupted",         kGDataDescValueLabeled },
    { @"MIMEType",         @"uploadMIMEType",           kGDataDescValueLabeled },
    { @"slug",             @"uploadSlug",               kGDataDescValueLabeled },
    { @"uploadDataOnly",   @"shouldUploadDataOnly",     kGDataDescBooleanPresent },
    { @"UploadData",       @"uploadData",               kGDataDescNonZeroLength },
    { @"deleted",          @"isDeleted",                kGDataDescBooleanPresent },
    { nil, nil, (GDataDescRecTypes)0 }
  };

  NSMutableArray *items = [super itemsForDescription];
  [self addDescriptionRecords:descRecs toItems:items];
  return items;
}
#endif

- (NSXMLElement *)XMLElement {
  NSXMLElement *element = [self XMLElementWithExtensionsAndDefaultName:@"entry"];
  return element;
}

#pragma mark -

- (NSDictionary *)contentHeaders {
  // This is also called from GDataServiceBase so it knows what headers to use
  // when uploading data chunked but without XML (so the body is empty.)
  return  [NSDictionary dictionaryWithObjectsAndKeys:
           [self uploadMIMEType], @"Content-Type",
           @"1.0", @"MIME-Version",
           [self uploadSlug], @"Slug", // slug may be nil
           nil];
}

- (BOOL)generateContentInputStream:(NSInputStream **)outInputStream
                            length:(unsigned long long *)outLength
                           headers:(NSDictionary **)outHeaders {

  // check if a subclass is providing data
  NSData *uploadData = [self uploadData];

  if (uploadData == nil) {
    // read from the file handle, if one was provided
    NSFileHandle *fileHandle = [self uploadFileHandle];
    if (fileHandle) {
      [fileHandle seekToFileOffset:0];
      uploadData = [fileHandle readDataToEndOfFile];
    }
  }

  NSString *uploadMIMEType = [self uploadMIMEType];
  NSString *slug = [self uploadSlug];

  BOOL hasUploadData = ([uploadData length] > 0);
  BOOL hasUploadMIMEType = ([uploadMIMEType length] > 0);
  GDATA_DEBUG_ASSERT(hasUploadData == hasUploadMIMEType,
                     @"upload data must be paired with MIME type");

  BOOL shouldUploadDataOnly = [self shouldUploadDataOnly];
  GDATA_DEBUG_ASSERT(!shouldUploadDataOnly
                     || (hasUploadData && hasUploadMIMEType),
                     @"missing data");

  if (shouldUploadDataOnly && hasUploadData && hasUploadMIMEType) {
    // we're not uploading the XML, so we don't need a multipart MIME document,
    // just a stream with the upload data
    *outInputStream = [NSInputStream inputStreamWithData:uploadData];
    *outLength = [uploadData length];
    *outHeaders = [self contentHeaders];
    return YES;
  }

  if (!hasUploadData || !hasUploadMIMEType) {
    // if there's no upload data, just fall back on the superclass since we
    // don't need a stream
    return [super generateContentInputStream:outInputStream
                                      length:outLength
                                     headers:outHeaders];
  }

  // make a MIME document with an XML part and a binary part
  NSDictionary* xmlHeader = [NSDictionary dictionaryWithObjectsAndKeys:
    @"application/atom+xml; charset=UTF-8", @"Content-Type", nil];

  NSString *xmlString = [[self XMLElement] XMLString];
  NSData *xmlBody = [xmlString dataUsingEncoding:NSUTF8StringEncoding];

  NSDictionary *binHeader = [NSDictionary dictionaryWithObjectsAndKeys:
    uploadMIMEType, @"Content-Type",
    @"binary", @"Content-Transfer-Encoding", nil];

  GTMMIMEDocument* doc = [GTMMIMEDocument MIMEDocument];

  [doc addPartWithHeaders:xmlHeader body:xmlBody];
  [doc addPartWithHeaders:binHeader body:uploadData];

  // generate the input stream, and make a header which includes the
  // boundary used between parts of the mime document
  NSString *partBoundary = nil; // typically this will be END_OF_PART

  [doc generateInputStream:outInputStream
                    length:outLength
                  boundary:&partBoundary];

  NSString *const streamTypeTemplate = @"multipart/related; boundary=\"%@\"";
  NSString *streamType = [NSString stringWithFormat:streamTypeTemplate,
    partBoundary];

  *outHeaders = [NSDictionary dictionaryWithObjectsAndKeys:
    streamType, @"Content-Type",
    @"1.0", @"MIME-Version",
    slug, @"Slug", // slug may be nil
    nil];

  return YES;
}

#pragma mark Dynamic object generation - Entry registration

//
// entry registration & lookup for dynamic object generation
//

static NSMutableDictionary *gEntryClassKindMap = nil;

+ (void)registerEntryClass {

  NSString *categoryKind = [self standardEntryKind];
  if (categoryKind) {
    [self registerClass:self
                  inMap:&gEntryClassKindMap
  forCategoryWithScheme:kGDataCategoryScheme
                   term:categoryKind];
  }

  NSString *attributeKind = [self standardKindAttributeValue];
  if (attributeKind) {
    [self registerClass:self
                  inMap:&gEntryClassKindMap
  forCategoryWithScheme:nil
                   term:attributeKind];
  }

  GDATA_DEBUG_ASSERT(attributeKind != nil || categoryKind != nil,
                     @"cannot register entry without a kind");
}

+ (void)registerEntryClass:(Class)theClass
     forCategoryWithScheme:(NSString *)scheme
                      term:(NSString *)term {

  // temporary bridge method - will be removed when subclasses all call
  // -registerEntryClass
  [self registerClass:theClass
                inMap:&gEntryClassKindMap
forCategoryWithScheme:scheme
                 term:term];
}

+ (Class)entryClassForCategoryWithScheme:(NSString *)scheme
                                    term:(NSString *)term {
  return [self classForCategoryWithScheme:scheme
                                     term:term
                                  fromMap:gEntryClassKindMap];
}

+ (Class)entryClassForKindAttributeValue:(NSString *)kind {
  return [self classForCategoryWithScheme:nil
                                     term:kind
                                  fromMap:gEntryClassKindMap];
}

#pragma mark Getters and Setters

- (NSString *)ETag {
  NSString *str = [self attributeValueForExtensionClass:[GDataETagAttribute class]];
  return str;
}

- (void)setETag:(NSString *)str {
  [self setAttributeValue:str forExtensionClass:[GDataETagAttribute class]];
}

- (NSString *)fieldSelection {
  NSString *str = [self attributeValueForExtensionClass:[GDataFieldsAttribute class]];
  return str;
}

- (void)setFieldSelection:(NSString *)str {
  [self setAttributeValue:str forExtensionClass:[GDataFieldsAttribute class]];
}

- (NSString *)kind {
  NSString *str = [self attributeValueForExtensionClass:[GDataKindAttribute class]];
  return str;
}

- (void)setKind:(NSString *)str {
  [self setAttributeValue:str forExtensionClass:[GDataKindAttribute class]];
}

- (NSString *)resourceID {
  GDataResourceID *obj = [self objectForExtensionClass:[GDataResourceID class]];
  return [obj stringValue];
}

- (void)setResourceID:(NSString *)str {
  GDataResourceID *obj = [GDataResourceID valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataResourceID class]];
}

- (NSString *)identifier {
  GDataAtomID *obj = [self objectForExtensionClass:[GDataAtomID class]];
  return [obj stringValue];
}

- (void)setIdentifier:(NSString *)str {
  GDataAtomID *obj = [GDataAtomID valueWithString:str];
  [self setObject:obj forExtensionClass:[GDataAtomID class]];
}

- (GDataDateTime *)publishedDate {
  GDataAtomPublishedDate *obj;

  obj = [self objectForExtensionClass:[GDataAtomPublishedDate class]];
  return [obj dateTimeValue];
}

- (void)setPublishedDate:(GDataDateTime *)dateTime {
  GDataAtomPublishedDate *obj;

  obj = [GDataAtomPublishedDate valueWithDateTime:dateTime];
  [self setObject:obj forExtensionClass:[GDataAtomPublishedDate class]];
}

- (GDataDateTime *)updatedDate {
  GDataAtomUpdatedDate *obj;

  obj = [self objectForExtensionClass:[GDataAtomUpdatedDate class]];
  return [obj dateTimeValue];
}

- (void)setUpdatedDate:(GDataDateTime *)dateTime {
  GDataAtomUpdatedDate *obj;

  obj = [GDataAtomUpdatedDate valueWithDateTime:dateTime];
  [self setObject:obj forExtensionClass:[GDataAtomUpdatedDate class]];
}

- (GDataDateTime *)editedDate {
  GDataValueElementConstruct *obj;

  obj = [self objectForExtensionClass:[GDataAtomPubEditedDate class]];
  return [obj dateTimeValue];
}

- (void)setEditedDate:(GDataDateTime *)dateTime {
  GDataValueElementConstruct *obj;

  obj = [GDataAtomPubEditedDate valueWithDateTime:dateTime];
  [self setObject:obj forExtensionClass:[GDataAtomPubEditedDate class]];
}

- (GDataTextConstruct *)title {
  GDataAtomTitle *obj = [self objectForExtensionClass:[GDataAtomTitle class]];
  return obj;
}

- (void)setTitle:(GDataTextConstruct *)obj {
  [self setObject:obj forExtensionClass:[GDataAtomTitle class]];
}

- (void)setTitleWithString:(NSString *)str {
  GDataAtomTitle *obj = [GDataAtomTitle textConstructWithString:str];
  [self setObject:obj forExtensionClass:[GDataAtomTitle class]];
}

- (GDataTextConstruct *)summary {
  GDataAtomSummary *obj = [self objectForExtensionClass:[GDataAtomSummary class]];
  return obj;
}

- (void)setSummary:(GDataTextConstruct *)obj {
  [self setObject:obj forExtensionClass:[GDataAtomSummary class]];
}

- (void)setSummaryWithString:(NSString *)str {
  GDataAtomSummary *obj = [GDataAtomSummary textConstructWithString:str];
  [self setObject:obj forExtensionClass:[GDataAtomSummary class]];
}

- (GDataEntryContent *)content {
  GDataAtomContent *obj;

  obj = [self objectForExtensionClass:[GDataAtomContent class]];
  return obj;
}

- (void)setContent:(GDataEntryContent *)obj {
  [self setObject:obj forExtensionClass:[GDataAtomContent class]];
}

- (void)setContentWithString:(NSString *)str {
  GDataAtomContent *obj = [GDataAtomContent contentWithString:str];
  [self setObject:obj forExtensionClass:[GDataAtomContent class]];
}

- (GDataTextConstruct *)rightsString {
  GDataTextConstruct *obj;

  obj = [self objectForExtensionClass:[GDataAtomRights class]];
  return obj;
}

- (void)setRightsString:(GDataTextConstruct *)obj {
  [self setObject:obj forExtensionClass:[GDataAtomRights class]];
}

- (void)setRightsStringWithString:(NSString *)str {
  GDataAtomRights *obj;

  obj = [GDataAtomRights textConstructWithString:str];
  [self setObject:obj forExtensionClass:[GDataAtomRights class]];
}

- (NSArray *)links {
  NSArray *array = [self objectsForExtensionClass:[GDataLink class]];
  return array;
}

- (void)setLinks:(NSArray *)array {
  [self setObjects:array forExtensionClass:[GDataLink class]];
}

- (void)addLink:(GDataLink *)obj {
  [self addObject:obj forExtensionClass:[GDataLink class]];
}

- (NSArray *)authors {
  NSArray *array = [self objectsForExtensionClass:[GDataAtomAuthor class]];
  return array;
}

- (void)setAuthors:(NSArray *)array {
  [self setObjects:array forExtensionClass:[GDataAtomAuthor class]];
}

- (void)addAuthor:(GDataPerson *)obj {
  [self addObject:obj forExtensionClass:[GDataAtomAuthor class]];
}

- (NSArray *)contributors {
  NSArray *array = [self objectsForExtensionClass:[GDataAtomContributor class]];
  return array;
}

- (void)setContributors:(NSArray *)array {
  [self setObjects:array forExtensionClass:[GDataAtomContributor class]];
}

- (void)addContributor:(GDataPerson *)obj {
  [self addObject:obj forExtensionClass:[GDataAtomContributor class]];
}

- (NSArray *)categories {
  NSArray *array = [self objectsForExtensionClass:[GDataCategory class]];
  return array;
}

- (void)setCategories:(NSArray *)array {
  [self setObjects:array forExtensionClass:[GDataCategory class]];
}

- (void)addCategory:(GDataCategory *)obj {
  [self addObject:obj forExtensionClass:[GDataCategory class]];
}

- (void)removeCategory:(GDataCategory *)obj {
  [self removeObject:obj forExtensionClass:[GDataCategory class]];
}

// File uploading

- (NSData *)uploadData {
  return uploadData_;
}

- (void)setUploadData:(NSData *)data {
  [uploadData_ autorelease];
  uploadData_ = [data retain];
}

- (NSFileHandle *)uploadFileHandle {
  return uploadFileHandle_;
}

- (void)setUploadFileHandle:(NSFileHandle *)data {
  [uploadFileHandle_ autorelease];
  uploadFileHandle_ = [data retain];
}

- (NSURL *)uploadLocationURL {
  return uploadLocationURL_;
}

- (void)setUploadLocationURL:(NSURL *)url {
  [uploadLocationURL_ autorelease];
  uploadLocationURL_ = [url retain];
}

- (NSString *)uploadMIMEType {
  return uploadMIMEType_;
}

- (void)setUploadMIMEType:(NSString *)str {
  [uploadMIMEType_ autorelease];
  uploadMIMEType_ = [str copy];
}

- (NSString *)uploadSlug {
  return uploadSlug_;
}

- (void)setUploadSlug:(NSString *)str {
  [uploadSlug_ autorelease];

  // encode per http://bitworking.org/projects/atom/rfc5023.html#rfc.section.9.7
  NSString *encoded = [GDataUtilities stringByPercentEncodingUTF8ForString:str];
  uploadSlug_ = [encoded copy];
}

- (BOOL)shouldUploadDataOnly {
  return shouldUploadDataOnly_;
}

- (void)setShouldUploadDataOnly:(BOOL)flag {
  shouldUploadDataOnly_ = flag;
}

// extension for deletion marking
- (BOOL)isDeleted {
  GDataDeleted *deleted = [self objectForExtensionClass:[GDataDeleted class]];
  return (deleted != nil);
}

- (void)setIsDeleted:(BOOL)isDeleted {
  if (isDeleted) {
    // set the extension
    [self setObject:[GDataDeleted deleted] forExtensionClass:[GDataDeleted class]];
  } else {
    // remove the extension
    [self setObject:nil forExtensionClass:[GDataDeleted class]];
  }
}

// extensions for Atom publishing control

- (GDataAtomPubControl *)atomPubControl {
  return [self objectForExtensionClass:[GDataAtomPubControl class]];
}

- (void)setAtomPubControl:(GDataAtomPubControl *)obj {
  [self setObject:obj forExtensionClass:[GDataAtomPubControl class]];
}

// extensions for batch support

- (GDataBatchOperation *)batchOperation {
  return (GDataBatchOperation *) [self objectForExtensionClass:[GDataBatchOperation class]];
}

- (void)setBatchOperation:(GDataBatchOperation *)obj {
  [self setObject:obj forExtensionClass:[GDataBatchOperation class]];
}

- (GDataBatchID *)batchID {
  return (GDataBatchID *) [self objectForExtensionClass:[GDataBatchID class]];
}

- (void)setBatchID:(GDataBatchID *)obj {
  [self setObject:obj forExtensionClass:[GDataBatchID class]];
}

- (void)setBatchIDWithString:(NSString *)str {
  GDataBatchID *obj = [GDataBatchID batchIDWithString:str];
  [self setBatchID:obj];
}

- (GDataBatchStatus *)batchStatus {
  return (GDataBatchStatus *) [self objectForExtensionClass:[GDataBatchStatus class]];
}

- (void)setBatchStatus:(GDataBatchStatus *)obj {
  [self setObject:obj forExtensionClass:[GDataBatchStatus class]];
}

- (GDataBatchInterrupted *)batchInterrupted {
  return (GDataBatchInterrupted *) [self objectForExtensionClass:[GDataBatchInterrupted class]];
}

- (void)setBatchInterrupted:(GDataBatchInterrupted *)obj {
  [self setObject:obj forExtensionClass:[GDataBatchInterrupted class]];
}

+ (NSDictionary *)batchNamespaces {
  NSDictionary *namespaces = [NSDictionary dictionaryWithObjectsAndKeys:
    kGDataNamespaceBatch, kGDataNamespaceBatchPrefix, nil];
  return namespaces;
}

#pragma mark -

- (NSArray *)categoriesWithScheme:(NSString *)scheme {
  NSArray *array = [GDataCategory categoriesWithScheme:scheme
                                        fromCategories:[self categories]];
  return array;
}

- (GDataCategory *)kindCategory {
  GDataCategory *cat = [GDataUtilities firstObjectFromArray:[self categories]
                                                  withValue:kGDataCategoryScheme
                                                 forKeyPath:@"scheme"];
  return cat;
}

- (NSArray *)linksWithRelAttributeValue:(NSString *)relValue {

  NSArray *array = [GDataUtilities objectsFromArray:[self links]
                                          withValue:relValue
                                         forKeyPath:@"rel"];
  return array;
}

- (GDataLink *)linkWithRelAttributeValue:(NSString *)rel {

  return [GDataLink linkWithRel:rel
                           type:nil
                      fromLinks:[self links]];
}

- (GDataLink *)linkWithRelAttributeValue:(NSString *)rel
                                    type:(NSString *)type {
  return [GDataLink linkWithRel:rel
                           type:type
                      fromLinks:[self links]];
}

- (GDataLink *)feedLink {
  return [self linkWithRelAttributeValue:kGDataLinkRelFeed];
}

- (GDataLink *)editLink {
  return [self linkWithRelAttributeValue:@"edit"];
}

- (GDataLink *)editMediaLink {
  return [self linkWithRelAttributeValue:@"edit-media"];
}

- (GDataLink *)alternateLink {
  return [self linkWithRelAttributeValue:@"alternate"];
}

- (GDataLink *)relatedLink {
  return [self linkWithRelAttributeValue:@"related"];
}

- (GDataLink *)postLink {
  return [self linkWithRelAttributeValue:kGDataLinkRelPost];
}

- (GDataLink *)selfLink {
  return [self linkWithRelAttributeValue:@"self"];
}

- (GDataLink *)HTMLLink {
  return [self linkWithRelAttributeValue:@"alternate"
                                    type:kGDataLinkTypeHTML];
}

- (GDataLink *)uploadEditLink {
  return [self linkWithRelAttributeValue:kGDataLinkRelResumableEdit];
}

- (BOOL)canEdit {
  return ([self editLink] != nil);
}
@end
