// Italk.m
// ネットワーク接続管理、データのやりとりなど。

#import "Italk.h"

#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

@implementation Italk
- (void)awakeFromNib
{
    m_isConnected = false;
    m_isLoggedIn = false;
    remainData = [[NSMutableData alloc] initWithCapacity: 0];
    [NSApp setDelegate:self];
}

- (void)dealloc
{
    if (m_isConnected) {
        [self disconnect];
    }
    
    [remainData release];
    
    [super dealloc];
}

- (void)connect: (NSString *)serverName port:(int)port
{
    int sockfd;
	const char *serverStr = [serverName UTF8String];
	struct sockaddr_in sin;

    // 既に接続済みのときは切る
	if (m_isConnected) {
        [self disconnect];
    }
        
	if (!inet_aton(serverStr, &sin.sin_addr)) {
		struct hostent *hp;
		if (!(hp = gethostbyname(serverStr))) {
			printf("%s: unknown host\n", serverStr);
			return;
		}
		
		memset(&sin, 0, sizeof(struct sockaddr_in));
		memcpy(&sin.sin_addr.s_addr, hp->h_addr, hp->h_length);
		sin.sin_family = hp->h_addrtype;
	} else {
		sin.sin_family = AF_INET;
	}
	
	sin.sin_port = htons(port);
	
	if ((sockfd = socket(sin.sin_family, SOCK_STREAM, 0)) < 0) {
		printf("cannot create socket\n");
		return;
	}
	
	if (connect(sockfd, (struct sockaddr *)&sin, sizeof(sin)) < 0) {
		printf("cannot connect\n");
		close(sockfd);
		return;
	}
    
    sockHandle = [[NSFileHandle alloc] initWithFileDescriptor:sockfd];

    // socketへのNotificationを設定
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(receiveMessage:)
               name:NSFileHandleReadCompletionNotification
             object:sockHandle];
    
    // socketからbackgroundで読み込む
    [sockHandle readInBackgroundAndNotify];
    
    m_isConnected = true;
}

// 切断
- (void)disconnect
{
    // ログイン中ならば"/q"を送って抜ける
    if (m_isLoggedIn) {
        // send quit command
        NSString *quitCommand = @"/q\n";
        NSData *quitData = [quitCommand dataUsingEncoding:NSISO2022JPStringEncoding];
        [sockHandle writeData:quitData];
        m_isLoggedIn = false;
    }
    
    // remove myself from sockHandle's observers list
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // socketをクローズ & ハンドルを解放
    [sockHandle closeFile];
    [sockHandle release];
    m_isConnected = false;
}

// "What's your name?"が流れてきたか？
- (bool)scanPromptForHandle:(NSString *)message
{
    NSString *prompt = @"\n# What's your name?";
    
    if (message == nil) {
        return false;
    }
    
    NSRange range = [message rangeOfString:prompt];
    if (range.location != NSNotFound) {
        return true;
    } else {
        return false;
    }
}

// Notificationハンドラ
// このハンドラからの脱出時にはsocketに対して再度background readを設定する必要がある
- (void)receiveMessage:(NSNotification *)notification
{
    // notificationからデータを受け取る
    NSData *messageData = [[notification userInfo]
                    objectForKey:NSFileHandleNotificationDataItem];
    
    if ( [messageData length] == 0 ) {
        //[sockHandle readInBackgroundAndNotify];
        [self disconnect];
        return;
    }

    NSString *message = nil;

    NSData *toProcess;
    if ( [remainData length] > 0 ) {
        [remainData appendData: messageData];
        toProcess = remainData;
    } else {
        toProcess = messageData;
    }
    NSUInteger length = [toProcess length];
    char *lineStart = (char *)[toProcess bytes];
    char *lineEnd = lineStart;
    int i, processed;
    for ( i = 0, processed = 0; i < length; ++i, ++lineEnd ) {
        if ( *lineEnd == '\n' ) {
            message = [[[NSString alloc] initWithBytes:lineStart
                                                length:lineEnd - lineStart
                                              encoding:NSJapaneseEUCStringEncoding] autorelease];
            [theController addLogText:message];
            lineStart = lineEnd;
        }
        ++processed;
    }
    if ( lineEnd == lineStart + 1 ) {
        [remainData setLength:0];
    } else {
        NSData *unprocessed = [[NSData alloc] initWithBytes:[remainData bytes] + processed
                                                     length:length - processed];
        [remainData setData:unprocessed];
        [remainData appendBytes:lineStart
                         length:lineEnd - lineStart];
        [unprocessed release];
    }
    
#if 0
    // 流れてきたデータがEUCだと仮定してNSStringに変換
    //NSString *message = [[[NSString alloc] initWithData:messageData
    //                                          encoding:NSJapaneseEUCStringEncoding] autorelease];
    NSError *error = nil;
    NSString *message = [messageData stringByNKFWithOptions:@"" error:&error];
    if (error != nil)
    {
        NSAlert *theAlert = [NSAlert alertWithError:error];
        [theAlert runModal];
    }
//    printf("%s\n", [message UTF8String]);
    /*
     * XXX 変換が失敗したときには無条件でデータを捨てている。その分ログは欠ける。
     * 変換に失敗するのは、例えばマルチバイト文字の1バイト目で一回分の転送データが切れたときなど。
     */
    if (message != nil) {
        [theController addLogText:message];
    } else {

    }
#endif
    
    // ログインしていないときはプロンプトが流れてきてるかチェックする
    if (!m_isLoggedIn) {
        if ([self scanPromptForHandle:message]) {
            NSString *handle = [[NSUserDefaults standardUserDefaults] stringForKey:@"handleName"];
            [self sendLine:handle];
        }
        
        m_isLoggedIn = true;
    }
    
    [sockHandle readInBackgroundAndNotify];    
}

// NSStringを送信
- (void)sendMessage:(NSString *)message
{
    // 送信するデータをISO-2022-JPに変換（変換できない文字はあきらめる）
    NSData *messageData = [message dataUsingEncoding:NSISO2022JPStringEncoding
                                allowLossyConversion:YES];
    
    [sockHandle writeData:messageData];
}

// 行末に\nをつけてNSStringを送信
- (void)sendLine:(NSString *)message
{
    NSString *toSend = [message stringByAppendingString:@"\n"];
    
    [self sendMessage:toSend];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

// ユーザがアプリケーションを終了しようとしたときのハンドラ
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (!m_isConnected) {
        return YES;
    }
    
    NSAlert* alert = [[NSAlert alloc] init];
    alert.messageText = @"Confirmation";
    alert.informativeText = @"Really Quit?";
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    NSModalResponse result = [alert runModal];
    switch (result) {
        case NSAlertFirstButtonReturn:
            [self disconnect];
            return YES;
        case NSAlertSecondButtonReturn:
            return NO;
        default:
            return NO;
    }
}
@end
