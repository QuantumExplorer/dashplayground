// Chilkat Objective-C header.
// This is a generated header file for Chilkat version 9.5.0.66

// Generic/internal class name =  Accounts
// Wrapped Chilkat C++ class name =  CkAccounts

@class CkoPublicKey;
@class CkoPrivateKey;


@interface CkoAccounts : NSObject {

	@private
		void *m_obj;

}

- (id)init;
- (void)dealloc;
- (void)dispose;
- (NSString *)stringWithUtf8: (const char *)s;
- (void *)CppImplObj;
- (void)setCppImplObj: (void *)pObj;

- (void)clearCppImplObj;

@property (nonatomic, copy) NSString *DebugLogFilePath;
@property (nonatomic, readonly, copy) NSString *LastErrorHtml;
@property (nonatomic, readonly, copy) NSString *LastErrorText;
@property (nonatomic, readonly, copy) NSString *LastErrorXml;
@property (nonatomic) BOOL LastMethodSuccess;
@property (nonatomic) BOOL VerboseLogging;
@property (nonatomic, readonly, copy) NSString *Version;
// method: DeleteAccount
- (BOOL)DeleteAccount: (NSString *)accountName;
// method: GetEncrypted
- (NSString *)GetEncrypted: (NSString *)encoding 
	rsaKey: (CkoPublicKey *)rsaKey;
// method: GetJson
- (NSString *)GetJson;
// method: LoadEncrypted
- (BOOL)LoadEncrypted: (NSString *)accountData 
	encoding: (NSString *)encoding 
	rsaKey: (CkoPrivateKey *)rsaKey;
// method: LoadJson
- (BOOL)LoadJson: (NSString *)accountData;
// method: SaveLastError
- (BOOL)SaveLastError: (NSString *)path;

@end
