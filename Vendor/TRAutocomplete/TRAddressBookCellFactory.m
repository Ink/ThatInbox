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

#import "TRAddressBookCellFactory.h"
#import "TRAutocompleteItemsSource.h"
#import "TRAddressBookSuggestion.h"

@interface TRAddressBookCell : UITableViewCell <TRAutocompletionCell>
@end

@implementation TRAddressBookCell

- (void)updateWith:(id <TRSuggestionItem>)item
{
    self.textLabel.text = [item headerText];
    self.detailTextLabel.text = [item subheaderText];
}

@end

@implementation TRAddressBookCellFactory
{
    UIColor *_foregroundColor;
    CGFloat _fontSize;
}

- (id)initWithCellForegroundColor:(UIColor *)foregroundColor fontSize:(CGFloat)fontSize
{
    self = [super init];
    if (self)
    {
        _foregroundColor = foregroundColor;
        _fontSize = fontSize;
    }

    return self;
}

- (id <TRAutocompletionCell>)createReusableCellWithIdentifier:(NSString *)identifier
{
    TRAddressBookCell *cell = [[TRAddressBookCell alloc]
                                                                            initWithStyle:UITableViewCellStyleSubtitle
                                                                          reuseIdentifier:identifier];
    cell.textLabel.font = [UIFont systemFontOfSize:_fontSize];
    cell.textLabel.textColor = _foregroundColor;

    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;

}

@end