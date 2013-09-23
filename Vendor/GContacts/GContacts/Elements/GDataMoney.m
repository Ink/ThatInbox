/* Copyright (c) 2008 Google Inc.
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
//  GDataMoney.m
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_FINANCE_SERVICE || GDATA_INCLUDE_BOOKS_SERVICE

#import "GDataMoney.h"

static NSString* const kAmountAttr = @"amount";
static NSString* const kCurrencyCodeAttr = @"currencyCode";

@implementation GDataMoney
// money element, as in
//  <gd:money amount="10" currencyCode="USD"/>

+ (NSString *)extensionElementURI       { return kGDataNamespaceGData; }
+ (NSString *)extensionElementPrefix    { return kGDataNamespaceGDataPrefix; }
+ (NSString *)extensionElementLocalName { return @"money"; }

+ (GDataMoney *)moneyWithAmount:(NSNumber *)amount
                   currencyCode:(NSString *)currencyCode {
  GDataMoney *obj = [self object];
  [obj setAmount:amount];
  [obj setCurrencyCode:currencyCode];
  return obj;
}

- (void)addParseDeclarations {
  NSArray *attrs = [NSArray arrayWithObjects: 
                    kAmountAttr, kCurrencyCodeAttr, nil];
  
  [self addLocalAttributeDeclarations:attrs];
}

#pragma mark -

- (NSDecimalNumber *)amount {
  return [self decimalNumberForAttribute:kAmountAttr];
}

- (void)setAmount:(NSNumber *)num {
  [self setStringValue:[num stringValue] forAttribute:kAmountAttr];
}

- (NSString *)currencyCode {
  return [self stringValueForAttribute:kCurrencyCodeAttr]; 
}

- (void)setCurrencyCode:(NSString *)str {
  [self setStringValue:str forAttribute:kCurrencyCodeAttr];
}

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_FINANCE_SERVICE || GDATA_INCLUDE_BOOKS_SERVICE
