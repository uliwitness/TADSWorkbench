//
//  ProjectDocument.m
//  foo
//
//  Created by Uli Kusterer on Mon May 26 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import "ProjectDocument.h"
#import "ErrorListEntry.h"
#import "UKErrorsWindow.h"
#import "UKSyntaxColoredTextDocument.h"
#import "NSFileHandle+AppendToStringAndNotify.h"
#import "NSString+FetchNextLine.h"

static ProjectDocument*		sProjectDocumentCurrDocument = nil;



@implementation ProjectDocument

+(ProjectDocument*)		currentProject
{
	return sProjectDocumentCurrDocument;
}


-(id)	init
{
    self = [super init];
    if( self )
	{
		NSBundle* bndl = [NSBundle mainBundle];
	
		sourceFiles = [[NSMutableArray alloc] init];
		headerPaths = [[NSMutableArray alloc] init];
		libraries = [[NSMutableArray alloc] initWithObjects: [NSMutableString stringWithString:@"system.tl"], [NSMutableString stringWithString:@"adv3/adv3.tl"], nil];
		constants = [[NSMutableArray alloc] initWithObjects: [NSMutableString stringWithString:NSLocalizedString(@"LANGUAGE=en_us", @"")], [NSMutableString stringWithString:NSLocalizedString(@"MESSAGESTYLE=neu", @"")], nil];
		errorsWindow = [[UKErrorsWindow alloc] init];
        [errorsWindow setDelegate: self];
		
		topCommentStore = [[NSMutableString alloc] initWithContentsOfFile:[bndl pathForResource:@"TopComment" ofType:@"txt"]];
		sourcesCommentStore = [[NSMutableString alloc] initWithContentsOfFile:[bndl pathForResource:@"SourcesComment" ofType:@"txt"]];
		otherConfigStore = [[NSMutableString alloc] initWithContentsOfFile:[bndl pathForResource:@"OtherConfig" ofType:@"txt"]];
		otherOptionsStore = [[NSMutableString alloc] initWithContentsOfFile:[bndl pathForResource:@"OtherOptions" ofType:@"txt"]];
		outputFileStore = [[NSMutableString alloc] init];
		tadscOutBuffer = [[NSMutableString alloc] init];
		
		settingsPanel = nil;	// Used as a flag whether nib's been loaded.
		
		gotSomething = NO;
		hadDoubleComment = NO;
		ourConfig = NO;
		
		preInitStore = 1;
		debugSymbolsStore = NO;
		rebuildUnchangedStore = NO;
		relinkUnchangedStore = NO;
		warningsModeStore = 2;
		quietModeStore = NO;
		verboseErrorsStore = NO;
		noDefaultFilesStore = NO;
		
		tadsc = nil;
	}
	
    return self;
}


-(void)	dealloc
{
	[sourceFiles release];
	sourceFiles = nil;
	[headerPaths release];
	headerPaths = nil;
	[libraries release];
	libraries = nil;
	[constants release];
	constants = nil;
	[errorsWindow release];
	errorsWindow = nil;
	
	[topCommentStore release];
	topCommentStore = nil;
	[sourcesCommentStore release];
	sourcesCommentStore = nil;
	[otherConfigStore release];
	otherConfigStore = nil;
	[otherOptionsStore release];
	otherOptionsStore = nil;
	[outputFileStore release];
	outputFileStore = nil;
	[tadscOutBuffer release];
	tadscOutBuffer = nil;
	
	if( sProjectDocumentCurrDocument == self )
		sProjectDocumentCurrDocument = nil;
	
	[super dealloc];
}


-(void) windowDidBecomeMain: (NSNotification*)notification
{
	sProjectDocumentCurrDocument = self;
}


-(NSString *)	windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"ProjectDocument";
}

-(void)	windowControllerDidLoadNib: (NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];

	[listView expandItem: sourceFiles];
	[listView expandItem: headerPaths];
	[listView expandItem: libraries];
	[listView expandItem: constants];
	[listView setDoubleAction: @selector(doubleClickOutlineView:)];
	
	[projectName setStringValue: [self displayName]];
	
	[self updateUI];

	[projectWindow makeKeyAndOrderFront: nil];
}


/* -----------------------------------------------------------------------------
	validateMenuItem:
		Make sure menu items are enabled properly.
	
	REVISIONS:
        2005-03-18  UK  Changed to work with includes and constants in separate
                        lists.
		2003-05-31	UK	Created.
   -------------------------------------------------------------------------- */

-(BOOL)	validateMenuItem: (NSMenuItem*)menuItem
{
	if( [menuItem action] == @selector(delete:) )
    {
        NSTableView*    lv = [self selectedListView];
        
        
		return (lv && [lv selectedRow] >= 0);
    }
	else
		return [super validateMenuItem: menuItem];
}


/* -----------------------------------------------------------------------------
	selectedListView:
		Return the one of our three list views that has keyboard focus, or NIL
        if it's another.
	
	REVISIONS:
        2005-03-18  UK  Created.
   -------------------------------------------------------------------------- */

-(NSTableView*) selectedListView
{
    if( [projectWindow isKeyWindow] && [projectWindow firstResponder] == listView )
        return listView;
    else if( [settingsPanel isKeyWindow] )
    {
        if( [settingsPanel firstResponder] == constantListView )
            return constantListView;
        else if( [settingsPanel firstResponder] == includesListView )
            return includesListView;
    }
    
    return nil;
}


/* -----------------------------------------------------------------------------
	clear:
		Call through, just in case.
	
	REVISIONS:
        2005-03-18  UK  Created.
   -------------------------------------------------------------------------- */

-(IBAction)	clear: (id)sender
{
    [self delete: sender];
}


/* -----------------------------------------------------------------------------
	delete:
		Handle choice of "delete" menu item by deleting an item or several
		from our list of files/constants/libraries/headers.
	
	REVISIONS:
        2005-03-18  UK  Changed to work with includes and constants in separate
                        lists.
		2003-05-31	UK	Created.
   -------------------------------------------------------------------------- */

-(IBAction)	delete: (id)sender
{
    NSTableView*    lv = [self selectedListView];
    
    if( !lv )
    {
        NSBeep();
        return;
    }
    
	int             row = [lv selectedRow];
	id              vItem = (lv == listView) ? [(NSOutlineView*)lv itemAtRow: row] : [self tableView: lv objectValueForTableColumn: nil row: row];
	
	if( [vItem isKindOfClass: [NSMutableArray class]] )	// Container item.
		[vItem removeAllItems];
	else if( [sourceFiles containsObject:vItem] )
		[sourceFiles removeObject:vItem];
	else if( [constants containsObject:vItem] )
		[constants removeObject:vItem];
	else if( [headerPaths containsObject:vItem] )
		[headerPaths removeObject:vItem];
	else if( [libraries containsObject:vItem] )
		[libraries removeObject:vItem];
	
	[self projectChanged: nil];
	
	[lv reloadData];
}


-(BOOL)	writeToFile: (NSString*)fileName ofType: (NSString*)type
{	
	FILE*			theFile = fopen([fileName UTF8String],"w");
	NSEnumerator*	itty;
	NSString*		str;

	if( !theFile )
		return NO;
	
	// Comment at top of file:
	fputs( [[topComment string] UTF8String], theFile );
	if( [[topComment string] characterAtIndex: ([[topComment string] length]-1)] != '\r'
		&& [[topComment string] characterAtIndex: ([[topComment string] length]-1)] != '\n')
		fputs("\n",theFile);
	
	// Options we understand:
	if( [[outputFile stringValue] length] > 0 )
		fprintf( theFile, "-o %s\n", [EscapeNSStringForT3m( [outputFile stringValue] ) UTF8String] );
	if( [debugSymbols state] )
		fputs( "-d\n", theFile );
	if( [preInit intValue] == 2 )
		fputs( "-pre\n", theFile );
	else if( [preInit intValue] == 3 )
		fputs( "-nopre\n", theFile );
	if( [noDefaultFiles state] )
		fputs( "-nodef\n", theFile );
	if( [quietMode state] )
		fputs( "-q\n", theFile );
	if( [verboseErrors state] )
		fputs( "-v\n", theFile );
	if( [warningsMode intValue] != 2 )
		fprintf( theFile, "-w%d\n", ([warningsMode intValue] -1) );
	if( [rebuildUnchanged state] )
		fputs( "-a\n", theFile );
	if( [relinkUnchanged state] )
		fputs( "-al\n", theFile );
	
	// Write defines:
	itty = [constants objectEnumerator];
	while( str = [itty nextObject] )
		fprintf( theFile, "-D %s\n", [str UTF8String] );
	
	// Options we don't understand:
	if( [[otherOptions string] length] > 0 )
	{
		fputs( [[otherOptions string] UTF8String], theFile );
		if( [[otherOptions string] characterAtIndex: ([[otherOptions string] length]-1)] != '\r'
			&& [[otherOptions string] characterAtIndex: ([[otherOptions string] length]-1)] != '\n')
			fputs("\n",theFile);
	}
	
	// Comment between options & sources:
	if( [[sourcesComment string] length] > 0 )
	{
		if( [[sourcesComment string] rangeOfString: @"##sources"].location == NSNotFound )
			fputs("##sources\n",theFile);
		fputs( [[sourcesComment string] UTF8String], theFile );
		if( [[sourcesComment string] characterAtIndex: ([[sourcesComment string] length]-1)] != '\r'
			&& [[sourcesComment string] characterAtIndex: ([[sourcesComment string] length]-1)] != '\n')
			fputs("\n",theFile);
	}
	
	// Now write includes, libs, sources:
	itty = [headerPaths objectEnumerator];
	while( str = [itty nextObject] )
		fprintf( theFile, "-I %s\n", [EscapeNSStringForT3m(str) UTF8String] );
	
	itty = [libraries objectEnumerator];
	while( str = [itty nextObject] )
		fprintf( theFile, "-lib %s\n", [EscapeNSStringForT3m(str) UTF8String] );
	
	itty = [sourceFiles objectEnumerator];
	while( str = [itty nextObject] )
		fprintf( theFile, "-source %s\n", [EscapeNSStringForT3m(str) UTF8String] );
	
	// Write config info we don't understand:
	if( [[otherConfig string] length] > 0 )
	{
		fputs( [[otherConfig string] UTF8String], theFile );
		if( [[otherConfig string] characterAtIndex: ([[otherConfig string] length]-1)] != '\r'
			&& [[otherConfig string] characterAtIndex: ([[otherConfig string] length]-1)] != '\n')
			fputs("\n",theFile);
	}
	
	fclose( theFile );
	
	return YES;
}

-(BOOL)	readFromFile:(NSString *)fileName ofType:(NSString *)type
{
	NSTadsOptFileHelper*		helper;
	BOOL						success;
	
	helper = [[[NSTadsOptFileHelper alloc] initWithDelegate: self] autorelease];
	success = [helper processFile: fileName];
	[progressBar setDoubleValue:0];
	[self updateUI];
	
	return success;
}


-(IBAction)	projectChanged: (id)sender
{
	[self updateChangeCount:NSChangeDone];
}


-(void)	updateUI
{
	[statusText setStringValue: @"Updating UI..."];
	
	[topComment setString: topCommentStore];
	[sourcesComment setString: sourcesCommentStore];
	[otherConfig setString: otherConfigStore];
	[otherOptions setString: otherOptionsStore];
	[outputFile setStringValue: outputFileStore];
	
	[preInit setIntValue: preInitStore];
	[debugSymbols setState: debugSymbolsStore];
	[rebuildUnchanged setState: rebuildUnchangedStore];
	[relinkUnchanged setState: relinkUnchangedStore];
	[warningsMode setIntValue: warningsModeStore];
	[quietMode setState: quietModeStore];
	[verboseErrors setState: verboseErrorsStore];
	
    [includesListView reloadData];
    [constantListView reloadData];
    
	[statusText setStringValue: @"Finished."];
}


-(NSString*)	gameFileName
{
	NSString*	gameFileName = nil;
	if( [outputFileStore length] > 0 )
		gameFileName = [[[self fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent: outputFileStore];
	else
	{
		NSString*		firstFile = [sourceFiles objectAtIndex: 0];
		NSString*		leafName = [[[firstFile lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension: @"t3"];
		gameFileName = [[[self fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent: leafName];
	}
	
	return gameFileName;
}


-(IBAction)	buildGame: (id) sender
{
	NSArray* params = [NSArray arrayWithObjects:nil];
	runAfterBuilding = NO;
	debugAfterBuilding = NO;
	[self runTadsCompiler: params];
}

-(IBAction)	buildAndRunGame: (id) sender
{
	NSArray* params = [NSArray arrayWithObjects:nil];
	runAfterBuilding = YES;
	debugAfterBuilding = NO;
	[self runTadsCompiler: params];
}


-(IBAction)	runGame: (id)sender
{
	NSString*		runtimeName;
	
	runtimeName = [[NSUserDefaults standardUserDefaults] stringForKey: @"UKTADSInterpreterPath"];
	if( runtimeName == nil )
		runtimeName = [[NSBundle mainBundle] pathForResource: @"frob" ofType: nil];
	if( [[runtimeName pathExtension] caseInsensitiveCompare: @"app"] == NSOrderedSame )
		[[NSWorkspace sharedWorkspace] openFile: [self gameFileName] withApplication: runtimeName];
	else
		[self runScriptOnGameFile: @"RunTadsScript" withTool: runtimeName];
}


-(IBAction)	debugGame: (id)sender
{
	[self runScriptOnGameFile: @"DebugTadsScript" withTool: [[NSUserDefaults standardUserDefaults] stringForKey: @"UKTADSDebuggerPath"]];
}


-(void)	runScriptOnGameFile: (NSString*)fname withTool: (NSString*)theTool
{
	NSMutableString*		gameFileName;
	NSMutableString*		toolName;
	NSString*				cmd;
	NSAppleScript*			runTadsScript;
	NSAppleEventDescriptor*	desc;
	
	[statusText setStringValue: @"Launching script..."];
	
	toolName = [theTool mutableCopy];
	EscapeNSStringForCommandline( toolName );	// Escape for command line.
	EscapeCharInNSString( '\\', toolName );	// Now escape again for AppleScript.
	
	gameFileName = [[[self gameFileName] mutableCopy] autorelease];
	EscapeNSStringForCommandline( gameFileName );	// Escape for command line.
	EscapeCharInNSString( '\\', gameFileName );	// Now escape again for AppleScript.
	cmd = [NSString stringWithFormat: [NSString stringWithContentsOfFile: [[NSBundle mainBundle] pathForResource:fname ofType:@"txt"]], toolName, gameFileName];
	
	runTadsScript = [[[NSAppleScript alloc] initWithSource:cmd] autorelease];
	desc = [runTadsScript executeAndReturnError:nil];
	//result = [[NSString alloc] initWithString: [desc stringValue]];
	
	[statusText setStringValue: @"Ready."];
}


-(IBAction)	buildAndDebugGame: (id) sender
{
	NSArray* params = [NSArray arrayWithObjects:@"-d",nil];
	runAfterBuilding = NO;
	debugAfterBuilding = YES;
	[self runTadsCompiler: params];
}


-(IBAction)	cleanGame: (id) sender
{
	NSArray* params = [NSArray arrayWithObjects:@"-clean",nil];
	runAfterBuilding = NO;
	debugAfterBuilding = NO;
	[self runTadsCompiler: params];
}

// -----------------------------------------------------------------------------
//  runTadsCompiler:
//      Main bottleneck for compiler interaction. This collects the settings
//      And hands them to NSTask as parameters and environment variables and
//      stuff. Then it calls readDataToEndOfFileIntoString:endSelector:delegate:
//      to get all the output from the compiler, which is sent to
//      compilerOutputFrom:finished:.
//
//  REVISIONS:
//      2004-11-13  UK  Changed to use readDataToEndOfFileIntoString.
// -----------------------------------------------------------------------------

-(void)	runTadsCompiler: (NSArray*) params
{
	// Update makefile on disk:
	if( [self isDocumentEdited] )
	{
		[statusText setStringValue: @"Saving Project..."];
		[self saveDocument:nil];
	}
	
	if( [self fileName] == nil )
	{
		NSBeginAlertSheet( NSLocalizedString(@"Can't build game.", @""), NSLocalizedString(@"OK",@""), nil, nil, projectWindow, nil, 0, 0, nil, NSLocalizedString(@"The project file needs to be saved to disk once before the game can be built.", @"") );
		return;
	}
	
	NSDictionary*	environment = nil;
	NSString*		currentDir = [[self fileName] stringByDeletingLastPathComponent];
	NSString*		symDir = [currentDir stringByAppendingPathComponent: @"build"];
	NSBundle*		bndl = [NSBundle mainBundle];
	NSArray*		moreParams = [NSArray arrayWithObjects:@"-errnum",@"-statprefix",@"::status::",
									@"-nobanner",@"-f",[self fileName],@"-Fy",symDir,@"-Fo",symDir,
									@"-cs",@"mac",nil];
	
	[progressBar setMaxValue:(([sourceFiles count] +[libraries count]) *2)];
	[progressBar setDoubleValue:0];
	
	// Create folder for output files:
	[statusText setStringValue: @"Creating build folder..."];
	[[NSFileManager defaultManager] createDirectoryAtPath:symDir attributes:nil];
	
	// Make sure output goes to a special folder:
	params = [params arrayByAddingObjectsFromArray:moreParams];
	
	// Create our task for running t3make:
	[statusText setStringValue: @"Launching t3make..."];
	tadscPipe = [[NSPipe alloc] init];
	tadsc = [[NSTask alloc] init];
	
	// Set up the task:
	NSString*	tadsCompilerPath = [[NSUserDefaults standardUserDefaults] objectForKey: @"UKTADSCompilerPath"];
	if( !tadsCompilerPath )
		tadsCompilerPath = [bndl pathForResource:@"t3make" ofType: nil];
	[tadsc setLaunchPath: tadsCompilerPath];
	[tadsc setCurrentDirectoryPath: currentDir];	// Make sure current directory is set to makefile's directory.
	[tadsc setStandardOutput: tadscPipe];			// Redirect stdout...
	[tadsc setStandardError: tadscPipe];			// ... and stderr just in case.
	[tadsc setArguments:params];					// Hand params to t3make
	
	// Set up environment variables so t3make knows where to look for libraries etc.:
	NSString*		t3libPath = [bndl pathForResource:@"t3library" ofType:@""];
	NSString*		t3includePath = [bndl pathForResource:@"t3include" ofType:@""];
	NSString*		t3resPath = [bndl pathForResource:@"t3resource" ofType:@""];
	NSString*		t3libIncludePath = [NSString stringWithFormat: @"%@:%@", t3libPath, t3includePath];
	environment = [NSDictionary dictionaryWithObjectsAndKeys:
					t3includePath, @"T3_INCDIR",
					t3libPath, @"T3_LIBDIR",
					t3resPath, @"T3_RESDIR",
					t3libIncludePath, @"T3_USERLIBDIR",
					nil ];
	[tadsc setEnvironment: environment];
	
	[tadscOutBuffer deleteCharactersInRange:NSMakeRange(0,[tadscOutBuffer length])];    // Clear buffer.
	[errorsWindow removeAllObjects];                                                    // Clear errors/warnings list.
	tadscStream = [tadscPipe fileHandleForReading];	// Get a stream to read t3make's output from.
    
    // Make sure we get any output t3make sends our way:
	[tadscStream readDataToEndOfFileIntoString: tadscOutBuffer endSelector: @selector(compilerOutputFrom:finished:)
										delegate: self];
	
	// Launch t3make:
	[tadsc launch];
	
	// Read the output asynchronously in the background:
	[statusText setStringValue: @"t3make ..."];
}


// -----------------------------------------------------------------------------
//  compilerOutputFrom:finished:
//      Called by runTadsCompiler: to get all the output from the compiler,
//      which is then parsed line-wise and added to our errors window.
//
//  REVISIONS:
//      2004-11-13  UK  Changed to use nextFullLine.
// -----------------------------------------------------------------------------

-(void) compilerOutputFrom: (NSFileHandle*)hd finished: (BOOL)fini
{
	NSString*		string = nil;
	
	[progressBar animate:nil];
	
    while( (string = [tadscOutBuffer nextFullLine]) )
    {
        if( [string hasPrefix: @"::status::"] )
        {
            [statusText setStringValue: [string substringFromIndex: 10]];
            [progressBar setDoubleValue: ([progressBar doubleValue] +0.1)];
        }
        else if( [string hasPrefix: @"Errors:"] || [string hasPrefix: @"Warnings:"] )
            ; // Do nothing and just skip number of errors/warnings info.
        else
        {
            [errorsWindow addObject: [[[ErrorListEntry alloc] initWithString: string] autorelease]];
            [progressBar setDoubleValue: ([progressBar doubleValue] +1)];
        }
    }
    
    if( fini )
        [self performSelectorOnMainThread:@selector(compilerFinished:) withObject:nil waitUntilDone:NO];
}


-(void)	textDidChange:(NSNotification *)notification
{
	[self projectChanged: nil];
}


// -----------------------------------------------------------------------------
//  compilerFinished:
//      Called by compilerOutputFrom:finished: when t3make has no more data to
//      send. This terminates the NSTask and cleans up the related pipes etc.
//
//  REVISIONS:
//      2004-11-13  UK  Documented, updated to use new errorsWindow.
// -----------------------------------------------------------------------------

-(void)	compilerFinished: (NSNotification *)aNotification
{
	[tadsc terminate];
	[tadsc release]; // Don't forget to clean up memory
	tadsc = nil; // Just in case...
	[tadscPipe release];
	tadscPipe = nil;
	tadscStream = nil;
	
	[errorsWindow addObject: [[[ErrorListEntry alloc] initWithMessage: NSLocalizedString(@"Ready.",@"")] autorelease]];
	
	[progressBar setDoubleValue:0];
	[statusText setStringValue: NSLocalizedString(@"t3make Finished.",@"")];
	
	if( runAfterBuilding )
		[self runGame:nil];
	if( debugAfterBuilding )
		[self debugGame:nil];
}


-(IBAction)	showSettings: (id) sender
{
	[settingsPanel makeKeyAndOrderFront:nil];
}


-(IBAction)	showSettingsPage: (int)settingsPage
{
    [settingsTabView selectTabViewItemAtIndex: settingsPage];
	[settingsPanel makeKeyAndOrderFront: nil];
}


-(IBAction)	showErrorWindow: (id) sender
{
	[errorsWindow showErrorWindow: self];
}


-(IBAction)	addSourceFile: (id) sender
{
	NSOpenPanel*		thePanel = [[NSOpenPanel alloc] init];
	[thePanel setAllowsMultipleSelection: YES];
	[thePanel setCanChooseFiles: YES];
	[thePanel setCanChooseDirectories: NO];
	[thePanel beginSheetForDirectory:nil file:nil
		types:[NSArray arrayWithObjects:@"t", NSFileTypeForHFSTypeCode( 'TEXT' ), nil]
		modalForWindow:projectWindow modalDelegate:self
		didEndSelector:@selector(addSourceFileOpenPanelDidEnd:returnCode:contextInfo:) contextInfo:thePanel];
}

-(IBAction)	addLibrary: (id) sender
{
	NSOpenPanel*		thePanel = [[NSOpenPanel alloc] init];
	[thePanel setAllowsMultipleSelection: YES];
	[thePanel setCanChooseFiles: YES];
	[thePanel setCanChooseDirectories: NO];
	[thePanel beginSheetForDirectory:nil file:nil
		types:[NSArray arrayWithObjects:@"tl", nil] modalForWindow:projectWindow modalDelegate:self
		didEndSelector:@selector(addLibraryOpenPanelDidEnd:returnCode:contextInfo:) contextInfo:thePanel];
}


-(IBAction)	addIncludeFolder: (id) sender
{
	NSOpenPanel*		thePanel = [[NSOpenPanel alloc] init];
	[thePanel setAllowsMultipleSelection: YES];
	[thePanel setCanChooseFiles: NO];
	[thePanel setCanChooseDirectories: YES];
	[thePanel beginSheetForDirectory:nil file:nil
		types:nil modalForWindow:projectWindow modalDelegate:self
		didEndSelector:@selector(addIncludeFolderOpenPanelDidEnd:returnCode:contextInfo:) contextInfo:thePanel];
}


-(void)	addSourceFileOpenPanelDidEnd: (NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	if( returnCode == NSOKButton )
		[self addFiles: [sheet filenames] toGroup: sourceFiles];
	[((id)contextInfo) release];
}

-(void)	addLibraryOpenPanelDidEnd: (NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	if( returnCode == NSOKButton )
		[self addFiles: [sheet filenames] toGroup: libraries];
	[((id)contextInfo) release];
}

-(void)	addIncludeFolderOpenPanelDidEnd: (NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	if( returnCode == NSOKButton )
    {
		[self addFiles: [sheet filenames] toGroup: headerPaths];
        [self showSettingsPage: SETTINGS_PAGE_HEADERS];
    }
	[((id)contextInfo) release];
}


-(void)	addFiles: (NSArray*)fnames toGroup: (NSMutableArray*)group
{
	NSEnumerator*		vItty = [fnames objectEnumerator];
	NSString*			vCurrPath;
	
	while( vCurrPath = [vItty nextObject] )
	{
		[group addObject:[NSMutableString stringWithString: vCurrPath]];
	}
	
    if( group == headerPaths )
        [includesListView reloadData];
    else
    {
        [listView reloadData];
        [listView expandItem: group];
    }
	[self projectChanged: nil];
}


-(void)		addSourceFileAtPath: (NSString*)pt
{
	NSMutableString*		thePath = [NSMutableString stringWithString: pt];
	NSString*				projPath = [[[self fileName] stringByDeletingLastPathComponent] stringByAppendingString: @"/"];
	
	// If we can, express this path relative to folder containing project:
	if( projPath )
	{
		NSRange rootPath = [thePath rangeOfString: projPath];
		if( rootPath.location == 0 )
			[thePath deleteCharactersInRange: rootPath];
	}
	
	[sourceFiles addObject: thePath];
	
	[listView reloadData];
	[listView expandItem: sourceFiles];
	[self projectChanged: nil];
} 


-(IBAction)	addPreprocessorConstant: (id) sender
{
	[constants addObject:[NSMutableString stringWithString: NSLocalizedString(@"CONSTANT=value",@"")]];	
	[constantListView reloadData];
    [self showSettingsPage: SETTINGS_PAGE_CONSTANTS];
	[self projectChanged: nil];
}


-(IBAction)	extractGameText: (id) sender
{
	NSSavePanel*		thePanel = [[NSSavePanel alloc] init];
	[thePanel beginSheetForDirectory:nil file: NSLocalizedString(@"GameText.txt",@"") modalForWindow:projectWindow modalDelegate:self
		didEndSelector:@selector(extractTextSavePanelDidEnd:returnCode:contextInfo:) contextInfo:thePanel];
}


-(void)	extractTextSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	if( returnCode == NSOKButton )
	{
		NSArray* params = [NSArray arrayWithObjects:@"-Os",[sheet filename],nil];
		[self runTadsCompiler: params];
	}
	[((id)contextInfo) release];
}


-(void)	tadsPrepareParsing: (NSTadsOptFileHelper*)sender
{
	[statusText setStringValue: NSLocalizedString(@"Parsing makefile...",@"")];

	// Make sure any old data is overwritten, in case this was a "revert":
	[topCommentStore deleteCharactersInRange:NSMakeRange(0,[topCommentStore length])];
	[outputFileStore deleteCharactersInRange:NSMakeRange(0,[outputFileStore length])];
	[sourcesCommentStore deleteCharactersInRange:NSMakeRange(0,[sourcesCommentStore length])];
	[otherConfigStore deleteCharactersInRange:NSMakeRange(0,[otherConfigStore length])];
	[otherOptionsStore deleteCharactersInRange:NSMakeRange(0,[otherOptionsStore length])];
	
	[sourceFiles removeAllObjects];
	[headerPaths removeAllObjects];
	[libraries removeAllObjects];
	[constants removeAllObjects];
	
	preInitStore = 1;
	debugSymbolsStore = NO;
	rebuildUnchangedStore = NO;
	relinkUnchangedStore = NO;
	warningsModeStore = 2;
	quietModeStore = NO;
	verboseErrorsStore = NO;
	
	// Progress bar can't be seen unless it's a revert:
	[progressBar setMaxValue:[sender progressMax]];
}


-(void)	tadsProcessCommentLine: (NSString*)theline
{
	[progressBar setDoubleValue: ([progressBar doubleValue] +1)];

	if( !gotSomething || !hadDoubleComment )
	{
		if( [theline hasPrefix: @"##sources"] )
		{
			gotSomething = false;
			hadDoubleComment = true;
		}
		
		if( hadDoubleComment )
		{
			if( [sourcesCommentStore length] > 0 )
				[sourcesCommentStore appendString: @"\n"];
			[sourcesCommentStore appendString: theline];
		}
		else
		{
			if( [topCommentStore length] > 0 )
				[topCommentStore appendString: @"\n"];
			[topCommentStore appendString: theline];
		}
		[statusText setStringValue: NSLocalizedString(@"Processing Comment...",@"")];
	}
}


-(void)	tadsProcessNonCommentLine: (NSString*)theline
{
	NSMutableString*		str;
	
	[progressBar setDoubleValue: ([progressBar doubleValue] +1)];

	if( ![theline hasPrefix:@"-"] )
	{
		if( !gotSomething )
			[self tadsProcessCommentLine: theline];
		[statusText setStringValue: NSLocalizedString(@"Preserving Unknown line among options...",@"")];
	}
	else
	{
		gotSomething = true;
		if( [theline hasPrefix:@"-I"] )
		{
			NSMutableString*	ipath = [[theline substringFromIndex: 2] mutableCopy];
			StripExcessSpacesFromNSString(ipath);
			UnstutterT3mNSString(ipath);
			[headerPaths addObject: ipath];
		}
		else if( [theline hasPrefix:@"-o"] )
		{
			[outputFileStore setString: [theline substringFromIndex: 2]];
			StripExcessSpacesFromNSString(outputFileStore);
			UnstutterT3mNSString(outputFileStore);
		}
		else if( [theline hasPrefix:@"-D"] )
		{
			str = [theline mutableCopy];
			[str deleteCharactersInRange: NSMakeRange(0,2)];
			StripExcessSpacesFromNSString(str);
			UnstutterT3mNSString(str);
			[constants addObject: str];
		}
		else if( [theline hasPrefix:@"-lib"] )
		{
			str = [theline mutableCopy];
			[str deleteCharactersInRange: NSMakeRange(0,4)];
			StripExcessSpacesFromNSString(str);
			UnstutterT3mNSString(str);
			[libraries addObject: str];
		}
		else if( [theline hasPrefix:@"-source"] )
		{
			str = [theline mutableCopy];
			[str deleteCharactersInRange: NSMakeRange(0,7)];
			StripExcessSpacesFromNSString(str);
			UnstutterT3mNSString(str);
			[sourceFiles addObject: str];
		}
		else if( [theline hasPrefix:@"-d"] )
			debugSymbolsStore = YES;
		else if( [theline hasPrefix:@"-pre"] )
			preInitStore = 2;
		else if( [theline hasPrefix:@"-nopre"] )
			preInitStore = 3;
		else if( [theline hasPrefix:@"-q"] )
			quietModeStore = YES;
		else if( [theline hasPrefix:@"-v"] )
			verboseErrorsStore = YES;
		else if( [theline hasPrefix:@"-w0"] )
			warningsModeStore = 1;
		else if( [theline hasPrefix:@"-w1"] )
			warningsModeStore = 2;
		else if( [theline hasPrefix:@"-w2"] )
			warningsModeStore = 3;
		else if( [theline hasPrefix:@"-a"] )
			rebuildUnchangedStore = YES;
		else if( [theline hasPrefix:@"-al"] )
			relinkUnchangedStore = YES;
		else if( [theline hasPrefix:@"-nodef"] )
			noDefaultFilesStore = YES;
		else
		{
			[otherOptionsStore appendString: @"\n"];
			[otherOptionsStore appendString: theline];
		}
		
		[statusText setStringValue: NSLocalizedString(@"Processing Option...",@"")];
	}
}


-(void) tadsProcessConfigLine: (NSString*)theline withID: (NSString*)configID newSection: (BOOL)newsection
{
	[progressBar setDoubleValue: ([progressBar doubleValue] +1)];

	gotSomething = YES;
	if( newsection )
		ourConfig = [configID isEqual: @"lebend"];
	if( ourConfig )
	{
		if( [theline hasPrefix: @"project_pos"] )
		{
			float		x, y;
			int			result;
			
			result = sscanf( [theline cString], "project_pos %f %f", &x, &y );
			if( result != 0 && result != EOF )
			{
				// FIX ME! Position project window.
				NSLog( @"Option: project_pos %f %f", x, y );
			}
		}
		else if( [theline hasPrefix: @"settings_pos"] )
		{
			float		x, y;
			int			result;
			
			result = sscanf( [theline cString], "settings_pos %f %f", &x, &y );
			if( result != 0 && result != EOF )
			{
				NSLog( @"Option: settings_pos %f %f", x, y );
			}
		}
		else if( [theline hasPrefix: @"log_bounds"] )
		{
			float		l, t, w, h;
			int			result;
			
			result = sscanf( [theline cString], "log_bounds %f %f %f %f", &l, &t, &w, &h );
			if( result != 0 && result != EOF )
			{
				NSLog( @"Option: log_bounds %f %f %f %f", l, t, w, h );
			}
		}
	}
	else
	{
		//if( newsection )
		//	[otherConfigStore appendString: [NSString stringWithFormat:@"[config:%@]\n", configID]];
		[otherConfigStore appendString: @"\n"];
		[otherConfigStore appendString: theline];
	}
	[statusText setStringValue: NSLocalizedString(@"Processing Config Line...",@"")];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return( [item isKindOfClass: [NSMutableArray class]] );
}


-(int)	outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if( [item isKindOfClass: [NSMutableArray class]] )
		return [item count];
	else if( item == nil )
		return 2;
	else
		return 0;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
{
	NSMutableArray*		rootItems[2] = { sourceFiles, libraries };
	
	if( item == nil )
		return rootItems[index];
	else if( [item isKindOfClass: [NSMutableArray class]] )
		return [item objectAtIndex: index];
	else
		return nil;
}


-(id)	outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	int					x;
	NSMutableArray*		rootItems[2] = { sourceFiles, libraries };
	NSString*			rootItemNames[2] = { @"Sources", @"Libs" };
	
	if( [item isKindOfClass: [NSMutableArray class]] )
	{
		if( [[tableColumn identifier] isEqual:@"name" ] )
		{
			for( x = 0; x < 4; x++ )
			{
				if( rootItems[x] == item )
					return NSLocalizedString(rootItemNames[x],@"");
			}
		}
		else if( [[tableColumn identifier] isEqual:@"icon" ] )
		{
			NSImage*		img = nil;
			
			img = [NSImage imageNamed: @"Folder"];
			img = [[img copy] autorelease];
			[img setSize: NSMakeSize(16,16)];
			
			return img;
		}
		
		return nil;
	}
	else
	{
		if( [[tableColumn identifier] isEqual:@"name"] )
		{
			return item;
		}
		else if( [[tableColumn identifier] isEqual:@"icon"] )
		{
			NSString*   fullPath = [self filePathForPartialPath: item];
			NSImage*	img = nil;
			
			if( fullPath )
				img = [[NSWorkspace sharedWorkspace] iconForFile: fullPath];
            else if( [[item pathExtension] isEqualToString: @"tl"] )
                img = [NSImage imageNamed: @"Suitcase"];
			else
				img = [NSImage imageNamed: @"BrokenDocIcon"];
			
			img = [[img copy] autorelease];
			[img setScalesWhenResized: YES];
			[img setSize: NSMakeSize(16,16)];
			
			return img;
		}
		else
			return nil;
	}
}


-(void)	outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if( [item isKindOfClass: [NSMutableArray class]] )	// Can't rename categories.
		NSBeep();
	else
	{
		if( [[tableColumn identifier] isEqual:@"name"] )
			[item setString: object];
		[self projectChanged: nil];
	}
}


-(void)	doubleClickOutlineView:(id)sender
{
	id		item = [listView itemAtRow: [listView clickedRow]];
	
	if( ![item isKindOfClass: [NSMutableArray class]] )
	{
		[self openWindowForFile:item];
	}
}


- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    if( tableView == constantListView )
        return [constants count];
    else if( tableView == includesListView )
        return [headerPaths count];
    else
        return 0;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if( tableView == constantListView )
        return [constants objectAtIndex: row];
    else if( tableView == includesListView )
        return [headerPaths objectAtIndex: row];
    else
        return nil;

}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if( tableView == constantListView )
    {
        [[constants objectAtIndex: row] setString: object];
        [self projectChanged: nil];
    }
    else if( tableView == includesListView )
    {
        [[headerPaths objectAtIndex: row] setString: object];
        [self projectChanged: nil];
    }
}



-(void) errorsWindow: (UKErrorsWindow*)errWin itemDoubleClicked: (ErrorListEntry*)item
{
	UKSyntaxColoredTextDocument*	fileWin = [self openWindowForFile: [item file]];
	[fileWin goToLine: [item line]];
}


// Turn a (possibly partial) search path as specified in the makefile into a full path to an existing file:
-(NSString*)	filePathForPartialPath: (NSString*)filePath
{
	NSEnumerator*   enny = [[self possiblePathsForFile: filePath] objectEnumerator];
    NSString*       currPath;
    
    while( (currPath = [enny nextObject]) )
    {
        if( [[NSFileManager defaultManager] fileExistsAtPath: currPath] )
            return currPath;
    }
    
    return nil;
}


-(NSArray*)     possiblePathsForFile: (NSString*)filePath
{
    NSMutableArray*     arr = [NSMutableArray array];
    NSString*           tempPath;
    NSString*           suffixedPathT = nil;
    NSString*           suffixedPathTL = nil;
    
    if( filePath == nil )
        return nil;
    
    // Check whether file has an extension, and if yes, which one:
	if( ![[filePath pathExtension] isEqualToString: @"t"]
        && ![[filePath pathExtension] isEqualToString: @"tl"]
        && ![[filePath pathExtension] isEqualToString: @"h"] )
    {
        suffixedPathT = [filePath stringByAppendingString: @".t"];
        [arr addObject: suffixedPathT];
        suffixedPathTL = [filePath stringByAppendingString: @".tl"];
        [arr addObject: suffixedPathTL];
    }
    else
    {
        if( [[filePath pathExtension] isEqualToString: @"t"]
            || [[filePath pathExtension] isEqualToString: @"h"] )
            suffixedPathT = filePath;
        else
            suffixedPathTL = filePath;
    }
    
    // Absolute path? No alternatives possible except suffixes:
    if( [suffixedPathT characterAtIndex: 0] == '/' )
    {
        if( suffixedPathT )
            [arr addObject: suffixedPathT];
        if( suffixedPathTL )
            [arr addObject: suffixedPathTL];

        return arr;
    }
    
    // Relative to this document?
	if( [self fileName] != nil )
    {
        if( suffixedPathT )
        {
            tempPath = [[[self fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent: suffixedPathT];
            [arr addObject: tempPath];
        }
        if( suffixedPathTL )
		{
            tempPath = [[[self fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent: suffixedPathTL];
            [arr addObject: tempPath];
        }
    }
    
    // In t3include/t3library?
    if( suffixedPathT )
    {
        tempPath = [[NSBundle mainBundle] pathForResource:@"lib" ofType:@""];
        tempPath = [tempPath stringByAppendingPathComponent: suffixedPathT];
        if( tempPath )
			[arr addObject: tempPath];
        tempPath = [[NSBundle mainBundle] pathForResource:@"t3library" ofType:@""];
        tempPath = [tempPath stringByAppendingPathComponent: suffixedPathT];
        if( tempPath )
			[arr addObject: tempPath];
    }
    if( suffixedPathTL )
    {
        tempPath = [[NSBundle mainBundle] pathForResource:@"t3library" ofType:@""];
        tempPath = [tempPath stringByAppendingPathComponent: suffixedPathTL];
        if( tempPath )
			[arr addObject: tempPath];
    }
    
    return arr;
}


-(id)	openWindowForFile: (NSString*)filePath
{
	if( filePath == nil )
		return nil;
	
	NSString*		realPath = [self filePathForPartialPath: filePath];
	
	if( !realPath )
		NSBeginAlertSheet( NSLocalizedString(@"No such file.", @""), NSLocalizedString(@"OK",@""), nil, nil, projectWindow, nil, 0, 0, nil, NSLocalizedString(@"The file '%@' does not exist.", @""), filePath );
	
    // The following should probably be replaced with a document class that handles .tl files:
    if( [[realPath pathExtension] isEqualToString: @"tl"] )
    {
        [[NSWorkspace sharedWorkspace] selectFile: realPath inFileViewerRootedAtPath: @""];
        return nil;
    }
    else
        return [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile: realPath display:YES];
}


@end
