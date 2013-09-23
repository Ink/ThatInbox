//
//  TRAddressBookSource+GoogleContacts.m
//  ThatInbox
//
//  Created by Andrey Yastrebov on 23.09.13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "TRAddressBookSource+GoogleContacts.h"
#import "TRAddressBookSuggestion.h"
#import "AuthManager.h"
#import <GContacts/GDataContacts.h>

@implementation TRAddressBookSource (GoogleContacts)

- (void)useGoogleContacts:(BOOL)use
{
    if (use)
    {
        GDataFeedBase *gContactsData = [[AuthManager sharedManager] googleContacts];
        
        if (gContactsData)
        {
            //We already have contacts, let's go on
            [self getGoogleContacts:gContactsData];
        }
        else
        {
            //Our contacts are empty, so let's get them
            [[AuthManager sharedManager] requestGoogleContacts:^(GDataFeedBase *feed, NSError *error)
            {
                if (!error)
                {
                    [self getGoogleContacts:feed];
                }
            }];
        }
    }
}

- (void)getGoogleContacts:(GDataFeedBase *)contactsFeed
{
    NSArray *allPeople = [contactsFeed entries];
    
    NSMutableArray *mutEmails = [[NSMutableArray alloc] initWithCapacity:allPeople.count];
    
    for (GDataEntryContact *person in allPeople)
    {
        GDataName *gName = [person name];
        
        NSString *firstName = gName.givenName.stringValue;
        NSString *lastName = gName.familyName.stringValue;
        if (!firstName){
            firstName = @"";
        }
        if (!lastName) {
            lastName = @"";
        }

        NSArray *emailAddresses = person.emailAddresses;
        
        for (GDataEmail* gEmail in emailAddresses)
        {
            NSString *email = [gEmail address];
            
            TRAddressBookSuggestion *suggestion = [[TRAddressBookSuggestion alloc] initWith:[NSString stringWithFormat:@"%@ %@ <%@>", firstName, lastName, email]];
            suggestion.subheaderText = email;
            suggestion.headerText = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            if ([suggestion.headerText length] == 1)
            {
                suggestion.headerText = email;
            }
            [mutEmails addObject:suggestion];
        }
    }
    
    [self performSelector:@selector(fillEmailsListWithData:) withObject:[NSSet setWithArray:mutEmails]];
}

@end
