#import "Keychain.h"

@implementation Keychain

+ (KeychainItemWrapper *)sharedKeychain
{
  static KeychainItemWrapper *sharedKeychain = nil;
  if (!sharedKeychain)
  {
    sharedKeychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"YourAppKeychainId" accessGroup:nil];
  }
  
  return sharedKeychain;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
  return (id)[self sharedKeychain];
}

@end
