//
//  PXDocumentController.m
//  Pixen
//


//This class is the application delegate.
//it respond as delegate for  applicationShouldOpenUntitledFile: 
//applicationDidFinishLaunching: applicationWillTerminate: 
//methods (see NSApplication documentation)
// it also responds to message from menu (only menu ??) 
// TODO : finish that 

#import "PXDocumentController.h"
#import "PXDocument.h"
#import "PXAboutController.h"
#import "PXWelcomeController.h"
#import "PXPreferencesController.h"
#import "PXCanvasWindowController.h"
#import "PXCanvasWindowController_IBActions.h"
#import "PXCanvasController.h"
#import "PXCanvasDocument.h"
#import "PXAnimationDocument.h"
#import "PXImageSizePrompter.h"
#import "PXLayer.h"
#import "PXCanvas.h"
#import "PXPalette.h"
#import "PXPanelManager.h"
#import "PathUtilities.h"
#import "PXToolPaletteController.h"
#import "PXToolSwitcher.h"
#import "PXTool.h"
#import "PXCanvasWindowController.h"
#import "PXCanvasView.h"
#import "PXGifImporter.h"
#import "PXCel.h"
#import "PXAnimation.h"
#import "PXPaletteImporter.h"

#import "PXCanvas_ImportingExporting.h"

#import <Foundation/NSFileManager.h>
#import <AppKit/NSAlert.h>

/***********************************/
/******** Private method ***********/
/***********************************/

@interface PXDocumentController (Private)
//Call from applicationDidFinishLaunching:
- (void) _createApplicationSupportSubdirectories;
@end

@implementation PXDocumentController (Private)

//TODO Create Subdirectories for colors too
- (void) _createApplicationSupportSubdirectory:(NSString *)sub
								   inDirectory:(NSString *)root
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDir;
	NSString *path = [root stringByAppendingPathComponent:sub];
	
	if(![fileManager fileExistsAtPath:path isDirectory:&isDir])
	{
		NSError *err=nil;
		if (![fileManager createDirectoryAtPath:path 
					withIntermediateDirectories:YES 
									 attributes:nil 
										  error:&err] ) 
		{
			[self presentError:err];
			return;
		}
	}
	else
	{
		if(!isDir) 
		{
			[NSException raise:@"Directory Error" format:@"Couldn't create Pixen support directory."];
			return;
		}
	}	
}
NSString *appSupportSubdirName = @"Pixen";
NSString *backgroundsSubdirName = @"Backgrounds";
NSString *backgroundPresetSubdirName = @"Presets";
NSString *presetsSubdirName = @"Presets";
NSString *palettesSubdirName = @"Palettes";

- (void) _createApplicationSupportSubdirectories
{
	NSString *path = GetApplicationSupportDirectory();
	
	// ./Pixen
	[self _createApplicationSupportSubdirectory:appSupportSubdirName inDirectory:path];   
	
	// ./Pixen/Backgrounds
	path = [path stringByAppendingPathComponent:appSupportSubdirName];
	[self _createApplicationSupportSubdirectory:backgroundsSubdirName inDirectory:path];
	
	
	// ./Pixen/Backgrounds/Presets 
	[self _createApplicationSupportSubdirectory:backgroundPresetSubdirName
									inDirectory:[path stringByAppendingPathComponent:backgroundsSubdirName]]; 
	
	// ./Pixen/Palettes
	[self _createApplicationSupportSubdirectory:palettesSubdirName inDirectory:path];
}
@end


@implementation PXDocumentController

- (void)updateShowsToolPreviewCache
{
	if ([[NSUserDefaults standardUserDefaults] objectForKey:PXToolPreviewEnabledKey] == nil)
	{
		cachedShowsToolPreview = YES;
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:PXToolPreviewEnabledKey];
	}
	else
	{
		cachedShowsToolPreview = [[NSUserDefaults standardUserDefaults] boolForKey:PXToolPreviewEnabledKey];
	}
}


- (void)updateShowsPreviousCelOverlayCache
{
	if ([[NSUserDefaults standardUserDefaults] objectForKey:PXPreviousCelOverlayEnabledKey] == nil)
	{
		cachedShowsPreviousCelOverlay = NO;
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:PXPreviousCelOverlayEnabledKey];
	}
	else
	{
		cachedShowsPreviousCelOverlay = [[NSUserDefaults standardUserDefaults] boolForKey:PXPreviousCelOverlayEnabledKey];
	}
}

- (IBAction)globalInstallPalette:sender
{
	PXPaletteImporter *importer = [[PXPaletteImporter alloc] init];
	[importer runInWindow:nil];
	[importer release];
}

//
// Delegate methods
//
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[self updateShowsToolPreviewCache];
	[self updateShowsPreviousCelOverlayCache];
	
	//Create some directories needs to store backgrounds and Colors 
	[self _createApplicationSupportSubdirectories];
	
	[[PXPanelManager sharedManager] restorePanelStates];
	
	if ([defaults boolForKey:@"PXActivateColorWellOnStartup"]) {
		[[[PXToolPaletteController sharedToolPaletteController] leftSwitcher] activateColorWell];
	}
	
	//If it is the first time Pixen run launch the welcome Panel
	//TODO (could be cleaner) : Fabien
	if (! [defaults boolForKey:PXHasRunBeforeKey] )
	{
		//id welcome = [[PXWelcomeController alloc] init];
		[defaults setBool:YES forKey:@"PXActivateColorWellOnStartup"];
		[defaults setBool:YES forKey:@"SUCheckAtStartup"];
		[defaults setInteger:60 forKey:PXAutosaveIntervalKey];
		[defaults setBool:YES forKey:PXAutosaveEnabledKey];
		[defaults setBool:YES forKey:PXZoomNewDocumentsToFitKey];
		[defaults setBool:YES forKey:PXInfoPanelIsOpenKey];
		[defaults setBool:YES forKey:PXHasRunBeforeKey];
		[defaults synchronize];
		[[NSColorPanel sharedColorPanel] setMode:NSCustomPaletteModeColorPanel];
		[[[PXPanelManager sharedManager] welcomePanel] makeKeyAndOrderFront:self];
		//[welcome showWindow:self];
	}
	
	
	if ( [defaults floatForKey:PXVersionKey] < 3 ) // <3 <3 <3
	{
		[defaults setBool:YES forKey:PXZoomNewDocumentsToFitKey];
		[defaults setFloat:3 forKey:@"PXVersion"];
	}
	
	mouseTrackingTimer = [[NSTimer scheduledTimerWithTimeInterval:.05
														   target:self
														 selector:@selector(updateMousePosition:)
														 userInfo:nil
														  repeats:YES] retain];
	
	[self rescheduleAutosave];
}

- (void)rescheduleAutosave
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	NSTimeInterval repeatTime = [defaults floatForKey:PXAutosaveIntervalKey];
	if([defaults boolForKey:PXAutosaveEnabledKey])
	{
		[self setAutosavingDelay:repeatTime];
	}
	else
	{
		[self setAutosavingDelay:0];
	}
}

- (void)applicationWillResignActive:(NSNotification *)aNotification
{
	for (PXCanvasDocument *current in [self documents])
	{
		[[[current canvasController] view] setAcceptsFirstMouse:NO];
	}
}

- (void)updateMousePosition:(NSTimer *)timer
{
	PXCanvasDocument *doc = [self currentDocument];
	if(doc)
	{
		//FIXME: coupled to canvas controller
		PXCanvasController *canvasController = [doc canvasController];
		NSWindow *window = [canvasController window];
		if (![window isKeyWindow]) {
			[canvasController updateMousePosition:[window mouseLocationOutsideOfEventStream]];
		}
	}
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	if([[filename pathExtension] isEqual:PXBackgroundSuffix])
	{
		id bgName = [filename lastPathComponent];
		id dest = [GetBackgroundPresetsDirectory() stringByAppendingPathComponent:bgName];
		int result = [[NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Install Background Template \"%@\"?", @"Install Background Template \"%@\"?"), bgName] defaultButton:NSLocalizedString(@"Install", @"Install") alternateButton:NSLocalizedString(@"Cancel", @"CANCEL") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"%@ will be copied to %@.", @"%@ will be copied to %@."), [filename stringByAbbreviatingWithTildeInPath], [dest stringByAbbreviatingWithTildeInPath]] runModal];
		if(result == NSAlertDefaultReturn)
		{
			NSError *err=nil;
			if(![[NSFileManager defaultManager] copyItemAtPath:filename toPath:dest error:&err]) 
			{
				[self presentError:err];
				return NO;
			}
			else
			{
				[[NSNotificationCenter defaultCenter] postNotificationName:PXBackgroundTemplateInstalledNotificationName object:self];
			}
		}
	}
	if([[filename pathExtension] isEqual:PXPatternSuffix])
	{
		NSString *patternName = [filename lastPathComponent];
		int result = [[NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Install Pattern \"%@\"?", @"Install Pattern \"%@\"?"), patternName] defaultButton:NSLocalizedString(@"Install", @"Install") alternateButton:NSLocalizedString(@"Cancel", @"CANCEL") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The pattern %@ will be added to Pixen's saved pattern list.", @"The pattern %@ will be added to Pixen's saved pattern list."), [filename stringByAbbreviatingWithTildeInPath]] runModal];
		if(result == NSAlertDefaultReturn)
		{
			NSString *patternArchiveFilename = GetPixenPatternFile();
			NSArray *patterns = [[NSKeyedUnarchiver unarchiveObjectWithFile:patternArchiveFilename] arrayByAddingObject:[NSKeyedUnarchiver unarchiveObjectWithFile:filename]];
			[NSKeyedArchiver archiveRootObject:patterns toFile:patternArchiveFilename];
			[[NSNotificationCenter defaultCenter] postNotificationName:PXPatternsChangedNotificationName object:self userInfo:[NSDictionary dictionaryWithObject:patterns forKey:@"patterns"]];
		}
	}
	if([[filename pathExtension] isEqual:PXPaletteSuffix] || [[filename pathExtension] isEqual:MicrosoftPaletteSuffix] || [[filename pathExtension] isEqual:AdobePaletteSuffix])
	{
		id paletteName = [filename lastPathComponent];
		id dest = [GetPixenPaletteDirectory() stringByAppendingPathComponent:paletteName];
		int result = [[NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Install Palette \"%@\"?", @"Instal Palette \"%@\"?"), paletteName] defaultButton:NSLocalizedString(@"Install", @"Install") alternateButton:NSLocalizedString(@"Cancel", @"CANCEL") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"%@ will be copied to %@.", @"%@ will be copied to %@."), [filename stringByAbbreviatingWithTildeInPath], [dest stringByAbbreviatingWithTildeInPath]] runModal];
		if(result == NSAlertDefaultReturn)
		{
			PXPaletteImporter *importer = [[PXPaletteImporter alloc] init];
			[importer importPaletteAtPath:filename];
			[importer release];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:PXUserPalettesChangedNotificationName object:self];
			
			return YES;
		}
	}
	NSError *err = nil;
	NSDocument *doc = [self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:YES error:&err];
	if(err) {
		[self presentError:err];
	}
	
	return doc != nil;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[[PXPanelManager sharedManager] archivePanelStates];
	[mouseTrackingTimer invalidate];
	[mouseTrackingTimer release];
}


//IBAction 

- (IBAction)newFromClipboard:sender
{
	NSError *err=nil;
	PXCanvasDocument *doc = [self makeUntitledDocumentOfType:PixenImageFileType showSizePrompt:NO error:&err];
	if(err) {
		[self presentError:err];
		return;
	}
	[self addDocument:doc];
	[doc loadFromPasteboard:[NSPasteboard generalPasteboard]];
}

// It occurs to me (after having renamed this object to be a document controller, of course)
// that this sort of method really should be in, like, an app delegate. But I'm not going
// to deal with that right now.
- (IBAction)toggleAlignmentCrosshairs:sender
{
	BOOL showCrosshairs = [[NSUserDefaults standardUserDefaults] boolForKey:PXCrosshairEnabledKey];
	showCrosshairs = !showCrosshairs;
	[[NSUserDefaults standardUserDefaults] setBool:showCrosshairs forKey:PXCrosshairEnabledKey];
	//FIXME: coupled to canvas window controller
	[[[[self currentDocument] windowControllers] objectAtIndex:0] redrawCanvas:self];
}

- (BOOL)showsToolPreview
{
	return cachedShowsToolPreview;
}

- (IBAction)toggleToolPreview:sender
{
	BOOL showToolPreview = [[NSUserDefaults standardUserDefaults] boolForKey:PXToolPreviewEnabledKey];
	cachedShowsToolPreview = !showToolPreview;
	if (!cachedShowsToolPreview) // clear what's there
	{
		[[PXToolPaletteController sharedToolPaletteController] clearBeziers];
	}
	[[NSUserDefaults standardUserDefaults] setBool:cachedShowsToolPreview forKey:PXToolPreviewEnabledKey];
	//FIXME: coupled to canvas window controller 
	[[[[self currentDocument] windowControllers] objectAtIndex:0] redrawCanvas:self];
}

- (BOOL)showsPreviousCelOverlay
{
	return cachedShowsPreviousCelOverlay;
}

- (void)togglePreviousCelOverlay:sender
{
	BOOL showPreviousCelOverlay = [[NSUserDefaults standardUserDefaults] boolForKey:PXPreviousCelOverlayEnabledKey];
	cachedShowsPreviousCelOverlay = !showPreviousCelOverlay;
	[[NSUserDefaults standardUserDefaults] setBool:cachedShowsPreviousCelOverlay forKey:PXPreviousCelOverlayEnabledKey];
	//FIXME: coupled to canvas window controller
	[[[self currentDocument] windowControllers] makeObjectsPerformSelector:@selector(redrawCanvas:) withObject:self];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if ([anItem action] == @selector(newFromClipboard:))
	{
		NSPasteboard *board = [NSPasteboard generalPasteboard];
		
		if ([[board types] containsObject:PXLayerPboardType])
			return YES;
		
		for (NSString *type in [NSImage imagePasteboardTypes])
		{
			if ([[board types] containsObject:type])
				return YES;
		}
		
		return NO;
	}
	else if ([anItem action] == @selector(toggleAlignmentCrosshairs:))
	{
		BOOL showCrosshairs = [[NSUserDefaults standardUserDefaults] boolForKey:PXCrosshairEnabledKey];
		[anItem setTitle:(showCrosshairs) ? NSLocalizedString(@"HIDE_ALIGNMENT_CROSSHAIRS", @"Hide Alignment Crosshairs") :
		 NSLocalizedString(@"SHOW_ALIGNMENT_CROSSHAIRS", @"Show Alignment Crosshairs")];
		return YES;
	}
	else if ([anItem action] == @selector(toggleToolPreview:))
	{
		BOOL showsToolPreview = [self showsToolPreview];
		[anItem setTitle:(showsToolPreview) ? NSLocalizedString(@"HIDE_TOOL_PREVIEW", @"Hide Tool Preview") :
		 NSLocalizedString(@"SHOW_TOOL_PREVIEW", @"Show Tool Preview")];
		return YES;
	}
	else if ([anItem action] == @selector(togglePreviousCelOverlay:))
	{
		[anItem setTitle:([self showsPreviousCelOverlay]) ? NSLocalizedString(@"HIDE_PREVIOUS_CEL_OVERLAY", @"Hide Previous Cel Overlay") :
		 NSLocalizedString(@"SHOW_PREVIOUS_CEL_OVERLAY", @"Show Previous Cel Overlay")];
		return YES;
	}
	else {
		return YES;
	}
}

- (PXAnimationDocument *)handleAnimatedGifAtURL:(NSURL *)aURL
{
	BOOL isAnimated = [PXGifImporter fileAtURLIsAnimated:aURL];
	if (isAnimated)
	{
		NSError *error=nil;
		PXAnimationDocument *doc = [[[PXAnimationDocument alloc] initWithContentsOfURL:aURL ofType:GIFFileType error:&error] autorelease];
		if(error) {
			[self presentError:error];
		}
		return doc;
	}
	return nil;
}

- (BOOL)presentError:(NSError *)error
{
	if ([[error domain] isEqualToString:NSCocoaErrorDomain] && [error code] == 260) {
		return NO; // suppress 'Document could not be created errors' which are the result of returning nil in 'makeUntitledDocumentOfType:error:'
	}
	
	return YES;
}

- (id)makeUntitledDocumentOfType:(NSString *)typeName showSizePrompt:(BOOL)showPrompt error:(NSError **)outError
{
	if (!showPrompt) {
		return [super makeUntitledDocumentOfType:typeName error:outError];
	}
	
	PXImageSizePrompter *prompter = [[PXImageSizePrompter alloc] init];
	
	if (![prompter runModal]) {
		[prompter release];
		
		if (outError)
			*outError = nil;
		
		return nil;
	}
	
	id document = [super makeUntitledDocumentOfType:typeName error:outError];
	
	if (!document) {
		[prompter release];
		return nil;
	}
	
	[[document canvas] setSize:[prompter size]
					withOrigin:NSZeroPoint
			   backgroundColor:[prompter backgroundColor]];
	
	[[document canvasController] updateCanvasSize];
	
	[prompter release];
	
	return document;
}

- (id)makeUntitledDocumentOfType:(NSString *)typeName error:(NSError **)outError
{
	return [self makeUntitledDocumentOfType:typeName showSizePrompt:YES error:outError];
}

- (id)makeDocumentWithContentsOfURL:(NSURL *)aURL ofType:(NSString *)docType
{
	if ([docType isEqualToString:GIFFileType])
	{
		id potentiallyAnimatedDocument = [self handleAnimatedGifAtURL:aURL];
		if (potentiallyAnimatedDocument)
			return potentiallyAnimatedDocument;
	}
	NSError *err = nil;
	NSDocument *doc = [super makeDocumentWithContentsOfURL:aURL ofType:docType error:&err];
	if(err) {
		[self presentError:err];
	}
	return doc;
}

- (id)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)docType error:(NSError **)err
{
	if ([docType isEqualToString:GIFFileType])
	{
		id potentiallyAnimatedDocument = [self handleAnimatedGifAtURL:url];
		if (potentiallyAnimatedDocument)
			return potentiallyAnimatedDocument;
	}
	NSDocument *doc = [super makeDocumentWithContentsOfURL:url ofType:docType error:err];
	if(err && *err) {
		[self presentError:*err];
		return nil;
	}
	return doc;
}

- (id)makeDocumentForURL:(NSURL *)absoluteDocumentURL withContentsOfURL:(NSURL *)absoluteDocumentContentsURL ofType:(NSString *)typeName error:(NSError **)outError
{
	if ([typeName isEqualToString:GIFFileType])
	{
		id potentiallyAnimatedDocument = [self handleAnimatedGifAtURL:absoluteDocumentURL];
		if (potentiallyAnimatedDocument)
			return potentiallyAnimatedDocument;
	}
	return [super makeDocumentForURL:absoluteDocumentURL withContentsOfURL:absoluteDocumentContentsURL ofType:typeName error:nil];
}

- (IBAction)newAnimationDocument:sender
{
	NSError *err = nil;
	NSDocument *doc = [self makeUntitledDocumentOfType:PixenAnimationFileType error:&err];
	if(err) 
	{
		[self presentError:err];
		return;
	}
	[self addDocument:doc];
	[doc makeWindowControllers];
	[doc showWindows];
}

- (NSArray *)animationDocuments
{
	NSMutableArray *animationDocuments = [NSMutableArray array];
	for (NSDocument *document in [self documents])
    {
		if ([document isKindOfClass:[PXAnimationDocument class]]) {
			[animationDocuments addObject:document];
		}
	}
	return animationDocuments;
}

- (IBAction)importAnimationFromImageSequence:sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setPrompt:@"Import"];
	[openPanel setTitle:@"Import Sequence"];
	
	// Determine the appropriate extensions for the open panel.
	NSArray *longTypes = [PXCanvasDocument readableTypes];
	NSMutableArray *types = [[[NSMutableArray alloc] initWithCapacity:[longTypes count]] autorelease];
	for (NSString *currentType in longTypes)
	{
		[types addObjectsFromArray:[[NSDocumentController sharedDocumentController] fileExtensionsFromType:currentType]];
	}
	[openPanel setAllowsOtherFileTypes:NO];
	[openPanel setCanChooseDirectories:NO];
	
	NSInteger returnCode = [openPanel runModalForTypes:types];
	if (returnCode == NSFileHandlingPanelCancelButton) { return; }
	
	PXAnimationDocument *animationDocument = (PXAnimationDocument *)[self makeUntitledDocumentOfType:PixenAnimationFileType error:NULL];
	
	[[animationDocument animation] removeCel:[[animationDocument animation] objectInCelsAtIndex:0]];
	
	NSMutableArray *images = [[[NSMutableArray alloc] initWithCapacity:[[openPanel filenames] count]] autorelease];
    for (NSString *currentFile in [openPanel filenames])
	{
		[images addObject:[PXCanvas canvasWithContentsOfFile:currentFile]];
	}
	
	float defaultDuration = 1.0f;
	for(PXCanvas *current in images)
	{
		[[animationDocument animation] addCel:[[[PXCel alloc] initWithCanvas:current duration:defaultDuration] autorelease]];
	}	
	[self addDocument:animationDocument];
	[animationDocument makeWindowControllers];
	[animationDocument showWindows];
	[animationDocument updateChangeCount:NSChangeReadOtherContents];
}

@end

