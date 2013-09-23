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
// GDataDefines.h
//

// Ensure Apple's conditionals we depend on are defined.
#import <TargetConditionals.h>
#import <AvailabilityMacros.h>

//
// The developer may choose to define these in the project:
//
//   #define GDATA_TARGET_NAMESPACE Xxx  // preface all GData class names with Xxx (recommended for building plug-ins)
//   #define GDATA_FOUNDATION_ONLY 1     // builds without AppKit or Carbon (default for iPhone builds)
//   #define GDATA_SIMPLE_DESCRIPTIONS 1 // remove elaborate -description methods, reducing code size (default for iPhone release builds)
//   #define STRIP_GDATA_FETCH_LOGGING 1 // omit http logging code (default for iPhone release builds)
//
// Mac developers may find GDATA_SIMPLE_DESCRIPTIONS and STRIP_GDATA_FETCH_LOGGING useful for
// reducing code size.
//

// Define later OS versions when building on earlier versions
#ifdef MAC_OS_X_VERSION_10_0
  #ifndef MAC_OS_X_VERSION_10_6
    #define MAC_OS_X_VERSION_10_6 1060
  #endif
#endif


#ifdef GDATA_TARGET_NAMESPACE
// prefix all GData class names with GDATA_TARGET_NAMESPACE for this target
  #import "GDataTargetNamespace.h"
#endif

// Provide a common definition for externing constants/functions
#if defined(__cplusplus)
#define GDATA_EXTERN extern "C"
#else
#define GDATA_EXTERN extern
#endif

#if TARGET_OS_IPHONE // iPhone SDK

  #define GDATA_IPHONE 1

#endif

#if GDATA_IPHONE

  #define GDATA_FOUNDATION_ONLY 1

  #define GDATA_USES_LIBXML 1

  #import "GDataXMLNode.h"

  #define NSXMLDocument                  GDataXMLDocument
  #define NSXMLElement                   GDataXMLElement
  #define NSXMLNode                      GDataXMLNode
  #define NSXMLNodeKind                  GDataXMLNodeKind
  #define NSXMLInvalidKind               GDataXMLInvalidKind
  #define NSXMLDocumentKind              GDataXMLDocumentKind
  #define NSXMLElementKind               GDataXMLElementKind
  #define NSXMLAttributeKind             GDataXMLAttributeKind
  #define NSXMLNamespaceKind             GDataXMLNamespaceKind
  #define NSXMLProcessingInstructionKind GDataXMLDocumentKind
  #define NSXMLCommentKind               GDataXMLCommentKind
  #define NSXMLTextKind                  GDataXMLTextKind
  #define NSXMLDTDKind                   GDataXMLDTDKind
  #define NSXMLEntityDeclarationKind     GDataXMLEntityDeclarationKind
  #define NSXMLAttributeDeclarationKind  GDataXMLAttributeDeclarationKind
  #define NSXMLElementDeclarationKind    GDataXMLElementDeclarationKind
  #define NSXMLNotationDeclarationKind   GDataXMLNotationDeclarationKind

  // properties used for retaining the XML tree in the classes that use them
  #define kGDataXMLDocumentPropertyKey @"_XMLDocument"
  #define kGDataXMLElementPropertyKey  @"_XMLElement"
#endif

//
// GDATA_ASSERT is like NSAssert, but takes a variable number of arguments:
//
//     GDATA_ASSERT(condition, @"Problem in argument %@", argStr);
//
// GDATA_DEBUG_ASSERT is similar, but compiles in only for debug builds
//

#ifndef GDATA_ASSERT
  // we directly invoke the NSAssert handler so we can pass on the varargs
  #if !defined(NS_BLOCK_ASSERTIONS)
    #define GDATA_ASSERT(condition, ...)                                       \
      do {                                                                     \
        if (!(condition)) {                                                    \
          [[NSAssertionHandler currentHandler]                                 \
              handleFailureInFunction:[NSString stringWithUTF8String:__PRETTY_FUNCTION__] \
                                 file:[NSString stringWithUTF8String:__FILE__] \
                           lineNumber:__LINE__                                 \
                          description:__VA_ARGS__];                            \
        }                                                                      \
      } while(0)
  #else
    #define GDATA_ASSERT(condition, ...) do { } while (0)
  #endif // !defined(NS_BLOCK_ASSERTIONS)
#endif // GDATA_ASSERT

#ifndef GDATA_DEBUG_ASSERT
  #if DEBUG
    #define GDATA_DEBUG_ASSERT(condition, ...) GDATA_ASSERT(condition, __VA_ARGS__)
  #else
    #define GDATA_DEBUG_ASSERT(condition, ...) do { } while (0)
  #endif
#endif

#ifndef GDATA_DEBUG_LOG
  #if DEBUG
    #define GDATA_DEBUG_LOG(...) NSLog(__VA_ARGS__)
  #else
    #define GDATA_DEBUG_LOG(...) do { } while (0)
  #endif
#endif

//
// Simple macros to allow building headers for non-ARC files
// into ARC apps
//

#ifndef GDATA_REQUIRES_ARC
  #if defined(__clang__)
    #if __has_feature(objc_arc)
      #define GDATA_REQUIRES_ARC 1
    #endif
  #endif
#endif

#if GDATA_REQUIRES_ARC
  #define GDATA_UNSAFE_UNRETAINED __unsafe_unretained
#else
  #define GDATA_UNSAFE_UNRETAINED
#endif

//
// To reduce code size on iPhone release builds, we compile out the helpful
// description methods for GData objects
//
#ifndef GDATA_SIMPLE_DESCRIPTIONS
  #if GDATA_IPHONE && !DEBUG
    #define GDATA_SIMPLE_DESCRIPTIONS 1
  #else
    #define GDATA_SIMPLE_DESCRIPTIONS 0
  #endif
#endif

#ifndef STRIP_GDATA_FETCH_LOGGING
  #if GDATA_IPHONE && !DEBUG
    #define STRIP_GDATA_FETCH_LOGGING 1
  #else
    #define STRIP_GDATA_FETCH_LOGGING 0
  #endif
#endif
