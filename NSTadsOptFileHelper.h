/* ================================================================================
	PROJECT:	UlisTADS
	FILE:		NSTadsOptFileHelper.h
	PURPOSE:	Cocoa wrapper around Mike Roberts' C++ code for parsing
				TADS 3 Makefiles (.t3m).
   ============================================================================= */

/* --------------------------------------------------------------------------------
	Headers:
   ----------------------------------------------------------------------------- */

#import <Cocoa/Cocoa.h>


/* --------------------------------------------------------------------------------
	NSTadsOptFileHelper:
		Pass a delegate to this class that will be sent the messages from the
		NSTadsOptFileHelperDelegate category. Then you can call processFile to
		have a TADS 3 makefile parsed.
		
		This is neat because you can pretend C++ didn't exist and still benefit
		from Mike's Mad Programmer Skillz :-)
   ----------------------------------------------------------------------------- */

@interface NSTadsOptFileHelper : NSObject
{
	void*		helper;			// C++ helper object, private.
	int			progressMax;	// Maximum value for progress bars while processFile is executing.
}


-(id)	initWithDelegate: (id)delegate;
-(void)	dealloc;

-(BOOL)	processFile: (NSString*)pathname;	// Call this to actually do some work.

-(int)	progressMax;
@end



/* --------------------------------------------------------------------------------
	NSTadsOptFileHelperDelegate:
		The following methods are sent to any object that is passed as a
		delegate to NSTadsOptFileHelper's initWithDelegate: method.
   ----------------------------------------------------------------------------- */

@interface NSObject (NSTadsOptFileHelperDelegate)

-(void)	tadsPrepareParsing: (NSTadsOptFileHelper*)sender;
-(void)	tadsProcessCommentLine: (NSString*)theline;
-(void)	tadsProcessNonCommentLine: (NSString*)theline;

// "config" means app-specific and ignored by t3make. Workbench for Windows remembers
// window positions in its own section with a custom configID, we do likewise.
// if newSection is YES, a new section has started.
-(void) tadsProcessConfigLine: (NSString*)theline withID: (NSString*)configID newSection: (BOOL)newsection;

@end


#ifdef __cplusplus
extern "C" {
#endif

/* --------------------------------------------------------------------------------
	Utility functions:
		These are some utility functions you can use when further parsing
		input from one of the tadsProcessXXXLine: methods in your delegate.
   ----------------------------------------------------------------------------- */

void		StripExcessSpacesFromNSString( NSMutableString* str );		// Wrapper around stringByTrimmingCharactersInSet:.
void		EscapeNSStringForCommandline( NSMutableString* outstr );
void		EscapeCharInNSString( char pattern, NSMutableString* outstr ); // Used by EscapeNSStringForCommandline.

/* Work with "stuttered" strings, which are enclosed in quotes, and escape
	existing quotes by placing a second one in front of it.  */
NSString*	EscapeNSStringForT3m( NSString* inStr );				// NSString -> T3M
void		UnstutterT3mNSString( NSMutableString* outstr );		// T3M -> NSString

#ifdef __cplusplus
}
#endif









