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

#import "TRAutocompleteView.h"
#import "TRAutocompleteItemsSource.h"
#import "TRAutocompletionCellFactory.h"

#import "FlatUIKit.h"

@interface TRAutocompleteView () <UITableViewDelegate, UITableViewDataSource>

@property(readwrite) id <TRSuggestionItem> selectedSuggestion;
@property(readwrite) NSArray *suggestions;

@end

@implementation TRAutocompleteView
{
    BOOL _visible;
    BOOL _keyboardVisible;

    
    __weak UITextField *_queryTextField;
    __weak UIViewController *_contextController;

    UITableView *_table;
    id <TRAutocompleteItemsSource> _itemsSource;
    id <TRAutocompletionCellFactory> _cellFactory;
}

+ (TRAutocompleteView *)autocompleteViewBindedTo:(UITextField *)textField
                                     usingSource:(id <TRAutocompleteItemsSource>)itemsSource
                                     cellFactory:(id <TRAutocompletionCellFactory>)factory
                                    presentingIn:(UIViewController *)controller
{
    return [[TRAutocompleteView alloc] initWithFrame:CGRectZero
                                           textField:textField
                                         itemsSource:itemsSource
                                         cellFactory:factory
                                          controller:controller];
}

- (id)initWithFrame:(CGRect)frame
          textField:(UITextField *)textField
        itemsSource:(id <TRAutocompleteItemsSource>)itemsSource
        cellFactory:(id <TRAutocompletionCellFactory>)factory
         controller:(UIViewController *)controller
{
    
    self = [super initWithFrame:frame];
    if (self)
    {
        [self loadDefaults];
        _keyboardVisible = NO;
        
        _queryTextField = textField;
        _itemsSource = itemsSource;
        _cellFactory = factory;
        _contextController = controller;

        _table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _table.backgroundColor = [UIColor cloudsColor];
        _table.separatorColor = self.separatorColor;
        _table.separatorStyle = self.separatorStyle;
        _table.delegate = self;
        _table.dataSource = self;

        [[NSNotificationCenter defaultCenter]
                               addObserver:self
                                  selector:@selector(queryChanged:)
                                      name:UITextFieldTextDidChangeNotification
                                    object:_queryTextField];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];


        [self addSubview:_table];
        
        
        self.frame = [self calculateFrame];
        _table.frame = [self calculateTableFrame];
    }

    return self;
}

- (int) keyboardHeight {
    
    if (!_keyboardVisible){
        return 0;
    }
    
    //44 is an adjustment for the attachments bar.
    if(UIInterfaceOrientationIsPortrait(_contextController.interfaceOrientation)) {
        return 264;
    } else {
        return 352;
    }
}


- (CGRect)calculateFrame {
    
    //CGPoint textPosition = [_queryTextField convertPoint:_queryTextField.bounds.origin toView:self]; //Taking in account Y position of queryTextField relatively to it's Window
    //NSLog(@"text position %@", NSStringFromCGPoint(textPosition));
    
    NSLog(@"query %@", NSStringFromCGRect(_queryTextField.frame));
    //44 for nav bar and 10 for the padding
    CGFloat calculatedY = _queryTextField.frame.origin.y + _queryTextField.frame.size.height + 44 + 10;

    NSLog(@"CalcY: %f %@", calculatedY, NSStringFromCGRect(_contextController.view.bounds));
    return CGRectMake(0, calculatedY, _contextController.view.bounds.size.width, _contextController.view.bounds.size.height - calculatedY - [self keyboardHeight]);
    
}


- (CGRect)calculateTableFrame {
    return CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
}


- (void)loadDefaults
{
    self.backgroundColor = [UIColor whiteColor];

    self.separatorColor = [UIColor lightGrayColor];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    _keyboardVisible = YES;
    self.frame = [self calculateFrame];
    _table.frame = [self calculateTableFrame];

}

- (void)keyboardWillHide:(NSNotification *)notification
{
    _keyboardVisible = NO;
    
    self.frame = [self calculateFrame];
    _table.frame = [self calculateTableFrame];

    /*
    if (_visible){
        [self removeFromSuperview];
        _visible = NO;
    }
     */
}

- (void)orientationDidChange:(NSNotification *)note
{
    self.frame = [self calculateFrame];
    _table.frame = [self calculateTableFrame];
}

- (void)queryChanged:(id)sender
{
    
    NSString *query = [[[_queryTextField.text componentsSeparatedByString:@","] lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([query length] >= _itemsSource.minimumCharactersToTrigger)
    {
        [_itemsSource itemsFor:query whenReady:
                                                            ^(NSArray *suggestions)
                                                            {
                                                                if (query.length
                                                                    < _itemsSource.minimumCharactersToTrigger)
                                                                {
                                                                    self.suggestions = nil;
                                                                    [_table reloadData];
                                                                }
                                                                else
                                                                {
                                                                    self.suggestions = suggestions;
                                                                    [_table reloadData];

                                                                    if (self.suggestions.count > 0 && !_visible)
                                                                    {
                                                                        [_contextController.view addSubview:self];
                                                                        _visible = YES;
                                                                    }
                                                                    
                                                                    if (self.suggestions.count == 0 && _visible){
                                                                        [self removeFromSuperview];
                                                                        _visible = NO;
                                                                    }
                                                                    
                                                                }
                                                            }];
    }
    else
    {
        self.suggestions = nil;
        [_table reloadData];
        if (_visible){
            [self removeFromSuperview];
            _visible = NO;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.suggestions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"TRAutocompleteCell";

    id cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
        cell = [_cellFactory createReusableCellWithIdentifier:identifier];

    NSAssert([cell isKindOfClass:[UITableViewCell class]], @"Cell must inherit from UITableViewCell");
    NSAssert([cell conformsToProtocol:@protocol(TRAutocompletionCell)], @"Cell must conform TRAutocompletionCell");
    UITableViewCell <TRAutocompletionCell> *completionCell = (UITableViewCell <TRAutocompletionCell> *) cell;

    id suggestion = self.suggestions[(NSUInteger) indexPath.row];
    NSAssert([suggestion conformsToProtocol:@protocol(TRSuggestionItem)], @"Suggestion item must conform TRSuggestionItem");
    id <TRSuggestionItem> suggestionItem = (id <TRSuggestionItem>) suggestion;

    [completionCell updateWith:suggestionItem];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id suggestion = self.suggestions[(NSUInteger) indexPath.row];
    NSAssert([suggestion conformsToProtocol:@protocol(TRSuggestionItem)], @"Suggestion item must conform TRSuggestionItem");

    self.selectedSuggestion = (id <TRSuggestionItem>) suggestion;

    
    NSArray *components = [_queryTextField.text componentsSeparatedByString:@","];
    NSMutableArray *outComponents = [[NSMutableArray alloc] init];
    for (NSString *c in components) {
        [outComponents addObject:[c stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    }    
    [outComponents removeLastObject];
    [outComponents addObject:self.selectedSuggestion.completionText];
    _queryTextField.text = [[outComponents componentsJoinedByString:@", "] stringByAppendingString:@", "];
    [self queryChanged:nil];
    //[_queryTextField resignFirstResponder];

    if (self.didAutocompleteWith)
        self.didAutocompleteWith(self.selectedSuggestion);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55.0f;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
                           removeObserver:self
                                     name:UITextFieldTextDidChangeNotification
                                   object:nil];
    [[NSNotificationCenter defaultCenter]
                           removeObserver:self
                                     name:UIKeyboardDidShowNotification
                                   object:nil];
    [[NSNotificationCenter defaultCenter]
                           removeObserver:self
                                     name:UIKeyboardWillHideNotification
                                   object:nil];
    [[NSNotificationCenter defaultCenter]
                            removeObserver:self
                                      name:UIDeviceOrientationDidChangeNotification
                                    object:nil];
}

@end