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
//  GDataBatchInterrupted.h
//

#import "GDataObject.h"


// for batch Interrupteds, like
//  <batch:interrupted reason="reason" success="N" failures="N" parsed="N" />

@interface GDataBatchInterrupted : GDataObject <GDataExtension> {
}

+ (GDataBatchInterrupted *)batchInterrupted;

- (NSString *)reason;
- (void)setReason:(NSString *)str;

- (NSNumber *)successCount;
- (void)setSuccessCount:(NSNumber *)val;

- (NSNumber *)errorCount;
- (void)setErrorCount:(NSNumber *)val;

- (NSNumber *)totalCount;
- (void)setTotalCount:(NSNumber *)val;

- (NSString *)contentType;
- (void)setContentType:(NSString *)str;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;
@end
