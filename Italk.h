// Italk.h

#import <Cocoa/Cocoa.h>

@interface Italk : NSObject
{
    NSFileHandle    *sockHandle;
    IBOutlet id     theController;
    NSMutableData   *remainData;
    bool            m_isConnected;
    bool            m_isLoggedIn;
};

- (void)dealloc;
- (void)connect: (NSString *)serverName port:(int)port;
- (void)disconnect;
- (void)receiveMessage:(NSNotification *)notification;
- (void)sendMessage:(NSString *)message;
- (void)sendLine:(NSString *)message;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
- (bool)scanPromptForHandle:(NSString *)message;
@end
