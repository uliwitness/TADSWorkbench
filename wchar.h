/*
 *  wchar.h
 *  CocoaTADS
 *
 *  Created by Uli Kusterer on Sun Nov 02 2003.
 *  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
 *
 */

/* *BSD does not have wcs functions. */
#if defined(FREEBSD_386) || defined(OPENBSD) || defined(DARWIN) || defined(NEXT)

#include <stdlib.h>

int wcslen(wchar_t *wc);

wchar_t *wcscpy(wchar_t *dst, const wchar_t *src);

#endif /* FREEBSD_386 || OPENBSD || DARWIN */
