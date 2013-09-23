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
// GDataElements.h
//
// Common classes needed for any service
//

#import "GDataFramework.h"

// utility classes
#import "GTMHTTPFetcher.h"
#import "GTMHTTPFetcherLogging.h"
#import "GTMHTTPUploadFetcher.h"
#import "GTMGatherInputStream.h"
#import "GTMMIMEDocument.h"

#import "GDataDateTime.h"
#import "GDataServerError.h"

// base classes
#import "GDataObject.h"
#import "GDataEntryBase.h"
#import "GDataFeedBase.h"
#import "GDataServiceBase.h"
#import "GDataServiceGoogle.h"
#import "GDataQuery.h"
