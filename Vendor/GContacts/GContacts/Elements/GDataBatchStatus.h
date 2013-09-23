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
//  GDataBatchStatus.h
//

#import "GDataObject.h"

@class GDataFeedBase;

// a batch response status
//  <batch:status  code="404"
//    reason="Bad request"
//    content-type="application/xml">
//    <errors>
//      <error type="request" reason="Cannot find item"/>
//    </errors>
//  </batch:status>

@interface GDataBatchStatus : GDataObject <GDataExtension> {
}

+ (GDataBatchStatus *)batchStatusWithCode:(NSInteger)code
                                   reason:(NSString *)reason;

- (NSString *)reason;
- (void)setReason:(NSString *)str;

- (NSNumber *)code;
- (void)setCode:(NSNumber *)val;

- (NSString *)contentType;
- (void)setContentType:(NSString *)str;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;

@end
