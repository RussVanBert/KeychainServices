#import "KeychainItemWrapper.h"
#import <Security/Security.h>

@interface KeychainItemWrapper (PrivateMethods)

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
- (void)writeToKeychain;

@end

@implementation KeychainItemWrapper

- (id)initWithIdentifier: (NSString *)identifier accessGroup:(NSString *) accessGroup;
{
  if (self = [super init]) {
    self.genericPasswordQuery = NSMutableDictionary.new;
    
    _genericPasswordQuery[b_kSecClass] = b_kSecClassGenericPassword;
    _genericPasswordQuery[b_kSecAttrGeneric] = identifier;
    
    if (accessGroup != nil) {
#if !TARGET_IPHONE_SIMULATOR
        _genericPasswordQuery[b_kSecAttrAccessGroup] = accessGroup;
#endif
    }
    
    _genericPasswordQuery[b_kSecMatchLimit] = b_kSecMatchLimitOne;
    _genericPasswordQuery[b_kSecReturnAttributes] = (b_id)kCFBooleanTrue;
    
    NSDictionary *tempQuery = [NSDictionary dictionaryWithDictionary:_genericPasswordQuery];
    CFMutableDictionaryRef outDictionary = nil;
    
    if (! SecItemCopyMatching((b_CFDictionaryRef)tempQuery, (CFTypeRef *)&outDictionary) == noErr) {
      [self resetKeychainItem];
      _keychainItemData[b_kSecAttrGeneric] = identifier;

#if !TARGET_IPHONE_SIMULATOR
      if (accessGroup != nil) {
        _keychainItemData[b_kSecAttrAccessGroup] = accessGroup;
      }
#endif
        
    } else {
      // load the saved data from keychain
      self.keychainItemData = [self secItemFormatToDictionary:(b_NSDictionary *)outDictionary];
    }
    
    if (outDictionary) {
      CFRelease(outDictionary);
    }
  }
  
  return self;
}


- (void)setObject:(id)inObject forKey:(id)key
{
  if (inObject == nil) return;
  
  if (![_keychainItemData[key] isEqual:inObject]) {
    _keychainItemData[key] = inObject;
    [self writeToKeychain];
  }
}

- (id)objectForKey:(id)key
{
  return _keychainItemData[key];
}

- (void)resetKeychainItem
{
  OSStatus junk = noErr;
  if (!_keychainItemData) {
    self.keychainItemData = NSMutableDictionary.new;
  } else {
    NSMutableDictionary *tempDictionary = [self dictionaryToSecItemFormat:_keychainItemData];
    junk = SecItemDelete((b_CFDictionaryRef)tempDictionary);
    NSAssert( junk == noErr || junk == errSecItemNotFound, @"Problem deleting current dictionary." );
  }
  
  // Default attributes for keychain item.
  _keychainItemData[b_kSecAttrAccount] = @"";
  _keychainItemData[b_kSecAttrLabel] = @"";
  _keychainItemData[b_kSecAttrDescription] = @"";
  
  // Default data for keychain item.
  _keychainItemData[b_kSecValueData] = @"";
}

- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert
{
  NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
  returnDictionary[b_kSecClass] = b_kSecClassGenericPassword;
  returnDictionary[b_kSecValueData] = [[dictionaryToConvert objectForKey:b_kSecValueData]
                                       dataUsingEncoding:NSUTF8StringEncoding];
  return returnDictionary;
}

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
  NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
  returnDictionary[b_kSecReturnData] = (id)kCFBooleanTrue;
  returnDictionary[b_kSecClass] = b_kSecClassGenericPassword;
  
  CFDataRef passwordData = NULL;
  if (SecItemCopyMatching((b_CFDictionaryRef)returnDictionary, (CFTypeRef *)&passwordData) == noErr) {
    [returnDictionary removeObjectForKey:b_kSecReturnData];
    NSString *password = [[NSString alloc] initWithBytes:[(b_NSData *)passwordData bytes]
                                                  length:[(b_NSData *)passwordData length]
                                                encoding:NSUTF8StringEncoding];
    returnDictionary[b_kSecValueData] = password;
  } else {
    NSAssert(NO, @"Serious error, no matching item found in the keychain.\n");
  }
  
  if (passwordData) {
    CFRelease(passwordData);
  }
  
  return returnDictionary;
}

- (void)writeToKeychain
{
  CFDictionaryRef attributes = NULL;
  NSMutableDictionary *updateItem = NULL;
  OSStatus result;
  
  if (SecItemCopyMatching((b_CFDictionaryRef)_genericPasswordQuery, (CFTypeRef *)&attributes) == noErr) {
    updateItem = [NSMutableDictionary dictionaryWithDictionary:(b_NSDictionary *)(attributes)];
    updateItem[b_kSecClass] = [_genericPasswordQuery objectForKey:b_kSecClass];

    NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:_keychainItemData];
    [tempCheck removeObjectForKey:b_kSecClass];
    
#if TARGET_IPHONE_SIMULATOR
    [tempCheck removeObjectForKey:b_kSecAttrAccessGroup];
#endif

    result = SecItemUpdate((b_CFDictionaryRef)updateItem, (b_CFDictionaryRef)tempCheck);
    NSAssert( result == noErr, @"Could not update the Keychain Item." );
  } else {
    result = SecItemAdd((b_CFDictionaryRef)[self dictionaryToSecItemFormat:_keychainItemData], NULL);
    NSAssert( result == noErr, @"Could not add the Keychain Item." );
  }
}

@end
