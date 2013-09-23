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
//  GDataBatchInterrupted.m
//

#import "GDataBatchInterrupted.h"

static NSString* const kReasonAttr = @"reason";
static NSString* const kSuccessAttr = @"success";
static NSString* const kFailuresAttr = @"failures";
static NSString* const kParsedAttr = @"parsed";
static NSString* const kContentTypeAttr = @"content-type";

@implementation GDataBatchInterrupted

// for batch Interrupteds, like
//  <batch:interrupted reason="reason" success="N" failures="N" parsed="N" />

+ (NSString *)extensionElementURI       { return kGDataNamespaceBatch; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceBatchPrefix; }
+ (NSString *)extensionElementLocalName { return @"interrupted"; }

+ (GDataBatchInterrupted *)batchInterrupted {
  GDataBatchInterrupted* obj = [self object];
  return obj;
}

- (void)addParseDeclarations {

  NSArray *attrs = [NSArray arrayWithObjects:
                    kReasonAttr, kSuccessAttr, kFailuresAttr, kParsedAttr,
                    kContentTypeAttr, nil];

  [self addLocalAttributeDeclarations:attrs];

  [self addContentValueDeclaration];
}

#if !GDATA_SIMPLE_DESCRIPTIONS
- (NSMutableArray *)itemsForDescription {
  NSMutableArray *items = [NSMutableArray array];

  [self addAttributeDescriptionsToArray:items];
  [self addContentDescriptionToArray:items withName:@"content"];

  return items;
}
#endif

- (NSString *)reason {
  return [self stringValueForAttribute:kReasonAttr];
}

- (void)setReason:(NSString *)str {
  [self setStringValue:str forAttribute:kReasonAttr];
}

- (NSNumber *)successCount {
  return [self intNumberForAttribute:kSuccessAttr];
}

- (void)setSuccessCount:(NSNumber *)val {
  [self setStringValue:[val stringValue] forAttribute:kSuccessAttr];
}

- (NSNumber *)errorCount {
  return [self intNumberForAttribute:kFailuresAttr];
}

- (void)setErrorCount:(NSNumber *)val {
  [self setStringValue:[val stringValue] forAttribute:kFailuresAttr];
}

- (NSNumber *)totalCount {
  return [self intNumberForAttribute:kParsedAttr];
}

- (void)setTotalCount:(NSNumber *)val {
  [self setStringValue:[val stringValue] forAttribute:kParsedAttr];
}

- (NSString *)contentType {
  return [self stringValueForAttribute:kContentTypeAttr];
}

- (void)setContentType:(NSString *)str {
  [self setStringValue:str forAttribute:kContentTypeAttr];
}

- (NSString *)stringValue {
  return [self contentStringValue];;
}

- (void)setStringValue:(NSString *)str {
  [self setContentStringValue:str];
}

@end

