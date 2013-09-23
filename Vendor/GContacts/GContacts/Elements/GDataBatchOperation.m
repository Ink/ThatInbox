/* Copyright (c) 2007-2008 Google Inc.
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
//  GDataBatchOperation.m
//

#define GDATABATCH_DEFINE_GLOBALS 1
#import "GDataBatchOperation.h"

static NSString* const kTypeAttr = @"type";

@implementation GDataBatchOperation
// for batch operations, like
//  <batch:operation type="insert"/>

+ (NSString *)extensionElementURI       { return kGDataNamespaceBatch; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceBatchPrefix; }
+ (NSString *)extensionElementLocalName { return @"operation"; }

+ (GDataBatchOperation *)batchOperationWithType:(NSString *)type {
  GDataBatchOperation* obj = [self object];
  [obj setType:type];
  return obj;
}

- (void)addParseDeclarations {

  NSArray *attrs = [NSArray arrayWithObject:kTypeAttr];

  [self addLocalAttributeDeclarations:attrs];
}

- (NSString *)type {
  return [self stringValueForAttribute:kTypeAttr];
}

- (void)setType:(NSString *)str {
  [self setStringValue:str forAttribute:kTypeAttr];
}

@end

