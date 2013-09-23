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

#define GDATASERVERERROR_DEFINE_GLOBALS 1
#import "GDataServerError.h"

#import "GDataObject.h"   // for namespace
#import "GDataUtilities.h" // for AreEqualOrBothNil

//
// GDataServerErrorGroup
//

@interface GDataServerErrorGroup (PrivateMethods)
- (NSArray *)serverErrorsWithData:(NSData *)data;
@end

@implementation GDataServerErrorGroup

- (id)initWithData:(NSData *)data {

  self = [super init];
  if (self) {

    NSArray *errors = [self serverErrorsWithData:data];
    if (errors) {

      [self setErrors:errors];

    } else {
      // failed to parse errors
      [self release];
      return nil;
    }
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@ %p: {errors: %@}",
          [self class], self, [self errors]];
}

- (NSUInteger)hash {
  return (NSUInteger) (void *) [GDataServerErrorGroup class];
}

- (BOOL)isEqual:(GDataServerErrorGroup *)other {
  if (self == other) return YES;
  if (![other isKindOfClass:[GDataServerErrorGroup class]]) return NO;

  return AreEqualOrBothNil([self errors], [other errors]);
}

- (id)copyWithZone:(NSZone *)zone {
  GDataServerErrorGroup* newObj = [[[self class] allocWithZone:zone] init];

  NSArray *errorsCopy = [[[NSArray alloc] initWithArray:[self errors]
                                              copyItems:YES] autorelease];
  [newObj setErrors:errorsCopy];

  return newObj;
}

- (void)dealloc {
  [errors_ release];
  [super dealloc];
}

#pragma mark -

- (NSArray *)errors {
  return errors_;
}

- (void)setErrors:(NSArray *)array {
  [errors_ autorelease];
  errors_ = [array retain];
}

- (GDataServerError *)mainError {

  if ([errors_ count] > 0) {
    GDataServerError *obj = [errors_ objectAtIndex:0];
    return obj;
  }
  return nil;
}

#pragma mark -

// -serverErrorsWithData is used by the initFromData: method
//
// convert the data to an XML document, step through the <error> elements,
// and make each into a GDataServerError object
//
// returns nil if the data cannot be parsed or no error elements are found
//
// data is expected to look like:
//
//  <?xml version="1.0" ?>
//  <errors xmlns="http://schemas.google.com/g/2005">
//    <error>
//      <domain>GData</domain>
//      <code>invalidUri</code>
//      <internalReason>Badly formatted URI</internalReason>
//    </error>
//  </errors>

- (NSArray *)serverErrorsWithData:(NSData *)data {

  NSMutableArray *serverErrors = [NSMutableArray array];

  NSError *docError = nil;
  NSXMLDocument *xmlDoc;

  xmlDoc = [[[NSXMLDocument alloc] initWithData:data
                                        options:0
                                          error:&docError] autorelease];
  if (xmlDoc != nil) {

    // step through all <error> elements and make a GDataServerError instance
    // for each
    NSXMLElement *errorsElem = [xmlDoc rootElement];
    NSArray *errorElems = [errorsElem elementsForLocalName:@"error"
                                                       URI:kGDataNamespaceGData];

    for (NSXMLElement *errorElem in errorElems) {

      GDataServerError *serverError;

      serverError = [[[GDataServerError alloc] initWithXMLElement:errorElem] autorelease];

      if (serverError != nil) {
        [serverErrors addObject:serverError];
      }
    }

  }

  if ([serverErrors count] > 0) {
    return serverErrors;
  }

  // failed to parse, or found no errors
#if DEBUG
  NSString *errStr;
  errStr = [[[NSString alloc] initWithData:data
                                  encoding:NSUTF8StringEncoding] autorelease];
  NSLog(@"Could not parse error: %@\n  Error XML data: %@", docError, errStr);
#endif

  return nil;
}

@end

//
// GDataServerError
//

@interface GDataServerError (PrivateMethods)
+ (NSString *)errorStringForParentElement:(NSXMLElement *)parent
                                childName:(NSString *)childName;
@end

@implementation GDataServerError

- (id)initWithXMLElement:(NSXMLElement *)element {
  self = [super init];
  if (self) {
    NSString *domain = [GDataServerError errorStringForParentElement:element
                                                           childName:@"domain"];
    [self setDomain:domain];

    NSString *code = [GDataServerError errorStringForParentElement:element
                                                         childName:@"code"];
    [self setCode:code];

    NSString *reason = [GDataServerError errorStringForParentElement:element
                                                           childName:@"internalReason"];
    [self setInternalReason:reason];

    NSString *help = [GDataServerError errorStringForParentElement:element
                                                         childName:@"extendedHelp"];
    [self setExtendedHelpURI:help];

    NSString *report = [GDataServerError errorStringForParentElement:element
                                                           childName:@"sendReport"];
    [self setSendReportURI:report];
  }
  return self;
}

- (NSString *)description {
  NSMutableArray *arr = [NSMutableArray array];

  if (domain_) {
    [arr addObject:[NSString stringWithFormat:@"domain=\"%@\"", domain_]];
  }
  if (code_) {
    [arr addObject:[NSString stringWithFormat:@"code=\"%@\"", code_]];
  }
  if (internalReason_) {
    [arr addObject:[NSString stringWithFormat:@"reason=\"%@\"", internalReason_]];
  }
  if (extendedHelpURI_) {
    [arr addObject:[NSString stringWithFormat:@"help=\"%@\"", extendedHelpURI_]];
  }
  if (sendReportURI_) {
    [arr addObject:[NSString stringWithFormat:@"report=\"%@\"", sendReportURI_]];
  }
  NSString *str = [arr componentsJoinedByString:@" "];

  return [NSString stringWithFormat:@"%@ %p: {%@}", [self class], self, str];
}

- (NSUInteger)hash {
  return (NSUInteger) (void *) [GDataServerError class];
}

- (BOOL)isEqual:(GDataServerError *)other {
  if (self == other) return YES;
  if (![other isKindOfClass:[GDataServerError class]]) return NO;

  return AreEqualOrBothNil([self domain], [other domain])
    && AreEqualOrBothNil([self code], [other code])
    && AreEqualOrBothNil([self internalReason], [other internalReason])
    && AreEqualOrBothNil([self extendedHelpURI], [other extendedHelpURI])
    && AreEqualOrBothNil([self sendReportURI], [other sendReportURI]);
}

- (id)copyWithZone:(NSZone *)zone {
  GDataServerError* newObj = [[[self class] allocWithZone:zone] init];

  [newObj setDomain:[self domain]];
  [newObj setCode:[self code]];
  [newObj setInternalReason:[self internalReason]];
  [newObj setExtendedHelpURI:[self extendedHelpURI]];
  [newObj setSendReportURI:[self sendReportURI]];

  return newObj;
}

- (void)dealloc {
  [domain_ release];
  [code_ release];
  [internalReason_ release];
  [extendedHelpURI_ release];
  [sendReportURI_ release];
  [super dealloc];
}

#pragma mark -

- (NSString *)summary {

  NSString *summary;

  NSString *domain = [self domain];
  NSString *code = [self code];
  NSString *internalReason = [self internalReason];

  if ([internalReason length] > 0) {
    summary = [NSString stringWithFormat:@"%@ error %@: \"%@\"",
               domain, code, internalReason];
  } else {
    summary = [NSString stringWithFormat:@"%@ error %@", domain, code];
  }
  return summary;
}

#pragma mark -

- (NSString *)domain {
  return domain_;
}

- (void)setDomain:(NSString *)str {
  [domain_ autorelease];
  domain_ = [str copy];
}

- (NSString *)code {
  return code_;
}

- (void)setCode:(NSString *)str {
  [code_ autorelease];
  code_ = [str copy];
}

- (NSString *)internalReason {
  return internalReason_;
}

- (void)setInternalReason:(NSString *)str {
  [internalReason_ autorelease];
  internalReason_ = [str copy];
}

- (NSString *)extendedHelpURI {
  return extendedHelpURI_;
}

- (void)setExtendedHelpURI:(NSString *)str {
  [extendedHelpURI_ autorelease];
  extendedHelpURI_ = [str copy];
}

- (NSString *)sendReportURI {
  return sendReportURI_;
}

- (void)setSendReportURI:(NSString *)str {
  [sendReportURI_ autorelease];
  sendReportURI_ = [str copy];
}

#pragma mark -

// internal utility routine to get the string value of the named child element,
// assuming the GData namespace
+ (NSString *)errorStringForParentElement:(NSXMLElement *)parent
                                childName:(NSString *)childName {

  NSArray *array = [parent elementsForLocalName:childName
                                            URI:kGDataNamespaceGData];
  if ([array count] > 0) {
    NSXMLElement *elem = [array objectAtIndex:0];
    NSString *str = [elem stringValue];
    return str;
  }
  return nil;
}

@end

