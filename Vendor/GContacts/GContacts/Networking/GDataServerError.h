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
// GDataServerError.h
//
// Wrapper around the list of structured errors returned by GData servers
//
// See also the Java library's ErrorDomain.java, ServiceException.java, and
// CoreErrorDomain.java
//

#import <Foundation/Foundation.h>

#import "GDataDefines.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATASERVERERROR_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataErrorDomainCore _INITIALIZE_AS(@"GData");


@class GDataServerError;

//
// GDataServerErrorGroup represents an array of error objects
//

@interface GDataServerErrorGroup : NSObject {
  NSArray *errors_;
}

- (id)initWithData:(NSData *)data;

- (NSArray *)errors;
- (void)setErrors:(NSArray *)array;

- (GDataServerError *)mainError;

@end

//
// GDataServerError
//

@interface GDataServerError : NSObject {
  NSString *domain_;          // domain name
  NSString *code_;            // error name, unique within the domain
  NSString *internalReason_;  // internal server message
  NSString *extendedHelpURI_; // URI to additional help
  NSString *sendReportURI_;   // URI for sending a report
}

- (id)initWithXMLElement:(NSXMLElement *)element;

// summary is a minimally user-readable summary of the domain, code, and
// reason
- (NSString *)summary;

- (NSString *)domain;
- (void)setDomain:(NSString *)str;

- (NSString *)code;
- (void)setCode:(NSString *)str;

- (NSString *)internalReason;
- (void)setInternalReason:(NSString *)str;

- (NSString *)extendedHelpURI;
- (void)setExtendedHelpURI:(NSString *)str;

- (NSString *)sendReportURI;
- (void)setSendReportURI:(NSString *)str;

@end
