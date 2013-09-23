//
//  FPExternalHeaders.h
//  FPPicker
//
//  Created by Liyan David Chang on 7/8/12.
//  Copyright (c) 2012 Filepicker.io (Couldtop Inc.). All rights reserved.
//

#import <Foundation/Foundation.h>

@class FPPickerController;
@class FPSaveController;

@protocol FPPickerDelegate <NSObject>

- (void)FPPickerController:(FPPickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)FPPickerControllerDidCancel:(FPPickerController *)picker;

@optional
- (void)FPPickerController:(FPPickerController *)picker didPickMediaWithInfo:(NSDictionary *) info;


@end

@protocol FPSaveDelegate <NSObject>
- (void)FPSaveController:(FPSaveController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)FPSaveControllerDidCancel:(FPSaveController *)picker;

@optional
- (void)FPSaveController:(FPSaveController *)picker didError:(NSDictionary *)info;
- (void)FPSaveControllerDidSave:(FPSaveController *)picker;


@end

@class FPSourceController;

@protocol FPSourcePickerDelegate <NSObject>

- (void)FPSourceController:(FPSourceController *)picker didPickMediaWithInfo:(NSDictionary *) info;
- (void)FPSourceController:(FPSourceController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)FPSourceControllerDidCancel:(FPSourceController *)picker;

@end

@protocol FPSourceSaveDelegate <NSObject>

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSURL *dataurl;
@property (nonatomic, strong) NSString *dataType;

- (void)FPSourceController:(FPSourceController *)picker didPickMediaWithInfo:(NSDictionary *) info;
- (void)FPSourceController:(FPSourceController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)FPSourceControllerDidCancel:(FPSourceController *)picker;

@end

