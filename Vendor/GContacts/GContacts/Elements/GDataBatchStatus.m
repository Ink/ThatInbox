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
//  GDataBatchStatus.m
//


#import "GDataBatchStatus.h"

static NSString *const kCodeAttr = @"code";
static NSString *const kReasonAttr = @"reason";
static NSString *const kContentTypeAttr = @"content-type";


@implementation GDataBatchStatus
// a batch response status
//  <batch:status  code="404"
//    reason="Bad request"
//    content-type="application/xml">
//    <errors>
//      <error type="request" reason="Cannot find item"/>
//    </errors>
//  </batch:status>

+ (NSString *)extensionElementURI       { return kGDataNamespaceBatch; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceBatchPrefix; }
+ (NSString *)extensionElementLocalName { return @"status"; }

- (void)addParseDeclarations {

  NSArray *attrs = [NSArray arrayWithObjects:
                    kCodeAttr, kReasonAttr, kContentTypeAttr, nil];

  [self addLocalAttributeDeclarations:attrs];

  [self addContentValueDeclaration];
}

+ (GDataBatchStatus *)batchStatusWithCode:(NSInteger)code
                                   reason:(NSString *)reason {
  GDataBatchStatus* obj = [self object];
  [obj setReason:reason];
  [obj setCode:[NSNumber numberWithInt:(int)code]];
  return obj;
}

- (NSString *)reason {
  return [self stringValueForAttribute:kReasonAttr];
}

- (void)setReason:(NSString *)str {
  [self setStringValue:str forAttribute:kReasonAttr];
}

- (NSNumber *)code {
  return [self intNumberForAttribute:kCodeAttr];
}

- (void)setCode:(NSNumber *)num {
  [self setStringValue:[num stringValue] forAttribute:kCodeAttr];
}

- (NSString *)contentType {
  return [self stringValueForAttribute:kContentTypeAttr];
}

- (void)setContentType:(NSString *)str {
  [self setStringValue:str forAttribute:kContentTypeAttr];
}

- (NSString *)stringValue {
  return [self contentStringValue];
}

- (void)setStringValue:(NSString *)str {
  [self setContentStringValue:str];
}

@end


