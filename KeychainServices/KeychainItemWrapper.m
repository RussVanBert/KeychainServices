#import "KeychainItemWrapper.h"
#import <Security/Security.h>

@interface KeychainItemWrapper (PrivateMethods)
/*
 The decision behind the following two methods (secItemFormatToDictionary and dictionaryToSecItemFormat) was
 to encapsulate the transition between what the detail view controller was expecting (NSString *) and what the
 Keychain API expects as a validly constructed container class.
 */
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;

// Updates the item in the keychain, or adds it if it doesn't exist.
- (void)writeToKeychain;

@end

@implementation KeychainItemWrapper

- (id)initWithIdentifier: (NSString *)identifier accessGroup:(NSString *) accessGroup;
{
  if (self = [super init]) {
    // Begin Keychain search setup. The genericPasswordQuery leverages the special user
    // defined attribute kSecAttrGeneric to distinguish itself between other generic Keychain
    // items which may be included by the same application.
    self.genericPasswordQuery = NSMutableDictionary.new;
    
    _genericPasswordQuery[b_kSecClass] = b_kSecClassGenericPassword;
    _genericPasswordQuery[b_kSecAttrGeneric] = identifier;
    
		// The keychain access group attribute determines if this item can be shared
		// amongst multiple apps whose code signing entitlements contain the same keychain access group.
#if !TARGET_IPHONE_SIMULATOR
    // Ignore the access group if running on the iPhone simulator.
    //
    // Apps that are built for the simulator aren't signed, so there's no keychain access group
    // for the simulator to check. This means that all apps can see all keychain items when run
    // on the simulator.
    //
    // If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
    // simulator will return -25243 (errSecNoAccessForItem).
    if (accessGroup != nil) {
        _genericPasswordQuery[b_kSecAttrAccessGroup] = accessGroup;
    }
#endif
    
		// Use the proper search constants, return only the attributes of the first match.
    _genericPasswordQuery[b_kSecMatchLimit] = b_kSecMatchLimitOne;
    _genericPasswordQuery[b_kSecReturnAttributes] = (b_id)kCFBooleanTrue;
    
    NSDictionary *tempQuery = [NSDictionary dictionaryWithDictionary:_genericPasswordQuery];
    CFMutableDictionaryRef outDictionary = nil;
    
    if (! SecItemCopyMatching((b_CFDictionaryRef)tempQuery, (CFTypeRef *)&outDictionary) == noErr) {
      // Stick these default values into keychain item if nothing found.
      [self resetKeychainItem];
      _keychainItemData[b_kSecAttrGeneric] = identifier;

#if !TARGET_IPHONE_SIMULATOR
      if (accessGroup != nil) {
        // Add the generic attribute and the keychain access group.
        //
				// Ignore the access group if running on the iPhone simulator.
				//
				// Apps that are built for the simulator aren't signed, so there's no keychain access group
				// for the simulator to check. This means that all apps can see all keychain items when run
				// on the simulator.
				//
				// If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
				// simulator will return -25243 (errSecNoAccessForItem).
        _keychainItemData[b_kSecAttrAccessGroup] = accessGroup;
      }
#endif
        
    } else {
      // load the saved data from Keychain.
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
  OSStatus result = noErr;
  if (!_keychainItemData) {
    self.keychainItemData = NSMutableDictionary.new;
  } else {
    NSMutableDictionary *tempDictionary = [self dictionaryToSecItemFormat:_keychainItemData];
    result = SecItemDelete((b_CFDictionaryRef)tempDictionary);
    NSAssert( result == noErr || result == errSecItemNotFound, @"Problem deleting current dictionary." );
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
  // The assumption is that this method will be called with a properly populated dictionary
  // containing all the right key/value pairs for a SecItem.
  
  // Create a dictionary to return populated with the attributes and data.
  NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
  // Add the Generic Password keychain item class attribute.
  returnDictionary[b_kSecClass] = b_kSecClassGenericPassword;
  // Convert the NSString to NSData to meet the requirements for the value type kSecValueData.
	// This is where to store sensitive data that should be encrypted.
  returnDictionary[b_kSecValueData] = [[dictionaryToConvert objectForKey:b_kSecValueData]
                                       dataUsingEncoding:NSUTF8StringEncoding];
  return returnDictionary;
}

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
  // The assumption is that this method will be called with a properly populated dictionary
  // containing all the right key/value pairs for the UI element.
  
  // Create a dictionary to return populated with the attributes and data.
  NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
  // Add the proper search key and class attribute.
  returnDictionary[b_kSecReturnData] = (id)kCFBooleanTrue;
  returnDictionary[b_kSecClass] = b_kSecClassGenericPassword;
  
  // Acquire the password data from the attributes.
  CFDataRef passwordData = NULL;
  if (SecItemCopyMatching((b_CFDictionaryRef)returnDictionary, (CFTypeRef *)&passwordData) == noErr) {
    // Remove the search, class, and identifier key/value, we don't need them anymore.
    [returnDictionary removeObjectForKey:b_kSecReturnData];
    // Add the password to the dictionary, converting from NSData to NSString.
    NSString *password = [[NSString alloc] initWithBytes:[(b_NSData *)passwordData bytes]
                                                  length:[(b_NSData *)passwordData length]
                                                encoding:NSUTF8StringEncoding];
    returnDictionary[b_kSecValueData] = password;
  } else {
    // Don't do anything if nothing is found.
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
    // First we need the attributes from the Keychain.
    updateItem = [NSMutableDictionary dictionaryWithDictionary:(b_NSDictionary *)(attributes)];
    // Second we need to add the appropriate search key/values.
    updateItem[b_kSecClass] = [_genericPasswordQuery objectForKey:b_kSecClass];

    // Lastly, we need to set up the updated attribute list being careful to remove the class.
    NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:_keychainItemData];
    [tempCheck removeObjectForKey:b_kSecClass];
    
#if TARGET_IPHONE_SIMULATOR
		// Remove the access group if running on the iPhone simulator.
		//
		// Apps that are built for the simulator aren't signed, so there's no keychain access group
		// for the simulator to check. This means that all apps can see all keychain items when run
		// on the simulator.
		//
		// If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
		// simulator will return -25243 (errSecNoAccessForItem).
		//
		// The access group attribute will be included in items returned by SecItemCopyMatching,
		// which is why we need to remove it before updating the item.
    [tempCheck removeObjectForKey:b_kSecAttrAccessGroup];
#endif

    // An implicit assumption is that you can only update a single item at a time.
    result = SecItemUpdate((b_CFDictionaryRef)updateItem, (b_CFDictionaryRef)tempCheck);
    NSAssert( result == noErr, @"Could not update the Keychain Item." );
  } else {
    // No previous item found; add the new one.
    result = SecItemAdd((b_CFDictionaryRef)[self dictionaryToSecItemFormat:_keychainItemData], NULL);
    NSAssert( result == noErr, @"Could not add the Keychain Item." );
  }
}

@end
