//
//  ErrorListEntry.h
//  CocoaTADS
//
//  Created by Uli Kusterer on Fri May 30 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
	ErrorListEntry
	
	This class encapsulates the various messages that can show up in our
	"build errors and warnings" window. It takes care of parsing TADS 3 output
	selects a nice icon and can be displayed in an NSTableView by using
	[entry valueForKey: [column identifier]] on it.
*/


// Message types for ErrorListEntry's "type" field:
#define	ERROR_TYPE_ERROR		1	// Real error that stops the build.
#define	ERROR_TYPE_WARNING		2	// Simply a warning that doesn't stop the build.
#define ERROR_TYPE_NOTE			3	// No error, a note.
#define ERROR_TYPE_NONE			0	// No error, a status message or so.


@interface ErrorListEntry : NSObject
{
	NSString*		message;		// Error/warning message text.
	NSString*		file;			// Path of the file it occurred in.
	int				line;			// Line the error happened on.
	int				type;			// What kind is this? Error? Warning?
}

-(id)	initWithString: (NSString*)str;		// Parses TADS 3 output.
-(id)	initWithMessage: (NSString*)msg;	// Creates an ERROR_TYPE_NONE message with no icon and msg un-parsed as the message displayed.

// Accessors so you can do key-value-coding with this object:
-(NSString*)	message;
-(NSImage*)		icon;
-(NSString*)	file;
-(NSString*)	shortFileName;
-(NSNumber*)	lineNumber;		// KVC version of "line".

// Other accessors:
-(int)			line;
-(int)          messageType;    // type.

@end
