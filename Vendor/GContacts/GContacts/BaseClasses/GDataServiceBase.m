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
//  GDataServiceBase.m
//

#import <TargetConditionals.h>
#if TARGET_OS_MAC
#include <sys/utsname.h>
#endif

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#define GDATASERVICEBASE_DEFINE_GLOBALS 1
#import "GDataServiceBase.h"
#import "GDataServerError.h"
#import "GDataFramework.h"

static NSString *const kXMLErrorContentType = @"application/vnd.google.gdata.error+xml";

static NSString* const kFetcherDelegateKey             = @"_delegate";
static NSString* const kFetcherObjectClassKey          = @"_objectClass";
static NSString* const kFetcherFinishedSelectorKey     = @"_finishedSelector";
static NSString* const kFetcherCompletionHandlerKey    = @"_completionHandler";
static NSString* const kFetcherTicketKey               = @"_ticket";
static NSString* const kFetcherStreamDataKey           = @"_streamData";
static NSString* const kFetcherParsedObjectKey         = @"_parsedObject";
static NSString* const kFetcherParseErrorKey           = @"_parseError";
static NSString* const kFetcherCallbackThreadKey       = @"_callbackThread";
static NSString* const kFetcherCallbackRunLoopModesKey = @"_runLoopModes";

NSString* const kFetcherRetryInvocationKey = @"_retryInvocation";

static const NSUInteger kMaxNumberOfNextLinksFollowed = 25;

// we'll enforce 50K chunks minimum just to avoid the server getting hit
// with too many small upload chunks
static const NSUInteger kMinimumUploadChunkSize = 50000;

// XorPlainMutableData is a simple way to keep passwords held in heap objects
// from being visible as plain-text
static void XorPlainMutableData(NSMutableData *mutableData) {

  // this helps avoid storing passwords on the heap in plaintext
  const unsigned char theXORValue = 0x95; // 0x95 = 0xb10010101

  unsigned char *dataPtr = [mutableData mutableBytes];
  NSUInteger length = [mutableData length];

  for (NSUInteger idx = 0; idx < length; idx++) {
    dataPtr[idx] ^= theXORValue;
  }
}


// category to provide opaque access to tickets stored in fetcher properties
@implementation GTMHTTPFetcher (GDataServiceTicketAdditions)
- (id)GDataTicket {
  return [self propertyForKey:kFetcherTicketKey];
}
@end

// If GTMHTTPUploadFetcher is available, it can be used for chunked uploads
//
// We locally declare some methods of GTMHTTPUploadFetcher so we
// do not need to import the header, as some projects may not have it available
@interface GTMHTTPUploadFetcher : GTMHTTPFetcher
+ (GTMHTTPUploadFetcher *)uploadFetcherWithRequest:(NSURLRequest *)request
                                        uploadData:(NSData *)data
                                    uploadMIMEType:(NSString *)uploadMIMEType
                                         chunkSize:(NSUInteger)chunkSize
                                    fetcherService:(GTMHTTPFetcherService *)fetcherService;
+ (GTMHTTPUploadFetcher *)uploadFetcherWithRequest:(NSURLRequest *)request
                                  uploadFileHandle:(NSFileHandle *)uploadFileHandle
                                    uploadMIMEType:(NSString *)uploadMIMEType
                                         chunkSize:(NSUInteger)chunkSize
                                    fetcherService:(GTMHTTPFetcherService *)fetcherService;
+ (GTMHTTPUploadFetcher *)uploadFetcherWithLocation:(NSURL *)locationURL
                                   uploadFileHandle:(NSFileHandle *)uploadFileHandle
                                     uploadMIMEType:(NSString *)uploadMIMEType
                                          chunkSize:(NSUInteger)chunkSize
                                     fetcherService:(GTMHTTPFetcherService *)fetcherService;
- (void)pauseFetching;
- (void)resumeFetching;
- (BOOL)isPaused;
@end

@interface GDataEntryBase (PrivateMethods)
- (NSDictionary *)contentHeaders;
@end

@interface GDataServiceBase (PrivateMethods)
- (BOOL)fetchNextFeedWithURL:(NSURL *)nextFeedURL
                    delegate:(id)delegate
         didFinishedSelector:(SEL)finishedSelector
           completionHandler:(GDataServiceCompletionHandler)completionHandler
                      ticket:(GDataServiceTicketBase *)ticket;

- (NSDictionary *)userInfoForErrorResponseData:(NSData *)data
                                   contentType:(NSString *)contentType
                              previousUserInfo:(NSDictionary *)previousUserInfo;

- (void)objectFetcher:(GTMHTTPFetcher *)fetcher
     finishedWithData:(NSData *)data
                error:(NSError *)error;
- (void)objectFetcher:(GTMHTTPFetcher *)fetcher
       failedWithData:(NSData *)data
                error:(NSError *)error;
- (BOOL)objectFetcher:(GTMHTTPFetcher *)fetcher
            willRetry:(BOOL)willRetry
             forError:(NSError *)error;
- (void)objectFetcher:(GTMHTTPFetcher *)fetcher
         didSendBytes:(NSInteger)bytesSent
       totalBytesSent:(NSInteger)totalBytesSent
totalBytesExpectedToSend:(NSInteger)totalBytesExpected;

- (void)parseObjectFromDataOfFetcher:(GTMHTTPFetcher *)fetcher;
- (void)handleParsedObjectForFetcher:(GTMHTTPFetcher *)fetcher;
@end

@implementation GDataServiceBase

+ (Class)ticketClass {
  return [GDataServiceTicketBase class];
}

- (id)init {
  self = [super init];
  if (self) {

#if GDATA_IPHONE || (MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5)
    operationQueue_ = [[NSOperationQueue alloc] init];
#elif !GDATA_SKIP_PARSE_THREADING
    // Avoid NSOperationQueue prior to 10.5.6, per
    // http://www.mikeash.com/?page=pyblog/use-nsoperationqueue.html
    SInt32 bcdSystemVersion = 0;
    (void) Gestalt(gestaltSystemVersion, &bcdSystemVersion);

    if (bcdSystemVersion >= 0x1057) {
      operationQueue_ = [[NSOperationQueue alloc] init];
    }
#else
    // operationQueue_ defaults to nil, so parsing will be done immediately
    // on the current thread
#endif

    fetcherService_ = [[GTMHTTPFetcherService alloc] init];
    [fetcherService_ setShouldRememberETags:YES];

    cookieStorageMethod_ = -1;

    NSUInteger chunkSize = [[self class] defaultServiceUploadChunkSize];
    [self setServiceUploadChunkSize:chunkSize];
  }
  return self;
}

- (void)dealloc {
  [operationQueue_ release];

  [serviceVersion_ release];
  [userAgent_ release];
  [fetcherService_ release];

  [username_ release];
  [password_ release];

  [serviceUserData_ release];
  [serviceProperties_ release];
  [serviceSurrogates_ release];

#if NS_BLOCKS_AVAILABLE
  [serviceUploadProgressBlock_ release];
#endif

  [super dealloc];
}

+ (NSString *)systemVersionString {
  NSString *str = GTMSystemVersionString();
  return str;
}

- (NSString *)requestUserAgent {

  NSString *userAgent = [self userAgent];

  if ([userAgent length] == 0 || [userAgent hasPrefix:@"MyCompany-"]) {

    // the service instance is missing an explicit user-agent; use the bundle ID
    // or process name
    userAgent = [[self class] defaultApplicationIdentifier];
  }

  NSString *requestUserAgent = userAgent;

  // if the user agent already specifies the library version, we'll
  // use it verbatim in the request
  NSString *libraryString = @"GData-ObjectiveC";
  NSRange libRange = [userAgent rangeOfString:libraryString
                                      options:NSCaseInsensitiveSearch];
  if (libRange.location == NSNotFound) {
    // the user agent doesn't specify the client library, so append that
    // information, and the system version
    NSString *libVersionString = GDataFrameworkVersionString();

    NSString *systemString = [[self class] systemVersionString];

    // Google servers look for gzip in the user agent before sending gzip-
    // encoded responses.  See Service.java
    requestUserAgent = [NSString stringWithFormat:@"%@ %@/%@ %@ (gzip)",
      userAgent, libraryString, libVersionString, systemString];
  }
  return requestUserAgent;
}

- (NSMutableURLRequest *)requestForURL:(NSURL *)url
                                  ETag:(NSString *)etag
                            httpMethod:(NSString *)httpMethod
                                ticket:(GDataServiceTicketBase *)ticket {

  // subclasses may add headers to this
  NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url
                                                               cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                           timeoutInterval:60] autorelease];

  NSString *requestUserAgent = [self requestUserAgent];
  [request setValue:requestUserAgent forHTTPHeaderField:@"User-Agent"];

  NSString *serviceVersion = [self serviceVersion];
  if ([serviceVersion length] > 0) {

    // only add a version header if the URL lacks a v= version parameter
    NSString *queryString = [url query];
    if  (queryString == nil
         || ([queryString rangeOfString:@"&v="].location == NSNotFound
             && ![queryString hasPrefix:@"v="])) {

      [request setValue:serviceVersion forHTTPHeaderField:@"GData-Version"];
    }
  }

  if ([httpMethod length] > 0) {
    [request setHTTPMethod:httpMethod];
  }

  if ([etag length] > 0) {

    // it's rather unexpected for an etagged object to be provided for a GET,
    // but we'll check for an etag anyway, similar to HttpGDataRequest.java,
    // and if present use it to request only an unchanged resource

    BOOL isDoingHTTPGet = (httpMethod == nil
               || [httpMethod caseInsensitiveCompare:@"GET"] == NSOrderedSame);

    if (isDoingHTTPGet) {

      // set the etag header, even if weak, indicating we don't want
      // another copy of the resource if it's the same as the object
      [request setValue:etag forHTTPHeaderField:@"If-None-Match"];

    } else {

      // if we're doing PUT or DELETE, set the etag header indicating
      // we only want to update the resource if our copy matches the current
      // one (unless the etag is weak and so shouldn't be a constraint at all)
      BOOL isWeakETag = [etag hasPrefix:@"W/"];

      BOOL isModifying =
        [httpMethod caseInsensitiveCompare:@"PUT"] == NSOrderedSame
        || [httpMethod caseInsensitiveCompare:@"DELETE"] == NSOrderedSame
        || [httpMethod caseInsensitiveCompare:@"PATCH"] == NSOrderedSame;

      if (isModifying && !isWeakETag) {
        [request setValue:etag forHTTPHeaderField:@"If-Match"];
      }
    }
  }

  return request;
}

- (NSMutableURLRequest *)requestForURL:(NSURL *)url
                                  ETag:(NSString *)etag
                            httpMethod:(NSString *)httpMethod {
  // this public entry point authenticates from the service object but
  // not from the auth token in the ticket
  return [self requestForURL:url ETag:etag httpMethod:httpMethod ticket:nil];
}

// objectRequestForURL returns an NSMutableURLRequest for a GData object as XML
//
// the object is the object being sent to the server, or nil;
// the http method may be nil for get, or POST, PUT, DELETE

- (NSMutableURLRequest *)objectRequestForURL:(NSURL *)url
                                      object:(GDataObject *)object
                                        ETag:(NSString *)etag
                                  httpMethod:(NSString *)httpMethod
                                      ticket:(GDataServiceTicketBase *)ticket {
  NSString *contentType = @"application/atom+xml; charset=utf-8";

  if (object) {
    // if the object being sent has an etag, add it to the request header to
    // avoid retrieving a duplicate or to avoid writing over an updated
    // version of the resource on the server
    //
    // Typically, delete requests will provide an explicit ETag parameter, and
    // other requests will have the ETag carried inside the object being updated
    if (etag == nil) {
      SEL selEtag = @selector(ETag);
      if ([object respondsToSelector:selEtag]) {
        etag = [object performSelector:selEtag];
      }
    }

    if (httpMethod != nil
        && [httpMethod caseInsensitiveCompare:@"PATCH"] == NSOrderedSame) {
      // PATCH isn't part of Atom
      contentType = @"application/xml; charset=utf-8";
    }
  }

  NSMutableURLRequest *request = [self requestForURL:url
                                                ETag:etag
                                          httpMethod:httpMethod
                                              ticket:ticket];

  [request setValue:@"application/atom+xml, text/xml" forHTTPHeaderField:@"Accept"];

  [request setValue:contentType forHTTPHeaderField:@"Content-Type"];

  [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];

  return request;
}

#pragma mark -

- (GDataServiceTicketBase *)fetchObjectWithURL:(NSURL *)feedURL
                                   objectClass:(Class)objectClass
                                  objectToPost:(GDataObject *)objectToPost
                                          ETag:(NSString *)etag
                                    httpMethod:(NSString *)httpMethod
                                      delegate:(id)delegate
                             didFinishSelector:(SEL)finishedSelector
                             completionHandler:(id)completionHandler // GDataServiceCompletionHandler
                          retryInvocationValue:(NSValue *)retryInvocationValue
                                        ticket:(GDataServiceTicketBase *)ticket {

  GTMAssertSelectorNilOrImplementedWithArgs(delegate, finishedSelector, @encode(GDataServiceTicketBase *), @encode(GDataObject *), @encode(NSError *), 0);

  // The completionHandler argument is declared as an id, not as a block
  // pointer, so this can be built with the 10.6 SDK and still run on 10.5.
  // If the argument were declared as a block pointer, the invocation for
  // fetchObjectWithURL: created in GDataServiceGoogle would cause an exception
  // since 10.5's NSInvocation cannot deal with encoding of block pointers.

  NSURL *uploadLocationURL = [objectToPost uploadLocationURL];

  // if no URL was supplied, and we're not resuming an upload, treat this as
  // if the fetch failed (below) and immediately return a nil ticket, skipping
  // the callbacks
  //
  // this might be considered normal (say, updating a read-only entry
  // that lacks an edit link) though higher-level calls may assert or
  // returns errors depending on the specific usage
  if (feedURL == nil && uploadLocationURL == nil) {
    return nil;
  }

  // we need to create a ticket unless one was created earlier (like during
  // authentication)
  if (!ticket) {
    ticket = [[[self class] ticketClass] ticketForService:self];
  }

  NSMutableURLRequest *request = nil;
  if (feedURL) {
    request = [self objectRequestForURL:feedURL
                                 object:objectToPost
                                   ETag:etag
                             httpMethod:httpMethod
                                 ticket:ticket];
  }

  GTMAssertSelectorNilOrImplementedWithArgs(delegate, [ticket uploadProgressSelector],
      @encode(GDataServiceTicketBase *), @encode(unsigned long long),
      @encode(unsigned long long), 0);
  GTMAssertSelectorNilOrImplementedWithArgs(delegate, [ticket retrySelector],
      @encode(GDataServiceTicketBase *), @encode(BOOL), @encode(NSError *), 0);

  //
  // package the object's XML and any upload data
  //

  NSInputStream *streamToPost = nil;
  NSData *dataToPost = nil;
  SEL sentDataSel = NULL;
  NSData *uploadData = nil;
  NSFileHandle *uploadFileHandle = nil;
  BOOL shouldUploadDataChunked = ([self serviceUploadChunkSize] > 0);
  BOOL isUploadingDataChunked = NO;

  NSMutableDictionary *uploadProperties = nil;
  if (objectToPost) {

    NSData *xmlData = nil;

    [ticket setPostedObject:objectToPost];

    // An upload object may provide a custom input stream, such as for
    // multi-part MIME or media uploads.
    NSInputStream *contentInputStream = nil;
    unsigned long long contentLength = 0;
    NSDictionary *contentHeaders = nil;

    uploadProperties = [NSMutableDictionary dictionary];

    BOOL doesSupportSentData = [GTMHTTPFetcher doesSupportSentDataCallback];

    uploadData = [objectToPost uploadData];
    uploadFileHandle = [objectToPost uploadFileHandle];

    isUploadingDataChunked = ((uploadData != nil || uploadFileHandle != nil)
                              && shouldUploadDataChunked);
    BOOL shouldUploadDataOnly = ([objectToPost shouldUploadDataOnly]
                                 || uploadLocationURL != nil);

    BOOL shouldReportUploadProgress;
#if NS_BLOCKS_AVAILABLE
    shouldReportUploadProgress = ([ticket uploadProgressSelector] != NULL
                                  || [ticket uploadProgressHandler] != NULL);
#else
    shouldReportUploadProgress = ([ticket uploadProgressSelector] != NULL);
#endif

    if ((!isUploadingDataChunked) &&
        [objectToPost generateContentInputStream:&contentInputStream
                                          length:&contentLength
                                         headers:&contentHeaders]) {
      // now we have a stream containing the XML and the upload data

    } else if (isUploadingDataChunked && shouldUploadDataOnly) {
      // no XML is needed since we're uploading data only, and there's no upload
      // data for the first fetch because the data will be sent chunked later,
      // so now we'll have an empty body with appropriate headers
      contentHeaders = [objectToPost performSelector:@selector(contentHeaders)];
      contentLength = 0;

    } else {
      // we're sending either just XML, or XML now with chunked upload data
      // later
      xmlData = [[objectToPost XMLDocument] XMLData];
      contentLength = [xmlData length];

      if (!shouldReportUploadProgress
          || doesSupportSentData
          || isUploadingDataChunked) {
        // there is no progress selector, or the fetcher can call us back on
        // sent data, or we're uploading chunked; we can post plain NSData,
        // which is simpler because it survives http redirects
        dataToPost = xmlData;

      } else {
        // there is a progress selector and NSURLConnection won't call us back,
        // so we need to be posting a stream
        //
        // we'll make a default input stream from the XML data
        contentInputStream = [NSInputStream inputStreamWithData:xmlData];

        // NSInputStream fails to retain or copy its data in 10.4, so we will
        // retain it in the callback dictionary.  We won't use this property in
        // the callbacks at all, but retaining it will ensure it's still around
        // until the upload completes.
        //
        // If it weren't for this bug in NSInputStream, we could just have
        // GDataObject's -contentInputStream method create the input stream for
        // us, so this service class wouldn't ever need to have the plain XML.
        [uploadProperties setObject:xmlData forKey:kFetcherStreamDataKey];
      }

      if ([objectToPost respondsToSelector:@selector(uploadSlug)]) {
        NSString *slug = [objectToPost performSelector:@selector(uploadSlug)];
        if ([slug length] > 0) {
          [request setValue:slug forHTTPHeaderField:@"Slug"];
        }
      }
    }

    if (contentHeaders) {
      // add the content-specific headers, if any
      for (NSString *key in contentHeaders) {
        NSString *value = [contentHeaders objectForKey:key];
        [request setValue:value forHTTPHeaderField:key];
      }
    }

    streamToPost = contentInputStream;

    NSNumber* num = [NSNumber numberWithUnsignedLongLong:contentLength];
    [request setValue:[num stringValue] forHTTPHeaderField:@"Content-Length"];

    if (shouldReportUploadProgress) {
      if (doesSupportSentData || isUploadingDataChunked) {
        // there is sentData callback support in NSURLConnection,
        // or we're using an upload fetcher which can always call us
        // back
        sentDataSel = @selector(objectFetcher:didSendBytes:totalBytesSent:totalBytesExpectedToSend:);
      }
    }
  }

  //
  // now that we have all the request header info ready,
  // create and set up the fetcher for this request
  //
  GTMHTTPFetcher* fetcher = nil;

  if (isUploadingDataChunked) {
    // hang on to the user's requested chunk size, and ensure it's not tiny
    NSUInteger uploadChunkSize = [self serviceUploadChunkSize];
    if (uploadChunkSize < kMinimumUploadChunkSize) {
      uploadChunkSize = kMinimumUploadChunkSize;
    }

#ifdef GDATA_TARGET_NAMESPACE
    // prepend the class name prefix
    Class uploadClass = NSClassFromString(@GDATA_TARGET_NAMESPACE_STRING
                                          "_GTMHTTPUploadFetcher");
#else
    Class uploadClass = NSClassFromString(@"GTMHTTPUploadFetcher");
#endif
    GDATA_ASSERT(uploadClass != nil, @"GTMHTTPUploadFetcher needed");

    NSString *uploadMIMEType = [objectToPost uploadMIMEType];

    if (uploadData) {
      fetcher = [uploadClass uploadFetcherWithRequest:request
                                           uploadData:uploadData
                                       uploadMIMEType:uploadMIMEType
                                            chunkSize:uploadChunkSize
                                       fetcherService:fetcherService_];
    } else if (uploadLocationURL) {
      fetcher = [uploadClass uploadFetcherWithLocation:uploadLocationURL
                                      uploadFileHandle:uploadFileHandle
                                        uploadMIMEType:uploadMIMEType
                                             chunkSize:uploadChunkSize
                                        fetcherService:fetcherService_];
    } else {
      fetcher = [uploadClass uploadFetcherWithRequest:request
                                     uploadFileHandle:uploadFileHandle
                                       uploadMIMEType:uploadMIMEType
                                            chunkSize:uploadChunkSize
                                       fetcherService:fetcherService_];
    }
  } else {
    fetcher = [fetcherService_ fetcherWithRequest:request];
  }

  // allow the user to specify static app-wide cookies for fetching
  NSInteger cookieStorageMethod = [self cookieStorageMethod];
  if (cookieStorageMethod >= 0) {
    [fetcher setCookieStorageMethod:cookieStorageMethod];
  }

  // copy the ticket's retry settings into the fetcher
  [fetcher setRetryEnabled:[ticket isRetryEnabled]];
  [fetcher setMaxRetryInterval:[ticket maxRetryInterval]];

  if ([ticket retrySelector]) {
    [fetcher setRetrySelector:@selector(objectFetcher:willRetry:forError:)];
  }

  // remember the object fetcher in the ticket
  [ticket setObjectFetcher:fetcher];
  [ticket setCurrentFetcher:fetcher];

  // add parameters used by the callbacks

  [fetcher setProperty:objectClass forKey:kFetcherObjectClassKey];

  [fetcher setProperty:delegate forKey:kFetcherDelegateKey];

  [fetcher setProperty:NSStringFromSelector(finishedSelector)
                forKey:kFetcherFinishedSelectorKey];

  [fetcher setProperty:ticket
                forKey:kFetcherTicketKey];

#if NS_BLOCKS_AVAILABLE
  // copy the completion handler block to the heap; this does nothing if the
  // block is already on the heap
  completionHandler = [[completionHandler copy] autorelease];
  [fetcher setProperty:completionHandler
                forKey:kFetcherCompletionHandlerKey];
#endif

  // we want to add the invocation itself, not the value wrapper of it,
  // to ensure the invocation is retained until the callback completes
  NSInvocation *retryInvocation = [retryInvocationValue nonretainedObjectValue];
  [fetcher setProperty:retryInvocation
                forKey:kFetcherRetryInvocationKey];

  // set the upload data
  GDATA_DEBUG_ASSERT(dataToPost == nil || streamToPost == nil,
                     @"upload conflict");
  [fetcher setPostData:dataToPost];
  [fetcher setPostStream:streamToPost];
  [fetcher setSentDataSelector:sentDataSel];
  [fetcher addPropertiesFromDictionary:uploadProperties];

  // attach OAuth authorization object, if any
  //
  // the fetcher already has this authorizer from the fetcher service, but this
  // lets the client remove the authorizer from the ticket to make an
  // unauthorized request
  [fetcher setAuthorizer:[ticket authorizer]];

  // add username/password, if any
  [self addAuthenticationToFetcher:fetcher];

  if (finishedSelector) {
    [fetcher setComment:NSStringFromSelector(finishedSelector)];
  }

  // failed fetches call the failure selector, which will delete the ticket
  BOOL didFetch = [fetcher beginFetchWithDelegate:self
                                didFinishSelector:@selector(objectFetcher:finishedWithData:error:)];

  // If something weird happens and the networking callbacks have been called
  // already synchronously, we don't want to return the ticket since the caller
  // will never know when to stop retaining it, so we'll make sure the
  // success/failure callbacks have not yet been called by checking the
  // ticket
  if (!didFetch || [ticket hasCalledCallback]) {
    [fetcher setProperties:nil];
    [ticket setCurrentFetcher:nil];
    return nil;
  }

  return ticket;
}

- (void)invokeProgressCallbackForTicket:(GDataServiceTicketBase *)ticket
                         deliveredBytes:(unsigned long long)numReadSoFar
                             totalBytes:(unsigned long long)total {

  SEL progressSelector = [ticket uploadProgressSelector];
  if (progressSelector) {

    GTMHTTPFetcher *fetcher = [ticket objectFetcher];
    id delegate = [fetcher propertyForKey:kFetcherDelegateKey];

    NSMethodSignature *signature = [delegate methodSignatureForSelector:progressSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];

    [invocation setSelector:progressSelector];
    [invocation setTarget:delegate];
    [invocation setArgument:&ticket atIndex:2];
    [invocation setArgument:&numReadSoFar atIndex:3];
    [invocation setArgument:&total atIndex:4];
    [invocation invoke];
  }

#if NS_BLOCKS_AVAILABLE
  GDataServiceUploadProgressHandler block = [ticket uploadProgressHandler];
  if (block) {
    block(ticket, numReadSoFar, total);
  }
#endif
}

// sentData callback from fetcher
- (void)objectFetcher:(GTMHTTPFetcher *)fetcher
         didSendBytes:(NSInteger)bytesSent
       totalBytesSent:(NSInteger)totalBytesSent
totalBytesExpectedToSend:(NSInteger)totalBytesExpected {

  GDataServiceTicketBase *ticket = [fetcher propertyForKey:kFetcherTicketKey];

  [self invokeProgressCallbackForTicket:ticket
                         deliveredBytes:(unsigned long long)totalBytesSent
                             totalBytes:(unsigned long long)totalBytesExpected];
}

- (void)objectFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
  if (error) {
    [self objectFetcher:fetcher failedWithData:data error:error];
    return;
  }

  // we now have the XML data for a feed or entry

  // save the current thread into the fetcher, since we'll handle additional
  // fetches and callbacks on this thread
  [fetcher setProperty:[NSThread currentThread]
                forKey:kFetcherCallbackThreadKey];

  // copy the run loop modes, if any, so we don't need to access them
  // from the parsing thread
  [fetcher setProperty:[[[self runLoopModes] copy] autorelease]
                forKey:kFetcherCallbackRunLoopModesKey];

  // we post parsing notifications now to ensure they're on caller's
  // original thread
  GDataServiceTicketBase *ticket = [fetcher propertyForKey:kFetcherTicketKey];
  NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
  [defaultNC postNotificationName:kGDataServiceTicketParsingStartedNotification
                           object:ticket];

  // if there's an operation queue, then use that to schedule parsing on another
  // thread
  SEL parseSel = @selector(parseObjectFromDataOfFetcher:);
  if (operationQueue_ != nil) {

    NSInvocationOperation *op;
    op = [[[NSInvocationOperation alloc] initWithTarget:self
                                               selector:parseSel
                                                 object:fetcher] autorelease];
    [ticket setParseOperation:op];
    [operationQueue_ addOperation:op];
    // the fetcher now belongs to the parsing thread
  } else {
    // parse on the current thread, on Mac OS X 10.4 through 10.5.7
    // or when the project defines GDATA_SKIP_PARSE_THREADING
    [self performSelector:parseSel
               withObject:fetcher];
  }
}

- (void)parseObjectFromDataOfFetcher:(GTMHTTPFetcher *)fetcher {

  // this may be invoked in a separate thread
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

#if GDATA_LOG_PERFORMANCE
  NSTimeInterval secs1, secs2;
  secs1 = [NSDate timeIntervalSinceReferenceDate];
#endif

  NSError *error = nil;
  GDataObject* object = nil;

  // Generally protect the fetcher properties, since canceling a ticket would
  // release the fetcher properties dictionary
  NSMutableDictionary *properties = [[[fetcher properties] retain] autorelease];

  // The callback thread is retaining the fetcher, so the fetcher shouldn't keep
  // retaining the callback thread
  NSThread *callbackThread = [properties valueForKey:kFetcherCallbackThreadKey];
  [[callbackThread retain] autorelease];
  [properties removeObjectForKey:kFetcherCallbackThreadKey];

  GDataServiceTicketBase *ticket = [properties valueForKey:kFetcherTicketKey];
  [[ticket retain] autorelease];

  NSDictionary *responseHeaders = [fetcher responseHeaders];
  [[responseHeaders retain] autorelease];

  NSOperation *parseOperation = [ticket parseOperation];

  Class objectClass = (Class)[properties objectForKey:kFetcherObjectClassKey];

  NSData *data = [fetcher downloadedData];
  NSXMLDocument *xmlDocument = [[[NSXMLDocument alloc] initWithData:data
                                                            options:0
                                                              error:&error] autorelease];
  if ([parseOperation isCancelled]) return;

  if (xmlDocument) {

    NSXMLElement* root = [xmlDocument rootElement];

    if (!objectClass) {
      objectClass = [GDataObject objectClassForXMLElement:root];
    }

    // see if the top-level class for the XML is listed in the surrogates;
    // if so, instantiate the surrogate class instead
    NSDictionary *surrogates = [ticket surrogates];
    Class baseSurrogate = (Class)[surrogates objectForKey:objectClass];
    if (baseSurrogate) {
      objectClass = baseSurrogate;
    }

    // use the actual service version indicated by the response headers
    NSString *serviceVersion = [responseHeaders objectForKey:@"Gdata-Version"];

    // feeds may optionally be instantiated without unknown elements tracked
    //
    // we only ever want to fetch feeds and discard the unknown XML, never
    // entries
    BOOL shouldIgnoreUnknowns = ([ticket shouldFeedsIgnoreUnknowns]
                                 && [objectClass isSubclassOfClass:[GDataFeedBase class]]);

    object = [[objectClass alloc] initWithXMLElement:root
                                              parent:nil
                                      serviceVersion:serviceVersion
                                          surrogates:surrogates
                                shouldIgnoreUnknowns:shouldIgnoreUnknowns];

    // we're done parsing; the extension declarations won't be needed again
    [object clearExtensionDeclarationsCache];


#if GDATA_USES_LIBXML
    // retain the document so that pointers to internal nodes remain valid
    [object setProperty:xmlDocument forKey:kGDataXMLDocumentPropertyKey];
#endif

    [properties setValue:object forKey:kFetcherParsedObjectKey];
    [object release];

#if GDATA_LOG_PERFORMANCE
    secs2 = [NSDate timeIntervalSinceReferenceDate];
    NSLog(@"allocation of %@ took %f seconds", objectClass, secs2 - secs1);
#endif
  }
  [properties setValue:error forKey:kFetcherParseErrorKey];

  if ([parseOperation isCancelled]) return;

  SEL parseDoneSel = @selector(handleParsedObjectForFetcher:);

  if (operationQueue_ != nil) {
    NSArray *runLoopModes = [properties valueForKey:kFetcherCallbackRunLoopModesKey];
    if (runLoopModes) {
      [self performSelector:parseDoneSel
                   onThread:callbackThread
                 withObject:fetcher
              waitUntilDone:NO
                      modes:runLoopModes];
    } else {
      // defaults to common modes
      [self performSelector:parseDoneSel
                   onThread:callbackThread
                 withObject:fetcher
              waitUntilDone:NO];
    }
    // the fetcher now belongs to the callback thread
  } else {
    // in 10.4, there's no performSelector:onThread:
    [self performSelector:parseDoneSel withObject:fetcher];
    [properties removeObjectForKey:kFetcherCallbackThreadKey];
  }

  // We drain here to keep the clang static analyzer quiet.
  [pool drain];
}

- (void)handleParsedObjectForFetcher:(GTMHTTPFetcher *)fetcher {

  // after parsing is complete, this is invoked on the thread that the
  // fetch was performed on

  GDataServiceTicketBase *ticket = [fetcher propertyForKey:kFetcherTicketKey];
  [ticket setParseOperation:nil];

  // unpack the callback parameters
  id delegate = [fetcher propertyForKey:kFetcherDelegateKey];
  GDataObject *object = [fetcher propertyForKey:kFetcherParsedObjectKey];
  NSError *error = [fetcher propertyForKey:kFetcherParseErrorKey];
  SEL finishedSelector = NSSelectorFromString([fetcher propertyForKey:kFetcherFinishedSelectorKey]);

  GDataServiceCompletionHandler completionHandler;
#if NS_BLOCKS_AVAILABLE
  completionHandler = [fetcher propertyForKey:kFetcherCompletionHandlerKey];
#else
  completionHandler = NULL;
#endif

  NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
  [defaultNC postNotificationName:kGDataServiceTicketParsingStoppedNotification
                           object:ticket];

  NSData *data = [fetcher downloadedData];
  NSUInteger dataLength = [data length];

  // if we created the object (or we got empty data back, as from a GData
  // delete resource request) then we succeeded
  if (object != nil || dataLength == 0) {

    // if the user is fetching a feed and the ticket specifies that "next" links
    // should be followed, then do that now
    if ([ticket shouldFollowNextLinks]
        && [object isKindOfClass:[GDataFeedBase class]]) {

      GDataFeedBase *latestFeed = (GDataFeedBase *)object;

      // append the latest feed
      [ticket accumulateFeed:latestFeed];

      NSURL *nextURL = [[latestFeed nextLink] URL];
      if (nextURL) {

        BOOL isFetchingNextFeed = [self fetchNextFeedWithURL:nextURL
                                                    delegate:delegate
                                         didFinishedSelector:finishedSelector
                                           completionHandler:completionHandler
                                                      ticket:ticket];

        // skip calling the callbacks since the ticket is still in progress
        if (isFetchingNextFeed) {

          return;

        } else {
          // the fetch didn't start; fall through to the callback for the
          // feed accumulated so far
        }
      }

      // no more "next" links are present, so we don't need to accumulate more
      // entries
      GDataFeedBase *accumulatedFeed = [ticket accumulatedFeed];
      if (accumulatedFeed) {

        // remove the misleading "next" link from the accumulated feed
        GDataLink *accumulatedFeedNextLink = [accumulatedFeed nextLink];
        if (accumulatedFeedNextLink) {
          [accumulatedFeed removeLink:accumulatedFeedNextLink];
        }

#if DEBUG && !GDATA_SKIP_NEXTLINK_WARNING
        // each next link followed to accumulate all pages of a feed takes up to
        // a few seconds.  When multiple next links are being followed, that
        // usually indicates that a larger page size (that is, more entries per
        // feed fetched) should be requested.
        //
        // To avoid following next links, when fetching a feed, make it a query
        // fetch instead; when fetching a query, use setMaxResults: so the feed
        // requested is large enough to rarely need to follow next links.
        NSUInteger feedPageCount = [ticket nextLinksFollowedCounter];
        if (feedPageCount > 2) {
          NSLog(@"Fetching %@ required following %u \"next\" links; use a query with a larger setMaxResults: for faster feed accumulation",
                NSStringFromClass([accumulatedFeed class]),
                (unsigned int) [ticket nextLinksFollowedCounter]);
        }
#endif
        // return the completed feed as the object that was fetched
        object = accumulatedFeed;
      }
    }

    if (finishedSelector) {
      [[self class] invokeCallback:finishedSelector
                            target:delegate
                            ticket:ticket
                            object:object
                             error:nil];
    }

#if NS_BLOCKS_AVAILABLE
    if (completionHandler) {
      completionHandler(ticket, object, nil);
    }
#endif

    [ticket setFetchedObject:object];

  } else {
    if (error == nil) {
      error = [NSError errorWithDomain:kGDataServiceErrorDomain
                                  code:kGDataCouldNotConstructObjectError
                              userInfo:nil];
    }
    if (finishedSelector) {
      [[self class] invokeCallback:finishedSelector
                            target:delegate
                            ticket:ticket
                            object:nil
                             error:error];
    }

#if NS_BLOCKS_AVAILABLE
    if (completionHandler) {
      completionHandler(ticket, nil, error);
    }
#endif
    [ticket setFetchError:error];
  }

  [fetcher setProperties:nil];

  [ticket setHasCalledCallback:YES];
  [ticket setCurrentFetcher:nil];
}

- (void)objectFetcher:(GTMHTTPFetcher *)fetcher failedWithData:(NSData *)data error:(NSError *)error {

#if DEBUG
  NSString *dataString = [[[NSString alloc] initWithData:data
                                            encoding:NSUTF8StringEncoding] autorelease];
  if (dataString) {
   NSLog(@"serviceBase:%@ objectFetcher:%@ failedWithStatus:%ld data:%@",
         self, fetcher, (long) [error code], dataString);
  }
#endif

  id delegate = [fetcher propertyForKey:kFetcherDelegateKey];

  GDataServiceTicketBase *ticket = [fetcher propertyForKey:kFetcherTicketKey];

  NSString *finishedSelectorStr = [fetcher propertyForKey:kFetcherFinishedSelectorKey];
  SEL finishedSelector = finishedSelectorStr ? NSSelectorFromString(finishedSelectorStr) : NULL;

  if (error != nil) {
    // create structured errors in the userInfo, if appropriate
    NSDictionary *responseHeaders = [fetcher responseHeaders];
    NSString *contentType = [responseHeaders objectForKey:@"Content-Type"];

    NSDictionary *newUserInfo = [self userInfoForErrorResponseData:data
                                                    contentType:contentType
                                                  previousUserInfo:[error userInfo]];
    error = [NSError errorWithDomain:[error domain]
                                code:[error code]
                            userInfo:newUserInfo];
  }

  if (finishedSelector) {
    [[self class] invokeCallback:finishedSelector
                          target:delegate
                          ticket:ticket
                          object:nil
                           error:error];
  }

#if NS_BLOCKS_AVAILABLE
  GDataServiceCompletionHandler completionHandler;

  completionHandler = [fetcher propertyForKey:kFetcherCompletionHandlerKey];
  if (completionHandler) {
    completionHandler(ticket, nil, error);
  }
#endif

  [fetcher setProperties:nil];

  [ticket setFetchError:error];
  [ticket setHasCalledCallback:YES];
  [ticket setCurrentFetcher:nil];
}

#pragma mark -

// create an error userInfo dictionary containing a useful reason string and,
// for structured XML errors, a server error group object
- (NSDictionary *)userInfoForErrorResponseData:(NSData *)data
                                   contentType:(NSString *)contentType
                              previousUserInfo:(NSDictionary *)previousUserInfo {
  // NSError's default localizedReason value looks like
  //   "(com.google.GDataServiceDomain error -4.)"
  //
  // The NSError domain and numeric code aren't the ones we care about
  // so much as the error present in the server response data, so
  // we'll try to store a more useful reason in the userInfo dictionary

  NSString *reasonStr = nil;
  NSMutableDictionary *userInfo;
  if (previousUserInfo) {
    userInfo = [NSMutableDictionary dictionaryWithDictionary:previousUserInfo];
  } else {
    userInfo = [NSMutableDictionary dictionary];
  }

  if ([data length] > 0) {

    // check if the response is a structured XML error string, according to the
    // response content-type header; if so, convert the XML to a
    // GDataServerErrorGroup
    if ([[contentType lowercaseString] hasPrefix:kXMLErrorContentType]) {

      GDataServerErrorGroup *errorGroup
        = [[[GDataServerErrorGroup alloc] initWithData:data] autorelease];

      if (errorGroup != nil) {

        // store the server group in the userInfo for the error
        [userInfo setObject:errorGroup forKey:kGDataStructuredErrorsKey];

        reasonStr = [[errorGroup mainError] summary];
      }
    }

    if ([userInfo count] == 0) {

      // no structured XML error was available; deal with a plaintext server
      // error response
      reasonStr = [[[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding] autorelease];
    }
  }

  if (reasonStr != nil) {
    // we always store an error in the userInfo key "error"
    [userInfo setObject:reasonStr forKey:kGDataServerErrorStringKey];

    // store a user-readable "reason" to show up when an error is logged,
    // in parentheses like NSError does it
    NSString *parenthesized = [NSString stringWithFormat:@"(%@)", reasonStr];
    [userInfo setObject:parenthesized forKey:NSLocalizedFailureReasonErrorKey];
  }

  return userInfo;
}

+ (void)invokeCallback:(SEL)callbackSel
                target:(id)target
                ticket:(id)ticket
                object:(id)object
                 error:(id)error {

  // GData fetch callbacks have no return value
  NSMethodSignature *signature = [target methodSignatureForSelector:callbackSel];
  NSInvocation *retryInvocation = [NSInvocation invocationWithMethodSignature:signature];
  [retryInvocation setSelector:callbackSel];
  [retryInvocation setTarget:target];
  [retryInvocation setArgument:&ticket atIndex:2];
  [retryInvocation setArgument:&object atIndex:3];
  [retryInvocation setArgument:&error atIndex:4];
  [retryInvocation invoke];
}

// The object fetcher may call into this retry method; this one invokes the
// selector provided by the user.
- (BOOL)objectFetcher:(GTMHTTPFetcher *)fetcher willRetry:(BOOL)willRetry forError:(NSError *)error {

  id delegate = [fetcher propertyForKey:kFetcherDelegateKey];
  GDataServiceTicketBase *ticket = [fetcher propertyForKey:kFetcherTicketKey];

  SEL retrySelector = [ticket retrySelector];
  if (retrySelector) {

    willRetry = [self invokeRetrySelector:retrySelector
                                 delegate:delegate
                                   ticket:ticket
                                willRetry:willRetry
                                    error:error];
  }
  return willRetry;
}

- (BOOL)invokeRetrySelector:(SEL)retrySelector
                   delegate:(id)delegate
                     ticket:(GDataServiceTicketBase *)ticket
                  willRetry:(BOOL)willRetry
                      error:(NSError *)error {

  if ([delegate respondsToSelector:retrySelector]) {

    // Unlike the retry selector invocation in GTMHTTPFetcher, this invocation
    // passes the ticket rather than the fetcher as argument 2
    NSMethodSignature *signature = [delegate methodSignatureForSelector:retrySelector];
    NSInvocation *retryInvocation = [NSInvocation invocationWithMethodSignature:signature];
    [retryInvocation setSelector:retrySelector];
    [retryInvocation setTarget:delegate];
    [retryInvocation setArgument:&ticket atIndex:2]; // ticket passed
    [retryInvocation setArgument:&willRetry atIndex:3];
    [retryInvocation setArgument:&error atIndex:4];
    [retryInvocation invoke];

    [retryInvocation getReturnValue:&willRetry];
  }
  return willRetry;
}

- (void)addAuthenticationToFetcher:(GTMHTTPFetcher *)fetcher {
  NSString *username = [self username];
  NSString *password = [self password];

  if ([username length] > 0 && [password length] > 0) {
    // We're avoiding +[NSURCredential credentialWithUser:password:persistence:]
    // because it fails to autorelease itself on OS X 10.4 .. 10.5.x
    // rdar://5596278

    NSURLCredential *cred;
    cred = [[[NSURLCredential alloc] initWithUser:username
                                         password:password
                                      persistence:NSURLCredentialPersistenceForSession] autorelease];
    [fetcher setCredential:cred];
  }
}

// when a ticket is set to follow "next" links for feeds, this routine
// initiates the fetch for each additional feed
- (BOOL)fetchNextFeedWithURL:(NSURL *)nextFeedURL
                    delegate:(id)delegate
         didFinishedSelector:(SEL)finishedSelector
           completionHandler:(GDataServiceCompletionHandler)completionHandler
                      ticket:(GDataServiceTicketBase *)ticket {

  // sanity check the number of pages fetched already
  NSUInteger followedCounter = [ticket nextLinksFollowedCounter];

  if (followedCounter > kMaxNumberOfNextLinksFollowed) {

    // the client should be querying with a higher max results per page
    // to avoid this
    GDATA_DEBUG_ASSERT(0, @"Following next links retrieves too many pages (URL %@)",
              nextFeedURL);
    return NO;
  }

  [ticket setNextLinksFollowedCounter:(1 + followedCounter)];

  // by definition, feed requests are GETs, so objectToPost: and httpMethod:
  // should be nil
  GDataServiceTicketBase *startedTicket;
  startedTicket = [self fetchObjectWithURL:nextFeedURL
                               objectClass:[[ticket accumulatedFeed] class]
                              objectToPost:nil
                                      ETag:nil
                                httpMethod:nil
                                  delegate:delegate
                         didFinishSelector:finishedSelector
                         completionHandler:completionHandler
                      retryInvocationValue:nil
                                    ticket:ticket];

  // in the bizarre case that the fetch didn't begin, startedTicket will be
  // nil.  So long as the started ticket is the same as the ticket we're
  // continuing, then we're happy.
  return (ticket == startedTicket);
}


- (BOOL)waitForTicket:(GDataServiceTicketBase *)ticket
              timeout:(NSTimeInterval)timeoutInSeconds
        fetchedObject:(GDataObject **)outObjectOrNil
                error:(NSError **)outErrorOrNil {

  NSDate* giveUpDate = [NSDate dateWithTimeIntervalSinceNow:timeoutInSeconds];

  // loop until the fetch completes with an object or an error,
  // or until the timeout has expired
  while (![ticket hasCalledCallback]
         && [giveUpDate timeIntervalSinceNow] > 0) {

    // run the current run loop 1/1000 of a second to give the networking
    // code a chance to work
    NSDate *stopDate = [NSDate dateWithTimeIntervalSinceNow:0.001];
    [[NSRunLoop currentRunLoop] runUntilDate:stopDate];
  }

  NSError *fetchError = [ticket fetchError];

  if (![ticket hasCalledCallback] && fetchError == nil) {
    fetchError = [NSError errorWithDomain:kGDataServiceErrorDomain
                                     code:kGDataWaitTimedOutError
                                 userInfo:nil];
  }

  if (outObjectOrNil) *outObjectOrNil = [ticket fetchedObject];
  if (outErrorOrNil)  *outErrorOrNil = fetchError;

  return (fetchError == nil);
}

#pragma mark -

// These external entry points all call into fetchObjectWithURL: defined above

- (GDataServiceTicketBase *)fetchPublicFeedWithURL:(NSURL *)feedURL
                                         feedClass:(Class)feedClass
                                          delegate:(id)delegate
                                 didFinishSelector:(SEL)finishedSelector {

  return [self fetchObjectWithURL:feedURL
                      objectClass:feedClass
                     objectToPost:nil
                             ETag:nil
                       httpMethod:nil
                         delegate:delegate
                didFinishSelector:finishedSelector
                completionHandler:nil
             retryInvocationValue:nil
                           ticket:nil];
}

- (GDataServiceTicketBase *)fetchPublicEntryWithURL:(NSURL *)entryURL
                                         entryClass:(Class)entryClass
                                           delegate:(id)delegate
                                  didFinishSelector:(SEL)finishedSelector {

  return [self fetchObjectWithURL:entryURL
                      objectClass:entryClass
                     objectToPost:nil
                             ETag:nil
                       httpMethod:nil
                         delegate:delegate
                didFinishSelector:finishedSelector
                completionHandler:nil
             retryInvocationValue:nil
                           ticket:nil];
}

- (GDataServiceTicketBase *)fetchPublicFeedWithQuery:(GDataQuery *)query
                                           feedClass:(Class)feedClass
                                            delegate:(id)delegate
                                   didFinishSelector:(SEL)finishedSelector {

  return [self fetchPublicFeedWithURL:[query URL]
                            feedClass:feedClass
                             delegate:delegate
                    didFinishSelector:finishedSelector];
}

- (GDataServiceTicketBase *)fetchPublicFeedWithBatchFeed:(GDataFeedBase *)batchFeed
                                              forFeedURL:(NSURL *)feedURL
                                                delegate:(id)delegate
                                       didFinishSelector:(SEL)finishedSelector
                                      completionHandler:(GDataServiceCompletionHandler)completionHandler {
  // internal routine, used for both callback and blocks style of batch feed
  // fetches

  // add basic namespaces to feed, if needed
  if ([[batchFeed namespaces] objectForKey:kGDataNamespaceGDataPrefix] == nil) {
    [batchFeed addNamespaces:[GDataEntryBase baseGDataNamespaces]];
  }

  // add batch namespace, if needed
  if ([[batchFeed namespaces] objectForKey:kGDataNamespaceBatchPrefix] == nil) {
    [batchFeed addNamespaces:[GDataEntryBase batchNamespaces]];
  }

  GDataServiceTicketBase *ticket;

  ticket = [self fetchObjectWithURL:feedURL
                        objectClass:[batchFeed class]
                       objectToPost:batchFeed
                               ETag:nil
                         httpMethod:nil
                           delegate:delegate
                  didFinishSelector:finishedSelector
                  completionHandler:completionHandler
               retryInvocationValue:nil
                             ticket:nil];

  // batch feeds never ignore unknowns, since they are intrinsically
  // used for updating so their entries need to include complete XML
  [ticket setShouldFeedsIgnoreUnknowns:NO];

  return ticket;
}

- (GDataServiceTicketBase *)fetchPublicFeedWithBatchFeed:(GDataFeedBase *)batchFeed
                                              forFeedURL:(NSURL *)feedURL
                                                delegate:(id)delegate
                                       didFinishSelector:(SEL)finishedSelector {

  return [self fetchPublicFeedWithBatchFeed:batchFeed
                                 forFeedURL:feedURL
                                   delegate:delegate
                          didFinishSelector:finishedSelector
                          completionHandler:NULL];
}

#if NS_BLOCKS_AVAILABLE

- (GDataServiceTicketBase *)fetchPublicFeedWithURL:(NSURL *)feedURL
                                         feedClass:(Class)feedClass
                                 completionHandler:(GDataServiceFeedBaseCompletionHandler)handler {

  return [self fetchObjectWithURL:feedURL
                      objectClass:feedClass
                     objectToPost:nil
                             ETag:nil
                       httpMethod:nil
                         delegate:nil
                didFinishSelector:NULL
                completionHandler:(GDataServiceCompletionHandler)handler
             retryInvocationValue:nil
                           ticket:nil];
}

- (GDataServiceTicketBase *)fetchPublicFeedWithQuery:(GDataQuery *)query
                                           feedClass:(Class)feedClass
                                   completionHandler:(GDataServiceFeedBaseCompletionHandler)handler {
return [self fetchPublicFeedWithURL:[query URL]
                            feedClass:feedClass
                             completionHandler:handler];
}

- (GDataServiceTicketBase *)fetchPublicEntryWithURL:(NSURL *)entryURL
                                         entryClass:(Class)entryClass
                                  completionHandler:(GDataServiceEntryBaseCompletionHandler)handler {
return [self fetchObjectWithURL:entryURL
                      objectClass:entryClass
                     objectToPost:nil
                             ETag:nil
                       httpMethod:nil
                         delegate:nil
                didFinishSelector:NULL
              completionHandler:(GDataServiceCompletionHandler)handler
             retryInvocationValue:nil
                           ticket:nil];
}

- (GDataServiceTicketBase *)fetchPublicFeedWithBatchFeed:(GDataFeedBase *)batchFeed
                                              forFeedURL:(NSURL *)feedURL
                                       completionHandler:(GDataServiceFeedBaseCompletionHandler)handler {
return [self fetchPublicFeedWithBatchFeed:batchFeed
                                 forFeedURL:feedURL
                                   delegate:nil
                          didFinishSelector:NULL
                        completionHandler:(GDataServiceCompletionHandler)handler];
}

#endif // NS_BLOCKS_AVAILABLE

#pragma mark -

// Subclasses typically implement defaultServiceVersion to specify the expected
// version of the feed, but clients may also explicitly set the version
// if they are using an instance of the base class directly.
+ (NSString *)defaultServiceVersion {
  return nil;
}

- (NSString *)serviceVersion {
  if (serviceVersion_ != nil) {
    return serviceVersion_;
  }

  NSString *str = [[self class] defaultServiceVersion];
  return str;
}

- (void)setServiceVersion:(NSString *)str {
  [serviceVersion_ autorelease];
  serviceVersion_ = [str copy];
}

- (NSString *)userAgent {
  return userAgent_;
}

- (void)setExactUserAgent:(NSString *)userAgent {
  // internal use only
  [userAgent_ release];
  userAgent_ = [userAgent copy];
}

- (void)setUserAgent:(NSString *)userAgent {
  // remove whitespace and unfriendly characters
  NSString *str = GTMCleanedUserAgentString(userAgent);
  [self setExactUserAgent:str];
}

- (NSArray *)runLoopModes {
  return [fetcherService_ runLoopModes];
}

- (void)setRunLoopModes:(NSArray *)modes {
  [fetcherService_ setRunLoopModes:modes];
}

- (BOOL)shouldFetchInBackground {
  return [fetcherService_ shouldFetchInBackground];
}

- (void)setShouldFetchInBackground:(BOOL)flag {
  [fetcherService_ setShouldFetchInBackground:flag];
}

// save the username and password, converting the password to non-plaintext
- (void)setUserCredentialsWithUsername:(NSString *)username
                              password:(NSString *)password {
  if (username && ![username_ isEqual:username]) {

    // username changed; discard history so we're not caching for the wrong
    // user
    [fetcherService_ clearHistory];
  }

  [username_ release];
  username_ = [username copy];

  [password_ release];

  if (password) {
    const char *utf8password = [password UTF8String];
    size_t passwordLength = strlen(utf8password);
    password_ = [[NSMutableData alloc] initWithBytes:utf8password
                                              length:passwordLength];
    XorPlainMutableData(password_);
  } else {
    password_ = nil;
  }
}

- (NSString *)username {
  return username_;
}

// return the password as plaintext
- (NSString *)password {
  if (password_) {
    XorPlainMutableData(password_);
    NSString *result = [[[NSString alloc] initWithData:password_
                                              encoding:NSUTF8StringEncoding] autorelease];
    XorPlainMutableData(password_);
    return result;
  }
  return nil;
}

- (id)authorizer {
  return [fetcherService_ authorizer];
}

- (void)setAuthorizer:(id)obj {
  if (obj != nil) {
    // clear any existing username/password
    [self setUserCredentialsWithUsername:nil
                                password:nil];
  }

  if (obj != [fetcherService_ authorizer]) {
    [self clearResponseDataCache];

    [fetcherService_ setAuthorizer:obj];
  }
}

// Turn on data caching to receive a copy of previously-retrieved objects.
// Otherwise, fetches may return status 304 (Not Modified) rather than actual
// data
- (void)setShouldCacheResponseData:(BOOL)flag {
  [fetcherService_ setShouldCacheETaggedData:flag];
}

- (BOOL)shouldCacheResponseData {
  return [fetcherService_ shouldCacheETaggedData];
}

- (void)setResponseDataCacheCapacity:(NSUInteger)totalBytes {
  [[fetcherService_ fetchHistory] setMemoryCapacity:totalBytes];
}

- (NSUInteger)responseDataCacheCapacity {
  return [[fetcherService_ fetchHistory] memoryCapacity];
}

// reset the cache to avoid getting a Not Modified status
// based on prior queries
- (void)clearResponseDataCache {
  [fetcherService_ clearETaggedDataCache];
}

- (void)setFetcherService:(GTMHTTPFetcherService *)obj {
  [fetcherService_ autorelease];
  fetcherService_ = [obj retain];
}

- (GTMHTTPFetcherService *)fetcherService {
  return fetcherService_;
}

- (void)setCookieStorageMethod:(NSInteger)method {
  cookieStorageMethod_ = method;
}

- (NSInteger)cookieStorageMethod {
  return cookieStorageMethod_;
}

- (void)setServiceShouldFollowNextLinks:(BOOL)flag {
  serviceShouldFollowNextLinks_ = flag;
}

- (BOOL)serviceShouldFollowNextLinks {
  return serviceShouldFollowNextLinks_;
}

// The service userData becomes the initial value for each future ticket's
// userData.
//
// Since the network transactions may begin before the client has been
// returned the ticket by the fetch call, it's preferable to call
// setServiceUserData before the ticket is created rather than call the
// ticket's setUserData:.  Either way, the ticket's userData:
// method will return the value.
- (void)setServiceUserData:(id)userData {
  [serviceUserData_ autorelease];
  serviceUserData_ = [userData retain];
}

- (id)serviceUserData {
  return serviceUserData_;
}

// The service properties dictionary becomes the dictionary for each future
// ticket.

- (void)setServiceProperties:(NSDictionary *)dict {
  [serviceProperties_ autorelease];
  serviceProperties_ = [dict mutableCopy];
}

- (NSDictionary *)serviceProperties {
  // be sure the returned pointer has the life of the autorelease pool,
  // in case self is released immediately
  return [[serviceProperties_ retain] autorelease];
}

- (void)setServiceProperty:(id)obj forKey:(NSString *)key {

  if (obj == nil) {
    // user passed in nil, so delete the property
    [serviceProperties_ removeObjectForKey:key];
  } else {
    // be sure the property dictionary exists
    if (serviceProperties_ == nil) {
      [self setServiceProperties:[NSDictionary dictionary]];
    }
    [serviceProperties_ setObject:obj forKey:key];
  }
}

- (id)servicePropertyForKey:(NSString *)key {
  id obj = [serviceProperties_ objectForKey:key];

  // be sure the returned pointer has the life of the autorelease pool,
  // in case self is released immediately
  return [[obj retain] autorelease];
}

- (NSDictionary *)serviceSurrogates {
  return serviceSurrogates_;
}

- (void)setServiceSurrogates:(NSDictionary *)dict {
  [serviceSurrogates_ autorelease];
  serviceSurrogates_ = [dict retain];
}

- (BOOL)shouldServiceFeedsIgnoreUnknowns {
  return shouldServiceFeedsIgnoreUnknowns_;
}

- (void)setShouldServiceFeedsIgnoreUnknowns:(BOOL)flag {
  shouldServiceFeedsIgnoreUnknowns_ = flag;
}

- (SEL)serviceUploadProgressSelector {
  return serviceUploadProgressSelector_;
}

- (void)setServiceUploadProgressSelector:(SEL)progressSelector {
  serviceUploadProgressSelector_ = progressSelector;
}

#if NS_BLOCKS_AVAILABLE
- (void)setServiceUploadProgressHandler:(GDataServiceUploadProgressHandler)block {
  [serviceUploadProgressBlock_ autorelease];
  serviceUploadProgressBlock_ = [block copy];
}

- (GDataServiceUploadProgressHandler)serviceUploadProgressHandler {
  return serviceUploadProgressBlock_;
}
#endif

+ (NSUInteger)defaultServiceUploadChunkSize {
  // subclasses may override
  return 0;
}

- (NSUInteger)serviceUploadChunkSize {
  return uploadChunkSize_;
}

- (void)setServiceUploadChunkSize:(NSUInteger)val {

  if (val == kGDataStandardUploadChunkSize) {
    // determine an appropriate upload chunk size for the system

#if GDATA_IPHONE
    if (![GTMHTTPFetcher doesSupportSentDataCallback]) {
      // for iPhone 2, we need a small upload chunk size so there
      // are frequent intrachunk callbacks for progress monitoring
      //
      // Picasa Web Albums has a minimum 256K chunk size when uploading photos
      val = 256*1024;
    } else {
      val = 1024*1024;
    }
#else
    if (NSFoundationVersionNumber >= 751.00) {
      // Mac OS X 10.6 and later
      //
      // we'll pick a huge upload chunk size, which minimizes http overhead
      // and server effort, and we'll hope that NSURLConnection can finally
      // handle big uploads reliably
      val = 25*1024*1024;
    } else {
      // Mac OS X 10.5
      //
      // NSURLConnection is more reliable on POSTs in 10.5 than it was in
      // 10.4, but it still fails mysteriously on big uploads on some
      // systems, so we'll limit the chunks to a megabyte
      val = 1024*1024;
    }
#endif
  }
  uploadChunkSize_ = val;
}

// retrying; see comments on retry support at the top of GTMHTTPFetcher
- (BOOL)isServiceRetryEnabled {
  return isServiceRetryEnabled_;
}

- (void)setIsServiceRetryEnabled:(BOOL)flag {
  isServiceRetryEnabled_ = flag;
}

- (SEL)serviceRetrySelector {
  return serviceRetrySEL_;
}

- (void)setServiceRetrySelector:(SEL)theSel {
  serviceRetrySEL_ = theSel;
}

- (NSTimeInterval)serviceMaxRetryInterval {
  return serviceMaxRetryInterval_;
}

- (void)setServiceMaxRetryInterval:(NSTimeInterval)secs {
  serviceMaxRetryInterval_ = secs;
}

- (id)operationQueue {
  return operationQueue_;
}

- (void)setOperationQueue:(id)queue {
  [operationQueue_ autorelease];
  operationQueue_ = [queue retain];
}

#pragma mark -

+ (NSBundle *)owningBundle {
  NSBundle *bundle = [NSBundle bundleForClass:self];
  if (bundle == nil
      || [[bundle bundleIdentifier] isEqual:@"com.google.GDataFramework"]) {

    bundle = [NSBundle mainBundle];
  }
  return bundle;
}

// return a generic name and version for the current application; this avoids
// anonymous server transactions.  Applications should call setUserAgent
// to avoid the need for this method to be used.
+ (NSString *)defaultApplicationIdentifier {
  NSBundle *bundle = [[self class] owningBundle];
  NSString *appID = GTMApplicationIdentifier(bundle);
  return appID;
}
@end

@implementation GDataServiceTicketBase

+ (id)ticketForService:(GDataServiceBase *)service {
  return [[[self alloc] initWithService:service] autorelease];
}

- (id)initWithService:(GDataServiceBase *)service {
  self = [super init];
  if (self) {
    service_ = [service retain];

    [self setUserData:[service serviceUserData]];
    [self setProperties:[service serviceProperties]];
    [self setSurrogates:[service serviceSurrogates]];
    [self setUploadProgressSelector:[service serviceUploadProgressSelector]];
    [self setIsRetryEnabled:[service isServiceRetryEnabled]];
    [self setRetrySelector:[service serviceRetrySelector]];
    [self setMaxRetryInterval:[service serviceMaxRetryInterval]];
    [self setShouldFollowNextLinks:[service serviceShouldFollowNextLinks]];
    [self setShouldFeedsIgnoreUnknowns:[service shouldServiceFeedsIgnoreUnknowns]];
#if NS_BLOCKS_AVAILABLE
    [self setUploadProgressHandler:[service serviceUploadProgressHandler]];
#endif
    [self setAuthorizer:[service authorizer]];
  }
  return self;
}

- (void)dealloc {
  [service_ release];

  [userData_ release];
  [ticketProperties_ release];
  [surrogates_ release];

  [currentFetcher_ release];
  [objectFetcher_ release];

#if NS_BLOCKS_AVAILABLE
  [uploadProgressBlock_ release];
#endif
  [postedObject_ release];
  [fetchedObject_ release];
  [accumulatedFeed_ release];
  [fetchError_ release];

  [parseOperation_ release];

  [authorizer_ release];

  [super dealloc];
}

- (NSString *)description {
  NSString *const templateStr = @"%@ %p: {service:%@ currentFetcher:%@ userData:%@}";
  return [NSString stringWithFormat:templateStr,
    [self class], self, service_, currentFetcher_, userData_];
}

- (void)pauseUpload {
  BOOL canPause = [objectFetcher_ respondsToSelector:@selector(pauseFetching)];
  GDATA_DEBUG_ASSERT(canPause, @"unpauseable ticket");

  if (canPause) {
    [(GTMHTTPUploadFetcher *)objectFetcher_ pauseFetching];
  }
}

- (void)resumeUpload {
  BOOL canResume = [objectFetcher_ respondsToSelector:@selector(resumeFetching)];
  GDATA_DEBUG_ASSERT(canResume, @"unresumable ticket");

  if (canResume) {
    [(GTMHTTPUploadFetcher *)objectFetcher_ resumeFetching];
  }
}

- (BOOL)isUploadPaused {
  BOOL isPausable = [objectFetcher_ respondsToSelector:@selector(isPaused)];
  GDATA_DEBUG_ASSERT(isPausable, @"unpauseable ticket");

  if (isPausable) {
    return [(GTMHTTPUploadFetcher *)objectFetcher_ isPaused];
  }
  return NO;
}

- (void)cancelTicket {
  NSOperation *op = [self parseOperation];
  [op cancel];
  [self setParseOperation:nil];

  [objectFetcher_ stopFetching];
  [objectFetcher_ setProperties:nil];

  [self setObjectFetcher:nil];
  [self setCurrentFetcher:nil];
  [self setUserData:nil];
  [self setProperties:nil];

  [self setUploadProgressSelector:NULL];
#if NS_BLOCKS_AVAILABLE
  [self setUploadProgressHandler:nil];
#endif

  [service_ autorelease];
  service_ = nil;
}

- (id)service {
  return service_;
}

- (id)userData {
  return [[userData_ retain] autorelease];
}

- (void)setUserData:(id)obj {
  [userData_ autorelease];
  userData_ = [obj retain];
}

- (void)setProperties:(NSDictionary *)dict {
  [ticketProperties_ autorelease];
  ticketProperties_ = [dict mutableCopy];
}

- (NSDictionary *)properties {
  // be sure the returned pointer has the life of the autorelease pool,
  // in case self is released immediately
  return [[ticketProperties_ retain] autorelease];
}

- (void)setProperty:(id)obj forKey:(NSString *)key {

  if (obj == nil) {
    // user passed in nil, so delete the property
    [ticketProperties_ removeObjectForKey:key];
  } else {
    // be sure the property dictionary exists
    if (ticketProperties_ == nil) {
      [self setProperties:[NSDictionary dictionary]];
    }
    [ticketProperties_ setObject:obj forKey:key];
  }
}

- (id)propertyForKey:(NSString *)key {
  id obj = [ticketProperties_ objectForKey:key];

  // be sure the returned pointer has the life of the autorelease pool,
  // in case self is released immediately
  return [[obj retain] autorelease];
}

- (NSDictionary *)surrogates {
  return surrogates_;
}

- (void)setSurrogates:(NSDictionary *)dict {
  [surrogates_ autorelease];
  surrogates_ = [dict retain];
}

- (SEL)uploadProgressSelector {
  return uploadProgressSelector_;
}

- (void)setUploadProgressSelector:(SEL)progressSelector {
  uploadProgressSelector_ = progressSelector;

  // if the user is turning on the progress selector in the ticket after the
  // ticket's fetcher has been created, we need to give the fetcher our sentData
  // callback.
  if (progressSelector != NULL) {
    SEL sentDataSel = @selector(objectFetcher:didSendBytes:totalBytesSent:totalBytesExpectedToSend:);
    [[self objectFetcher] setSentDataSelector:sentDataSel];
  }
}

#if NS_BLOCKS_AVAILABLE
- (void)setUploadProgressHandler:(GDataServiceUploadProgressHandler)block {
  [uploadProgressBlock_ autorelease];
  uploadProgressBlock_ = [block copy];

  if (uploadProgressBlock_) {
    // as above, we need the fetcher to call us back when bytes are sent
    SEL sentDataSel = @selector(objectFetcher:didSendBytes:totalBytesSent:totalBytesExpectedToSend:);
    [[self objectFetcher] setSentDataSelector:sentDataSel];
  }
}

- (GDataServiceUploadProgressHandler)uploadProgressHandler {
  return uploadProgressBlock_;
}
#endif

- (BOOL)shouldFollowNextLinks {
  return shouldFollowNextLinks_;
}

- (void)setShouldFollowNextLinks:(BOOL)flag {
  shouldFollowNextLinks_ = flag;
}

- (BOOL)shouldFeedsIgnoreUnknowns {
  return shouldFeedsIgnoreUnknowns_;
}

- (void)setShouldFeedsIgnoreUnknowns:(BOOL)flag {
  shouldFeedsIgnoreUnknowns_ = flag;
}

- (BOOL)isRetryEnabled {
  return isRetryEnabled_;
}

- (void)setIsRetryEnabled:(BOOL)flag {
  isRetryEnabled_ = flag;
};

- (SEL)retrySelector {
  return retrySEL_;
}

- (void)setRetrySelector:(SEL)theSelector {
  retrySEL_ = theSelector;
}

- (NSTimeInterval)maxRetryInterval {
  return maxRetryInterval_;
}

- (void)setMaxRetryInterval:(NSTimeInterval)secs {
  maxRetryInterval_ = secs;
}

- (GTMHTTPFetcher *)currentFetcher {
  return [[currentFetcher_ retain] autorelease];
}

- (void)setCurrentFetcher:(GTMHTTPFetcher *)fetcher {
  [currentFetcher_ autorelease];
  currentFetcher_ = [fetcher retain];
}

- (GTMHTTPFetcher *)objectFetcher {
  return [[objectFetcher_ retain] autorelease];
}

- (void)setObjectFetcher:(GTMHTTPFetcher *)fetcher {
  [objectFetcher_ autorelease];
  objectFetcher_ = [fetcher retain];
}

- (NSInteger)statusCode {
  return [objectFetcher_ statusCode];
}

- (void)setHasCalledCallback:(BOOL)flag {
  hasCalledCallback_ = flag;
}

- (BOOL)hasCalledCallback {
  return hasCalledCallback_;
}

- (void)setPostedObject:(GDataObject *)obj {
  [postedObject_ autorelease];
  postedObject_ = [obj retain];
}

- (id)postedObject {
  return postedObject_;
}

- (void)setFetchedObject:(GDataObject *)obj {
  [fetchedObject_ autorelease];
  fetchedObject_ = [obj retain];
}

- (GDataObject *)fetchedObject {
  return fetchedObject_;
}

- (void)setFetchError:(NSError *)error {
  [fetchError_ autorelease];
  fetchError_ = [error retain];
}

- (NSError *)fetchError {
  return fetchError_;
}

- (void)setAccumulatedFeed:(GDataFeedBase *)feed {
  [accumulatedFeed_ autorelease];
  accumulatedFeed_ = [feed retain];
}

// accumulateFeed is used by the service to append an incomplete feed
// to the ticket when shouldFollowNextLinks is enabled
- (GDataFeedBase *)accumulatedFeed {
  return accumulatedFeed_;
}

- (void)accumulateFeed:(GDataFeedBase *)newFeed {

  GDataFeedBase *accumulatedFeed = [self accumulatedFeed];
  if (accumulatedFeed == nil) {

    // the new feed becomes the accumulated feed
    [self setAccumulatedFeed:newFeed];

  } else {

    // A feed's addEntry: routine requires that a new entry's parent
    // not be set to some other feed.  Calling addEntryWithEntry: would make
    // a new, parentless copy of the entry for us, but that would be a needless
    // copy. Instead, we'll explicitly clear the entry's parent and call
    // addEntry:.

    NSArray *newEntries = [newFeed entries];

    for (GDataEntryBase *entry in newEntries) {
      [entry setParent:nil];
      [accumulatedFeed addEntry:entry];
    }
  }
}

- (void)setNextLinksFollowedCounter:(NSUInteger)val {
  nextLinksFollowedCounter_ = val;
}

- (NSUInteger)nextLinksFollowedCounter {
  return nextLinksFollowedCounter_;
}

- (NSOperation *)parseOperation {
  return parseOperation_;
}

- (void)setParseOperation:(NSOperation *)op {
  [parseOperation_ autorelease];
  parseOperation_ = [op retain];
}

// OAuth support
- (id)authorizer {
  return authorizer_;
}

- (void)setAuthorizer:(id)obj {
  [authorizer_ autorelease];
  authorizer_ = [obj retain];

  GDATA_DEBUG_ASSERT([obj respondsToSelector:@selector(authorizeRequest:delegate:didFinishSelector:)]
                     || obj == nil, @"invalid authorization object");
}

@end
