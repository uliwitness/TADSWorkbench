//
//  ProjectDocument.h
//  foo
//
//  Created by Uli Kusterer on Mon May 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSTadsOptFileHelper.h"


@class UKErrorsWindow;
@class ErrorListEntry;


#define SETTINGS_PAGE_COMPILER      0
#define SETTINGS_PAGE_CONSTANTS     1
#define SETTINGS_PAGE_HEADERS       1
#define SETTINGS_PAGE_COMMENTS      2
#define SETTINGS_PAGE_OTHER_OPTS    3
#define SETTINGS_PAGE_OTHER_CONF    3



@interface ProjectDocument : NSDocument
{
	// Outlets:
	IBOutlet NSWindow*					projectWindow;		// Our project window.
	IBOutlet NSOutlineView*				listView;			// The list view our project's contents are displayed in.
	IBOutlet NSProgressIndicator*		progressBar;		// The progress bar we update when the compiler is chugging away.
	IBOutlet NSTextField*				statusText;			// A status text field used to tell the user what's happening for semi-long operations.

	IBOutlet NSWindow*					settingsPanel;		// Our "Project Settings" window.
	IBOutlet NSTextView*				topComment;			// Comment at top of file.
	IBOutlet NSTextView*				sourcesComment;		// Comment before we reach list of source files.
	IBOutlet NSTextView*				otherConfig;		// TADS config data that we're not interested in.
	IBOutlet NSTextView*				otherOptions;		// TADS options that we're not interested in.
	IBOutlet NSMatrix*					preInit;			// Pre-init only non-debug builds, always pre-init, or never pre-init?
	IBOutlet NSButton*					debugSymbols;		// Add debug symbols?
	IBOutlet NSButton*					rebuildUnchanged;	// Always rebuild unchanged files?
	IBOutlet NSButton*					relinkUnchanged;	// Always relink unchanged files?
	IBOutlet NSMatrix*					warningsMode;		// Suppress/Standard/Pedantic warnings?
	IBOutlet NSButton*					quietMode;			// Keep progress messages out of the log?
	IBOutlet NSButton*					verboseErrors;		// Display verbose error messages?
	IBOutlet NSButton*					noDefaultFiles;		// Automatically compile _main.t etc. into the game?
	IBOutlet NSTextField*				outputFile;			// Name of output file.
	IBOutlet NSTextField*				projectName;		// Name of project displayed on settings panel.
    IBOutlet NSTableView*               constantListView;   // List view for constants in "Settings" window.
    IBOutlet NSTableView*               includesListView;   // List view for include folders in "Settings" window.
    IBOutlet NSTabView*                 settingsTabView;    // Tab view for different panes of "Settings" window.
	
	UKErrorsWindow*                     errorsWindow;       // Object that manages "errors and warnings" window.
	
	// Stuff used during parsing t3m files:
	BOOL								gotSomething;
	BOOL								hadDoubleComment;
	BOOL								ourConfig;
	
	// File's data goes here:
	NSMutableString*					topCommentStore;		// Comment at top of file.
	NSMutableString*					sourcesCommentStore;	// Comment before we reach list of source files.
	NSMutableString*					otherConfigStore;		// Config lines that we're not interested in.
	NSMutableString*					otherOptionsStore;		// TADS options that we're not interested in.
	NSMutableArray*						sourceFiles;			// List of source files to compile.
	NSMutableArray*						headerPaths;			// List of include folder paths.
	NSMutableArray*						libraries;				// List of library files.
	NSMutableArray*						constants;				// List of constants to define.
	NSMutableString*					outputFileStore;		// Name of file to generate.
	int									preInitStore;
	BOOL								debugSymbolsStore;
	BOOL								rebuildUnchangedStore;
	BOOL								relinkUnchangedStore;
	int									warningsModeStore;
	BOOL								quietModeStore;
	BOOL								verboseErrorsStore;
	BOOL								noDefaultFilesStore;
	
	// Used for executing t3make:
	NSTask*								tadsc;				// nil, or an NSTask pointing to our compiler that's currently busy.
	NSFileHandle*						tadscStream;		// Stream where TADS's stdout goes.
	NSPipe*								tadscPipe;			// Pipe that forwards TADS's stdout to tadscStream.
	NSMutableString*					tadscOutBuffer;		// Buffer where we collect output until we hit a newline.
	BOOL								runAfterBuilding;	// Start t3 file in TADS 3 runtime after it's been built?
	BOOL								debugAfterBuilding;	// Launch t3 file in debugger after it's been built.
}

+(ProjectDocument*)		currentProject;


// Load from file/write back:
-(BOOL)	readFromFile:(NSString *)fileName ofType:(NSString *)type;
-(BOOL)	writeToFile: (NSString*)fileName ofType: (NSString*)type;

-(void)	updateUI;

// Menu commands:
-(IBAction)	buildGame: (id)sender;
-(IBAction)	buildAndRunGame: (id)sender;
-(IBAction)	buildAndDebugGame: (id)sender;
-(IBAction)	cleanGame: (id)sender;
-(IBAction)	debugGame: (id)sender;
-(IBAction)	runGame: (id)sender;
-(IBAction)	extractGameText: (id)sender;
-(IBAction)	delete: (id)sender;

-(void)		addSourceFileAtPath: (NSString*)pt;

// Menu actions:
-(IBAction)	addSourceFile: (id)sender;
-(IBAction)	addLibrary: (id)sender;
-(IBAction)	addIncludeFolder: (id)sender;
-(IBAction)	addPreprocessorConstant: (id)sender;

// Used by addSourceFile, extractGameText & co:
-(void)	addSourceFileOpenPanelDidEnd: (NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo;
-(void)	addLibraryOpenPanelDidEnd: (NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo;
-(void)	addIncludeFolderOpenPanelDidEnd: (NSOpenPanel*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo;
-(void)	addFiles: (NSArray*)fnames toGroup: (NSMutableArray*)group;
-(void)	extractTextSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

// Used by buildGame & co:
-(void)	runTadsCompiler: (NSArray*) params;
-(void)	compilerFinished: (NSNotification *)aNotification;
-(void) compilerOutputFrom: (NSFileHandle*)hd finished: (BOOL)fini;
-(void)	runScriptOnGameFile: (NSString*)fname withTool: (NSString*)toolName;

-(IBAction)	showSettings: (id) sender;
-(IBAction)	showSettingsPage: (int)settingsPage;
-(IBAction)	showErrorWindow: (id) sender;
-(IBAction)	projectChanged: (id)sender;
-(void)	textDidChange:(NSNotification *)notification;

// Called by NSTadsOptFileHelper when we're persing t3m files:
-(void)	tadsPrepareParsing: (NSTadsOptFileHelper*)sender;
-(void)	tadsProcessCommentLine: (NSString*)theline;
-(void)	tadsProcessNonCommentLine: (NSString*)theline;
-(void) tadsProcessConfigLine: (NSString*)theline withID: (NSString*)configID newSection: (BOOL)newsection;

// Error list delegate:
-(void) errorsWindow: (UKErrorsWindow*)errWin itemDoubleClicked: (ErrorListEntry*)item;

// Project's outline view:
-(BOOL)	outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
-(int)	outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
-(id)	outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
-(id)	outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
-(void)	outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
-(void)	doubleClickOutlineView:(id)sender;

-(NSTableView*) selectedListView;

-(id)	openWindowForFile: (NSString*)filePath;	// Returns an NSDocument, I guess.

-(NSString*)	filePathForPartialPath: (NSString*)filePath;
-(NSArray*)     possiblePathsForFile: (NSString*)filePath;      // Used by filePathForPartialPath:.


@end
