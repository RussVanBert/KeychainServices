#import <Foundation/Foundation.h>
#import "KeychainItemWrapper.h"

@interface Keychain : NSObject

+ (KeychainItemWrapper *)sharedKeychain;

@end
