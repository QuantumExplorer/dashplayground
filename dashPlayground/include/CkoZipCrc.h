// Chilkat Objective-C header.
// This is a generated header file for Chilkat version 9.5.0.66

// Generic/internal class name =  ZipCrc
// Wrapped Chilkat C++ class name =  CkZipCrc

@class CkoTask;


@class CkoBaseProgress;

@interface CkoZipCrc : NSObject {

	@private
		void *m_eventCallback;
		void *m_obj;

}

- (id)init;
- (void)dealloc;
- (void)dispose;
- (NSString *)stringWithUtf8: (const char *)s;
- (void *)CppImplObj;
- (void)setCppImplObj: (void *)pObj;

- (void)clearCppImplObj;

// property setter: EventCallbackObject
- (void)setEventCallbackObject: (CkoBaseProgress *)eventObj;

@property (nonatomic) BOOL LastMethodSuccess;
// method: BeginStream
- (void)BeginStream;
// method: CalculateCrc
- (NSNumber *)CalculateCrc: (NSData *)data;
// method: EndStream
- (NSNumber *)EndStream;
// method: FileCrc
- (NSNumber *)FileCrc: (NSString *)path;
// method: FileCrcAsync
- (CkoTask *)FileCrcAsync: (NSString *)path;
// method: MoreData
- (void)MoreData: (NSData *)data;
// method: ToHex
- (NSString *)ToHex: (NSNumber *)crc;

@end
