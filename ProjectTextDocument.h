//
//  ProjectTextDocument.h
//  CocoaTADS
//
//  Created by Uli Kusterer on Fri Feb 13 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

#import "UKSyntaxColoredTextDocument.h"


@interface ProjectTextDocument : UKSyntaxColoredTextDocument

-(IBAction)		addToCurrentProject: (id)sender;
-(IBAction)     openQuickly: (id)sender;

@end
