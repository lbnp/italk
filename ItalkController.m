// ItalkController.m

#import "ItalkController.h"

@implementation ItalkController

- (void)awakeFromNib
{
    NSMutableCharacterSet *workingSet;
    
    // uppercase + lowercase + decimal + 記号からなるNSCharacterSetを生成
    workingSet = [[NSCharacterSet lowercaseLetterCharacterSet] mutableCopy];
    [workingSet formUnionWithCharacterSet:[NSCharacterSet uppercaseLetterCharacterSet]];
    [workingSet addCharactersInString:@"?=%/:,.~&$#_+-^0123456789"];
    urlCharSet = [workingSet copy];
    [workingSet release];
    font = [NSFont fontWithName:@"Osaka-Mono" size:14.0];
    fontAttr = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil] retain];
}

- (void)dealloc
{
    [fontAttr release];
    [urlCharSet release];
    [super dealloc];
}

- (IBAction)connect:(id)sender
{
    [italk connect:[serverNameField stringValue] port:12345];
}

// 文字列の特定の範囲からHTTP URLを抽出する
- (NSRange)findLink:(NSString *)aText range:(NSRange)aRange
{
    NSRange httpRange;
    NSString *httpStr = @"http://";
    // 元の文字列からaRangeの範囲を切り出す
    NSString *text = [aText substringWithRange:aRange];
    
    // "http://"が含まれているか？
    httpRange = [text rangeOfString:httpStr];
    if (httpRange.location == NSNotFound) {
        return httpRange;
    }
        
    NSRange urlRange = {httpRange.location + [httpStr length], 0};

    // URL文字が続く範囲をスキャン
    int i;
    int len = [text length];
    for (i = urlRange.location; i < len; i++) {
		unichar c = [text characterAtIndex:i];
		if (![urlCharSet characterIsMember:c]) {
            break;
        }
        urlRange.length++;
    }
    
    if (urlRange.length == 0) {
        urlRange.location = NSNotFound;
        return urlRange;
    }
    
    urlRange.location = httpRange.location;
    urlRange.length += [httpStr length];
    return urlRange;
}

// logTextをログに追加
- (void)addLogText:(NSString *)logText
{
    if (logText == nil) {
        return;
    }
    
    NSMutableAttributedString *attributed = [[[NSMutableAttributedString alloc] initWithString:logText] autorelease];
    NSMutableDictionary *attr = [[[NSMutableDictionary alloc] initWithCapacity:10] autorelease];
    NSRange extent = {0, [logText length]};
    NSRange urlRange;
    [attributed setAttributes:fontAttr range:extent];
    urlRange = [self findLink:logText range:extent];
    // URL文字にNSLinkAttributeを追加
    while (urlRange.location != NSNotFound) {
        urlRange.location += extent.location;
        NSURL *url = [[[NSURL alloc] initWithString:[logText substringWithRange:urlRange]] autorelease];
        if (url != nil) {
            [attr setObject:url forKey:NSLinkAttributeName];
            [attributed addAttributes:attr range:urlRange];
        
            extent.location = urlRange.location + urlRange.length;
            extent.length = [logText length] - (urlRange.location + urlRange.length);
        }
        urlRange = [self findLink:logText range:extent];
    }
    
    [[logTextView textStorage] appendAttributedString:attributed];

    NSRange	endOfText;

    endOfText.location = [[logTextView string] length];
    endOfText.length = 0;
    [logTextView scrollRangeToVisible: endOfText];
}

- (IBAction)textEntered:(id)sender
{
    NSString *text = [[sender stringValue] stringByAppendingString:@"\n"];
    [italk sendMessage:text];
    [sender setStringValue:@""];
    [[sender window] performSelector:@selector(makeFirstResponder:)
								 withObject:sender
								 afterDelay:0.0];
}

@end
