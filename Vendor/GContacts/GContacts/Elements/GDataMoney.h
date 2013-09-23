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
//  GDataMoney.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_FINANCE_SERVICE || GDATA_INCLUDE_BOOKS_SERVICE

#import "GDataObject.h"

// money element, as in
//  <gd:money amount="10" currencycode="USD"/>

@interface GDataMoney : GDataObject <GDataExtension>

+ (GDataMoney *)moneyWithAmount:(NSNumber *)amount
                   currencyCode:(NSString *)currencyCode;

- (NSDecimalNumber *)amount;
- (void)setAmount:(NSNumber *)num;

- (NSString *)currencyCode;
- (void)setCurrencyCode:(NSString *)str;
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_FINANCE_SERVICE || GDATA_INCLUDE_BOOKS_SERVICE
