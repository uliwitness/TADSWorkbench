//
//  UKErrorsWindow.m
//  CocoaTADS
//
//  Created by Uli Kusterer on 13.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "UKErrorsWindow.h"
#import "ErrorListEntry.h"


@implementation UKErrorsWindow

-(id)	init
{
    self = [super init];
    if( self )
	{
		errorListStore = [[NSMutableArray alloc] initWithObjects: [[[ErrorListEntry alloc] initWithMessage: NSLocalizedString(@"Ready.",@"")] autorelease], nil];
	}
	
    return self;
}


-(void)	dealloc
{
	[errorListStore release];
	errorListStore = nil;
	
	[super dealloc];
}


-(void) awakeFromNib
{
    [errorList setDoubleAction: @selector(doubleClickErrorList:)];
}


-(int)	numberOfRowsInTableView:(NSTableView *)tableView
{
	return [errorListStore count];
}


-(id)	tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if( !errorListStore )
		return nil;
	return [[errorListStore objectAtIndex: row] valueForKey: [tableColumn identifier]];
}


-(void) addObject: (id)errorListEntry
{
    BOOL        showIt = NO;
    
    [errorListStore addObject: errorListEntry];
    
    switch( [errorListEntry messageType] )
    {
        case ERROR_TYPE_ERROR:
            errorCount++;
            showIt = YES;
            break;
            
        case ERROR_TYPE_WARNING:
            warningCount++;
            showIt = YES;
            break;
            
        case ERROR_TYPE_NOTE:
            noteCount++;
            break;
    }
    
    [self updateGUI];
    
    if( showIt )
    {
        if( ![errorWindow isVisible] )
        {
            [errorWindow makeKeyAndOrderFront:self];
            if( [errorListEntry messageType] == ERROR_TYPE_ERROR )
                NSBeep();
        }
    }
}


-(void) removeObject: (id)errorListEntry
{
    switch( [(ErrorListEntry*)errorListEntry messageType] )
    {
        case ERROR_TYPE_ERROR:
            errorCount--;
            break;
            
        case ERROR_TYPE_WARNING:
            warningCount--;
            break;
            
        case ERROR_TYPE_NOTE:
            noteCount--;
            break;
    }
    
    [errorListStore removeObject: errorListEntry];
    [self updateGUI];
}


-(void) removeAllObjects
{
    noteCount = warningCount = errorCount = 0;
    [errorListStore removeAllObjects];
    [self updateGUI];
}


-(void) updateGUI
{
    [errCountField setStringValue: [NSString stringWithFormat: @"%d", errorCount]];
    [warnCountField setStringValue: [NSString stringWithFormat: @"%d", warningCount]];
    [noteCountField setStringValue: [NSString stringWithFormat: @"%d", noteCount]];
    [errorList reloadData];
}


-(IBAction)	showErrorWindow: (id) sender
{
	[errorWindow makeKeyAndOrderFront:self];
}


-(void)	doubleClickErrorList:(id)sender
{
    ErrorListEntry*		item = [errorListStore objectAtIndex: [errorList clickedRow]];
    
    [delegate errorsWindow: self itemDoubleClicked: item];
}


-(void) setDelegate: (NSObject*)del
{
    delegate = del;
}


-(NSObject*)    delegate
{
    return delegate;
}


// -----------------------------------------------------------------------------
//	Forwarding unknown methods to the delegate:
// -----------------------------------------------------------------------------

-(NSMethodSignature*)	methodSignatureForSelector: (SEL)itemAction
{
    BOOL                does = [super respondsToSelector: itemAction];
	NSMethodSignature*	sig = does? [super methodSignatureForSelector: itemAction] : nil;

	if( sig )
		return sig;
	
    if( [delegate respondsToSelector: itemAction] )
        return [delegate methodSignatureForSelector: itemAction];
    else
        return nil;
}


-(void)	forwardInvocation: (NSInvocation*)invocation
{
    SEL itemAction = [invocation selector];

    if( [delegate respondsToSelector: itemAction] )
	{
		[invocation setTarget: delegate];
		[invocation invoke];
	}
    else
        [self doesNotRecognizeSelector: itemAction];
}


-(BOOL)	respondsToSelector: (SEL)itemAction
{
	BOOL	does = [super respondsToSelector: itemAction];
	
	return( does || [delegate respondsToSelector: itemAction] );
}



@end
