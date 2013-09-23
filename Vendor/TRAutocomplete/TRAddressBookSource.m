//
// Copyright (c) 2013, Taras Roshko
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// The views and conclusions contained in the software and documentation are those
// of the authors and should not be interpreted as representing official policies,
// either expressed or implied, of the FreeBSD Project.
//

#import "TRAddressBookSource.h"
#import "TRAddressBookSuggestion.h"
#import <AddressBook/AddressBook.h>

@implementation TRAddressBookSource
{
    NSUInteger _minimumCharactersToTrigger;

    BOOL _requestToReload;
    BOOL _loading;
}

- (id)initWithMinimumCharactersToTrigger:(NSUInteger)minimumCharactersToTrigger {
    self = [super init];
    if (self)
    {
        _minimumCharactersToTrigger = minimumCharactersToTrigger;
        _emails = @[];

        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
        
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(nil, nil);
            
            if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
                ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                    [self getAddressBook:addressBook];
                });
            } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
                [self getAddressBook:addressBook];
            } else {
                _emails = @[];
            }
        });
    }

    return self;
}


- (void)getAddressBook:(ABAddressBookRef)addressBook {
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople( addressBook );
    CFIndex nPeople = ABAddressBookGetPersonCount( addressBook );
    
    
    NSMutableArray *mutEmails = [[NSMutableArray alloc] init];
    
    for ( int i = 0; i < nPeople; i++ )
    {
        ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );
        
        NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
        if (!firstName){
            firstName = @"";
        }
        if (!lastName) {
            lastName = @"";
        }
        
        ABMultiValueRef emailMultiValue = ABRecordCopyValue(person, kABPersonEmailProperty);
        NSArray *emailAddresses = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(emailMultiValue);
        CFRelease(emailMultiValue);
        
        for (NSString* email in emailAddresses){
            TRAddressBookSuggestion *suggestion = [[TRAddressBookSuggestion alloc] initWith:[NSString stringWithFormat:@"%@ %@ <%@>", firstName, lastName, email]];
            suggestion.subheaderText = email;
            suggestion.headerText = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            if ([suggestion.headerText length] == 1){
                suggestion.headerText = email;
            }
            [mutEmails addObject:suggestion];
        }
    }
    
    [self performSelector:@selector(fillEmailsListWithData:) withObject:[NSSet setWithArray:mutEmails]];
}

- (void)fillEmailsListWithData:(NSSet *)mailsSet
{
    if (_emails.count > 0)
    {
        NSMutableSet *existingEmails = [NSMutableSet setWithArray:_emails];
        [existingEmails unionSet:mailsSet];
        
        _emails = [existingEmails allObjects];
    }
    else
    {
        _emails = [mailsSet allObjects];
    }
}

- (NSUInteger)minimumCharactersToTrigger
{
    return _minimumCharactersToTrigger;
}

- (void)itemsFor:(NSString *)query whenReady:(void (^)(NSArray *))suggestionsReady
{
    @synchronized (self)
    {
        if (_loading)
        {
            _requestToReload = YES;
            return;
        }

        _loading = YES;
        [self requestSuggestionsFor:query whenReady:suggestionsReady];
    }
}

- (void)requestSuggestionsFor:(NSString *)query whenReady:(void (^)(NSArray *))suggestionsReady
{
    NSPredicate *containPred = [NSPredicate predicateWithFormat:@"completionText contains[cd] %@", query];
    NSArray *filtered  = [_emails filteredArrayUsingPredicate:containPred];
    suggestionsReady(filtered);
    _loading = NO;
}

@end