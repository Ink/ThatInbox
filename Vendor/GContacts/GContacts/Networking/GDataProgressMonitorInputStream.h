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

#import <Foundation/Foundation.h>

// The monitored input stream calls back into the monitor delegate
// with the number of bytes and total size:
//
// - (void)inputStream:(GDataProgressMonitorInputStream *)stream
//   hasDeliveredByteCount:(unsigned long long)numberOfBytesRead
//        ofTotalByteCount:(unsigned long long)dataLength;

// Define <NSStreamDelegate> only for Mac OS X 10.6+ or iPhone OS 4.0+.
#ifndef GDATA_NSSTREAM_DELEGATE
 #if (TARGET_OS_MAC && !TARGET_OS_IPHONE && (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)) || \
     (TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 40000))
   #define GDATA_NSSTREAM_DELEGATE <NSStreamDelegate>
 #else
   #define GDATA_NSSTREAM_DELEGATE
 #endif
#endif  // !defined(GDATA_NSSTREAM_DELEGATE)

#ifdef GDATA_TARGET_NAMESPACE
  // we're using target namespace macros
  #import "GDataDefines.h"
#endif

@interface GDataProgressMonitorInputStream : NSInputStream GDATA_NSSTREAM_DELEGATE {

  NSInputStream *inputStream_; // encapsulated stream that does the work

  NSThread *thread_;      // thread in which this object was created
  NSArray *runLoopModes_; // modes for calling callbacks, when necessary

  unsigned long long dataSize_;     // size of data in the source
  unsigned long long numBytesRead_; // bytes read from the input stream so far

  __weak id monitorDelegate_;
  SEL monitorSelector_;
  SEL readSelector_;

  __weak id monitorSource_;
}

// length is passed to the progress callback; it may be zero
// if the progress callback can handle that
+ (id)inputStreamWithStream:(NSInputStream *)input
                     length:(unsigned long long)length;

- (id)initWithStream:(NSInputStream *)input
              length:(unsigned long long)length;

// the monitor is called when bytes have been read
//
// monitorDelegate should respond to a selector with a signature matching:
//
// - (void)inputStream:(GDataProgressMonitorInputStream *)stream
//   hasDeliveredBytes:(unsigned long long)numReadSoFar
//        ofTotalBytes:(unsigned long long)total

- (void)setMonitorDelegate:(id)monitorDelegate; // not retained
- (id)monitorDelegate;

- (void)setMonitorSelector:(SEL)monitorSelector;
- (SEL)monitorSelector;

// the source lets the delegate know the source of this input stream
- (void)setMonitorSource:(id)source; // not retained
- (id)monitorSource;

// The monitor delegate may also provide a selector to see the bytes read, with
// a signature matching
//
// - (void)inputStream:(GDataProgressMonitorInputStream *)stream
//      readIntoBuffer:(uint8_t *)buffer
//              length:(unsigned long long)length;

- (void)setReadSelector:(SEL)readSelector;
- (SEL)readSelector;

// Modes for invoking callbacks, when necessary
- (NSArray *)runLoopModes;
- (void)setRunLoopModes:(NSArray *)modes;

@end
