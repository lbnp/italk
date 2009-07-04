// ItalkController.h

#import <Cocoa/Cocoa.h>
#import "Italk.h"

@interface ItalkController : NSObject
{
    // Italk object
    IBOutlet Italk  *italk;

    // UI Elements
    IBOutlet NSButton               *connectButton;
    IBOutlet NSProgressIndicator    *connectProgress;
    IBOutlet NSTextView             *logTextView;
    IBOutlet NSTextField            *serverNameField;
    
    // helper
    NSCharacterSet *urlCharSet;
    NSFont *font;
    NSDictionary *fontAttr;
}
- (void)dealloc;
- (IBAction)connect:(id)sender;
- (IBAction)textEntered:(id)sender;
- (void)addLogText:(NSString *)logText;
- (NSRange)findLink:(NSString *)aText range:(NSRange)aRange;
//- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)link atIndex:(unsigned)charIndex;
@end
