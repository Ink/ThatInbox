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
//  GDataBatchOperation.h
//

#import "GDataObject.h"

#undef _EXTERN
#undef _INITIALIZE_AS
#ifdef GDATABATCH_DEFINE_GLOBALS
#define _EXTERN
#define _INITIALIZE_AS(x) =x
#else
#define _EXTERN GDATA_EXTERN
#define _INITIALIZE_AS(x)
#endif

_EXTERN NSString* const kGDataBatchOperationInsert _INITIALIZE_AS(@"insert");
_EXTERN NSString* const kGDataBatchOperationUpdate _INITIALIZE_AS(@"update");
_EXTERN NSString* const kGDataBatchOperationDelete _INITIALIZE_AS(@"delete");
_EXTERN NSString* const kGDataBatchOperationQuery  _INITIALIZE_AS(@"query");


// for batch operations, like
//  <batch:operation type="insert"/>
@interface GDataBatchOperation : GDataObject <GDataExtension>

+ (GDataBatchOperation *)batchOperationWithType:(NSString *)type;

- (NSString *)type;
- (void)setType:(NSString *)str;

@end
