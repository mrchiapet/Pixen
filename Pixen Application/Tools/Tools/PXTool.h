//
//  PXTool.h
//  Pixen-XCode

// Copyright (c) 2003,2004,2005 Pixen

// Permission is hereby granted, free of charge, to any person obtaining a copy

// of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation 
// the rights  to use,copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom
//  the Software is  furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM,  OUT OF OR IN CONNECTION WITH
// THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  Created by Joe Osborn on Sat Dec 06 2003.
//  Copyright (c) 2003 Pixen. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "PXCanvasController.h"
@class PXToolSwitcher, PXToolPropertiesController, PXPattern, PXCanvas;
@interface PXTool : NSObject 
{
  @private
	BOOL isClicking;
	NSBezierPath *path;
	NSBezierPath *wrappedPath;
	PXToolSwitcher *switcher;
	PXToolPropertiesController *propertiesController;
	NSColor *color;
	BOOL initialLoad;
}

@property (nonatomic, assign) BOOL isClicking;
@property (nonatomic, retain) NSBezierPath *path;
@property (nonatomic, retain) NSBezierPath *wrappedPath;
@property (nonatomic, assign) PXToolSwitcher *switcher;
@property (nonatomic, retain) NSColor *color;

@property (nonatomic, readonly) PXToolPropertiesController *propertiesController;

- (NSString *)name;

- (PXToolPropertiesController *)createPropertiesController;

- (void)mouseDownAt:(NSPoint)aPoint 
fromCanvasController:(PXCanvasController *) controller;

- (void)mouseDraggedFrom:(NSPoint)origin 
					  to:(NSPoint)destination 
    fromCanvasController:(PXCanvasController *)controller;

- (void)mouseUpAt:(NSPoint)point 
fromCanvasController:(PXCanvasController *)controller;

- (void)mouseMovedTo:(NSPoint)aPoint
fromCanvasController:(PXCanvasController *)controller;

- (void)keyDown:(NSEvent *)event fromCanvasController:(PXCanvasController *)cc;

- (NSRect)crosshairRectCenteredAtPoint:(NSPoint)aPoint;

- (NSColor *)colorForCanvas:(PXCanvas *)canvas;

- (NSCursor *)cursor;

- (BOOL)shiftKeyDown;
- (BOOL)shiftKeyUp;
- (BOOL)optionKeyDown;
- (BOOL)optionKeyUp;
- (BOOL)commandKeyDown;
- (BOOL)commandKeyUp;

- (void)clearBezier;
- (BOOL)shouldUseBezierDrawing;
- (BOOL)supportsPatterns;

- (void)setPattern:(PXPattern *)pat;

@end
