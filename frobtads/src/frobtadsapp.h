/* The FrobTadsApplication class represents the main application object.
 * It provides an easy to use interface to the screen.  That way, code
 * that needs to do any I/O on the terminal won't have to use the
 * lower-level curses-routines or even FrobTadsWindow widgets.
 *
 * It also is responsible for starting the TADS2/3 VM.
 */
#ifndef FROBTADSAPPLICATION_H
#define FROBTADSAPPLICATION_H

#include "common.h"

#include <string.h>

#include "os.h"
extern "C" {
#include "osgen.h"
}

#include "tadswindow.h"


/* Global application pointer.
 */
extern class FrobTadsApplication* globalApp;

class FrobTadsApplication {
  public:
	// Signal handlers are such a pain in the ass...
	friend RETSIGTYPE winResizeHandler(int);

	// Instead of using a gazillion of constructor-arguments, we
	// group them inside this structure.
	struct FrobOptions {
		bool useColors;         // Enable colors?
		bool forceColors;       // Force colors?
		bool defColors;         // Use default colors for color pair 0?
		bool softScroll;        // Scroll softly?
		bool exitPause;         // Pause prior to exit?
		bool changeDir;         // Change to the game's directory?
		int textColor;          // Default text color.
		int bgColor;            // Default background color.
		int statTextColor;      // Default text color of statusline.
		int statBgColor;        // Default background color of statusline.
		unsigned scrollBufSize; // Scroll-back buffer size.
		int safetyLevel;        // File I/O safety level.
		char characterSet[40];  // Local character set name.
	};

	// Our options.  Once set, they remain constant during run-time.
	// We make them public so other code can use them too.  They're
	// const so there's no reason to hide them.
	const FrobOptions options;

  private:
	FrobTadsWindow *fGameWindow; // The window we use for I/O.

	// Tads never tries to display a string that is longer than the
	// window's width.  We use this knowledge to optimize output
	// somewhat.  Instead of allocating and deallocating memory each
	// time we print a string (memory allocation is slow), we use
	// this small buffer instead whose memory is allocated only once
	// when a game window is created.
	chtype* fDispBuf;

	// Are we using colors?
	bool fColorsEnabled;

	// We store the remaining input-timeout here in case a
	// window-resize occurs; the signal handler can then restore it.
	int fRemainingTimeout;

	/* Create and initialize a new game window.
	 */
	void
	fCreateGameWindow();

	/* Runs the T2VM.
	 */
	int
	fRunTads2( char* filename );

	/* Runs the T3VM.
	 */
	int
	fRunTads3( char* filename );

  public:
	FrobTadsApplication( const FrobOptions& opts );
	~FrobTadsApplication();

	/* Are colors enabled?
	 */
	bool
	colorsEnabled() const
	{ return this->fColorsEnabled; }

	/* Starts the VM and returns its exit code.  Which VM is started
	 * is given by the 'vm' argument: 0 for TADS2, non-0 for TADS3.
	 */
	int
	runTads( const char* filename, int vm );

	/* Moves the cursor to the specified position.
	 */
	void
	moveCursor( int line, int column )
	{ this->fGameWindow->moveCursor(line, column); }

	/* Prints a string at the specified position, using 'attrs' as
	 * atributes.
	 */
	void
	print( int line, int column, int attrs, const char* str )
	{
		int i;
		for (i = 0; str[i] != '\0'; ++i) this->fDispBuf[i] = str[i] | attrs;
		this->fDispBuf[i] = '\0';
		this->fGameWindow->printStr(line, column, this->fDispBuf);
	}

	/* Clears a portion of the screen.
	 */
	void
	clear( int top, int left, int bottom, int right, int attrs );

	/* Scroll the specified region of the screen 1 line up/down.
	 * 'attrs' holds the attributes of the generated empty lines.
	 */
	void
	scrollRegionUp( int top, int left, int bottom, int right, int attrs );

	void
	scrollRegionDown( int top, int left, int bottom, int right, int attrs );

	/* Reads a character from the keyboard and returns it.  If a
	 * function key has been pressed, then a curses KEY_* value is
	 * returned (have a look at your system's <curses.h> header for
	 * a list of KEY_ macros).
	 *
	 * If 'cursorVisible' is false, no cursor is shown while waiting
	 * for a key-press.
	 *
	 * If 'timeout' is > 0, then the routine will wait for a key
	 * only for 'timeout' milliseconds.  If a key has been pressed
	 * before the timeout expires it is returned as usual.  If the
	 * timeout expires and there's still no key, ERR is returned.
	 *
	 * Note that KEY_BACKSPACE and KEY_DL are handled correctly; you
	 * don't need to use the low-level curses routines erasechar()
	 * and killchar().  Just check for KEY_BACKSPACE and KEY_DL.
	 */
	int
	getRawChar( bool cursorVisible, int timeout );

	/* Pause for 'ms' milliseconds.
	 */
	void
	sleep( int ms )
	{ this->fGameWindow->flush(); napms(ms); }

	/* Change the current working directory, if possible.  Returns
	 * true on success, false on failure.
	 */
	bool
	changeDirectory( const char* dir );
};

#endif // FROBTADSAPPLICATION_H
