//
//  NKFCocoa.h
//  NKFCocoa
//
//  Created by hippos on 08/12/29.
//  Copyright 2008 hippos-lab.com. All rights reserved.
//
/*!
 * @header NKFCocoa
 * @abstract nkf(network kanji filter) wrapper for Cocoa
 * @copyright hippos-lab.com
 * @version 2.0.8
 */
#import <Cocoa/Cocoa.h>

/*!
 * @enum NKFCocoaErrorDomainErrorCode NKFCocoaErrorDomain Error Code
 * @abstract NKFCocoaErrorDomainのcode
 * @discussion NKFCocoaErrorDomainのエラーコード。メソッド呼び出し時にnilを指定された場合はこれらの情報は返されません。
 * @constant NKFCocoaNKFError nkf内部エラー
 * @constant NKFCocoaRangeError データ範囲エラー
 * @constant NKFCocoaWriteToURLError ファイルの書き込みエラーが発生
 * @constant NKFCocoaStringWithContentsOfURL ファイルの読み込みエラーが発生
 */
enum NKFCocoaErrorDomainErrorCode
{
  NKFCocoaNKFError                = 1,
  NKFCocoaRangeError              = 3,
  NKFCocoaWriteToURLError         = 5,
  NKFCocoaStringWithContentsOfURL = 7
};

/*!
 * @const NKFCocoaErrorDomain NKFCocoaErrorDomain String
 */
NSString* NKFCocoaErrorDomain = @"com.hippos-lab.NKFCocoa.ErrorDomain";

/*!
 * @category NSData(NKFCocoa)
 * @abstract nkf(network kanji filter) wrapper for Cocoa
 * @discussion <p>NKFCocoaはnkfを通じてエンコーディングの判定・変換をおこないます。</p><p>Cocoaでエンコードを判定するメソッドはNSStringクラスの<ul><li>+ stringWithContentsOfFile:usedEncoding:error:</li><li>– initWithContentsOfFile:usedEncoding:error:</li>
 <li>+ stringWithContentsOfURL:usedEncoding:error:</li><li>– initWithContentsOfURL:usedEncoding:error:</li></ul><p>がありますがいずれも初期化メソッドであり少し使い勝手が悪いです。NKFCocoa.FrameworkではこれらのNSDataクラスを拡張し、nkfの機能を提供することによりエンコーディングの判定を助けます。提供する機能はnkf-2.0.8相当ですが、すべての機能を使用できるわけではありません。例えば、--version/--in-place/--orverwriteなどのオプションは指定できません。</p>
 <p>また、nkfのデフォルトエンコーディングは　ISO-2022-JPですが、NKFCocoa.FrameworkのデフォルトエンコーディングUTF-8です。</p>
 */
@interface NSData (NKFCocoa)

/*!
 * @method guessByNKFWithURL:error
 * @param url エンコード判定対象となるファイルのＵＲＬ
 * @param error NSErrorへのポインタ
 * @result 判定したエンコードを示すNSStringEncoding値。判定不能またはエラーの場合は０。
 */
+ (NSStringEncoding)guessByNKFWithURL:(NSURL *)url error:(NSError**)error;
/*!
 * @method guessByNKF
 * @param error NSErrorへのポインタ
 * @result 判定したエンコードを示すNSStringEncoding値。判定不能またはエラーの場合は０。
 */
- (NSStringEncoding)guessByNKF:(NSError**)error;
/*!
 * @method guessByNKFWithRange:error
 * @param range 判定対象となる範囲を示すNSRange
 * @param error NSErrorへのポインタ
 * @result 判定したエンコードを示すNSStringEncoding値。判定不能またはエラーの場合は０。
 */
- (NSStringEncoding)guessByNKFWithRange:(NSRange)range error:(NSError**)error;
/*!
 * @method stringByNKFWithOptions:error
 * @param options nkfのオプションパラメータ
 * @param error NSErrorへのポインタ
 * @discussion dataWithNkf:errorを参照。
 * @result 変換したNSStringオブジェクト。エラー発生時はnil。
 */
- (NSString *)stringByNKFWithOptions:(NSString *)options error:(NSError**)error;
/*!
 * @method dataByNKFWithOptions:error
 * @param options nkfのオプションパラメータ
 * @discussion 基本的にはnkf-2.0.8b相当のパラメータを指定します。（ただし使用できないパラメータもあります）
 文字列にはnkfに指定するオプション同様先頭にハイフンをつける必要があります。組み合わせ方もnkfと同等です。
 オプション文字列にnilまたは\@""を指定した場合NKFCocoaのデフォルトエンコーディング(UTF-8)でエンコードします。
 * @param error NSErrorへのポインタ
 * @result 変換したNSDataオブジェクト。エラー発生時はnil。
 */
- (NSData *)dataByNKFWithOptions:(NSString *)options error:(NSError**)error;

@end
