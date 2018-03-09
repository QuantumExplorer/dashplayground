// Chilkat Objective-C header.
// This is a generated header file for Chilkat version 9.5.0.72

// Generic/internal class name =  XmlDSigGen
// Wrapped Chilkat C++ class name =  CkXmlDSigGen

@class CkoStringBuilder;
@class CkoBinData;
@class CkoPrivateKey;
@class CkoCert;


@interface CkoXmlDSigGen : NSObject {

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

@property (nonatomic, copy) NSString *Behaviors;
@property (nonatomic, copy) NSString *CustomKeyInfoXml;
@property (nonatomic, copy) NSString *DebugLogFilePath;
@property (nonatomic, copy) NSString *IncNamespacePrefix;
@property (nonatomic, copy) NSString *IncNamespaceUri;
@property (nonatomic, copy) NSString *KeyInfoKeyName;
@property (nonatomic, copy) NSString *KeyInfoType;
@property (nonatomic, readonly, copy) NSString *LastErrorHtml;
@property (nonatomic, readonly, copy) NSString *LastErrorText;
@property (nonatomic, readonly, copy) NSString *LastErrorXml;
@property (nonatomic) BOOL LastMethodSuccess;
@property (nonatomic, copy) NSString *SigId;
@property (nonatomic, copy) NSString *SigLocation;
@property (nonatomic, copy) NSString *SigNamespacePrefix;
@property (nonatomic, copy) NSString *SigNamespaceUri;
@property (nonatomic, copy) NSString *SignedInfoCanonAlg;
@property (nonatomic, copy) NSString *SignedInfoDigestMethod;
@property (nonatomic, copy) NSString *SignedInfoPrefixList;
@property (nonatomic, copy) NSString *SigningAlg;
@property (nonatomic) BOOL VerboseLogging;
@property (nonatomic, readonly, copy) NSString *Version;
@property (nonatomic, copy) NSString *X509Type;
// method: AddEnvelopedRef
- (BOOL)AddEnvelopedRef: (NSString *)id 
	content: (CkoStringBuilder *)content 
	digestMethod: (NSString *)digestMethod 
	canonMethod: (NSString *)canonMethod 
	refType: (NSString *)refType;
// method: AddExternalBinaryRef
- (BOOL)AddExternalBinaryRef: (NSString *)uri 
	content: (CkoBinData *)content 
	digestMethod: (NSString *)digestMethod 
	refType: (NSString *)refType;
// method: AddExternalFileRef
- (BOOL)AddExternalFileRef: (NSString *)uri 
	localFilePath: (NSString *)localFilePath 
	digestMethod: (NSString *)digestMethod 
	refType: (NSString *)refType;
// method: AddExternalTextRef
- (BOOL)AddExternalTextRef: (NSString *)uri 
	content: (CkoStringBuilder *)content 
	charset: (NSString *)charset 
	includeBom: (BOOL)includeBom 
	digestMethod: (NSString *)digestMethod 
	refType: (NSString *)refType;
// method: AddExternalXmlRef
- (BOOL)AddExternalXmlRef: (NSString *)uri 
	content: (CkoStringBuilder *)content 
	digestMethod: (NSString *)digestMethod 
	canonMethod: (NSString *)canonMethod 
	refType: (NSString *)refType;
// method: AddSameDocRef
- (BOOL)AddSameDocRef: (NSString *)id 
	digestMethod: (NSString *)digestMethod 
	canonMethod: (NSString *)canonMethod 
	prefixList: (NSString *)prefixList 
	refType: (NSString *)refType;
// method: CreateXmlDSig
- (NSString *)CreateXmlDSig: (NSString *)inXml;
// method: CreateXmlDSigSb
- (BOOL)CreateXmlDSigSb: (CkoStringBuilder *)sbXml;
// method: SaveLastError
- (BOOL)SaveLastError: (NSString *)path;
// method: SetHmacKey
- (BOOL)SetHmacKey: (NSString *)key 
	encoding: (NSString *)encoding;
// method: SetPrivateKey
- (BOOL)SetPrivateKey: (CkoPrivateKey *)privKey;
// method: SetX509Cert
- (BOOL)SetX509Cert: (CkoCert *)cert 
	usePrivateKey: (BOOL)usePrivateKey;

@end
