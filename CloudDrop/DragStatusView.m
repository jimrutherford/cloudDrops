//
//  DragStatusView.m
//  CloudDrop
//
//  Created by James Rutherford on 12-04-26.
//  Copyright (c) 2012 Taptoincs. All rights reserved.
//

#import "DragStatusView.h"
#import <DropboxOSX/DropboxOSX.h>


@implementation DragStatusView

@synthesize statusItem;
@synthesize delegate;

NSString * currentImage;
NSTimer * progressTimer;
int progressAnimationStep;


- (id)initWithFrame:(NSRect)frame
{
    currentImage = @"drop";
    self = [super initWithFrame:frame];
    if (self) {
        statusItem = nil;
        isMenuVisible = NO;
        
        //register for drags
        [self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, NSURLPboardType, NSPasteboardTypeTIFF, nil]];
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    [statusItem drawStatusBarBackgroundInRect:[self bounds] withHighlight:isMenuVisible];
    
    NSImage * drop = [NSImage imageNamed:currentImage];
    [drop drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
}



#pragma mark Icon Animation Control

- (void) startThumper {
    progressAnimationStep = 1;
    [self animateIcon:progressAnimationStep];
    
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                     target:self
                                                   selector:@selector(updateProgress:)
                                                   userInfo:nil
                                                    repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:progressTimer forMode:NSRunLoopCommonModes];
}

- (void) stopThumper {
    [progressTimer invalidate];
    progressTimer = nil;
}


- (void) animateIcon:(int)progress {
    currentImage = [NSString stringWithFormat:@"Drop_Progress_%i", progress];
    [self setNeedsDisplay:YES];
}

- (void) resetIcon {
    currentImage = @"drop";
    [self setNeedsDisplay:YES];
}

- (void) showDoneIcon {
    currentImage = @"dropDone";
    [self setNeedsDisplay:YES];
}

- (void) updateProgress: (NSTimer*) theTimer
{
    progressAnimationStep++;
    if (progressAnimationStep > 6)
    {
        progressAnimationStep = 1;
    }
    
    [self animateIcon:progressAnimationStep];
    
    NSLog(@"progress update");
}


//we want to copy the files
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

//perform the drag and log the files that are dropped
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender 
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        
        NSLog(@"Files: %@",files);
        NSString * file = [files objectAtIndex:0];
        [delegate droppedSingleFile:file];
    } else if ([[pboard types] containsObject:NSURLPboardType]){
       
        NSArray *urls = [pboard propertyListForType:NSURLPboardType];
        NSString * theURL = [urls objectAtIndex:0];
        [delegate droppedURL: theURL];
    } 
    
    return YES;
}

- (void)mouseDown:(NSEvent *)event {
    [[self menu] setDelegate:self];
    [statusItem popUpStatusItemMenu:[self menu]];
    [self setNeedsDisplay:YES];
}

- (void)rightMouseDown:(NSEvent *)event {
    // Treat right-click just like left-click
    [self mouseDown:event];
}

- (void)menuWillOpen:(NSMenu *)menu {
    isMenuVisible = YES;
    [self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
    isMenuVisible = NO;
    [menu setDelegate:nil];    
    [self setNeedsDisplay:YES];
}

@end