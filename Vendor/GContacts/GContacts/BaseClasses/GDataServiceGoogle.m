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
//  GDataServiceGoogle.m
//

#define GDATASERVICEGOOGLE_DEFINE_GLOBALS 1
#import "GDataServiceGoogle.h"

#import "GDataAuthenticationFetcher.h"

extern NSString* const kFetcherRetryInvocationKey;

static NSString* const kCaptchaFullURLKey = @"CaptchaFullUrl";
static NSString* const kFetcherTicketKey = @"_ticket"; // same as in GDataServiceBase
static NSString* const kFetcherDependentInvocationsKey = @"_invocations";

static NSString* const kAuthDelegateKey = @"_delegate";
static NSString* const kAuthSelectorKey = @"_sel";

enum {
  // indices of parameters for the post-authentication invocation,
  // matching GDataServiceBase's method
  // fetchObjectWithURL:objectClass:objectToPost:ETag:httpMethod:delegate:didFinishSelector:completionHandler:retryInvocationValue:ticket:

  kInvocationObjectURLIndex = 2,
  kInvocationObjectClassIndex,
  kInvocationObjectToPostIndex,
  kInvocationObjectETagIndex,
  kInvocationHTTPMethodIndex,
  kInvocationDelegateIndex,
  kInvocationFinishedSelectorIndex,
  kInvocationCompletionHandlerIndex,
  kInvocationRetryInvocationValueIndex,
  kInvocationTicketIndex
};


@interface GDataServiceBase (ProtectedMethods)
- (GDataServiceTicketBase *)fetchObjectWithURL:(NSURL *)feedURL
                                   objectClass:(Class)objectClass
                                  objectToPost:(GDataObject *)objectToPost
                                          ETag:(NSString *)etag
                                    httpMethod:(NSString *)httpMethod
                                      delegate:(id)delegate
                             didFinishSelector:(SEL)finishedSelector
                             completionHandler:(id)completionHandler
                          retryInvocationValue:(NSValue *)retryInvocationValue
                                        ticket:(GDataServiceTicketBase *)ticket;
@end

@interface GDataServiceGoogle (PrivateMethods)
- (GTMHTTPFetcher *)authenticationFetcher;
- (NSError *)cannotCreateAuthFetcherError;

- (GDataServiceTicket *)deferUntilAuthenticationForInvocation:(NSInvocation *)invocation;

- (void)authFetcher:(GTMHTTPFetcher *)fetcher failedWithError:(NSError *)error data:(NSData *)data;
- (NSError *)errorForAuthFetcherStatus:(NSInteger)status data:(NSData *)data;

- (void)authFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error;
- (BOOL)authFetcher:(GTMHTTPFetcher *)fetcher willRetry:(BOOL)willRetry forError:(NSError *)error;

- (void)standaloneAuthFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error;
- (void)standaloneAuthFetcher:(GTMHTTPFetcher *)fetcher failedWithError:(NSError *)error data:(NSData *)data;

- (void)addNamespacesIfNoneToObject:(GDataObject *)obj;
@end


@implementation GDataServiceGoogle

+ (Class)ticketClass {
  return [GDataServiceTicket class];
}

- (void)dealloc {
  [captchaToken_ release];
  [captchaAnswer_ release];
  [authToken_ release];
  [authSubToken_ release];
  [accountType_ release];
  [signInDomain_ release];
  [serviceID_ release];
  [pendingAuthFetcher_ release];
  [credentialDate_ release];
  [super dealloc];
}

#pragma mark -

- (NSDictionary *)customAuthenticationRequestHeaders {
  // subclasses may override
  return nil;
}

- (GTMHTTPFetcher *)authenticationFetcher {
  // internal routine
  //
  // create and return an authentication fetcher, either for use alone or as
  // part of a GData object fetch sequence
  NSDictionary *customHeaders = [self customAuthenticationRequestHeaders];
  NSString *domain = [self signInDomain];
  NSString *serviceID = [self serviceID];
  NSString *accountType = [self accountType];
  NSString *password = [self password];

  NSString *userAgent = [self userAgent];
  if ([userAgent length] == 0) {
    userAgent = [[self class] defaultApplicationIdentifier];
  }

  NSDictionary *captchaDict = nil;
  if ([captchaToken_ length] > 0 && [captchaAnswer_ length] > 0) {
    captchaDict = [NSDictionary dictionaryWithObjectsAndKeys:
                   captchaToken_, @"logintoken",
                   captchaAnswer_, @"logincaptcha", nil];
  }

  GTMHTTPFetcher *fetcher;
  fetcher = [GDataAuthenticationFetcher authTokenFetcherWithUsername:username_
                                                            password:password
                                                             service:serviceID
                                                              source:userAgent
                                                        signInDomain:domain
                                                         accountType:accountType
                                                additionalParameters:captchaDict
                                                       customHeaders:customHeaders];

  [fetcher setRunLoopModes:[self runLoopModes]];
  [fetcher setFetchHistory:[fetcherService_ fetchHistory]];

  [fetcher setRetryEnabled:[self isServiceRetryEnabled]];
  [fetcher setMaxRetryInterval:[self serviceMaxRetryInterval]];
  // note: this does not use the custom serviceRetrySelector, as that
  //       assumes there is a ticket associated with the fetcher

  return fetcher;
}

- (NSError *)cannotCreateAuthFetcherError {
  NSDictionary *userInfo;
  userInfo = [NSDictionary dictionaryWithObject:@"empty username/password"
                                         forKey:kGDataServerErrorStringKey];

  NSError *error = [NSError errorWithDomain:kGDataServiceErrorDomain
                                       code:-1
                                   userInfo:userInfo];
  return error;
}

- (void)addDependentInvocation:(NSInvocation *)invocation
                 toAuthFetcher:(GTMHTTPFetcher *)fetcher {
  // add the invocation to the list in the fetcher's properties
  NSMutableArray *array = [fetcher propertyForKey:kFetcherDependentInvocationsKey];
  if (array == nil) {
    array = [NSMutableArray arrayWithObject:invocation];
    [fetcher setProperty:array
                  forKey:kFetcherDependentInvocationsKey];
  } else {
    [array addObject:invocation];
  }
}

// This routine creates a new auth fetcher, and saves the invocation in the
// list of dependencies to call when the auth fetcher completes
- (GDataServiceTicket *)authenticateThenInvoke:(NSInvocation *)invocation {

  // this method always creates a new auth fetcher, so there should be none
  // already pending
  GDATA_DEBUG_ASSERT([self pendingAuthFetcher] == nil,
                     @"unexpected auth fetcher");

  GDataServiceTicket *ticket;
  [invocation getArgument:&ticket atIndex:kInvocationTicketIndex];

  GTMHTTPFetcher *fetcher = [self authenticationFetcher];
  if (fetcher) {

    [self addDependentInvocation:invocation
                   toAuthFetcher:fetcher];

    // store the ticket in the same property the base class uses when
    // fetching so that notification-time code can find the ticket easily
    [fetcher setProperty:ticket
                  forKey:kFetcherTicketKey];

    if ([ticket retrySelector]) {
      [fetcher setRetrySelector:@selector(authFetcher:willRetry:forError:)];
    }

    [ticket setAuthFetcher:fetcher];
    [ticket setCurrentFetcher:fetcher];

    [self setPendingAuthFetcher:fetcher];

    [fetcher setComment:@"API authentication"];

    [fetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(authFetcher:finishedWithData:error:)];

    return ticket;

  } else {
    // we could not initiate a fetch; tell the client

    id delegate;
    SEL finishedSelector;

    [invocation getArgument:&delegate         atIndex:kInvocationDelegateIndex];
    [invocation getArgument:&finishedSelector atIndex:kInvocationFinishedSelectorIndex];

    NSError *error = [self cannotCreateAuthFetcherError];

    if (finishedSelector) {
      [[self class] invokeCallback:finishedSelector
                            target:delegate
                            ticket:ticket
                            object:nil
                             error:error];
    }

#if NS_BLOCKS_AVAILABLE
    GDataServiceGoogleCompletionHandler completionHandler;
    [invocation getArgument:&completionHandler
                    atIndex:kInvocationCompletionHandlerIndex];

    if (completionHandler) {
      completionHandler(ticket, nil, error);
    }
#endif

    return nil;
  }
}

- (void)authFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
  if (error) {
    [self authFetcher:fetcher failedWithError:error data:data];
    return;
  }

  // authentication fetch completed
  NSDictionary *responseDict = [GDataUtilities dictionaryWithResponseData:data];
  NSString *authToken = [responseDict objectForKey:kGDataServiceAuthTokenKey];

  // if this is the pending auth fetcher, save the token for future auths
  if (fetcher == [self pendingAuthFetcher]) {
    [self setAuthToken:authToken];
    [self setPendingAuthFetcher:nil];
  }

  if ([authToken length] > 0) {
    // there was an auth token, so iterate through the callbacks
    NSArray *dependentInvocations = [fetcher propertyForKey:kFetcherDependentInvocationsKey];

    for (NSInvocation *invocation in dependentInvocations) {
      // set the ticket's currentFetcher to nil before we invoke the fetch of
      // the GData object so the user won't mistakenly see indication that
      // the auth fetch is still in progress
      GDataServiceTicket *ticket;

      [invocation getArgument:&ticket atIndex:kInvocationTicketIndex];
      [ticket setCurrentFetcher:nil];
      [ticket setAuthToken:authToken];

      [invocation invoke];
    }
  } else {
    // there was no auth token
    NSDictionary *userInfo;
    userInfo = [NSDictionary dictionaryWithObject:data
                                           forKey:kGTMHTTPFetcherStatusDataKey];
    NSError *error = [NSError errorWithDomain:kGTMHTTPFetcherStatusDomain
                                         code:kGTMHTTPFetcherStatusForbidden
                                     userInfo:userInfo];

    [self authFetcher:fetcher failedWithError:error data:data];
  }

  // the properties contain the ticket which points to the
  // fetcher; free those now to break the retain cycle
  [fetcher setProperties:nil];
}

- (void)authFetcher:(GTMHTTPFetcher *)fetcher failedWithError:(NSError *)error data:(NSData *)data {
  if (fetcher == [self pendingAuthFetcher]) {
    [self setAuthToken:nil];
    [self setPendingAuthFetcher:nil];
  }

  if ([[error domain] isEqual:kGTMHTTPFetcherStatusDomain]) {
    NSInteger status = [error code];
    error = [self errorForAuthFetcherStatus:status data:data];
  }

  // iterate through the callbacks to tell each that the fetch failed
  NSArray *dependentInvocations = [[[fetcher propertyForKey:kFetcherDependentInvocationsKey] retain] autorelease];
  [fetcher setProperties:nil];

  for (NSInvocation *invocation in dependentInvocations) {
    id delegate;
    SEL finishedSelector;
    GDataServiceTicket *ticket;

    [invocation getArgument:&delegate         atIndex:kInvocationDelegateIndex];
    [invocation getArgument:&finishedSelector atIndex:kInvocationFinishedSelectorIndex];
    [invocation getArgument:&ticket           atIndex:kInvocationTicketIndex];

    if (finishedSelector) {
      [[self class] invokeCallback:finishedSelector
                            target:delegate
                            ticket:ticket
                            object:nil
                             error:error];
    }

#if NS_BLOCKS_AVAILABLE
    GDataServiceGoogleCompletionHandler completionHandler;
    [invocation getArgument:&completionHandler
                    atIndex:kInvocationCompletionHandlerIndex];

    if (completionHandler) {
      completionHandler(ticket, nil, error);
    }
#endif

    [ticket setFetchError:error];
    [ticket setHasCalledCallback:YES];
    [ticket setCurrentFetcher:nil];
  }
}

- (NSError *)errorForAuthFetcherStatus:(NSInteger)status data:(NSData *)data {
  // convert the data into a useful NSError
  NSMutableDictionary *userInfo = nil;
  if ([data length] > 0) {
    // put user-readable error info into the error object
    NSDictionary *responseDict = [GDataUtilities dictionaryWithResponseData:data];
    userInfo = [NSMutableDictionary dictionaryWithDictionary:responseDict];

    // look for the partial-path URL to a captch image (which the user
    // can retrieve from the userInfo later with the -captchaURL method)
    NSString *str = [userInfo objectForKey:@"CaptchaUrl"];
    if ([str length] > 0) {

      // since we know the sign-in domain now, make a string with the full URL
      NSString *captchaURLString;

      if ([str hasPrefix:@"http:"] || [str hasPrefix:@"https:"]) {
        // the server gave us a full URL
        captchaURLString = str;
      } else {
        // the server gave us a relative URL
        captchaURLString = [NSString stringWithFormat:@"https://%@/accounts/%@",
                            [self signInDomain], str];
      }

      [userInfo setObject:captchaURLString forKey:kCaptchaFullURLKey];
    }

    // The auth server returns errors as "Error" but generally the library
    // provides errors in the userInfo as "error".  We'll copy over the
    // auth server's error to "error" as a convenience to clients, and hope
    // few are confused about why the error appears twice in the dictionary.
    NSString *authErrStr = [userInfo authenticationError];
    if (authErrStr != nil
        && [userInfo objectForKey:kGDataServerErrorStringKey] == nil) {
      [userInfo setObject:authErrStr forKey:kGDataServerErrorStringKey];
    }

    // copy additional error info into the NSError key so it shows up in the
    // error description string
    NSString *authInfoStr = [userInfo objectForKey:kGDataServerInfoStringKey];
    if (authInfoStr != nil) {
      [userInfo setObject:authInfoStr forKey:NSLocalizedFailureReasonErrorKey];
    }
  }

  NSError *error = [NSError errorWithDomain:kGDataServiceErrorDomain
                                       code:status
                                   userInfo:userInfo];
  return error;
}

// The auth fetcher may call into this retry method; this one invokes the
// first retry selector found among the tickets dependent on this auth fetcher
- (BOOL)authFetcher:(GTMHTTPFetcher *)fetcher willRetry:(BOOL)willRetry forError:(NSError *)error {

  NSArray *dependentInvocations = [fetcher propertyForKey:kFetcherDependentInvocationsKey];

  for (NSInvocation *invocation in dependentInvocations) {

    id delegate;
    GDataServiceTicket *ticket;

    [invocation getArgument:&delegate atIndex:kInvocationDelegateIndex];
    [invocation getArgument:&ticket   atIndex:kInvocationTicketIndex];

    SEL retrySelector = [ticket retrySelector];
    if (retrySelector) {

      willRetry = [self invokeRetrySelector:retrySelector
                                   delegate:delegate
                                     ticket:ticket
                                  willRetry:willRetry
                                      error:error];
      break;
    }
  }
  return willRetry;
}

// This is the main routine for invoking transactions with with Google services.
// If there is no auth token available, this routine authenticates before invoking
// the action.
- (GDataServiceTicket *)fetchAuthenticatedObjectWithURL:(NSURL *)objectURL
                                            objectClass:(Class)objectClass
                                           objectToPost:(GDataObject *)objectToPost
                                                   ETag:(NSString *)etag
                                             httpMethod:(NSString *)httpMethod
                                               delegate:(id)delegate
                                      didFinishSelector:(SEL)finishedSelector
                                      completionHandler:(GDataServiceGoogleCompletionHandler)completionHandler {

  // make an invocation for this call
  GDataServiceTicket *result = nil;

  SEL theSEL = @selector(fetchObjectWithURL:objectClass:objectToPost:ETag:httpMethod:delegate:didFinishSelector:completionHandler:retryInvocationValue:ticket:);

  GDataServiceTicket *ticket = [GDataServiceTicket ticketForService:self];

  if (objectToPost) {
    // be sure the postedObject is available to the callbacks even if we fail
    // in authenticating, before getting around to trying to upload it
    [ticket setPostedObject:objectToPost];
  }

#if NS_BLOCKS_AVAILABLE
  if (completionHandler) {
    // copy the completion handler to the heap now, before creating the
    // invocation that will retain it
    completionHandler = [[completionHandler copy] autorelease];
  }
#endif

  NSMethodSignature *signature = [self methodSignatureForSelector:theSEL];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setSelector:theSEL];
  [invocation setTarget:self];
  [invocation setArgument:&objectURL         atIndex:kInvocationObjectURLIndex];
  [invocation setArgument:&objectClass       atIndex:kInvocationObjectClassIndex];
  [invocation setArgument:&objectToPost      atIndex:kInvocationObjectToPostIndex];
  [invocation setArgument:&etag              atIndex:kInvocationObjectETagIndex];
  [invocation setArgument:&httpMethod        atIndex:kInvocationHTTPMethodIndex];
  [invocation setArgument:&delegate          atIndex:kInvocationDelegateIndex];
  [invocation setArgument:&finishedSelector  atIndex:kInvocationFinishedSelectorIndex];
  [invocation setArgument:&completionHandler atIndex:kInvocationCompletionHandlerIndex];
  [invocation setArgument:&ticket            atIndex:kInvocationTicketIndex];

  NSValue *noRetryInvocation = nil;
  [invocation setArgument:&noRetryInvocation atIndex:kInvocationRetryInvocationValueIndex];

  [invocation retainArguments];

  if ([username_ length] == 0) {
    // There's no username, so we can proceed to fetch.  We won't be retrying
    // this invocation if it fails.
    [invocation invoke];
    [invocation getReturnValue:&result];

  } else if ([[ticket authToken] length] > 0 || [authSubToken_ length] > 0) {
    // There is already an auth token.
    //
    // If the auth token has expired, we'll be retrying this same invocation
    // after getting a fresh token

    // Having the invocation retain itself as a parameter would cause a
    // retain loop, so we'll have it retain an NSValue of itself
    NSValue *invocationValue = [NSValue valueWithNonretainedObject:invocation];

    [invocation setArgument:&invocationValue
                    atIndex:kInvocationRetryInvocationValueIndex];
    [invocation invoke];
    [invocation getReturnValue:&result];

  } else {
    // we need to authenticate first.  We won't be retrying this invocation if
    // it fails.
    result = [self deferUntilAuthenticationForInvocation:invocation];
  }
  return result;
}

- (GDataServiceTicket *)deferUntilAuthenticationForInvocation:(NSInvocation *)invocation {

  GDataServiceTicket *ticket = nil;

  GTMHTTPFetcher *pendingAuthFetcher = [self pendingAuthFetcher];
  if (pendingAuthFetcher == nil) {
    // there is no pending auth fetcher, so create a new one
    ticket = [self authenticateThenInvoke:invocation];
  } else {
    // there is already an auth fetcher pending; make this fetch
    // dependent on it
    [self addDependentInvocation:invocation
                   toAuthFetcher:pendingAuthFetcher];

    [invocation getArgument:&ticket atIndex:kInvocationTicketIndex];

    [ticket setAuthFetcher:pendingAuthFetcher];
    [ticket setCurrentFetcher:pendingAuthFetcher];
  }
  return ticket;
}

// override the base class's failure handler to look for a session expired error
- (void)objectFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
  // check for an expired token
  NSInteger code = [error code];
  if (code == kGTMHTTPFetcherStatusUnauthorized
      || code == kGTMHTTPFetcherStatusForbidden) {

    NSInvocation *retryInvocation = [fetcher propertyForKey:kFetcherRetryInvocationKey];
    if (retryInvocation) {
      // clear out the ticket's auth token
      GDataServiceTicket *ticket = nil;
      [retryInvocation getArgument:&ticket atIndex:kInvocationTicketIndex];
      [ticket setAuthToken:nil];

      // avoid an infinite loop: remove the retry invocation before re-invoking
      NSValue *noRetryInvocation = nil;
      [retryInvocation setArgument:&noRetryInvocation
                           atIndex:kInvocationRetryInvocationValueIndex];

      // if the credential has changed, we don't want to try reauthentication
      // since it would be with a different username and password
      if (AreEqualOrBothNil([self credentialDate], [ticket credentialDate])) {

        [self deferUntilAuthenticationForInvocation:retryInvocation];
        return;
      }
    }
  }

  [super objectFetcher:fetcher finishedWithData:data error:error];
}

- (void)stopAuthenticationForTicket:(GDataServiceTicket *)ticket {
  // remove this ticket from the auth fetcher's list of ticket invocations
  GTMHTTPFetcher *authFetcher = [ticket authFetcher];

  // find this ticket's invocation in the auth fetcher's dependencies
  NSMutableArray *dependentInvocations = [authFetcher propertyForKey:kFetcherDependentInvocationsKey];
  for (NSInvocation *invocation in dependentInvocations) {
    // get the ticket from the invocation's arguments
    GDataServiceTicket *invTicket;
    [invocation getArgument:&invTicket atIndex:kInvocationTicketIndex];

    if (ticket == invTicket) {
      // we found the desired ticket; remove it from the list of dependents
      [dependentInvocations removeObject:invocation];
      break;
    }
  }

  if ([dependentInvocations count] == 0) {
    // this was the only dependent invocation, so we can discard the auth
    // fetcher
    [authFetcher stopFetching];
    [authFetcher setProperty:nil
                      forKey:kFetcherDependentInvocationsKey];
    if (authFetcher == [self pendingAuthFetcher]) {
      [self setPendingAuthFetcher:nil];
    }
  }

  // this ticket no longer has an associated auth fetcher
  [ticket setAuthFetcher:nil];
}


#pragma mark -

// Standalone auth: authenticate without fetching a feed or entry
//
// authSelector has a signature matching:
//   - (void)ticket:(GDataServiceTicket *)ticket authenticatedWithError:(NSError *)error;

- (GDataServiceTicket *)authenticateWithDelegate:(id)delegate
                         didAuthenticateSelector:(SEL)authSelector {
  GTMAssertSelectorNilOrImplementedWithArgs(delegate, authSelector, @encode(GDataServiceGoogle *), @encode(NSError *), 0);

  // make a new auth fetcher
  GTMHTTPFetcher *fetcher = [self authenticationFetcher];
  if (fetcher) {

    NSString *selStr = NSStringFromSelector(authSelector);
    [fetcher setProperty:delegate forKey:kAuthDelegateKey];
    [fetcher setProperty:selStr forKey:kAuthSelectorKey];

    GDataServiceTicket *ticket = [GDataServiceTicket ticketForService:self];
    [ticket setAuthFetcher:fetcher];
    [fetcher setProperty:ticket forKey:kFetcherTicketKey];

    [fetcher setComment:@"API authentication"];

    BOOL flag = [fetcher beginFetchWithDelegate:self
                              didFinishSelector:@selector(standaloneAuthFetcher:finishedWithData:error:)];
    if (flag) {
      return ticket;
    } else {
      // failed to start the fetch; the fetch failed callback was called
      return nil;
    }
  }

  // we could not initiate a fetch; tell the client
  if (authSelector) {
    NSError *error = [self cannotCreateAuthFetcherError];

    [delegate performSelector:authSelector
                   withObject:nil
                   withObject:error];
  }
  return nil;
}

- (void)standaloneAuthFetcher:(GTMHTTPFetcher *)fetcher
             finishedWithData:(NSData *)data
                        error:(NSError *)error {
  if (error) {
    [self standaloneAuthFetcher:fetcher failedWithError:error data:data];
    return;
  }

  NSDictionary *responseDict = [GDataUtilities dictionaryWithResponseData:data];

  NSString *authToken = [responseDict objectForKey:kGDataServiceAuthTokenKey];

  // save the new auth token, even if it's empty
  [self setAuthToken:authToken];

  GDataServiceTicket *ticket = [fetcher propertyForKey:kFetcherTicketKey];
  [ticket setAuthToken:authToken];

  NSString *selStr = [fetcher propertyForKey:kAuthSelectorKey];
  id delegate = [fetcher propertyForKey:kAuthDelegateKey];
  SEL authSelector = NSSelectorFromString(selStr);

  if ([authToken length] > 0) {
    // succeeded
    if (authSelector) {
      [delegate performSelector:authSelector
                     withObject:ticket
                     withObject:nil];
    }

    [ticket setAuthFetcher:nil];

    // avoid a retain cycle
    [fetcher setProperties:nil];
  } else {
    // failed: there was no auth token
    NSError *error = [self errorForAuthFetcherStatus:kGTMHTTPFetcherStatusForbidden
                                                data:data];
    [self standaloneAuthFetcher:fetcher failedWithError:error data:data];
  }
}

- (void)standaloneAuthFetcher:(GTMHTTPFetcher *)fetcher
              failedWithError:(NSError *)error
                         data:(NSData *)data {
  // failed to authenticate
  if ([[error domain] isEqual:kGTMHTTPFetcherStatusDomain]) {
    NSInteger status = [error code];
    error = [self errorForAuthFetcherStatus:status data:data];
  }

  NSString *selStr = [fetcher propertyForKey:kAuthSelectorKey];
  id delegate = [fetcher propertyForKey:kAuthDelegateKey];
  SEL authSelector = NSSelectorFromString(selStr);

  GDataServiceTicket *ticket = [fetcher propertyForKey:kFetcherTicketKey];
  [delegate performSelector:authSelector
                 withObject:ticket
                 withObject:error];

  [ticket setAuthFetcher:nil];

  // avoid a retain cycle
  [fetcher setProperties:nil];
}


#pragma mark -

- (GDataServiceTicket *)fetchFeedWithURL:(NSURL *)feedURL
                                delegate:(id)delegate
                       didFinishSelector:(SEL)finishedSelector {

  return [self fetchFeedWithURL:feedURL
                      feedClass:kGDataUseRegisteredClass
                           ETag:nil
                       delegate:delegate
              didFinishSelector:finishedSelector];
}

- (GDataServiceTicket *)fetchFeedWithURL:(NSURL *)feedURL
                               feedClass:(Class)feedClass
                                delegate:(id)delegate
                       didFinishSelector:(SEL)finishedSelector {

  return [self fetchFeedWithURL:feedURL
                      feedClass:feedClass
                           ETag:nil
                       delegate:delegate
              didFinishSelector:finishedSelector];
}

- (GDataServiceTicket *)fetchFeedWithURL:(NSURL *)feedURL
                               feedClass:(Class)feedClass
                                    ETag:(NSString *)etag
                                delegate:(id)delegate
                       didFinishSelector:(SEL)finishedSelector {

  return [self fetchAuthenticatedObjectWithURL:feedURL
                                   objectClass:feedClass
                                  objectToPost:nil
                                          ETag:etag
                                    httpMethod:nil
                                      delegate:delegate
                             didFinishSelector:finishedSelector
                             completionHandler:NULL];
}

- (GDataServiceTicket *)fetchEntryWithURL:(NSURL *)entryURL
                                 delegate:(id)delegate
                        didFinishSelector:(SEL)finishedSelector {

  return [self fetchEntryWithURL:entryURL
                      entryClass:kGDataUseRegisteredClass
                            ETag:nil
                        delegate:delegate
               didFinishSelector:finishedSelector];
}

- (GDataServiceTicket *)fetchEntryWithURL:(NSURL *)entryURL
                               entryClass:(Class)entryClass
                                 delegate:(id)delegate
                        didFinishSelector:(SEL)finishedSelector {

  return [self fetchEntryWithURL:entryURL
                      entryClass:entryClass
                            ETag:nil
                        delegate:delegate
               didFinishSelector:finishedSelector];
}

- (GDataServiceTicket *)fetchEntryWithURL:(NSURL *)entryURL
                               entryClass:(Class)entryClass
                                     ETag:(NSString *)etag
                                 delegate:(id)delegate
                        didFinishSelector:(SEL)finishedSelector {

  return [self fetchAuthenticatedObjectWithURL:entryURL
                                   objectClass:entryClass
                                  objectToPost:nil
                                          ETag:etag
                                    httpMethod:nil
                                      delegate:delegate
                             didFinishSelector:finishedSelector
                             completionHandler:NULL];
}

- (GDataServiceTicket *)fetchEntryByInsertingEntry:(GDataEntryBase *)entryToInsert
                                        forFeedURL:(NSURL *)feedURL
                                          delegate:(id)delegate
                                 didFinishSelector:(SEL)finishedSelector {

  NSString *etag = [entryToInsert ETag];

  // objects being uploaded will always need some namespaces at the root level
  [self addNamespacesIfNoneToObject:entryToInsert];

  return [self fetchAuthenticatedObjectWithURL:feedURL
                                   objectClass:[entryToInsert class]
                                  objectToPost:entryToInsert
                                          ETag:etag
                                    httpMethod:@"POST"
                                      delegate:delegate
                             didFinishSelector:finishedSelector
                             completionHandler:NULL];
}


- (GDataServiceTicket *)fetchEntryByUpdatingEntry:(GDataEntryBase *)entryToUpdate
                                         delegate:(id)delegate
                                didFinishSelector:(SEL)finishedSelector {

  NSURL *editURL = [[entryToUpdate editLink] URL];

  return [self fetchEntryByUpdatingEntry:entryToUpdate
                             forEntryURL:editURL
                                delegate:delegate
                       didFinishSelector:finishedSelector];
}

- (GDataServiceTicket *)fetchEntryByUpdatingEntry:(GDataEntryBase *)entryToUpdate
                                      forEntryURL:(NSURL *)entryURL
                                         delegate:(id)delegate
                                didFinishSelector:(SEL)finishedSelector {

  // Entries should be updated only if they contain copies of any unparsed XML
  // (unknown children and attributes) or if fields to update are explicitly
  // specified in the gd:field attribute.
  //
  // To update all fields of an entry that ignores unparsed XML, first fetch a
  // complete copy with fetchEntryWithURL: (or a service-specific entry fetch
  // method) using the URL from the entry's selfLink.
  //
  // See setShouldServiceFeedsIgnoreUnknowns in GDataServiceBase.h for more
  // information.

  NSString *fieldSelection = [entryToUpdate fieldSelection];

  GDATA_ASSERT(fieldSelection != nil || ![entryToUpdate shouldIgnoreUnknowns],
               @"unsafe update of %@", [entryToUpdate class]);

  // objects being uploaded will always need some namespaces at the root level
  [self addNamespacesIfNoneToObject:entryToUpdate];

  NSString *httpMethod = (fieldSelection == nil ? @"PUT" : @"PATCH");

  return [self fetchAuthenticatedObjectWithURL:entryURL
                                   objectClass:[entryToUpdate class]
                                  objectToPost:entryToUpdate
                                          ETag:[entryToUpdate ETag]
                                    httpMethod:httpMethod
                                      delegate:delegate
                             didFinishSelector:finishedSelector
                             completionHandler:NULL];
}

- (GDataServiceTicket *)deleteEntry:(GDataEntryBase *)entryToDelete
                           delegate:(id)delegate
                  didFinishSelector:(SEL)finishedSelector {

  NSString *etag = [entryToDelete ETag];
  NSURL *editURL = [[entryToDelete editLink] URL];

  GDATA_ASSERT(editURL != nil, @"deleting uneditable entry: %@", entryToDelete);

  GDataServiceTicket *ticket = [self deleteResourceURL:editURL
                                                  ETag:etag
                                              delegate:delegate
                                     didFinishSelector:finishedSelector];

  // we'll put the entry being deleted into the ticket's postedObject property
  // as a convenience to the caller even though we're not really posting an
  // object
  [ticket setPostedObject:entryToDelete];

  return ticket;
}

- (GDataServiceTicket *)deleteResourceURL:(NSURL *)resourceEditURL
                                     ETag:(NSString *)etag
                                 delegate:(id)delegate
                        didFinishSelector:(SEL)finishedSelector {

  GDATA_ASSERT(resourceEditURL != nil, @"deleting unspecified resource");

  return [self fetchAuthenticatedObjectWithURL:resourceEditURL
                                   objectClass:nil
                                  objectToPost:nil
                                          ETag:etag
                                    httpMethod:@"DELETE"
                                      delegate:delegate
                             didFinishSelector:finishedSelector
                             completionHandler:NULL];
}

- (GDataServiceTicket *)fetchFeedWithQuery:(GDataQuery *)query
                                  delegate:(id)delegate
                         didFinishSelector:(SEL)finishedSelector {

  return [self fetchFeedWithURL:[query URL]
                      feedClass:kGDataUseRegisteredClass
                       delegate:delegate
              didFinishSelector:finishedSelector];
}

- (GDataServiceTicket *)fetchFeedWithQuery:(GDataQuery *)query
                                 feedClass:(Class)feedClass
                                  delegate:(id)delegate
                         didFinishSelector:(SEL)finishedSelector {

  return [self fetchFeedWithURL:[query URL]
                      feedClass:feedClass
                       delegate:delegate
              didFinishSelector:finishedSelector];
}

#pragma mark -


#if NS_BLOCKS_AVAILABLE
- (GDataServiceTicket *)fetchFeedWithURL:(NSURL *)feedURL
                       completionHandler:(GDataServiceGoogleFeedBaseCompletionHandler)handler {

  return [self fetchAuthenticatedObjectWithURL:feedURL
                                   objectClass:kGDataUseRegisteredClass
                                  objectToPost:nil
                                          ETag:nil
                                    httpMethod:nil
                                      delegate:nil
                             didFinishSelector:NULL
                             completionHandler:(GDataServiceGoogleCompletionHandler)handler];
}

- (GDataServiceTicket *)fetchFeedWithQuery:(GDataQuery *)query
                         completionHandler:(void (^)(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error))handler {
  return [self fetchFeedWithURL:[query URL]
              completionHandler:handler];
}


- (GDataServiceTicket *)fetchEntryWithURL:(NSURL *)entryURL
                               entryClass:(Class)entryClass
                        completionHandler:(GDataServiceGoogleEntryBaseCompletionHandler)handler {

  return [self fetchAuthenticatedObjectWithURL:entryURL
                                   objectClass:entryClass
                                  objectToPost:nil
                                          ETag:nil
                                    httpMethod:nil
                                      delegate:nil
                             didFinishSelector:NULL
                             completionHandler:(GDataServiceGoogleCompletionHandler)handler];
}

- (GDataServiceTicket *)fetchEntryWithURL:(NSURL *)entryURL
                        completionHandler:(GDataServiceGoogleEntryBaseCompletionHandler)handler {

  return [self fetchEntryWithURL:entryURL
                      entryClass:kGDataUseRegisteredClass
               completionHandler:handler];
}

- (GDataServiceTicket *)fetchEntryByInsertingEntry:(GDataEntryBase *)entryToInsert
                                        forFeedURL:(NSURL *)feedURL
                                 completionHandler:(GDataServiceGoogleEntryBaseCompletionHandler)handler {
  NSString *etag = [entryToInsert ETag];

  // objects being uploaded will always need some namespaces at the root level
  [self addNamespacesIfNoneToObject:entryToInsert];

  return [self fetchAuthenticatedObjectWithURL:feedURL
                                   objectClass:[entryToInsert class]
                                  objectToPost:entryToInsert
                                          ETag:etag
                                    httpMethod:@"POST"
                                      delegate:nil
                             didFinishSelector:NULL
                             completionHandler:(GDataServiceGoogleCompletionHandler)handler];
}

- (GDataServiceTicket *)fetchEntryByUpdatingEntry:(GDataEntryBase *)entryToUpdate
                                completionHandler:(GDataServiceGoogleEntryBaseCompletionHandler)handler {
  NSURL *editURL = [[entryToUpdate editLink] URL];

  return [self fetchEntryByUpdatingEntry:entryToUpdate
                             forEntryURL:editURL
                       completionHandler:handler];
}

- (GDataServiceTicket *)fetchEntryByUpdatingEntry:(GDataEntryBase *)entryToUpdate
                                      forEntryURL:(NSURL *)entryURL
                                completionHandler:(GDataServiceGoogleEntryBaseCompletionHandler)handler {
  // Entries should be updated only if they contain copies of any unparsed XML
  // (unknown children and attributes) or if fields to update are explicitly
  // specified in the gd:field attribute.
  //
  // To update all fields of an entry that ignores unparsed XML, first fetch a
  // complete copy with fetchEntryWithURL: (or a service-specific entry fetch
  // method) using the URL from the entry's selfLink.
  //
  // See setShouldServiceFeedsIgnoreUnknowns in GDataServiceBase.h for more
  // information.

  NSString *fieldSelection = [entryToUpdate fieldSelection];

  GDATA_ASSERT(fieldSelection != nil || ![entryToUpdate shouldIgnoreUnknowns],
               @"unsafe update of %@", [entryToUpdate class]);

  // objects being uploaded will always need some namespaces at the root level
  [self addNamespacesIfNoneToObject:entryToUpdate];

  NSString *httpMethod = (fieldSelection == nil ? @"PUT" : @"PATCH");

  return [self fetchAuthenticatedObjectWithURL:entryURL
                                   objectClass:[entryToUpdate class]
                                  objectToPost:entryToUpdate
                                          ETag:[entryToUpdate ETag]
                                    httpMethod:httpMethod
                                      delegate:nil
                             didFinishSelector:NULL
                             completionHandler:(GDataServiceGoogleCompletionHandler)handler];
}

- (GDataServiceTicket *)deleteEntry:(GDataEntryBase *)entryToDelete
                  completionHandler:(void (^)(GDataServiceTicket *ticket, id nilObject, NSError *error))handler {
  NSString *etag = [entryToDelete ETag];
  NSURL *editURL = [[entryToDelete editLink] URL];

  return [self deleteResourceURL:editURL
                            ETag:etag
               completionHandler:handler];
}

- (GDataServiceTicket *)deleteResourceURL:(NSURL *)resourceEditURL
                                     ETag:(NSString *)etag
                        completionHandler:(GDataServiceGoogleCompletionHandler)handler {
  GDATA_ASSERT(resourceEditURL != nil, @"deleting unspecified resource");

  return [self fetchAuthenticatedObjectWithURL:resourceEditURL
                                   objectClass:nil
                                  objectToPost:nil
                                          ETag:etag
                                    httpMethod:@"DELETE"
                                      delegate:nil
                             didFinishSelector:NULL
                             completionHandler:(GDataServiceGoogleCompletionHandler)handler];
}

#endif // NS_BLOCKS_AVAILABLE

// add namespaces to the object being uploaded, though only if it currently
// lacks root-level namespaces
- (void)addNamespacesIfNoneToObject:(GDataObject *)obj {

  if ([obj namespaces] == nil) {
    NSDictionary *namespaces = [[self class] standardServiceNamespaces];
    GDATA_DEBUG_ASSERT(namespaces != nil, @"nil namespaces in service");

    [obj setNamespaces:namespaces];
  }
}

+ (NSDictionary *)standardServiceNamespaces {
  // subclasses override this if they have custom namespaces
  return [GDataEntryBase baseGDataNamespaces];
}

#pragma mark -

// Batch feed support

- (GDataServiceTicket *)fetchFeedWithBatchFeed:(GDataFeedBase *)batchFeed
                               forBatchFeedURL:(NSURL *)feedURL
                                      delegate:(id)delegate
                             didFinishSelector:(SEL)finishedSelector
                             completionHandler:(GDataServiceGoogleCompletionHandler)completionHandler {
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

  GDataServiceTicket *ticket;

  ticket = [self fetchAuthenticatedObjectWithURL:feedURL
                                     objectClass:[batchFeed class]
                                    objectToPost:batchFeed
                                            ETag:nil
                                      httpMethod:nil
                                        delegate:delegate
                               didFinishSelector:finishedSelector
                               completionHandler:completionHandler];

  // batch feeds never ignore unknowns, since they are intrinsically
  // used for updating so their entries need to include complete XML
  [ticket setShouldFeedsIgnoreUnknowns:NO];

  return ticket;
}

- (GDataServiceTicket *)fetchFeedWithBatchFeed:(GDataFeedBase *)batchFeed
                               forBatchFeedURL:(NSURL *)feedURL
                                      delegate:(id)delegate
                             didFinishSelector:(SEL)finishedSelector {

  return [self fetchFeedWithBatchFeed:batchFeed
                      forBatchFeedURL:feedURL
                             delegate:delegate
                    didFinishSelector:finishedSelector
                    completionHandler:NULL];
}


#if NS_BLOCKS_AVAILABLE
- (GDataServiceTicket *)fetchFeedWithBatchFeed:(GDataFeedBase *)batchFeed
                               forBatchFeedURL:(NSURL *)feedURL
                             completionHandler:(void (^)(GDataServiceTicket *ticket, GDataFeedBase *feed, NSError *error))handler {
  return [self fetchFeedWithBatchFeed:batchFeed
                      forBatchFeedURL:feedURL
                             delegate:nil
                    didFinishSelector:NULL
                    completionHandler:(GDataServiceGoogleCompletionHandler)handler];
}
#endif


#pragma mark -

//
// Accessors
//

// When the username or password changes, we invalidate any held auth token
- (void)setUserCredentialsWithUsername:(NSString *)username
                              password:(NSString *)password {
  // if the username or password is changing, invalidate the
  // auth token and clear the history of last-modified dates
  if (!AreEqualOrBothNil([self username], username)
      || !AreEqualOrBothNil([self password], password)) {

    [self setAuthToken:nil];
    [self setAuthSubToken:nil];

    [self clearResponseDataCache];

    // we don't want to rely on any pending auth fetcher, but rather
    // want to force creation of a new one
    [self setPendingAuthFetcher:nil];

    [self setCredentialDate:[NSDate date]];

    if ([username length] > 0) {
      // username/password auth will now take precendence
      [self setAuthorizer:nil];
    }
  }

  [super setUserCredentialsWithUsername:username password:password];
}

- (void)setCaptchaToken:(NSString *)captchaToken
          captchaAnswer:(NSString *)captchaAnswer {

  [captchaToken_ release];
  captchaToken_ = [captchaToken copy];

  [captchaAnswer_ release];
  captchaAnswer_ = [captchaAnswer copy];
}

- (NSString *)authToken {
  return authToken_;
}

- (void)setAuthToken:(NSString *)str {
  [authToken_ autorelease];
  authToken_ = [str copy];
}

- (NSString *)authSubToken {
  return authSubToken_;
}

- (void)setAuthSubToken:(NSString *)str {
  [authSubToken_ autorelease];
  authSubToken_ = [str copy];
}

+ (NSString *)authorizationScope {
  // typically, the subclass's root URL string is the auth scope
  //
  // subclasses may override for custom scopes
  NSString *scope = [self serviceRootURLString];

  GDATA_DEBUG_ASSERT([scope length] > 0, @"Scope undefined for service");
  return scope;
}

+ (NSString *)serviceRootURLString {
  // subclasses should override
  return nil;
}

- (NSMutableURLRequest *)requestForURL:(NSURL *)url
                                  ETag:(NSString *)etag
                            httpMethod:(NSString *)httpMethod
                                ticket:(GDataServiceTicket *)ticket {

  NSMutableURLRequest *request = [super requestForURL:url
                                                 ETag:etag
                                           httpMethod:httpMethod
                                               ticket:ticket];

  // if appropriate set the method override header
  if (shouldUseMethodOverrideHeader_) {
    if ([httpMethod length] > 0 && ![httpMethod isEqualToString:@"POST"]) {
      // superclass set the http method; we'll change it to POST and
      // set the header
      [request setValue:httpMethod forHTTPHeaderField:@"X-HTTP-Method-Override"];
      [request setHTTPMethod:@"POST"];
    }
  }

  NSString *authToken;
  if (ticket) {
    authToken = [ticket authToken];
  } else {
    // no ticket was specified, so authenticate using the service object's
    // existing token
    authToken = authToken_;
  }

  // add the auth token to the header
  if ([authToken length] > 0) {
    NSString *value = [NSString stringWithFormat:@"GoogleLogin auth=%@",
                       authToken];
    [request setValue:value forHTTPHeaderField: @"Authorization"];
  } else if ([authSubToken_ length] > 0) {
    NSString *value = [NSString stringWithFormat:@"AuthSub token=%@",
                       authSubToken_];
    [request setValue:value forHTTPHeaderField: @"Authorization"];
  }
  return request;
}

+ (NSString *)serviceID {
  // subclasses should override this class method to return the service ID,
  // like @"cl" for calendar
  return nil;
}

- (NSString *)serviceID {
  // if the base class is used directly, call setServiceID: before fetching
  if (serviceID_) return serviceID_;

  NSString *str = [[self class] serviceID];
  if (str) return str;

  GDATA_ASSERT(0, @"GDataServiceGoogle should have a serviceID");
  return nil;
}

- (void)setServiceID:(NSString *)str {
  [serviceID_ autorelease];
  serviceID_ = [str copy];
}

- (NSString *)accountType {
  if (accountType_) {
    return accountType_;
  }
  return @"HOSTED_OR_GOOGLE";
}

- (void)setAccountType:(NSString *)str {
  [accountType_ autorelease];
  accountType_ = [str copy];
}

- (NSString *)signInDomain {
  if (signInDomain_) {
    return signInDomain_;
  }
  return @"www.google.com";
}

- (void)setSignInDomain:(NSString *)signInDomain {
  [signInDomain_ release];
  signInDomain_ = [signInDomain copy];
}

// when it's not possible to do http methods other than GET and POST,
// the X-HTTP-Method-Override header can be used in conjunction with POST
// for other commands.  Default for this is NO.
- (BOOL)shouldUseMethodOverrideHeader {
  return shouldUseMethodOverrideHeader_;
}

- (void)setShouldUseMethodOverrideHeader:(BOOL)flag {
  shouldUseMethodOverrideHeader_ = flag;
}

- (GTMHTTPFetcher *)pendingAuthFetcher {
  return pendingAuthFetcher_;
}

- (void)setPendingAuthFetcher:(GTMHTTPFetcher *)fetcher {
  [pendingAuthFetcher_ autorelease];
  pendingAuthFetcher_ = [fetcher retain];
}

- (NSDate *)credentialDate {
  return credentialDate_;
}

- (void)setCredentialDate:(NSDate *)date {
  [credentialDate_ autorelease];
  credentialDate_ = [date retain];
}

@end


@implementation GDataServiceTicket

- (id)initWithService:(GDataServiceGoogle *)service {
  self = [super initWithService:service];
  if (self) {
    [self setAuthToken:[service authToken]];
    [self setCredentialDate:[service credentialDate]];
  }
  return self;
}

- (void)dealloc {
  [authFetcher_ release];
  [authToken_ release];
  [credentialDate_ release];
  [super dealloc];
}

- (NSString *)description {
  if (authorizer_) {
    NSString *const templateStr = @"%@ %p: {service:%@ objectFetcher:%@ authorizer:%@}";
    return [NSString stringWithFormat:templateStr,
            [self class], self, service_, objectFetcher_, authorizer_];
  } else {
    NSString *const templateStr = @"%@ %p: {service:%@ objectFetcher:%@ authFetcher:%@}";
    return [NSString stringWithFormat:templateStr,
      [self class], self, service_, objectFetcher_, authFetcher_];
  }
}

- (void)cancelTicket {
  GDataServiceGoogle *service = [self service];
  [service stopAuthenticationForTicket:self];

  [super cancelTicket];
}

- (GTMHTTPFetcher *)authFetcher {
  return [[authFetcher_ retain] autorelease];
}

- (void)setAuthFetcher:(GTMHTTPFetcher *)fetcher {
  [authFetcher_ autorelease];
  authFetcher_ = [fetcher retain];
}

- (NSString *)authToken {
  return authToken_;
}

- (void)setAuthToken:(NSString *)str {
  [authToken_ autorelease];
  authToken_ = [str copy];
}

- (NSDate *)credentialDate {
  return credentialDate_;
}

- (void)setCredentialDate:(NSDate *)date {
  [credentialDate_ autorelease];
  credentialDate_ = [date retain];
}

@end

@implementation NSDictionary (GDataServiceGoogleAdditions)
// category to get authentication info from the callback error's userInfo
- (NSString *)authenticationError {
  return [self objectForKey:@"Error"];
}

- (NSString *)authenticationInfo {
  // if authenticationInfo is kGDataServerInfoInvalidSecondFactor the
  // password should be an application-specific password, as described at
  // http://goo.gl/bogZI
  return [self objectForKey:kGDataServerInfoStringKey];
}

- (NSString *)captchaToken {
  return [self objectForKey:@"CaptchaToken"];
}

- (NSURL *)captchaURL {
  NSString *str = [self objectForKey:kCaptchaFullURLKey];
  if ([str length] > 0) {
    return [NSURL URLWithString:str];
  }
  return nil;
}
@end
