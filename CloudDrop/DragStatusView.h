//
//  DragStatusView.h
//  CloudDrop
//
//  Created by James Rutherford on 12-04-26.
//  Copyright (c) 2012 Taptoincs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxOSX/DropboxOSX.h>

@protocol DragStatusViewDelegate <NSObject>

- (void) droppedSingleFile: (NSString*)withFile;
- (void) droppedMultipleFiles;
- (void) droppedURL: (NSString*)withURL;
@end

@interface DragStatusView : NSView <NSMenuDelegate> {
    NSStatusItem *statusItem;
    BOOL isMenuVisible;
    id <DragStatusViewDelegate> delegate;
}

@property (retain, nonatomic) id <DragStatusViewDelegate> delegate;
@property (retain, nonatomic) NSStatusItem *statusItem;

//- (void) animateIcon:(int)progress;
- (void) resetIcon;
- (void) showDoneIcon;
- (void) startThumper;
- (void) stopThumper;
@end
