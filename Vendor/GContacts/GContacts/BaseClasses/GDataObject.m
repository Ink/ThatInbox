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
//  GDataObject.m
//

#define GDATAOBJECT_DEFINE_GLOBALS 1

#import "GDataObject.h"
#import "GDataDateTime.h"

// for automatic-determination of feed and entry class types
#import "GDataFeedBase.h"
#import "GDataEntryBase.h"
#import "GDataCategory.h"

static inline NSMutableDictionary *GDataCreateStaticDictionary(void) {
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
#if !GDATA_IPHONE
  Class cls = NSClassFromString(@"NSGarbageCollector");
  if (cls) {
    id collector = [cls performSelector:@selector(defaultCollector)];
    [collector performSelector:@selector(disableCollectorForPointer:)
                    withObject:dict];
  }
#endif
  return dict;
}

// in a cache of attribute declarations, this marker indicates that the class
// also declared that it wants child text parsed as the content value or child
// xml held as xml element objects
//
// these start with a space to avoid colliding with any real attribute name
static NSString* const kContentValueDeclarationMarker = @" __content";
static NSString* const kChildXMLDeclarationMarker = @" __childXML";

// Elements may call -addExtensionDeclarationForParentClass:childClass: and
// addAttributeExtensionDeclarationForParentClass: to declare extensions to be
// parsed; the declaration applies in the element and all children of the element.
@interface GDataExtensionDeclaration : NSObject {
  Class parentClass_;
  Class childClass_;
  BOOL isAttribute_;
}
- (id)initWithParentClass:(Class)parentClass childClass:(Class)childClass isAttribute:(BOOL)attrFlag;
- (Class)parentClass;
- (Class)childClass;
- (BOOL)isAttribute;
@end

@interface GDataObject (PrivateMethods)

// array of local attribute names to be automatically parsed and
// generated
- (void)setAttributeDeclarationsCache:(NSDictionary *)decls;
- (NSMutableDictionary *)attributeDeclarationsCache;

// array of attribute declarations for the current class, from the cache
- (void)setAttributeDeclarations:(NSArray *)array;
- (NSMutableArray *)attributeDeclarations;

- (void)parseAttributesForElement:(NSXMLElement *)element;
- (void)addAttributesToElement:(NSXMLElement *)element;

// routines for comparing attributes
- (BOOL)hasAttributesEqualToAttributesOf:(GDataObject *)other;
- (NSArray *)attributesIgnoredForEquality;

// element string content
- (void)parseContentValueForElement:(NSXMLElement *)element;
- (void)addContentValueToElement:(NSXMLElement *)element;

- (BOOL)hasContentValueEqualToContentValueOf:(GDataObject *)other;

// XML values content (kept unparsed)
- (void)keepChildXMLElementsForElement:(NSXMLElement *)element;
- (void)addChildXMLElementsToElement:(NSXMLElement *)element;

- (BOOL)hasChildXMLElementsEqualToChildXMLElementsOf:(GDataObject *)other;

// dictionary of all extensions actually found in the XML element
- (void)setExtensions:(NSDictionary *)extensions;
- (NSDictionary *)extensions;

// cache of arrays of extensions that may be found in this class and in
// subclasses of this class.
- (void)setExtensionDeclarationsCache:(NSDictionary *)decls;
- (NSMutableDictionary *)extensionDeclarationsCache;

- (NSMutableArray *)extensionDeclarationsForParentClass:(Class)parentClass;

- (void)addExtensionDeclarationForParentClass:(Class)parentClass
                                   childClass:(Class)childClass
                                  isAttribute:(BOOL)isAttribute;

- (void)addUnknownChildNodesForElement:(NSXMLElement *)element;

- (void)parseExtensionsForElement:(NSXMLElement *)element;

- (void)handleParsedElement:(NSXMLNode *)element;
- (void)handleParsedElements:(NSArray *)array;

- (NSString *)qualifiedNameForExtensionClass:(Class)theClass;

+ (Class)classForCategoryWithScheme:(NSString *)scheme
                               term:(NSString *)term
                            fromMap:(NSDictionary *)map;
@end

@implementation GDataObject

// The qualified name map avoids the need to regenerate qualified
// element names (foo:bar) repeatedly
static NSMutableDictionary *gQualifiedNameMap = nil;

+ (void)load {
  // Initialize gQualifiedNameMap early so we can @synchronize on accesses
  // to it
  gQualifiedNameMap = GDataCreateStaticDictionary();
}

+ (id)object {
  return [[[self alloc] init] autorelease];
}

- (id)init {
  self = [super init];
  if (self) {
    // there is no parent
    extensionDeclarationsCache_ = [[NSMutableDictionary alloc] init];

    attributeDeclarationsCache_ = [[NSMutableDictionary alloc] init];

    [self addParseDeclarations];
  }
  return self;
}

// intended mainly for testing, initWithServiceVersion allows the service
// version to be set prior to declaring extensions; this is useful
// for overriding the default service version for the class when
// manually allocating a copy of the object
- (id)initWithServiceVersion:(NSString *)serviceVersion {
  [self setServiceVersion:serviceVersion];
  return [self init];
}

// this init routine is only used when passing in a top-level surrogates
// dictionary
- (id)initWithXMLElement:(NSXMLElement *)element
                  parent:(GDataObject *)parent
          serviceVersion:(NSString *)serviceVersion
              surrogates:(NSDictionary *)surrogates
    shouldIgnoreUnknowns:(BOOL)shouldIgnoreUnknowns {

  [self setServiceVersion:serviceVersion];

  [self setSurrogates:surrogates];

  [self setShouldIgnoreUnknowns:shouldIgnoreUnknowns];

  id obj = [self initWithXMLElement:element
                             parent:parent];
  return obj;
}

// subclasses will typically override initWithXMLElement:parent:
// and do their own parsing after this method returns
- (id)initWithXMLElement:(NSXMLElement *)element
                  parent:(GDataObject *)parent {
  self = [super init];
  if (self) {
    [self setParent:parent];

    if (parent != nil) {
      // top-level objects (feeds and entries) have nil parents, and
      // have their service version set previously in
      // initWithXMLElement:parent:serviceVersion:surrogates:; child
      // objects have their service version set here
      [self setServiceVersion:[parent serviceVersion]];

      // feeds may specify that contained entries and their child elements
      // should ignore any unparsed XML
      [self setShouldIgnoreUnknowns:[parent shouldIgnoreUnknowns]];

      // get the parent's declaration caches, and temporarily hang on to them
      // in our ivar to avoid the need to get them recursively from the topmost
      // parent
      //
      // We'll release these below, so that only the topmost parent retains
      // them. The topmost parent retains them in case some subclass code still
      // wants to do parsing after we return.
      extensionDeclarationsCache_ = [[parent extensionDeclarationsCache] retain];
      GDATA_DEBUG_ASSERT(extensionDeclarationsCache_ != nil, @"missing extn decl");

      attributeDeclarationsCache_ = [[parent attributeDeclarationsCache] retain];
      GDATA_DEBUG_ASSERT(extensionDeclarationsCache_ != nil, @"missing attr decl");

    } else {
      // parent is nil, so this is the topmost parent
      extensionDeclarationsCache_ = [[NSMutableDictionary alloc] init];

      attributeDeclarationsCache_ = [[NSMutableDictionary alloc] init];
    }

    [self setNamespaces:[[self class] dictionaryForElementNamespaces:element]];
    [self addUnknownChildNodesForElement:element];

    // if we've not previously cached declarations for this class,
    // add the declarations now
    Class currClass = [self class];
    NSDictionary *prevExtnDecls = [extensionDeclarationsCache_ objectForKey:currClass];
    if (prevExtnDecls == nil) {
      [self addExtensionDeclarations];
    }

    NSMutableArray *prevAttrDecls = [attributeDeclarationsCache_ objectForKey:currClass];
    if (prevAttrDecls == nil) {
      [self addParseDeclarations];
      // if any parse declarations are added, attributeDeclarations_ will be set
      // to the cached copy of this object's attribute decls
    } else {
      GDATA_DEBUG_ASSERT(attributeDeclarations_ == nil, @"attrDecls previously set");
      attributeDeclarations_ = [prevAttrDecls retain];
    }

    [self parseExtensionsForElement:element];
    [self parseAttributesForElement:element];
    [self parseContentValueForElement:element];
    [self keepChildXMLElementsForElement:element];
    [self setElementName:[element name]];

    if (parent != nil) {
      // rather than keep a reference to the cache of declarations in the
      // parent, set our pointer to nil; if a subclass continues to parse, the
      // getter will obtain them by calling into the parent.  This lets callers
      // free up the extensionDeclarations_ when parsing is done by just
      // freeing them in the topmost parent with clearExtensionDeclarationsCache
      [extensionDeclarationsCache_ release];
      extensionDeclarationsCache_ = nil;

      [attributeDeclarationsCache_ release];
      attributeDeclarationsCache_ = nil;
    }

#if GDATA_USES_LIBXML
    if (!shouldIgnoreUnknowns_) {
      // retain the element so that pointers to internal nodes remain valid
      [self setProperty:element forKey:kGDataXMLElementPropertyKey];
    }
#endif
  }
  return self;
}

- (BOOL)isEqual:(GDataObject *)other {
  if (self == other) return YES;
  if (![other isKindOfClass:[self class]]) return NO;

  // We used to compare the local names of the objects with
  // NSXMLNode's localNameForName: on each object's elementName, but that
  // prevents us from comparing the contents of a manually-constructed object
  // (which lacks a specific local name) with one found in an actual XML feed.

#if GDATA_USES_LIBXML
  // libxml adds namespaces when copying elements, so we can't rely
  // on those when comparing nodes
  return AreEqualOrBothNil([self extensions], [other extensions])
    && [self hasAttributesEqualToAttributesOf:other]
    && [self hasContentValueEqualToContentValueOf:other]
    && [self hasChildXMLElementsEqualToChildXMLElementsOf:other];
#else
  return AreEqualOrBothNil([self extensions], [other extensions])
    && [self hasAttributesEqualToAttributesOf:other]
    && [self hasContentValueEqualToContentValueOf:other]
    && [self hasChildXMLElementsEqualToChildXMLElementsOf:other]
    && AreEqualOrBothNil([self namespaces], [other namespaces]);
#endif

  // What we're not comparing here:
  //   parent object pointers
  //   extension declarations
  //   unknown attributes & children
  //   local element names
  //   service version
  //   userData
}

// By definition, for two objects to potentially be considered equal,
// they must have the same hash value.  The hash is mostly ignored,
// but removeObjectsInArray: in Leopard does seem to check the hash,
// and NSObject's default hash method just returns the instance pointer.
// We'll define hash here for all of our GDataObjects.
- (NSUInteger)hash {
  return (NSUInteger) (void *) [GDataObject class];
}

- (id)copyWithZone:(NSZone *)zone {
  GDataObject* newObject = [[[self class] allocWithZone:zone] init];
  [newObject setElementName:[self elementName]];
  [newObject setParent:nil];
  [newObject setServiceVersion:[self serviceVersion]];

  NSDictionary *namespaces =
    [GDataUtilities mutableDictionaryWithCopiesOfObjectsInDictionary:[self namespaces]];
  [newObject setNamespaces:namespaces];

  NSDictionary *extensions =
    [GDataUtilities mutableDictionaryWithCopiesOfArraysInDictionary:[self extensions]];
  [newObject setExtensions:extensions];

  NSDictionary *attributes =
    [GDataUtilities mutableDictionaryWithCopiesOfObjectsInDictionary:[self attributes]];
  [newObject setAttributes:attributes];

  [newObject setAttributeDeclarations:[self attributeDeclarations]];
  // we copy the attribute declarations, which are retained by this object,
  // but we do not copy not the caches of extension or attribute declarations,
  // as those will be invalid once the top parent is released

  // a marker in the attributes cache indicates the content value and
  // and child XML declaration settings
  if ([self hasDeclaredContentValue]) {
    [newObject setContentStringValue:[self contentStringValue]];
  }

  if ([self hasDeclaredChildXMLElements]) {
    NSArray *childElements = [self childXMLElements];
    NSArray *arr = [GDataUtilities arrayWithCopiesOfObjectsInArray:childElements];
    [newObject setChildXMLElements:arr];
  }

  BOOL shouldIgnoreUnknowns = [self shouldIgnoreUnknowns];
  [newObject setShouldIgnoreUnknowns:shouldIgnoreUnknowns];

  if (!shouldIgnoreUnknowns) {
    NSArray *unknownChildren =
      [GDataUtilities mutableArrayWithCopiesOfObjectsInArray:[self unknownChildren]];
    [newObject setUnknownChildren:unknownChildren];

    NSArray *unknownAttributes =
      [GDataUtilities mutableArrayWithCopiesOfObjectsInArray:[self unknownAttributes]];
    [newObject setUnknownAttributes:unknownAttributes];
  }

  return newObject;

  // What we're not copying:
  //   parent object pointer
  //   surrogates
  //   userData
  //   userProperties
}

- (void)dealloc {
  [elementName_ release];
  [namespaces_ release];
  [extensionDeclarationsCache_ release];
  [attributeDeclarationsCache_ release];
  [attributeDeclarations_ release];
  [extensions_ release];
  [attributes_ release];
  [contentValue_ release];
  [childXMLElements_ release];
  [unknownChildren_ release];
  [unknownAttributes_ release];
  [surrogates_ release];
  [serviceVersion_ release];
  [coreProtocolVersion_ release];
  [userData_ release];
  [userProperties_ release];
  [super dealloc];
}

// XMLElement must be implemented by subclasses
- (NSXMLElement *)XMLElement {
  // subclass should override if they have custom elements or attributes
  NSXMLElement *element = [self XMLElementWithExtensionsAndDefaultName:nil];
  return element;
}

- (NSXMLDocument *)XMLDocument {
  NSXMLElement *element = [self XMLElement];
  NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithRootElement:(id)element] autorelease];
  [doc setVersion:@"1.0"];
  [doc setCharacterEncoding:@"UTF-8"];
  return doc;
}

- (BOOL)generateContentInputStream:(NSInputStream **)outInputStream
                            length:(unsigned long long *)outLength
                           headers:(NSDictionary **)outHeaders {
  // subclasses may return a data stream representing this object
  // for uploading
  return NO;
}

- (NSString *)uploadMIMEType {
  // subclasses may return the type of data to be uploaded
  return nil;
}

- (NSData *)uploadData {
  // subclasses may return data to be uploaded along with the object
  return nil;
}

- (NSFileHandle *)uploadFileHandle {
  // subclasses may return a file handle to be uploaded along with the object
  return nil;
}

- (NSURL *)uploadLocationURL {
  // subclasses may return a resumable upload location URL for restarting
  // uploads
  return nil;
}

- (BOOL)shouldUploadDataOnly {
  return NO;
}

#pragma mark -

- (void)setElementName:(NSString *)name {
  [elementName_ release];
  elementName_ = [name copy];
}

- (NSString *)elementName {
  return elementName_;
}

- (void)setNamespaces:(NSDictionary *)dict {
  [namespaces_ release];
  namespaces_ = [dict mutableCopy];
}

- (void)addNamespaces:(NSDictionary *)dict {
  if (namespaces_ == nil) {
    namespaces_ = [[NSMutableDictionary alloc] init];
  }
  [namespaces_ addEntriesFromDictionary:dict];
}

- (NSDictionary *)namespaces {
  return namespaces_;
}

- (NSDictionary *)completeNamespaces {
  // return a dictionary containing all namespaces
  // in this object and its parent objects
  NSDictionary *parentNamespaces = [parent_ completeNamespaces];
  NSDictionary *ownNamespaces = namespaces_;

  if (ownNamespaces == nil) return parentNamespaces;
  if (parentNamespaces == nil) return ownNamespaces;

  // combine them, replacing parent-defined prefixes with own ones
  NSMutableDictionary *mutableDict;

  mutableDict = [NSMutableDictionary dictionaryWithDictionary:parentNamespaces];
  [mutableDict addEntriesFromDictionary:ownNamespaces];
  return mutableDict;
}

- (void)pruneInheritedNamespaces {

  if (parent_ == nil || [namespaces_ count] == 0) return;

  // if a prefix is explicitly defined the same for the parent as it is locally,
  // remove it, since we can rely on the parent's definition
  NSMutableDictionary *prunedNamespaces
    = [NSMutableDictionary dictionaryWithDictionary:namespaces_];

  NSDictionary *parentNamespaces = [parent_ completeNamespaces];

  for (NSString *prefix in namespaces_) {

    NSString *ownURI = [namespaces_ objectForKey:prefix];
    NSString *parentURI = [parentNamespaces objectForKey:prefix];

    if (AreEqualOrBothNil(ownURI, parentURI)) {
      [prunedNamespaces removeObjectForKey:prefix];
    }
  }

  [self setNamespaces:prunedNamespaces];
}

- (void)setParent:(GDataObject *)obj {
  parent_ = obj; // parent_ is a weak (not retained) reference
}

- (GDataObject *)parent {
  return parent_;
}

- (void)setAttributeDeclarationsCache:(NSDictionary *)cache {
  [attributeDeclarationsCache_ autorelease];
  attributeDeclarationsCache_ = [cache mutableCopy];
}

- (NSMutableDictionary *)attributeDeclarationsCache {
  // warning: rely on this only during parsing; it will not be safe if the
  //          top parent is no longer allocated
  if (attributeDeclarationsCache_) {
    return attributeDeclarationsCache_;
  }
  return [[self parent] attributeDeclarationsCache];
}

- (void)setAttributeDeclarations:(NSArray *)array {
  [attributeDeclarations_ autorelease];
  attributeDeclarations_ = [array mutableCopy];
}

- (NSMutableArray *)attributeDeclarations {
  return attributeDeclarations_;
}

- (void)setAttributes:(NSDictionary *)dict {
  [attributes_ autorelease];
  attributes_ = [dict mutableCopy];
}

- (NSDictionary *)attributes {
  return attributes_;
}

- (void)setExtensions:(NSDictionary *)extensions {
  [extensions_ autorelease];
  extensions_ = [extensions mutableCopy];
}

- (NSDictionary *)extensions {
  return extensions_;
}

- (void)setExtensionDeclarationsCache:(NSDictionary *)decls {
  [extensionDeclarationsCache_ autorelease];
  extensionDeclarationsCache_ = [decls mutableCopy];
}

- (NSMutableDictionary *)extensionDeclarationsCache {
  // warning: rely on this only during parsing; it will not be safe if the
  //          top parent is no longer allocated
  if (extensionDeclarationsCache_) {
    return extensionDeclarationsCache_;
  }

  return [[self parent] extensionDeclarationsCache];
}

- (void)clearExtensionDeclarationsCache {
  // allows external classes to free up the declarations
  [self setExtensionDeclarationsCache:nil];
}

- (void)setUnknownChildren:(NSArray *)arr {
  [unknownChildren_ autorelease];
  unknownChildren_ = [arr mutableCopy];
}

- (NSArray *)unknownChildren {
  return unknownChildren_;
}

- (void)setUnknownAttributes:(NSArray *)arr {
  [unknownAttributes_ autorelease];
  unknownAttributes_ = [arr mutableCopy];
}

- (NSArray *)unknownAttributes {
  return unknownAttributes_;
}

- (void)setShouldIgnoreUnknowns:(BOOL)flag {
  shouldIgnoreUnknowns_ = flag;
}

- (BOOL)shouldIgnoreUnknowns {
  return shouldIgnoreUnknowns_;
}

- (void)setSurrogates:(NSDictionary *)surrogates {
  [surrogates_ autorelease];
  surrogates_ = [surrogates retain];
}

- (NSDictionary *)surrogates {
  return surrogates_;
}

+ (NSString *)defaultServiceVersion {
  return nil;
}

- (void)setServiceVersion:(NSString *)str {
  if (!AreEqualOrBothNil(str, serviceVersion_)) {
    // reset the core protocol version, since it's based on the service version
    [self setCoreProtocolVersion:nil];

    [serviceVersion_ autorelease];
    serviceVersion_ = [str copy];
  }
}

- (NSString *)serviceVersion {
  if (serviceVersion_ != nil) {
    return serviceVersion_;
  }

  NSString *str = [[self class] defaultServiceVersion];
  return str;
}

- (BOOL)isServiceVersionAtLeast:(NSString *)otherVersion {
  NSString *serviceVersion = [self serviceVersion];
  NSComparisonResult result = [GDataUtilities compareVersion:serviceVersion
                                                   toVersion:otherVersion];
  return (result != NSOrderedAscending);
}

- (BOOL)isServiceVersionAtMost:(NSString *)otherVersion {
  NSString *serviceVersion = [self serviceVersion];
  NSComparisonResult result = [GDataUtilities compareVersion:serviceVersion
                                                   toVersion:otherVersion];
  return (result != NSOrderedDescending);
}

- (void)setCoreProtocolVersion:(NSString *)str {
  [coreProtocolVersion_ autorelease];
  coreProtocolVersion_ = [str copy];
}

- (NSString *)coreProtocolVersion {
  if (coreProtocolVersion_ != nil) {
    return coreProtocolVersion_;
  }

  NSString *serviceVersion = [self serviceVersion];
  NSString *coreVersion = [[self class] coreProtocolVersionForServiceVersion:serviceVersion];

  [self setCoreProtocolVersion:coreVersion];
  return coreVersion;
}

- (BOOL)isCoreProtocolVersion1 {
  NSString *coreVersion = [self coreProtocolVersion];

  // technically the version number is <integer>.<integer> rather than a float,
  // but intValue is a simple way to test just the major portion
  int majorVer = [coreVersion intValue];
  return (majorVer <= 1);
}

+ (NSString *)coreProtocolVersionForServiceVersion:(NSString *)str {
  // subclasses may override this when their service versions
  // do not match the core protocol version
  return str;
}

#pragma mark userData and properties

- (void)setUserData:(id)userData {
  [userData_ autorelease];
  userData_ = [userData retain];
}

- (id)userData {
  // be sure the returned pointer has the life of the autorelease pool,
  // in case self is released immediately
  return [[userData_ retain] autorelease];
}

- (void)setProperties:(NSDictionary *)dict {
  [userProperties_ autorelease];
  userProperties_ = [dict mutableCopy];
}

- (NSDictionary *)properties {
  // be sure the returned pointer has the life of the autorelease pool,
  // in case self is released immediately
  return [[userProperties_ retain] autorelease];
}

- (void)setProperty:(id)obj forKey:(NSString *)key {

  if (obj == nil) {
    // user passed in nil, so delete the property
    [userProperties_ removeObjectForKey:key];
  } else {
    // be sure the property dictionary exists
    if (userProperties_ == nil) {
      [self setProperties:[NSDictionary dictionary]];
    }
    [userProperties_ setObject:obj forKey:key];
  }
}

- (id)propertyForKey:(NSString *)key {
  id obj = [userProperties_ objectForKey:key];

  // be sure the returned pointer has the life of the autorelease pool,
  // in case self is released immediately
  return [[obj retain] autorelease];
}

#pragma mark XML generation helpers

- (void)addNamespacesToElement:(NSXMLElement *)element {

  // we keep namespaces in a dictionary with prefixes
  // as keys.  We'll step through our namespaces and convert them
  // to NSXML-stype namespaces.
  for (NSString *prefix in namespaces_) {

    NSString *uri = [namespaces_ objectForKey:prefix];

    // no per-version namespace transforms are currently needed
    // uri = [self updatedVersionedNamespaceURIForPrefix:prefix
    //                                              URI:uri];

    [element addNamespace:[NSXMLElement namespaceWithName:prefix
                                              stringValue:uri]];
  }
}

- (void)addExtensionsToElement:(NSXMLElement *)element {
  // extensions are in a dictionary of arrays, keyed by the class
  // of each kind of element

  // note: this adds actual extensions, not declarations
  NSDictionary *extensions = [self extensions];

  // step through each extension, by class, and add those
  // objects to the XML element
  for (Class oneClass in extensions) {

    id objectOrArray = [extensions_ objectForKey:oneClass];

    if ([objectOrArray isKindOfClass:[NSArray class]]) {
      [self addToElement:element XMLElementsForArray:objectOrArray];
    } else {
      [self addToElement:element XMLElementForObject:objectOrArray];
    }
  }
}

- (void)addUnknownChildNodesToElement:(NSXMLElement *)element {

  // we'll add every element and attribute as "unknown", then remove them
  // from this list as we parse them to create the GData object. Anything
  // left remaining in this list is considered unknown.

  if (shouldIgnoreUnknowns_) return;

  // we have to copy the children so they don't point at the previous parent
  // nodes
  for (NSXMLNode *child in unknownChildren_) {
    [element addChild:[[child copy] autorelease]];
  }

  for (NSXMLNode *attr in unknownAttributes_) {

    GDATA_DEBUG_ASSERT([element attributeForName:[attr name]] == nil,
              @"adding duplicate of attribute %@ (perhaps an object parsed with"
              "attributeForName: instead of attributeForName:fromElement:)",
              attr);

    [element addAttribute:[[attr copy] autorelease]];
  }
}

// this method creates a basic XML element from this GData object.
//
// this is called by the XMLElement method of subclasses; they will add their
// own attributes and children to the element returned by this method
//
// extensions may pass nil for defaultName to use the name specified in their
// extensionElementLocalName and extensionElementPrefix

- (NSXMLElement *)XMLElementWithExtensionsAndDefaultName:(NSString *)defaultName {

#if 0
  // code sometimes useful for finding unparsed xml; this can be turned on
  // during testing
  if ([unknownAttributes_ count]) {
    NSLog(@"%@ %p: unknown attributes %@\n%@\n", [self class], self, unknownAttributes_, self);
  }
  if ([unknownChildren_ count]) {
    NSLog(@"%@ %p: unknown children %@\n%@\n", [self class], self, unknownChildren_, self);
  }
#endif

  // use the name from the XML
  NSString *elementName = [self elementName];
  if (!elementName) {

    // if no name from the XML, use the name our class's XML element
    // routine supplied as a default
    if (defaultName) {
      elementName = defaultName;
    } else {
      // if no default name from the class, and this class is an extension,
      // use the extension's default element name
      if ([[self class] conformsToProtocol:@protocol(GDataExtension)]) {

        elementName = [self qualifiedNameForExtensionClass:[self class]];
      } else {
        // if not an extension, just use the class name
        elementName = NSStringFromClass([self class]);

        GDATA_DEBUG_LOG(@"GDataObject generating XML element with unknown name for class %@",
              elementName);
      }
    }
  }

  NSXMLElement *element = [NSXMLNode elementWithName:elementName];
  [self addNamespacesToElement:element];
  [self addAttributesToElement:element];
  [self addContentValueToElement:element];
  [self addChildXMLElementsToElement:element];
  [self addExtensionsToElement:element];
  [self addUnknownChildNodesToElement:element];
  return element;
}

- (NSXMLNode *)addToElement:(NSXMLElement *)element
     attributeValueIfNonNil:(NSString *)val
                   withName:(NSString *)name {
  if (val) {
    NSString *filtered = [GDataUtilities stringWithControlsFilteredForString:val];

    NSXMLNode* attr = [NSXMLNode attributeWithName:name stringValue:filtered];
    [element addAttribute:attr];
    return attr;
  }
  return nil;
}

- (NSXMLNode *)addToElement:(NSXMLElement *)element
     attributeValueIfNonNil:(NSString *)val
          withQualifiedName:(NSString *)qName
                        URI:(NSString *)attributeURI {

  if (attributeURI == nil) {
    return [self addToElement:element
       attributeValueIfNonNil:val
                     withName:qName];
  }

  if (val) {
    NSString *filtered = [GDataUtilities stringWithControlsFilteredForString:val];

    NSXMLNode *attr = [NSXMLNode attributeWithName:qName
                                               URI:attributeURI
                                       stringValue:filtered];
    if (attr != nil) {
      [element addAttribute:attr];
      return attr;
    }
  }
  return nil;
}

- (NSXMLNode *)addToElement:(NSXMLElement *)element
  attributeValueWithInteger:(NSInteger)val
                   withName:(NSString *)name {
  NSString* str = [NSString stringWithFormat:@"%ld", (long)val];
  NSXMLNode* attr = [NSXMLNode attributeWithName:name stringValue:str];
  [element addAttribute:attr];
  return attr;
}

// adding a child to an XML element
- (NSXMLNode *)addToElement:(NSXMLElement *)element
childWithStringValueIfNonEmpty:(NSString *)str
                   withName:(NSString *)name {
  if ([str length] > 0) {
    NSXMLNode *child = [NSXMLElement elementWithName:name stringValue:str];
    [element addChild:child];
    return child;
  }
  return nil;
}

// call the object's XMLElement method, and add the result as a new XML child
// element
- (void)addToElement:(NSXMLElement *)element
 XMLElementForObject:(id)object {

  if ([object isKindOfClass:[GDataAttribute class]]) {

    // attribute extensions are not GDataObjects and don't implement
    // XMLElement; we just get the attribute value from them
    NSString *str = [object stringValue];
    NSString *qName = [self qualifiedNameForExtensionClass:[object class]];
    NSString *theURI = [[object class] extensionElementURI];

    [self addToElement:element
attributeValueIfNonNil:str
     withQualifiedName:qName
                   URI:theURI];

  } else {
    // element extension
    NSXMLElement *child = [object XMLElement];
    if (child) {
      [element addChild:child];
    }
  }
}

// call the XMLElement method for each object in the array
- (void)addToElement:(NSXMLElement *)element
 XMLElementsForArray:(NSArray *)arrayOfGDataObjects {
  for(id item in arrayOfGDataObjects) {
    [self addToElement:element XMLElementForObject:item];
  }
}

#pragma mark description method helpers

#if !GDATA_SIMPLE_DESCRIPTIONS
// if the description label begins with version<= or version>= then do a service
// version check
//
// returns the label with any version prefix removed, or returns nil if the
// description fails the version check and should not be evaluated

- (NSString *)labelAdjustedForVersion:(NSString *)origLabel {

  BOOL checkMinVersion = NO;
  BOOL checkMaxVersion = NO;
  NSString *prefix = nil;

  static NSString *const kMinVersionPrefix = @"version>=";
  static NSString *const kMaxVersionPrefix = @"version<=";

  if ([origLabel hasPrefix:kMinVersionPrefix]) {
    checkMinVersion = YES;
    prefix = kMinVersionPrefix;
  } else if ([origLabel hasPrefix:kMaxVersionPrefix]) {
    checkMaxVersion = YES;
    prefix = kMaxVersionPrefix;
  }

  if (!checkMaxVersion && !checkMinVersion) return origLabel;

  // there is a version prefix; scan and test the version string,
  // and if the test succeeds, return the label without the prefix
  NSString *newLabel = origLabel;
  NSString *versionStr = nil;
  NSScanner *scanner = [NSScanner scannerWithString:origLabel];

  if ([scanner scanString:prefix intoString:NULL]
      && [scanner scanUpToString:@":" intoString:&versionStr]
      && [scanner scanString:@":" intoString:NULL]
      && [scanner scanUpToString:@"\n" intoString:&newLabel]) {

    if ((checkMinVersion && ![self isServiceVersionAtLeast:versionStr])
        || (checkMaxVersion && ![self isServiceVersionAtMost:versionStr])) {
      // version test failed
      return nil;
    }
  }
  return newLabel;
}
#endif

- (void)addDescriptionRecords:(GDataDescriptionRecord *)descRecordList
                      toItems:(NSMutableArray *)items {
#if !GDATA_SIMPLE_DESCRIPTIONS
  // the final descRecord in the list should be { nil, nil, 0 }

  for (NSUInteger idx = 0; descRecordList[idx].label != nil; idx++) {

    GDataDescRecTypes reportType = descRecordList[idx].reportType;
    NSString *label = descRecordList[idx].label;
    NSString *keyPath = descRecordList[idx].keyPath;

    label = [self labelAdjustedForVersion:label];
    if (label == nil) continue;

    id value;
    NSString *str;

    if (reportType == kGDataDescValueIsKeyPath) {
      value = keyPath;
    } else {
      value = [self valueForKeyPath:keyPath];
    }

    switch (reportType) {

      case kGDataDescValueLabeled:
      case kGDataDescValueIsKeyPath:
        [self addToArray:items objectDescriptionIfNonNil:value withName:label];
        break;

      case kGDataDescLabelIfNonNil:
        if (value != nil) [items addObject:label];
        break;

      case kGDataDescArrayCount:
        if ([(NSArray *)value count] > 0) {
          str = [NSString stringWithFormat:@"%lu", (unsigned long) [(NSArray *)value count]];
          [self addToArray:items objectDescriptionIfNonNil:str withName:label];
        }
        break;

      case kGDataDescArrayDescs:
        if ([(NSArray *)value count] > 0) {
          [self addToArray:items objectDescriptionIfNonNil:value withName:label];
        }
        break;

      case kGDataDescBooleanLabeled:
        // display the label with YES or NO
        str = ([value boolValue] ? @"YES" : @"NO");
        [self addToArray:items objectDescriptionIfNonNil:str withName:label];
        break;

      case kGDataDescBooleanPresent:
        // display the label:YES only if present
        if ([value boolValue]) {
          [self addToArray:items objectDescriptionIfNonNil:@"YES" withName:label];
        }
        break;

      case kGDataDescNonZeroLength:
        // display the length if non-zero
        if ([(NSData *)value length] > 0) {
          str = [NSString stringWithFormat:@"#%lu",
                 (unsigned long) [(NSData *)value length]];
          [self addToArray:items objectDescriptionIfNonNil:str withName:label];
        }
        break;
    }
  }
#endif
}

- (void)addToArray:(NSMutableArray *)stringItems
objectDescriptionIfNonNil:(id)obj
          withName:(NSString *)name {

  if (obj) {
    if (name) {
      [stringItems addObject:[NSString stringWithFormat:@"%@:%@", name, obj]];
    } else {
      [stringItems addObject:[obj description]];
    }
  }
}

- (void)addAttributeDescriptionsToArray:(NSMutableArray *)stringItems {

  // add attribute descriptions in the order the attributes were declared
  NSArray *attributeDeclarations = [self attributeDeclarations];
  for (NSString *name in attributeDeclarations) {

    NSString *value = [attributes_ valueForKey:name];
    [self addToArray:stringItems objectDescriptionIfNonNil:value withName:name];
  }
}

- (void)addContentDescriptionToArray:(NSMutableArray *)stringItems
                            withName:(NSString *)name {
  if ([self hasDeclaredContentValue]) {
    NSString *value = [self contentStringValue];
    [self addToArray:stringItems objectDescriptionIfNonNil:value withName:name];
  }
}

- (void)addChildXMLElementsDescriptionToArray:(NSMutableArray *)stringItems {
  if ([self hasDeclaredChildXMLElements]) {

    NSArray *childXMLElements = [self childXMLElements];
    if ([childXMLElements count] > 0) {

      NSArray *xmlStrings = [childXMLElements valueForKey:@"XMLString"];
      NSString *combinedStr = [xmlStrings componentsJoinedByString:@""];

      [self addToArray:stringItems objectDescriptionIfNonNil:combinedStr withName:@"XML"];
    }
  }
}

- (NSMutableArray *)itemsForDescription {
  NSMutableArray *items = [NSMutableArray array];
  [self addAttributeDescriptionsToArray:items];
  [self addContentDescriptionToArray:items withName:@"content"];

#if GDATA_SIMPLE_DESCRIPTIONS
  // with GDATA_SIMPLE_DESCRIPTIONS set, subclasses aren't adding their
  // own description items for extensions, so we'll just list the extension
  // elements that are present, by their qualified xml names
  //
  // The description string will look like
  //   {extensions:(gCal:color,link(3),gd:etag,id,updated)}
  NSMutableArray *extnsItems = [NSMutableArray array];

  for (Class extClass in extensions_) {

    // add the qualified XML name for each extension, followed by (n) when
    // there is more than one instance
    NSString *qname = [self qualifiedNameForExtensionClass:extClass];

    // there's one instance of this extension, unless the value is an array
    NSUInteger numberOfInstances = 1;
    id extnObj = [extensions_ objectForKey:extClass];
    if ([extnObj isKindOfClass:[NSArray class]]) {
      numberOfInstances = [extnObj count];
    }

    if (numberOfInstances == 1) {
      [extnsItems addObject:qname];
    } else {
      // append number of occurrences to the xml name
      NSString *str = [NSString stringWithFormat:@"%@(%lu)", qname,
                       (unsigned long) numberOfInstances];
      [extnsItems addObject:str];
    }
  }

  if ([extnsItems count] > 0) {
    // sort for predictable ordering in unit tests
    NSArray *sortedItems = [extnsItems sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSString *extnsStr = [NSString stringWithFormat:@"extensions:(%@)",
                          [sortedItems componentsJoinedByString:@","]];
    [items addObject:extnsStr];
  }
#endif

  [self addChildXMLElementsDescriptionToArray:items];
  return items;
}

- (NSString *)descriptionWithItems:(NSArray *)items {

  NSString *str;

  if ([items count] > 0) {
    str = [NSString stringWithFormat:@"%@ %p: {%@}",
      [self class], self, [items componentsJoinedByString:@" "]];

  } else {
    str = [NSString stringWithFormat:@"%@ %p", [self class], self];
  }
  return str;
}

- (NSString *)description {

  NSMutableArray *items = [self itemsForDescription];

#if !GDATA_SIMPLE_DESCRIPTIONS
  // add names of unknown children and attributes to the descriptions
  if ([unknownChildren_ count] > 0) {
    // remove repeats and put the element names in < > so they are more
    // readable
    NSArray *names = [unknownChildren_ valueForKey:@"name"];
    NSSet *namesSet = [NSSet setWithArray:names];
    NSMutableArray *fmtNames = [NSMutableArray arrayWithCapacity:[namesSet count]];

    for (NSString *name in namesSet) {
      NSString *fmtName = [NSString stringWithFormat:@"<%@>", name];
      [fmtNames addObject:fmtName];
    }

    // sort the names so the output is deterministic despite the set/array
    // conversion
    NSArray *sortedNames = [fmtNames sortedArrayUsingSelector:@selector(compare:)];
    NSString *desc = [sortedNames componentsJoinedByString:@","];
    [self addToArray:items objectDescriptionIfNonNil:desc withName:@"unparsed"];
  }

  if ([unknownAttributes_ count] > 0) {
    NSArray *names = [unknownAttributes_ valueForKey:@"name"];
    NSString *desc = [names componentsJoinedByString:@","];
    [self addToArray:items objectDescriptionIfNonNil:desc withName:@"unparsedAttr"];
  }
#endif

  NSString *str = [self descriptionWithItems:items];
  return str;
}


#pragma mark XML parsing helpers

+ (NSDictionary *)dictionaryForElementNamespaces:(NSXMLElement *)element {

  NSMutableDictionary *dict = nil;

  // for each namespace node, add a dictionary entry with the namespace
  // name (prefix) as key and the URI as value
  //
  // note: the prefix may be an empty string

  NSArray *namespaceNodes = [element namespaces];

  NSUInteger numberOfNamespaces = [namespaceNodes count];

  if (numberOfNamespaces > 0) {

    dict = [NSMutableDictionary dictionary];

    for (unsigned int idx = 0; idx < numberOfNamespaces; idx++) {
      NSXMLNode *node = [namespaceNodes objectAtIndex:idx];
      [dict setObject:[node stringValue]
               forKey:[node name]];
    }
  }
  return dict;
}

// classOrSurrogateForClass searches this object instance and all parent
// instances for a user surrogate for the supplied class, and returns
// the surrogate, or else the supplied class if no surrogate is found for it
- (Class)classOrSurrogateForClass:(Class)standardClass {

  for (GDataObject *currentObject = self;
       currentObject != nil;
       currentObject = [currentObject parent]) {

    // look for an object with a surrogates dict containing the standardClass
    NSDictionary *currentSurrogates = [currentObject surrogates];

    Class surrogate = (Class)[currentSurrogates objectForKey:standardClass];
    if (surrogate) return surrogate;
  }
  return standardClass;
}

// The following routines which parse XML elements remove the parsed elements
// from the list of unknowns.

// objectForElementWithNameIfAny:objectClass:objectClass: creates
// a single GDataObject of the specified class for the first XML child element
// with the specified name. Returns nil if no child element is present
//
// If objectClass is nil, the class is looked up from the registrations
// of entry and feed classes.
- (id)objectForChildOfElement:(NSXMLElement *)parentElement
                qualifiedName:(NSString *)qualifiedName
                 namespaceURI:(NSString *)namespaceURI
                  objectClass:(Class)objectClass {
  id object = nil;
  NSXMLElement *element = [self childWithQualifiedName:qualifiedName
                                          namespaceURI:namespaceURI
                                           fromElement:parentElement];
  if (element) {

    if (objectClass == nil) {
      // if the object is a feed or an entry, we might be able to determine the
      // type from the XML
      objectClass = [[self class] objectClassForXMLElement:element];
    }

    objectClass = [self classOrSurrogateForClass:objectClass];

    object = [[[objectClass alloc] initWithXMLElement:element
                                               parent:self] autorelease];
  }
  return object;
}


// get child elements from an element matching the given name and namespace
// (trying the namespace first, falling back on the fully-qualified name)
- (NSArray *)elementsForName:(NSString *)qualifiedName
                namespaceURI:(NSString *)namespaceURI
               parentElement:(NSXMLElement *)parentElement {

  NSArray *objElements = nil;

  if ([namespaceURI length] > 0) {

    NSString *localName = [NSXMLNode localNameForName:qualifiedName];

    objElements = [parentElement elementsForLocalName:localName
                                                  URI:namespaceURI];
  }

  // if we couldn't find the elements by name, fall back on the fully-qualified
  // name
  if ([objElements count] == 0) {

    objElements = [parentElement elementsForName:qualifiedName];
  }
  return objElements;

}

// return all child elements of an element which have the given namespace
// prefix
- (NSMutableArray *)childrenOfElement:(NSXMLElement *)parentElement
                           withPrefix:(NSString *)prefix {
  NSArray *allChildren = [parentElement children];
  NSMutableArray *matchingChildren = [NSMutableArray array];
  for (NSXMLNode *childNode in allChildren) {
    if ([childNode kind] == NSXMLElementKind
        && [[childNode prefix] isEqual:prefix]) {

      [matchingChildren addObject:childNode];
    }
  }

  return matchingChildren;
}

// returns a GDataObject or an array of them of the specified class for each XML
// child element with the specified name
//
// If objectClass is nil, the class is looked up from the registrations
// of entry and feed classes.

- (id)objectOrArrayForChildrenOfElement:(NSXMLElement *)parentElement
                          qualifiedName:(NSString *)qualifiedName
                           namespaceURI:(NSString *)namespaceURI
                            objectClass:(Class)objectClass {
  id result = nil;
  BOOL isResultAnArray = NO;

  NSArray *objElements = nil;

  NSString *localName = [NSXMLNode localNameForName:qualifiedName];
  if (![localName isEqual:@"*"]) {

    // searching for an actual element name (not a wildcard)
    objElements = [self elementsForName:qualifiedName
                           namespaceURI:namespaceURI
                          parentElement:parentElement];
  }

  else {
    // we weren't given a local name, so get all objects for this namespace
    // URI's prefix
    NSString *prefixSought = [NSXMLNode prefixForName:qualifiedName];
    if ([prefixSought length] == 0) {
      prefixSought = [parentElement resolvePrefixForNamespaceURI:namespaceURI];
    }

    if (prefixSought) {
      objElements = [self childrenOfElement:parentElement
                                 withPrefix:prefixSought];
    }
  }

  // if we're creating entries, we'll use an autorelease pool around each
  // allocation, just to bound overall pool size.  We'll check the class
  // of the first created object to determine if we want pools.
  BOOL hasCheckedObjectClass = NO;
  BOOL useLocalAutoreleasePool = NO;
  Class entryBaseClass = [GDataEntryBase class];

  // step through all child elements and create an appropriate GData object
  for (NSXMLElement *objElement in objElements) {

    Class elementClass = objectClass;
    if (elementClass == nil) {
      // if the object is a feed or an entry, we might be able to determine the
      // type for this element from the XML
      elementClass = [[self class] objectClassForXMLElement:objElement];

      // if a base feed class doesn't specify entry class, and the entry object
      // class can't be determined by examining its XML, fall back on
      // instantiating the base entry class
      if (elementClass == nil
        && [qualifiedName isEqual:@"entry"]
        && [namespaceURI isEqual:kGDataNamespaceAtom]) {

        elementClass = entryBaseClass;
      }
    }

    elementClass = [self classOrSurrogateForClass:elementClass];

    NSAutoreleasePool *pool = nil;

    if (!hasCheckedObjectClass) {
      useLocalAutoreleasePool = [elementClass isSubclassOfClass:entryBaseClass];
      hasCheckedObjectClass = YES;
    }

    if (useLocalAutoreleasePool) {
      pool = [[NSAutoreleasePool alloc] init];
    }

    id obj = [[elementClass alloc] initWithXMLElement:objElement
                                               parent:self];

    // We drain here to keep the clang static analyzer quiet.
    [pool drain];

    [obj autorelease];

    if (obj) {
      if (result == nil) {
        // first result
        result = obj;
      } else if (!isResultAnArray) {
        // second result; create an array with the previous and the new result
        result = [NSMutableArray arrayWithObjects:result, obj, nil];
        isResultAnArray = YES;
      } else {
        // third or later result
        [result addObject:obj];
      }
    }
  }

  // remove these elements from the unknown list
  [self handleParsedElements:objElements];

  return result;
}

// childOfElement:withName returns the element with the name, or nil if there
// are not exactly one of the element.  Pass "*" wildcards for name and URI
// to retrieve the child element if there is exactly one.
- (NSXMLElement *)childWithQualifiedName:(NSString *)qualifiedName
                            namespaceURI:(NSString *)namespaceURI
                             fromElement:(NSXMLElement *)parentElement {

  NSArray *elementArray;

  if ([qualifiedName isEqual:@"*"] && [namespaceURI isEqual:@"*"]) {
    // wilcards
    elementArray = [parentElement children];
  } else {
    // find the element by name and namespace URI
    elementArray = [self elementsForName:qualifiedName
                            namespaceURI:namespaceURI
                           parentElement:parentElement];
  }

  NSUInteger numberOfElements = [elementArray count];

  if (numberOfElements == 1) {
    NSXMLElement *element = [elementArray objectAtIndex:0];

    // remove this element from the unknown list
    [self handleParsedElement:element];

    return element;
  }

  // We might want to get rid of this assert if there turns out to be
  // legitimate reasons to call this where there are >1 elements available
  GDATA_ASSERT(numberOfElements == 0, @"childWithQualifiedName: could not handle "
               "multiple '%@' elements in list, use elementsForName:\n"
               "Found elements: %@\nURI: %@", qualifiedName, elementArray,
               namespaceURI);
  return nil;
}

#pragma mark element parsing

- (void)handleParsedElement:(NSXMLNode *)element {
  if (unknownChildren_ != nil && element != nil) {
    [unknownChildren_ removeObjectIdenticalTo:element];

    if ([unknownChildren_ count] == 0) {
      [unknownChildren_ release];
      unknownChildren_ = nil;
    }
  }
}

- (void)handleParsedElements:(NSArray *)array {
  if (unknownChildren_ != nil) {
    // rather than use NSMutableArray's removeObjects:, it's faster to iterate and
    // and use removeObjectIdenticalTo: since it avoids comparing the underlying
    // XML for equality
    for (NSXMLNode* element in array) {
      [unknownChildren_ removeObjectIdenticalTo:element];
    }

    if ([unknownChildren_ count] == 0) {
      [unknownChildren_ release];
      unknownChildren_ = nil;
    }
  }
}

- (NSString *)stringValueFromElement:(NSXMLElement *)element {
  // Originally, this was
  //    NSString *result = [element stringValue];
  // but that recursively descends children to build the string
  // so we'll just walk the remaining nodes and build the string ourselves

  if (element == nil) {
    return nil;
  }

  NSString *result = nil;

  // consider all text child nodes used to make this string value to now be
  // known
  //
  // in most cases, there is only one text node, so we'll optimize for that
  NSArray *children = [element children];

  for (NSXMLNode *childNode in children) {
    if ([childNode kind] == NSXMLTextKind) {

      NSString *newNodeString = [childNode stringValue];

      if (result == nil) {
        result = newNodeString;
      } else {
        result = [result stringByAppendingString:newNodeString];
      }
      [self handleParsedElement:childNode];
    }
  }

  return (result != nil ? result : @"");
}

- (GDataDateTime *)dateTimeFromElement:(NSXMLElement *)element {
  NSString *str = [self stringValueFromElement:element];
  if ([str length] > 0) {
    return [GDataDateTime dateTimeWithRFC3339String:str];
  }
  return nil;
}


- (NSNumber *)intNumberValueFromElement:(NSXMLElement *)element {
  NSString *str = [self stringValueFromElement:element];
  if ([str length] > 0) {
    NSNumber *number = [NSNumber numberWithInt:[str intValue]];
    return number;
  }
  return nil;
}

- (NSNumber *)doubleNumberValueFromElement:(NSXMLElement *)element {
  NSString *str = [self stringValueFromElement:element];
  return [GDataUtilities doubleNumberOrInfForString:str];
}

#pragma mark attribute parsing

- (void)handleParsedAttribute:(NSXMLNode *)attribute {

  if (unknownAttributes_ != nil && attribute != nil) {
    [unknownAttributes_ removeObjectIdenticalTo:attribute];

    if ([unknownAttributes_ count] == 0) {
      [unknownAttributes_ release];
      unknownAttributes_ = nil;
    }
  }
}

- (NSXMLNode *)attributeForName:(NSString *)attributeName
                    fromElement:(NSXMLElement *)element {

  NSXMLNode* attribute = [element attributeForName:attributeName];

  [self handleParsedAttribute:attribute];

  return attribute;
}

- (NSXMLNode *)attributeForLocalName:(NSString *)localName
                                 URI:(NSString *)attributeURI
                         fromElement:(NSXMLElement *)element {

  NSXMLNode* attribute = [element attributeForLocalName:localName
                                                    URI:attributeURI];
  [self handleParsedAttribute:attribute];

  return attribute;
}

- (NSString *)stringForAttributeLocalName:(NSString *)localName
                                      URI:(NSString *)attributeURI
                              fromElement:(NSXMLElement *)element {

  NSXMLNode* attribute = [self attributeForLocalName:localName
                                                 URI:attributeURI
                                         fromElement:element];
  return [attribute stringValue];
}


- (NSString *)stringForAttributeName:(NSString *)attributeName
                         fromElement:(NSXMLElement *)element {
  NSXMLNode* attribute = [self attributeForName:attributeName
                                    fromElement:element];
  return [attribute stringValue];
}

- (GDataDateTime *)dateTimeForAttributeName:(NSString *)attributeName
                                fromElement:(NSXMLElement *)element {

  NSXMLNode* attribute = [self attributeForName:attributeName
                                    fromElement:element];

  NSString* str = [attribute stringValue];
  if ([str length] > 0) {
    return [GDataDateTime dateTimeWithRFC3339String:str];
  }
  return nil;
}

- (BOOL)boolForAttributeName:(NSString *)attributeName
                 fromElement:(NSXMLElement *)element {
  NSXMLNode* attribute = [self attributeForName:attributeName
                                    fromElement:element];
  NSString* str = [attribute stringValue];
  BOOL isTrue = (str && [str caseInsensitiveCompare:@"true"] == NSOrderedSame);
  return isTrue;
}

- (NSNumber *)doubleNumberForAttributeName:(NSString *)attributeName
                               fromElement:(NSXMLElement *)element {
  NSXMLNode* attribute = [self attributeForName:attributeName
                                    fromElement:element];
  NSString* str = [attribute stringValue];
  return [GDataUtilities doubleNumberOrInfForString:str];
}

- (NSNumber *)intNumberForAttributeName:(NSString *)attributeName
                            fromElement:(NSXMLElement *)element {
  NSXMLNode* attribute = [self attributeForName:attributeName
                                    fromElement:element];
  NSString* str = [attribute stringValue];
  if (str) {
    NSNumber *number = [NSNumber numberWithInt:[str intValue]];
    return number;
  }
  return nil;
}


#pragma mark Extensions

- (void)addExtensionDeclarations {
  // overridden by subclasses which have extensions to add, like:
  //
  //  [self addExtensionDeclarationForParentClass:[GDataLink class]
  //                                   childClass:[GDataWebContent class]];
  // and
  //
  //  [self addAttributeExtensionDeclarationForParentClass:[GDataExtendedProperty class]
  //                                            childClass:[GDataExtPropValueAttribute class]];

}

- (void)addParseDeclarations {

  // overridden by subclasses which have local attributes, like:
  //
  //  [self addLocalAttributeDeclarations:[NSArray arrayWithObject:@"size"]];
  //
  //  Subclasses should add the attributes in the order they most usefully will
  //  appear in the object's -description output (or alternatively they may
  //  override -description).
  //
  // Note: this is only for namespace-less attributes or attributes with the
  // fixed xml: namespace, not for attributes that are qualified with variable
  // prefixes.  Those attributes should be parsed explicitly in
  // initWithXMLElement: methods, and generated by XMLElement: methods.
}

// subclasses call these to declare possible extensions for themselves and their
// children.
- (void)addExtensionDeclarationForParentClass:(Class)parentClass
                                   childClass:(Class)childClass {
  // add an element extension
  [self addExtensionDeclarationForParentClass:parentClass
                                   childClass:childClass
                                  isAttribute:NO];
}

- (void)addExtensionDeclarationForParentClass:(Class)parentClass
                                 childClasses:(Class)firstChildClass, ... {

  // like the method above, but for a list of child classes
  Class nextClass;
  va_list argumentList;

  if (firstChildClass != nil) {
    [self addExtensionDeclarationForParentClass:parentClass
                                     childClass:firstChildClass
                                    isAttribute:NO];

    va_start(argumentList, firstChildClass);
    while ((nextClass = (Class)va_arg(argumentList, Class)) != nil) {

      [self addExtensionDeclarationForParentClass:parentClass
                                       childClass:nextClass
                                      isAttribute:NO];
    }
    va_end(argumentList);
  }
}

- (void)addAttributeExtensionDeclarationForParentClass:(Class)parentClass
                                   childClass:(Class)childClass {
  // add an attribute extension
  [self addExtensionDeclarationForParentClass:parentClass
                                   childClass:childClass
                                  isAttribute:YES];
}

- (void)addExtensionDeclarationForParentClass:(Class)parentClass
                                   childClass:(Class)childClass
                                  isAttribute:(BOOL)isAttribute {

  // get or make the dictionary which caches the extension declarations for
  // this class
  Class currClass = [self class];
  NSMutableDictionary *extensionDeclarationsCache = [self extensionDeclarationsCache];
  GDATA_DEBUG_ASSERT(extensionDeclarationsCache != nil, @"missing extnDecls");

  NSMutableDictionary *extensionDecls = [extensionDeclarationsCache objectForKey:currClass];

  if (extensionDecls == nil) {
    extensionDecls = [NSMutableDictionary dictionary];
    [extensionDeclarationsCache setObject:extensionDecls forKey:(id<NSCopying>)currClass];
  }

  // get this class's extensions for the specified parent class
  NSMutableArray *array = [extensionDecls objectForKey:parentClass];
  if (array == nil) {
    array = [NSMutableArray array];
    [extensionDecls setObject:array forKey:(id<NSCopying>)parentClass];
  }

  GDATA_DEBUG_ASSERT([childClass conformsToProtocol:@protocol(GDataExtension)],
                @"%@ does not conform to GDataExtension protocol", childClass);

  GDataExtensionDeclaration *decl =
    [[[GDataExtensionDeclaration alloc] initWithParentClass:parentClass
                                                 childClass:childClass
                                                isAttribute:isAttribute] autorelease];
  [array addObject:decl];
}

- (void)removeExtensionDeclarationForParentClass:(Class)parentClass
                                      childClass:(Class)childClass {
  GDataExtensionDeclaration *decl =
    [[[GDataExtensionDeclaration alloc] initWithParentClass:parentClass
                                                 childClass:childClass
                                                isAttribute:NO] autorelease];

  NSMutableArray *array = [self extensionDeclarationsForParentClass:parentClass];
  [array removeObject:decl];
}

- (void)removeAttributeExtensionDeclarationForParentClass:(Class)parentClass
                                               childClass:(Class)childClass {
  GDataExtensionDeclaration *decl =
    [[[GDataExtensionDeclaration alloc] initWithParentClass:parentClass
                                                 childClass:childClass
                                                isAttribute:YES] autorelease];

  NSMutableArray *array = [self extensionDeclarationsForParentClass:parentClass];
  [array removeObject:decl];
}

// utility routine for getting declared extensions to the specified class
- (NSMutableArray *)extensionDeclarationsForParentClass:(Class)parentClass {

  // get the declarations for this class
  Class currClass = [self class];
  NSMutableDictionary *cache = [self extensionDeclarationsCache];
  NSMutableDictionary *classMap = [cache objectForKey:currClass];

  // get the extensions for the specified parent class
  NSMutableArray *array = [classMap objectForKey:parentClass];
  return array;
}

// objectsForExtensionClass: returns the array of all
// extension objects of the specified class, or nil
//
// this is typically called by the getter methods of subclasses

- (NSArray *)objectsForExtensionClass:(Class)theClass {
  id obj = [extensions_ objectForKey:theClass];
  if (obj == nil) return nil;

  if ([obj isKindOfClass:[NSArray class]]) {
    return obj;
  }

  return [NSArray arrayWithObject:obj];
}

// objectForExtensionClass: returns the first element of
// any extension objects of the specified class, or nil
//
// this is typically called by the getter methods of subclasses

- (id)objectForExtensionClass:(Class)theClass {
  id obj = [extensions_ objectForKey:theClass];

  if ([obj isKindOfClass:[NSArray class]]) {
    if ([(NSArray *)obj count] > 0) {
      return [obj objectAtIndex:0];
    }
    // an empty array
    return nil;
  }

  return obj;
}

// attributeValueForExtensionClass: returns the value of the first object of
// the array of attribute extension objects of the specified class, or nil
- (NSString *)attributeValueForExtensionClass:(Class)theClass {
  GDataAttribute *attr = [self objectForExtensionClass:theClass];
  NSString *str = [attr stringValue];
  return str;
}

- (void)setAttributeValue:(NSString *)str forExtensionClass:(Class)theClass {
  GDataAttribute *obj = [theClass attributeWithValue:str];
  [self setObject:obj forExtensionClass:theClass];
}

// generate the qualified name for this extension's element
- (NSString *)qualifiedNameForExtensionClass:(Class)theClass {

  NSString *name;

  @synchronized(gQualifiedNameMap) {

    name = [gQualifiedNameMap objectForKey:theClass];
    if (name == nil) {

      NSString *extensionURI = [theClass extensionElementURI];

      if (extensionURI == nil || [extensionURI isEqual:kGDataNamespaceAtom]) {
        name = [theClass extensionElementLocalName];
      } else {
        name = [NSString stringWithFormat:@"%@:%@",
                [theClass extensionElementPrefix],
                [theClass extensionElementLocalName]];
      }

      [gQualifiedNameMap setObject:name forKey:(id<NSCopying>)theClass];
    }
  }
  return name;
}

- (void)ensureObject:(GDataObject *)obj hasXMLNameForExtensionClass:(Class)theClass {
  // utility routine for setObjects:forExtensionClass:
  if ([obj isKindOfClass:[GDataObject class]]
      && [[obj elementName] length] == 0) {

    NSString *name = [self qualifiedNameForExtensionClass:theClass];
    [obj setElementName:name];
  }
}

// replace all actual extensions of the specified class with an array
//
// this is typically called by the setter methods of subclasses

- (void)setObjects:(NSArray *)objects forExtensionClass:(Class)theClass {

  GDATA_DEBUG_ASSERT(objects == nil || [objects isKindOfClass:[NSArray class]],
                     @"array expected");

  if (extensions_ == nil && objects != nil) {
    extensions_ = [[NSMutableDictionary alloc] init];
  }

  if (objects) {
    // be sure each object has an element name so we can generate XML for it
    for (GDataObject *obj in objects) {
      [self ensureObject:obj hasXMLNameForExtensionClass:theClass];
    }
    [extensions_ setObject:objects forKey:(id<NSCopying>)theClass];
  } else {
    [extensions_ removeObjectForKey:theClass];
  }
}

// replace all actual extensions of the specified class with a single object
//
// this is typically called by the setter methods of subclasses

- (void)setObject:(id)object forExtensionClass:(Class)theClass {

  GDATA_DEBUG_ASSERT(![object isKindOfClass:[NSArray class]], @"array unexpected");

  if (extensions_ == nil && object != nil) {
    extensions_ = [[NSMutableDictionary alloc] init];
  }

  if (object) {
    [self ensureObject:object hasXMLNameForExtensionClass:theClass];
    [extensions_ setObject:object forKey:(id<NSCopying>)theClass];
  } else {
    [extensions_ removeObjectForKey:theClass];
  }
}

// add an extension of the specified class
//
// this is typically called by addObject methods of subclasses

- (void)addObject:(id)newObj forExtensionClass:(Class)theClass {

  if (newObj == nil) return;

  id previousObjOrArray = [extensions_ objectForKey:theClass];
  if (previousObjOrArray) {

    if ([previousObjOrArray isKindOfClass:[NSArray class]]) {

      // add to the existing array
      [self ensureObject:newObj hasXMLNameForExtensionClass:theClass];
      [previousObjOrArray addObject:newObj];

    } else {

      // create an array with the previous object and the new object
      NSMutableArray *array = [NSMutableArray arrayWithObjects:
                               previousObjOrArray, newObj, nil];
      [extensions_ setObject:array forKey:(id<NSCopying>)theClass];
    }
  } else {

    // no previous object
    [self setObject:newObj forExtensionClass:theClass];
  }
}

// remove a known extension of the specified class
//
// this is typically called by removeObject methods of subclasses

- (void)removeObject:(id)object forExtensionClass:(Class)theClass {
  id previousObjOrArray = [extensions_ objectForKey:theClass];
  if ([previousObjOrArray isKindOfClass:[NSArray class]]) {

    // remove from the array
    [(NSMutableArray *)previousObjOrArray removeObject:object];

  } else if ([(GDataObject *)object isEqual:previousObjOrArray]) {

    // no array, so remove if it matches the sole object
    [extensions_ removeObjectForKey:theClass];
  }
}

// addUnknownChildNodesForElement: is called by initWithXMLElement.  It builds
// the initial list of unknown child elements; this list is whittled down by
// parseExtensionsForElement and objectForChildOfElement.
- (void)addUnknownChildNodesForElement:(NSXMLElement *)element {

  GDATA_DEBUG_ASSERT(unknownChildren_ == nil, @"unknChildren added twice");
  GDATA_DEBUG_ASSERT(unknownAttributes_ == nil, @"unknAttr added twice");

  if (!shouldIgnoreUnknowns_) {

    NSArray *children = [element children];
    if ([children count] > 0) {
      unknownChildren_ = [[NSMutableArray alloc] initWithArray:children];
    }

    NSArray *attributes = [element attributes];
    if ([attributes count] > 0) {
      unknownAttributes_ = [[NSMutableArray alloc] initWithArray:attributes];
    }
  }
}

// parseExtensionsForElement: is called by initWithXMLElement. It starts
// from the current object and works up the chain of parents, grabbing
// the declared extensions by each GDataObject in the ancestry and looking
// at the current element to see if any of the declared extensions are present.

- (void)parseExtensionsForElement:(NSXMLElement *)element {
  Class classBeingParsed = [self class];

  // For performance, we'll avoid looking up extension elements whose
  // local names aren't present in the element.  We don't bother doing
  // this for attribute extensions since those are so rare (most attributes
  // are parsed just by local declaration in parseAttributesForElement:.)

  NSArray *childLocalNames = [element valueForKeyPath:@"children.localName"];

  // allow wildcard lookups
  childLocalNames = [childLocalNames arrayByAddingObject:@"*"];

  Class arrayClass = [NSArray class];

  for (GDataObject * currentExtensionSupplier = self;
       currentExtensionSupplier != nil;
       currentExtensionSupplier = [currentExtensionSupplier parent]) {

    // find all extensions in this supplier with the current class as the parent
    NSArray *extnDecls = [currentExtensionSupplier extensionDeclarationsForParentClass:classBeingParsed];

    if (extnDecls) {
      for (GDataExtensionDeclaration *decl in extnDecls) {
        // if we've not already found this class when parsing at an earlier supplier
        Class extensionClass = [decl childClass];
        if ([extensions_ objectForKey:extensionClass] == nil) {

          // if this extension's local name really matches some child's local
          // name (or this is an attribute extension)

          NSString *declLocalName = [extensionClass extensionElementLocalName];
          if ([childLocalNames containsObject:declLocalName]
              || [decl isAttribute]) {

            GDATA_DEBUG_ASSERT([extensionClass conformsToProtocol:@protocol(GDataExtension)],
                      @"%@ does not conform to GDataExtension protocol",
                      extensionClass);

            NSString *namespaceURI = [extensionClass extensionElementURI];
            NSString *qualifiedName = [self qualifiedNameForExtensionClass:extensionClass];

            id objectOrArray = nil;

            if ([decl isAttribute]) {
              // parse for an attribute extension
              NSString *str = [self stringForAttributeName:qualifiedName
                                               fromElement:element];
              if (str) {
                id attr = [[[extensionClass alloc] init] autorelease];
                [attr setStringValue:str];
                objectOrArray = attr;
              }

            } else {
              // parse for an element extension
              objectOrArray = [self objectOrArrayForChildrenOfElement:element
                                                        qualifiedName:qualifiedName
                                                         namespaceURI:namespaceURI
                                                          objectClass:extensionClass];
            }

            if ([objectOrArray isKindOfClass:arrayClass]) {
              if ([(NSArray *)objectOrArray count] > 0) {

                // save the non-empty array of extensions
                [self setObjects:objectOrArray forExtensionClass:extensionClass];
              }
            } else if (objectOrArray != nil) {

              // save the single extension
              [self setObject:objectOrArray forExtensionClass:extensionClass];
            }
          }
        }
      }
    }
  }
}

#pragma mark Local Attributes

- (void)addLocalAttributeDeclarations:(NSArray *)attributeLocalNames {

  // get or make the array which caches the attribute declarations for
  // this class
  if (attributeDeclarations_ == nil) {

    Class currClass = [self class];
    NSMutableDictionary *cache = [self attributeDeclarationsCache];
    GDATA_DEBUG_ASSERT(cache != nil, @"missing attrDeclsCache");

    // we keep a strong pointer to the array in the cache since the cache
    // belongs to the feed or the topmost parent, and that may go away
    attributeDeclarations_ = [[cache objectForKey:currClass] retain];
    if (attributeDeclarations_ == nil) {
      attributeDeclarations_ = [[NSMutableArray alloc] init];
      [cache setObject:attributeDeclarations_ forKey:(id<NSCopying>)currClass];
    }
  }

#if DEBUG
  // check that no local attributes being declared have a prefix, except for
  // the hardcoded xml: prefix. Namespaced attributes must be parsed and
  // emitted manually, or be declared as GDataAttribute extensions;
  // they cannot be handled as local attributes, since this class makes no
  // attempt to keep track of namespace URIs for local attributes
  for (NSString *attr in attributeLocalNames) {
    GDATA_ASSERT([attr rangeOfString:@":"].location == NSNotFound
                 || [attr hasPrefix:@"xml:"],
                 @"invalid namespaced local attribute: %@", attr);
  }
#endif

  [attributeDeclarations_ addObjectsFromArray:attributeLocalNames];
}

- (void)addAttributeDeclarationMarker:(NSString *)marker {

  if (![attributeDeclarations_ containsObject:marker]) {

    // add the marker
    if (attributeDeclarations_ != nil) {

      // no need to create the cache
      [attributeDeclarations_ addObject:marker];
    } else {

      // create the cache by calling addLocalAttributeDeclarations:
      NSArray *array = [NSArray arrayWithObject:marker];
      [self addLocalAttributeDeclarations:array];
    }
  }
}

// attribute value getters
- (NSString *)stringValueForAttribute:(NSString *)name {

  GDATA_DEBUG_ASSERT([[self attributeDeclarations] containsObject:name],
            @"%@ getting undeclared attribute: %@", [self class], name);

  return [attributes_ valueForKey:name];
}

- (NSNumber *)intNumberForAttribute:(NSString *)name {

  NSString *str = [self stringValueForAttribute:name];
  if ([str length] > 0) {
    NSNumber *number = [NSNumber numberWithInt:[str intValue]];
    return number;
  }
  return nil;
}

- (NSNumber *)doubleNumberForAttribute:(NSString *)name {

  NSString *str = [self stringValueForAttribute:name];
  return [GDataUtilities doubleNumberOrInfForString:str];
}

- (NSNumber *)longLongNumberForAttribute:(NSString *)name {

  NSString *str = [self stringValueForAttribute:name];
  if (str) {
    long long val = [str longLongValue];
    NSNumber *number = [NSNumber numberWithLongLong:val];
    return number;
  }
  return nil;
}

- (NSDecimalNumber *)decimalNumberForAttribute:(NSString *)name {

  NSString *str = [self stringValueForAttribute:name];
  if ([str length] > 0) {

    // require periods as the separator
    NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:str
                                    locale:usLocale];
    return number;
  }
  return nil;
}

- (GDataDateTime *)dateTimeForAttribute:(NSString *)name  {

  NSString *str = [self stringValueForAttribute:name];
  if ([str length] > 0) {
    GDataDateTime *dateTime = [GDataDateTime dateTimeWithRFC3339String:str];
    return dateTime;
  }
  return nil;
}

- (BOOL)boolValueForAttribute:(NSString *)name defaultValue:(BOOL)defaultVal {
  NSString *str = [self stringValueForAttribute:name];
  BOOL isTrue;

  if (defaultVal) {
    // default to true, so true if attribute is missing or is not "false"
    isTrue = (str == nil
              || [str caseInsensitiveCompare:@"false"] != NSOrderedSame);
  } else {
    // default to false, so true only if attribute is present and "true"
    isTrue = (str != nil
              && [str caseInsensitiveCompare:@"true"] == NSOrderedSame);
  }
  return isTrue;
}

// attribute value setters
- (void)setStringValue:(NSString *)str forAttribute:(NSString *)name {

  GDATA_DEBUG_ASSERT([[self attributeDeclarations] containsObject:name],
            @"%@ setting undeclared attribute: %@", [self class], name);

  if (attributes_ == nil) {
    attributes_ = [[NSMutableDictionary alloc] init];
  }

  [attributes_ setValue:str forKey:name];
}

- (void)setBoolValue:(BOOL)flag defaultValue:(BOOL)defaultVal forAttribute:(NSString *)name {
  NSString *str;
  if (defaultVal) {
    // default to true, so include attribute only if false
    str = (flag ? nil : @"false");
  } else {
    // default to false, so include attribute only if true
    str = (flag ? @"true" : nil);
  }
  [self setStringValue:str forAttribute:name];
}

- (void)setExplicitBoolValue:(BOOL)flag forAttribute:(NSString *)name {
  NSString *value = (flag ? @"true" : @"false");
  [self setStringValue:value forAttribute:name];
}

- (void)setDecimalNumberValue:(NSDecimalNumber *)num forAttribute:(NSString *)name {

  // for most NSNumbers, just calling -stringValue is fine, but for decimal
  // numbers we want to specify that a period be the separator
  NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];

  NSString *str = [num descriptionWithLocale:usLocale];
  [self setStringValue:str forAttribute:name];
}

- (void)setDateTimeValue:(GDataDateTime *)cdate forAttribute:(NSString *)name {
  NSString *str = [cdate RFC3339String];
  [self setStringValue:str forAttribute:name];
}


// parseAttributesForElement: is called by initWithXMLElement.
// It stores the value of all declared & present attributes in the dictionary
- (void)parseAttributesForElement:(NSXMLElement *)element {

  // for better performance, look up the values for declared attributes only
  // if they are really present in the node
  NSArray *attributes = [element attributes];
  NSArray *attributeDeclarations = [self attributeDeclarations];

  for (NSXMLNode *attribute in attributes) {

    NSString *attrName = [attribute name];
    if ([attributeDeclarations containsObject:attrName]) {

      NSString *str = [attribute stringValue];
      if (str != nil) {
        [self setStringValue:str forAttribute:attrName];
      }

      [self handleParsedAttribute:attribute];
    }
  }
}

// XML generator for local attributes
- (void)addAttributesToElement:(NSXMLElement *)element {

  for (NSString *name in attributes_) {

    NSString *value = [attributes_ valueForKey:name];
    if (value != nil) {
      [self addToElement:element attributeValueIfNonNil:value withName:name];
    }
  }
}

// attribute comparison: subclasses may implement attributesIgnoredForEquality:
// to specify attributes not to be considered for equality comparison

- (BOOL)hasAttributesEqualToAttributesOf:(GDataObject *)other {

  NSArray *attributesToIgnore = [self attributesIgnoredForEquality];

  NSDictionary *selfAttrs = [self attributes];
  NSDictionary *otherAttrs = [other attributes];

  if ([attributesToIgnore count] == 0) {
    // none to ignore; just compare attribute dictionaries
    return AreEqualOrBothNil(selfAttrs, otherAttrs);
  }

  // step through attributes, comparing each non-ignored attribute
  // to look for a mismatch
  NSArray *attributeDeclarations = [self attributeDeclarations];
  for (NSString *attrKey in attributeDeclarations) {

    if (![attributesToIgnore containsObject:attrKey]) {

      NSString *val1 = [selfAttrs objectForKey:attrKey];
      NSString *val2 = [otherAttrs objectForKey:attrKey];

      if (!AreEqualOrBothNil(val1, val2)) {
        return NO;
      }
    }
  }
  return YES;
}

- (NSArray *)attributesIgnoredForEquality {
  // subclasses may override this to specify attributes that should
  // not be considered when comparing objects for equality
  return nil;
}

#pragma mark Content Value

- (void)addContentValueDeclaration {
  // derived classes should call this if they want the element's content
  // to be automatically parsed as a string
  [self addAttributeDeclarationMarker:kContentValueDeclarationMarker];
}

- (BOOL)hasDeclaredContentValue {
  NSMutableArray *attrDecls = [self attributeDeclarations];
  BOOL flag = [attrDecls containsObject:kContentValueDeclarationMarker];
  return flag;
}

- (void)setContentStringValue:(NSString *)str {

  GDATA_ASSERT([self hasDeclaredContentValue], @"%@ setting undeclared content value",
               [self class]);

  [contentValue_ autorelease];
  contentValue_ = [str copy];
}

- (NSString *)contentStringValue {

  GDATA_ASSERT([self hasDeclaredContentValue], @"%@ getting undeclared content value",
               [self class]);

  return contentValue_;

}

// parseContentForElement: is called by initWithXMLElement.
// This stores the content value parsed from the element.
- (void)parseContentValueForElement:(NSXMLElement *)element {

  if ([self hasDeclaredContentValue]) {
    [self setContentStringValue:[self stringValueFromElement:element]];
  }
}

// XML generator for content
- (void)addContentValueToElement:(NSXMLElement *)element {

  if ([self hasDeclaredContentValue]) {
    NSString *str = [self contentStringValue];
    if ([str length] > 0) {
      [element addStringValue:str];
    }
  }
}

- (BOOL)hasContentValueEqualToContentValueOf:(GDataObject *)other {

  if (![self hasDeclaredContentValue]) {
    // no content being stored
    return YES;
  }

  return AreEqualOrBothNil([self contentStringValue], [other contentStringValue]);
}

#pragma mark Child XML Elements

- (void)addChildXMLElementsDeclaration {
  // derived classes should call this if they want the element's unparsed
  // XML children to be accessible later
  [self addAttributeDeclarationMarker:kChildXMLDeclarationMarker];
}

- (BOOL)hasDeclaredChildXMLElements {
  NSMutableArray *attrDecls = [self attributeDeclarations];
  BOOL flag = [attrDecls containsObject:kChildXMLDeclarationMarker];
  return flag;
}

- (NSArray *)childXMLElements {
  if ([childXMLElements_ count] == 0) {
    return nil;
  }
  return childXMLElements_;
}

- (void)setChildXMLElements:(NSArray *)array {
  GDATA_DEBUG_ASSERT([self hasDeclaredChildXMLElements],
                     @"%@ setting undeclared XML values", [self class]);

  [childXMLElements_ release];
  childXMLElements_ = [array mutableCopy];
}

- (void)addChildXMLElement:(NSXMLNode *)node {
  GDATA_DEBUG_ASSERT([self hasDeclaredChildXMLElements],
                     @"%@ adding undeclared XML values", [self class]);

  if (childXMLElements_ == nil) {
    childXMLElements_ = [[NSMutableArray alloc] init];
  }
  [childXMLElements_ addObject:node];
}

// keepChildXMLElementsForElement: is called by initWithXMLElement.
// This stores a copy of the element's child XMLElements.
- (void)keepChildXMLElementsForElement:(NSXMLElement *)element {

  if ([self hasDeclaredChildXMLElements]) {

    NSArray *children = [element children];
    if (children != nil) {

      // save only top-level nodes that are elements
      for (NSXMLNode *childNode in children) {
        if ([childNode kind] == NSXMLElementKind) {
          if (childXMLElements_ == nil) {
            childXMLElements_ = [[NSMutableArray alloc] init];
          }
          NSXMLNode *childCopy = [[childNode copy] autorelease];
          [childXMLElements_ addObject:childCopy];

          [self handleParsedElement:childNode];
        }
      }
    }
  }
}

// XML generator for kept child XML elements
- (void)addChildXMLElementsToElement:(NSXMLElement *)element {

  if ([self hasDeclaredChildXMLElements]) {

    NSArray *childXMLElements = [self childXMLElements];
    if (childXMLElements != nil) {

      for (NSXMLNode *child in childXMLElements) {
        [element addChild:child];
      }
    }
  }
}

- (BOOL)hasChildXMLElementsEqualToChildXMLElementsOf:(GDataObject *)other {

  if (![self hasDeclaredChildXMLElements]) {
    // no values being stored
    return YES;
  }
  return AreEqualOrBothNil([self childXMLElements], [other childXMLElements]);
}

#pragma mark Dynamic GDataObject

// Dynamic object generation is used when the class being created is nil.
//
// These maps are populated by +load routines in feeds and entries.
// They specify category elements which identify the class of feed or entry
// to be created for a blob of XML.

static NSString *const kCategoryTemplate = @"{\"%@\":\"%@\"}";


// registerClass:inMap:forCategoryWithScheme:term: does the work for
// registerFeedClass: and registerEntryClass:
//
// This adds the class to the {"scheme":"term"} map, ensuring
// that it won't conflict with a previous class or category
// entry

+ (void)registerClass:(Class)theClass
                inMap:(NSMutableDictionary **)map
forCategoryWithScheme:(NSString *)scheme
                 term:(NSString *)term {

  // there's no autorelease pool in place at +load time, so we'll create our own
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  if (*map == nil) {
    *map = GDataCreateStaticDictionary();
  }

  // ensure this is a unique registration
  GDATA_DEBUG_ASSERT(nil == [*map objectForKey:theClass],
               @"%@ already registered", theClass);

#if !NS_BLOCK_ASSERTIONS
  Class prevClass = [self classForCategoryWithScheme:scheme
                                                term:term
                                             fromMap:*map];
  GDATA_ASSERT(prevClass == nil, @"%@ registration conflicts with %@",
               theClass, prevClass);
#endif

  // we have a map from the key "scheme:term" to the class
  //
  // generally, scheme will be nil or kGDataCategoryScheme, so we'll
  // use just the term as the key for those categories, avoiding
  // the need to format a string when looking up

  NSString *key;
  if (scheme == nil || [scheme isEqual:kGDataCategoryScheme]) {
    key = term;
  } else {
    key = [NSString stringWithFormat:kCategoryTemplate,
           scheme, term ? term : @""];
  }

  [*map setValue:theClass forKey:key];

  // We drain here to keep the clang static analyzer quiet.
  [pool drain];
}


// classForCategoryWithScheme does the work for feedClassForCategory
// and entryClassForCategory.  This method searches the entry
// or feed map for a class with a matching category.
//
// If the registration of the class specified a value, then the corresponding
// parameter values |scheme| or |term| must match and not be nil.
+ (Class)classForCategoryWithScheme:(NSString *)scheme
                               term:(NSString *)term
                            fromMap:(NSDictionary *)map {

  // |scheme| and |term| are from the XML that we're using to look up
  // a registered class.  The |term| value should be non-nil,
  // though the values stored in the map may have nil scheme or term.
  //
  // if the registered scheme was nil or kGDataCategoryScheme then the key
  // is just the term value.

  NSString *key = term;
  Class result = (Class)[map objectForKey:key];
  if (result) return result;

  if (scheme) {
    key = [NSString stringWithFormat:kCategoryTemplate, scheme, term];
    result = (Class)[map objectForKey:key];
    if (result) return result;

    key = [NSString stringWithFormat:kCategoryTemplate, scheme, @""];
    result = (Class)[map objectForKey:key];
    if (result) return result;
  }

  return nil;
}

// objectClassForXMLElement: returns a found registered feed
// or entry class for the XML according to its contained category,
// or an Atom service document class
//
// If no registered class is found with a matching category,
// this returns GDataFeedBase for feed elements, GDataEntryBase
// for entry elements.
+ (Class)objectClassForXMLElement:(NSXMLElement *)element {

  Class result = nil;
  NSString *elementName = [element localName];
  BOOL isFeed = [elementName isEqual:@"feed"];
  BOOL isEntry = [elementName isEqual:@"entry"];

  if (isFeed || isEntry) {
    // get the kind attribute, and see if it matches a registered feed or entry
    // class
    NSXMLNode *kindAttr = [element attributeForLocalName:@"kind"
                                                     URI:kGDataNamespaceGData];
    NSString *kind = [kindAttr stringValue];

    if (kind) {
      if (isFeed) {
        result = [GDataFeedBase feedClassForKindAttributeValue:kind];
      } else {
        result = [GDataEntryBase entryClassForKindAttributeValue:kind];
      }
    }

    if (result == nil) {
      // step through the feed or entry's category elements, looking for one
      // that matches a registered feed or entry class
      //
      // category elements look like <category scheme="blah" term="blahblah"/>
      // and there may be more than one

      NSArray *categories = [element elementsForLocalName:@"category"
                                                      URI:kGDataNamespaceAtom];
      if ([categories count] == 0) {
        NSString *atomPrefix = [element resolvePrefixForNamespaceURI:kGDataNamespaceAtom];
        if ([atomPrefix length] == 0) {
          categories = [element elementsForName:@"category"];
        }
      }

      for (NSXMLElement *categoryNode in categories) {

        NSString *scheme = [[categoryNode attributeForName:@"scheme"] stringValue];
        NSString *term = [[categoryNode attributeForName:@"term"] stringValue];

        if (scheme || term) {
          // we have a scheme or a term, so look for a registered class
          if (isFeed) {
            result = [GDataFeedBase feedClassForCategoryWithScheme:scheme
                                                              term:term];
          } else {
            result = [GDataEntryBase entryClassForCategoryWithScheme:scheme
                                                                    term:term];
          }
          if (result) {
            break;
          }
        }
      }
    }
  }

  if (result == nil) {
    if (isFeed) {
      // default to returning a feed base class
      result = [GDataFeedBase class];
    } else if (isEntry) {
      // default to returning this feed's entry base class
      if ([self isSubclassOfClass:[GDataFeedBase class]]) {
        result = (Class)[self performSelector:@selector(defaultClassForEntries)];
      } else {
        result = [GDataEntryBase class];
      }
    } else if ([elementName isEqual:@"service"]) {
      // introspection - return service document, if the class is available
      NSString *serviceDocClassName = @"GDataAtomServiceDocument";

  #ifdef GDATA_TARGET_NAMESPACE
      // prepend the class name prefix
      serviceDocClassName = [NSString stringWithFormat:@"%s_%@",
                            GDATA_TARGET_NAMESPACE_STRING, serviceDocClassName];
  #endif

      result = NSClassFromString(serviceDocClassName);

      GDATA_DEBUG_ASSERT(result != nil, @"service class %@ unavailable",
                         serviceDocClassName);
    } else {
      // this element is not a feed, entry, or service class; give up
    }
  }

  return result;
}

@end

@implementation NSXMLElement (GDataObjectExtensions)

- (void)addStringValue:(NSString *)str {
  // NSXMLNode's setStringValue: wipes out other children, so we'll use this
  // instead

  // filter out non-whitespace control characters
  NSString *filtered = [GDataUtilities stringWithControlsFilteredForString:str];

  NSXMLNode *strNode = [NSXMLNode textWithStringValue:filtered];
  [self addChild:strNode];
}

+ (id)elementWithName:(NSString *)name attributeName:(NSString *)attrName attributeValue:(NSString *)attrValue {

  NSString *filtered = [GDataUtilities stringWithControlsFilteredForString:attrValue];

  NSXMLNode *attr = [NSXMLNode attributeWithName:attrName stringValue:filtered];
  NSXMLElement *element = [NSXMLNode elementWithName:name];
  [element addAttribute:attr];
  return element;
}

@end

@implementation GDataExtensionDeclaration

- (id)initWithParentClass:(Class)parentClass
               childClass:(Class)childClass
              isAttribute:(BOOL)isAttribute {
  self = [super init];
  if (self) {
    parentClass_ = parentClass;
    childClass_ = childClass;
    isAttribute_ = isAttribute;
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@: {%@ can contain %@}%@",
    [self class], parentClass_, childClass_,
          isAttribute_ ? @" (attribute)" : @""];
}

- (Class)parentClass {
  return parentClass_;
}

- (Class)childClass {
  return childClass_;
}

- (BOOL)isAttribute {
  return isAttribute_;
}

- (BOOL)isEqual:(GDataExtensionDeclaration *)other {
  if (self == other) return YES;
  if (![other isKindOfClass:[GDataExtensionDeclaration class]]) return NO;

  return AreEqualOrBothNil((id)[self parentClass], (id)[other parentClass])
    && AreEqualOrBothNil((id)[self childClass], (id)[other childClass])
    && [self isAttribute] == [other isAttribute];
}

- (NSUInteger)hash {
  return (NSUInteger) (void *) [GDataExtensionDeclaration class];
}

@end

@implementation GDataAttribute

// This is the base class for attribute extensions.
//
// Functionally, this just stores a string value for the attribute.

+ (GDataAttribute *)attributeWithValue:(NSString *)str {
  return [[[self alloc] initWithValue:str] autorelease];
}

- (id)initWithValue:(NSString *)value {
  self = [super init];
  if (self) {
    [self setStringValue:value];
  }
  return self;
}

- (void)dealloc {
  [value_ release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
  GDataAttribute* newObj = [[[self class] allocWithZone:zone] init];
  [newObj setStringValue:[self stringValue]];
  return newObj;
}

- (NSString *)description {

  NSString *name;

  NSString *localName = [[self class] extensionElementLocalName];
  NSString *prefix = [[self class] extensionElementPrefix];
  if (prefix) {
    name = [NSString stringWithFormat:@"%@:%@", prefix, localName];
  } else {
    name = localName;
  }

  return [NSString stringWithFormat:@"%@ %p: {%@=%@}",
          [self class], self, name, [self stringValue]];
}

- (BOOL)isEqual:(GDataAttribute *)other {
  if (self == other) return YES;
  if (![other isKindOfClass:[GDataAttribute class]]) return NO;

  return AreEqualOrBothNil([self stringValue], [other stringValue]);
}

- (NSUInteger)hash {
  return (NSUInteger) (void *) [GDataAttribute class];
}

- (void)setStringValue:(NSString *)str {
  [value_ autorelease];
  value_ = [str copy];
}

- (NSString *)stringValue {
  return value_;
}

@end
