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
//  GDataObject.h
//

// This is the base class for most objects in the Objective-C GData implementation.
// Objects should derive from GDataObject in order to support XML parsing and
// generation, and to support the extension model.

// Subclasses will typically implement:
//
// - (void)addExtensionDeclarations;  -- declaring extensions
// - (id)initWithXMLElement:(NSXMLElement *)element
//                   parent:(GDataObject *)parent;  -- parsing
// - (NSXMLElement *)XMLElement;  -- XML generation
//
// Subclasses should implement other typical NSObject methods, too:
//
// - (NSString *)description;
// - (id)copyWithZone:(NSZone *)zone; (be sure to call superclass)
// - (BOOL)isEqual:(GDataObject *)other; (be sure to call superclass)
// - (void)dealloc;
//
// Subclasses which may be used as extensions should implement the
// simple GDataExtension protocol.
//

//
// Parsing and XML generation
//
// Parsing is done in the subclass's -initWithXMLElement:parent: method.
//
// For each parsed GData XML element, GDataObject maintains lists of
// un-parsed attributes and children (unknownChildren_ and unknownAttributes_)
// as raw NSXMLNodes.  Subclasses MUST use the methods in this class's
// "parsing helpers" (below) to extract properties and elements during parsing;
// this ensures that the lists of unknown properties and children are
// accurate.  DO NOT parse using NSXMLElement methods.
//
// XML generation is done in the subclass's -XMLElement method.
// That method will call XMLElementWithExtensionsAndDefaultName to get
// a "starter" NSXMLElement, already decorated with extensions, to which
// the subclass can add its unique children and attributes, if any.
//
//
//
// The extension model
//
// Extensions enable elements to contain children about which the element
// may know no details.
//
// Typically, entries add extensions to themselves. For example, a Calendar
// entry declares it may contain a color:
//
//  [self addExtensionDeclarationForParentClass:[GDataEntryCalendar class]
//                                   childClass:[GDataColorProperty class]];
//
// This lets the base class handle much of the work of managing the child
// element.  The Calendar entry can still provide accessor methods to get
// to the extension by calling into the base class, as in
//
//  - (GDataColorProperty *)color {
//    return (GDataColorProperty *)
//               [self objectForExtensionClass:[GDataColorProperty class]];
//  }
//
//  - (void)setColor:(GDataColorProperty *)val {
//    [self setObject:val forExtensionClass:[GDataColorProperty class]];
//  }
//
// The real purpose of extensions is to allow elements to contain children
// they may not know about.  For example, a CalendarEventEntry declares
// that GDataLinks contained within the calendar event entry may contain
// GDataWebContent elements:
//
//  [self addExtensionDeclarationForParentClass:[GDataLink class]
//                                   childClass:[GDataWebContent class]];
//
// The CalendarEvent has extended GDataLinks without GDataLinks knowing or
// caring.  Because GDataLink derives from GDataObject, the GDataLink
// object will automatically parse and maintain and copy and compare
// the GDataWebContents contained within.
//


#import <Foundation/Foundation.h>

#import "GDataDefines.h"
#import "GDataUtilities.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATAOBJECT_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataNamespaceAtom          _INITIALIZE_AS(@"http://www.w3.org/2005/Atom");
_EXTERN NSString* const kGDataNamespaceAtomPrefix    _INITIALIZE_AS(@"atom");

_EXTERN NSString* const kGDataNamespaceAtomPub       _INITIALIZE_AS(@"http://www.w3.org/2007/app");
_EXTERN NSString* const kGDataNamespaceAtomPubPrefix _INITIALIZE_AS(@"app");

_EXTERN NSString* const kGDataNamespaceOpenSearch       _INITIALIZE_AS(@"http://a9.com/-/spec/opensearch/1.1/");
_EXTERN NSString* const kGDataNamespaceOpenSearchPrefix _INITIALIZE_AS(@"openSearch");

_EXTERN NSString* const kGDataNamespaceXHTML       _INITIALIZE_AS(@"http://www.w3.org/1999/xhtml");
_EXTERN NSString* const kGDataNamespaceXHTMLPrefix _INITIALIZE_AS(@"xh");

_EXTERN NSString* const kGDataNamespaceGData       _INITIALIZE_AS(@"http://schemas.google.com/g/2005");
_EXTERN NSString* const kGDataNamespaceGDataPrefix _INITIALIZE_AS(@"gd");

_EXTERN NSString* const kGDataNamespaceBatch       _INITIALIZE_AS(@"http://schemas.google.com/gdata/batch");
_EXTERN NSString* const kGDataNamespaceBatchPrefix _INITIALIZE_AS(@"batch");

#define GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(versionString) \
  GDATA_DEBUG_ASSERT([self isServiceVersionAtLeast:versionString], \
    @"%@ requires newer version", NSStringFromSelector(_cmd))

#define GDATA_DEBUG_ASSERT_MAX_SERVICE_VERSION(versionString) \
  GDATA_DEBUG_ASSERT([self isServiceVersionAtMost:versionString], \
    @"%@ deprecated under v%@", NSStringFromSelector(_cmd), [self serviceVersion])

#define GDATA_DEBUG_ASSERT_MIN_SERVICE_V2() \
  GDATA_DEBUG_ASSERT_MIN_SERVICE_VERSION(@"2.0")

@class GDataDateTime;
@class GDataCategory;

@protocol GDataExtension
+ (NSString *)extensionElementURI;
+ (NSString *)extensionElementPrefix;
+ (NSString *)extensionElementLocalName;
@end

// GDataAttribute is the base class for attribute extensions.
// It is *not* used for local attributes, which are simply stored in
// GDataObject' attributes_ dictionary.
//
// This returns nil for the attribute's URI and prefix qualifier;
// subclasses must declare at least a local name.
//
// Functionally, this just stores a string value for the attribute.

@interface GDataAttribute : NSObject {
 @private
    NSString *value_;
}
+ (GDataAttribute *)attributeWithValue:(NSString *)str;
- (id)initWithValue:(NSString *)value;

- (void)setStringValue:(NSString *)str;
- (NSString *)stringValue;
@end

// GDataDescriptionRecords are used for describing how the elements
// and attributes of a GDataObject should be reported when -description
// is called.

typedef enum GDataDescRecTypes {
  kGDataDescValueLabeled = 1,
  kGDataDescLabelIfNonNil,
  kGDataDescArrayCount,
  kGDataDescArrayDescs,
  kGDataDescBooleanLabeled,
  kGDataDescBooleanPresent,
  kGDataDescNonZeroLength,
  kGDataDescValueIsKeyPath
} GDataDescRecTypes;

typedef struct GDataDescriptionRecord {
  NSString GDATA_UNSAFE_UNRETAINED *label;
  NSString GDATA_UNSAFE_UNRETAINED *keyPath;
  GDataDescRecTypes reportType;
} GDataDescriptionRecord;


@interface GDataObject : NSObject <NSCopying> {

  @private

  // element name from original XML, used for later XML generation
  NSString *elementName_;

  GDataObject GDATA_UNSAFE_UNRETAINED *parent_;  // weak: parent in tree of GData objects

  // GDataObjects keep namespaces as {key:prefix value:URI} dictionary entries
  NSMutableDictionary *namespaces_;

  // extension declaration cache, retained by the topmost parent
  //
  // keys are classes that have declared their extensions
  //
  // the values are dictionaries mapping declared parent classes to
  // GDataExtensionDeclarations objects
  NSMutableDictionary *extensionDeclarationsCache_;

  // list of attributes to be parsed for each class
  NSMutableDictionary *attributeDeclarationsCache_;

  // list of attributes to be parsed for this class (points strongly into the
  // attribute declarations cache)
  NSMutableArray *attributeDeclarations_;

  // arrays of actual extension elements found for this element, keyed by extension class
  NSMutableDictionary *extensions_;

  // dictionary of attributes set for this element, keyed by attribute name
  NSMutableDictionary *attributes_;

  // string for element body, if declared as parseable
  NSString *contentValue_;

  // XMLElements saved from element body but not parsed, if declared by the subclass
  NSMutableArray *childXMLElements_;

  // arrays of XMLNodes of attributes and child elements not yet parsed
  NSMutableArray *unknownChildren_;
  NSMutableArray *unknownAttributes_;
  BOOL shouldIgnoreUnknowns_;

  // mapping of standard classes to user's surrogate subclasses, used when
  // creating objects from XML
  NSDictionary *surrogates_;

  // service version, set for feeds and entries
  NSString *serviceVersion_;

  // core protocol version, set from the service version when
  // -coreProtocolVersion is invoked
  NSString *coreProtocolVersion_;

  // anything defined by the client; retained but not used internally; not
  // copied by copyWithZone:
  id userData_;
  NSMutableDictionary *userProperties_;
}

///////////////////////////////////////////////////////////////////////////////
//
// Public methods
//
// These methods are intended for users of the library
//

+ (id)object;

- (id)copyWithZone:(NSZone *)zone;

- (id)initWithServiceVersion:(NSString *)serviceVersion;

- (id)initWithXMLElement:(NSXMLElement *)element
                  parent:(GDataObject *)parent; // subclasses must override
- (NSXMLElement *)XMLElement; // subclasses must override

- (NSXMLDocument *)XMLDocument; // returns this XMLElement wrapped in an NSXMLDocument

// setters/getters

// namespaces here are a dictionary mapping prefix to URI; they are not
// NSXML namespace objects
- (void)setNamespaces:(NSDictionary *)namespaces;
- (void)addNamespaces:(NSDictionary *)namespaces;
- (NSDictionary *)namespaces;

// return a dictionary containing all namespaces
// in this object and its parent objects
- (NSDictionary *)completeNamespaces;

// if a prefix is explicitly defined the same for a parent as it is locally,
// remove it, since we can rely on the parent's definition
- (void)pruneInheritedNamespaces;

// name from original XML; this will be used during XML generation
- (void)setElementName:(NSString *)elementName;
- (NSString *)elementName;

// parent in object tree (weak reference)
- (void)setParent:(GDataObject *)obj;
- (GDataObject *)parent;

// surrogate lists for when alloc'ing classes from XML
- (void)setSurrogates:(NSDictionary *)surrogates;
- (NSDictionary *)surrogates;

// service API version
+ (NSString *)defaultServiceVersion;

// a side-effect of setServiceVersion: is that the coreProtocolVersion is
// reset
- (void)setServiceVersion:(NSString *)str;
- (NSString *)serviceVersion;

- (BOOL)isServiceVersionAtLeast:(NSString *)otherVersion;
- (BOOL)isServiceVersionAtMost:(NSString *)otherVersion;

// calling -coreProtocolVersion sets the initial core protocol version based
// on the service version
- (NSString *)coreProtocolVersion;
- (void)setCoreProtocolVersion:(NSString *)str;
- (BOOL)isCoreProtocolVersion1;

// userData is available for client use; retained by GDataObject, but not
// copied by the copyWithZone
- (void)setUserData:(id)obj;
- (id)userData;

// properties are supported for client convenience, but are not copied by
// copyWithZone.  Properties keys beginning with _ are reserved by the library.
- (void)setProperties:(NSDictionary *)dict;
- (NSDictionary *)properties;

- (void)setProperty:(id)obj forKey:(NSString *)key; // pass nil obj to remove property
- (id)propertyForKey:(NSString *)key;

// XMLNode children not parsed; primarily for internal use by the framework
- (void)setUnknownChildren:(NSArray *)arr;
- (NSArray *)unknownChildren;

// XMLNode attributes not parsed; primarily for internal use by the framework
- (void)setUnknownAttributes:(NSArray *)arr;
- (NSArray *)unknownAttributes;

// feeds and their elements may exclude tracking of unknown child elements
// and unknown attributes; see GDataServiceBase for more information
- (void)setShouldIgnoreUnknowns:(BOOL)flag;
- (BOOL)shouldIgnoreUnknowns;

///////////////////////////////////////////////////////////////////////////////
//
//  Protected methods
//
//  All remaining methods are intended for use only by subclasses
//  of GDataObject.
//

// this init method should  be used only when creating the base of a tree
// containing surrogates (the surrogate map is a dictionary of
// standard GDataObject classes to replacement subclasses); this method
// calls through to [self initWithXMLElement:parent:]
- (id)initWithXMLElement:(NSXMLElement *)element
                  parent:(GDataObject *)parent
          serviceVersion:(NSString *)serviceVersion
              surrogates:(NSDictionary *)surrogates
    shouldIgnoreUnknowns:(BOOL)shouldIgnoreUnknowns;

- (void)addExtensionDeclarations; // subclasses may override this to declare extensions

- (void)addParseDeclarations; // subclasses may override this to declare local attributes and content value

- (void)clearExtensionDeclarationsCache; // used by GDataServiceBase and by subclasses

// content stream and upload data: these always return NO/nil for objects
// other than entries

- (BOOL)generateContentInputStream:(NSInputStream **)outInputStream
                            length:(unsigned long long *)outLength
                           headers:(NSDictionary **)outHeaders;

- (NSString *)uploadMIMEType;
- (NSData *)uploadData;
- (NSFileHandle *)uploadFileHandle;
- (NSURL *)uploadLocationURL;
- (BOOL)shouldUploadDataOnly;

//
// Extensions
//

// declaring a potential extension; applies to this object and its children
- (void)addExtensionDeclarationForParentClass:(Class)parentClass
                                   childClass:(Class)childClass;
- (void)addExtensionDeclarationForParentClass:(Class)parentClass
                                 childClasses:(Class)firstChildClass, ...;

- (void)removeExtensionDeclarationForParentClass:(Class)parentClass
                                      childClass:(Class)childClass;

- (void)addAttributeExtensionDeclarationForParentClass:(Class)parentClass
                                            childClass:(Class)childClass;
- (void)removeAttributeExtensionDeclarationForParentClass:(Class)parentClass
                                               childClass:(Class)childClass;

// accessing actual extensions in this object
- (NSArray *)objectsForExtensionClass:(Class)theClass;
- (id)objectForExtensionClass:(Class)theClass;

- (NSString *)attributeValueForExtensionClass:(Class)theClass;

// replacing or adding actual extensions in this object
- (void)setObjects:(NSArray *)objects forExtensionClass:(Class)theClass;
- (void)setObject:(id)object forExtensionClass:(Class)theClass; // removes all previous objects for this class
- (void)addObject:(id)object forExtensionClass:(Class)theClass;
- (void)removeObject:(id)object forExtensionClass:(Class)theClass;

- (void)setAttributeValue:(NSString *)str forExtensionClass:(Class)theClass;

//
// Local attributes
//

// derived classes may override parseAttributesForElement if they need to
// inspect attributes prior to parsing of element content
- (void)parseAttributesForElement:(NSXMLElement *)element;

// derived classes should call -addLocalAttributeDeclarations in their
// -addParseDeclarations method if they want element attributes to
// automatically be parsed
- (void)addLocalAttributeDeclarations:(NSArray *)attributeLocalNames;

- (NSString *)stringValueForAttribute:(NSString *)name;
- (NSNumber *)intNumberForAttribute:(NSString *)name;
- (NSNumber *)doubleNumberForAttribute:(NSString *)name;
- (NSNumber *)longLongNumberForAttribute:(NSString *)name;
- (NSDecimalNumber *)decimalNumberForAttribute:(NSString *)name;
- (GDataDateTime *)dateTimeForAttribute:(NSString *)name;
- (BOOL)boolValueForAttribute:(NSString *)name defaultValue:(BOOL)defaultVal;

// setting nil value for attribute removes it
- (void)setStringValue:(NSString *)str forAttribute:(NSString *)name;
- (void)setBoolValue:(BOOL)flag defaultValue:(BOOL)defaultVal forAttribute:(NSString *)name;
- (void)setExplicitBoolValue:(BOOL)flag forAttribute:(NSString *)name;
- (void)setDecimalNumberValue:(NSDecimalNumber *)num forAttribute:(NSString *)name;
- (void)setDateTimeValue:(GDataDateTime *)cdate forAttribute:(NSString *)name;

// dictionary of all local attributes actually found in the XML element
- (void)setAttributes:(NSDictionary *)dict;
- (NSDictionary *)attributes;


//
// Element Content Value
//

// derived classes should call -addContentValueDeclaration in their
// -addParseDeclarations method if they want element content to
// automatically be parsed as a string
- (void)addContentValueDeclaration;
- (BOOL)hasDeclaredContentValue;
- (void)setContentStringValue:(NSString *)str;
- (NSString *)contentStringValue;

//
// Unparsed XML child elements
//

// derived classes should call -addXMLValuesDeclaration in their
// -addParseDeclarations method if they want all child elements to
// be held as an array of NSXMLElements
- (void)addChildXMLElementsDeclaration;
- (BOOL)hasDeclaredChildXMLElements;
- (NSArray *)childXMLElements;
- (void)setChildXMLElements:(NSArray *)array;
- (void)addChildXMLElement:(NSXMLNode *)node;


//
// Dynamic GDataObject generation
//
// Feeds and entries can register themselves in their + (void)load
// methods.  When XML is being parsed, if a matching category
// is found, the proper class is instantiated.
//
// The scheme or term in a category may be nil (during
// registration and lookup) to match any values.

// class registration method
+ (void)registerClass:(Class)theClass
                inMap:(NSMutableDictionary **)map
forCategoryWithScheme:(NSString *)scheme
                 term:(NSString *)term;

+ (Class)classForCategoryWithScheme:(NSString *)scheme
                               term:(NSString *)term
                            fromMap:(NSDictionary *)map;

// objectClassForXMLElement: returns a found registered feed
// or entry class for the XML according to its contained category
//
// If no registered class is found with a matching category,
// this returns GDataFeedBase for feed elements, GDataEntryBase
// for entry elements.
//
// If the element is not a <feed> or <entry> then nil is returned
+ (Class)objectClassForXMLElement:(NSXMLElement *)element;

//
// XML parsing helpers (used in initWithXMLElement:parent:)
//
// Use these parsing helpers, since they remove the parsed items from the
// "unknown children" list for this object.
//

// this creates a single object of the specified class for the first XML child
// element with the specified name. Returns nil if no child element is present.
- (id)objectForChildOfElement:(NSXMLElement *)parentElement
                qualifiedName:(NSString *)qualifiedName
                 namespaceURI:(NSString *)namespaceURI
                  objectClass:(Class)objectClass;

// this creates an array of objects of the specified class for each XML child
// element with the specified name
- (id)objectOrArrayForChildrenOfElement:(NSXMLElement *)parentElement
                          qualifiedName:(NSString *)qualifiedName
                           namespaceURI:(NSString *)namespaceURI
                            objectClass:(Class)objectClass;

// childOfElement:withName returns the element with the name, or nil of there
// are not exactly one of the element
- (NSXMLElement *)childWithQualifiedName:(NSString *)localName
                            namespaceURI:(NSString *)namespaceURI
                             fromElement:(NSXMLElement *)parentElement;

// searches up the parent tree to find a surrogate for the standard class;
// if there is  no surrogate, returns the standard class itself
- (Class)classOrSurrogateForClass:(Class)standardClass;

// element parsing

+ (NSDictionary *)dictionaryForElementNamespaces:(NSXMLElement *)element;

// this method avoids the "recursive descent" behavior of NSXMLElement's
// stringValue; the element parameter may be nil
- (NSString *)stringValueFromElement:(NSXMLElement *)element;

- (GDataDateTime *)dateTimeFromElement:(NSXMLElement *)element;

- (NSNumber *)intNumberValueFromElement:(NSXMLElement *)element;

- (NSNumber *)doubleNumberValueFromElement:(NSXMLElement *)element;

// attribute parsing
- (NSString *)stringForAttributeName:(NSString *)attributeName
                         fromElement:(NSXMLElement *)element;

- (NSString *)stringForAttributeLocalName:(NSString *)localName
                                      URI:(NSString *)attributeURI
                              fromElement:(NSXMLElement *)element;

- (GDataDateTime *)dateTimeForAttributeName:(NSString *)attributeName
                                fromElement:(NSXMLElement *)element;

- (NSXMLNode *)attributeForName:(NSString *)attributeName
                    fromElement:(NSXMLElement *)element;

- (BOOL)boolForAttributeName:(NSString *)attributeName
                 fromElement:(NSXMLElement *)element;

- (NSNumber *)doubleNumberForAttributeName:(NSString *)attributeName
                               fromElement:(NSXMLElement *)element;

- (NSNumber *)intNumberForAttributeName:(NSString *)attributeName
                            fromElement:(NSXMLElement *)element;


//
// XML generation helpers
//

// subclasses start their -XMLElement method by calling this
- (NSXMLElement *)XMLElementWithExtensionsAndDefaultName:(NSString *)defaultName;

// adding attributes
- (NSXMLNode *)addToElement:(NSXMLElement *)element
     attributeValueIfNonNil:(NSString *)val
                   withName:(NSString *)name;

- (NSXMLNode *)addToElement:(NSXMLElement *)element
     attributeValueIfNonNil:(NSString *)val
          withQualifiedName:(NSString *)qName
                        URI:(NSString *)attributeURI;

- (NSXMLNode *)addToElement:(NSXMLElement *)element
  attributeValueWithInteger:(NSInteger)val
                   withName:(NSString *)name;

// adding child elements
- (NSXMLNode *)addToElement:(NSXMLElement *)element
childWithStringValueIfNonEmpty:(NSString *)str
                   withName:(NSString *)name;

- (void)addToElement:(NSXMLElement *)element
 XMLElementForObject:(id)object;

- (void)addToElement:(NSXMLElement *)element
 XMLElementsForArray:(NSArray *)arrayOfGDataObjects;

//
// decription method helpers
//

// the final descRecord in the list should be { nil, nil, 0 }
- (void)addDescriptionRecords:(GDataDescriptionRecord *)descRecordList
                      toItems:(NSMutableArray *)items;

- (void)addToArray:(NSMutableArray *)stringItems
objectDescriptionIfNonNil:(id)obj
          withName:(NSString *)name;

- (void)addAttributeDescriptionsToArray:(NSMutableArray *)stringItems;

- (void)addContentDescriptionToArray:(NSMutableArray *)stringItems
                            withName:(NSString *)name;

// optional methods for overriding
//
// subclasses may implement -itemsForDescription and add to or
// replace the superclass's array of items
//
// The base class itemsForDescription provides items for local attributes and
// content, but not for any element extensions or attribute extensions
- (NSMutableArray *)itemsForDescription;
- (NSString *)descriptionWithItems:(NSArray *)items;
- (NSString *)description;

// coreProtocolVersionForServiceVersion maps the service version to the
// underlying core protocol version.  The default implementation returns
// the service version as the core protocol version.
//
// Entry and feed subclasses will need to implement this if their service
// version numbers deviate from the core protocol version numbers.
+ (NSString *)coreProtocolVersionForServiceVersion:(NSString *)str;

@end

@interface NSXMLElement (GDataObjectExtensions)

// XML generation helpers

// NSXMLNode's setStringValue: wipes out other children, so we'll use this
// instead
- (void)addStringValue:(NSString *)str;

// creating objects from child elements
+ (id)elementWithName:(NSString *)name attributeName:(NSString *)attrName attributeValue:(NSString *)attrValue;
@end
