#import <UIKit/UIKit.h>

#define b_kSecAttrAccessGroup      ((__bridge id) kSecAttrAccessGroup)
#define b_kSecAttrAccount          ((__bridge id) kSecAttrAccount)
#define b_kSecAttrGeneric          ((__bridge id) kSecAttrGeneric)
#define b_kSecAttrDescription      ((__bridge id) kSecAttrDescription)
#define b_kSecAttrLabel            ((__bridge id) kSecAttrLabel)
#define b_kSecClass                ((__bridge id) kSecClass)
#define b_kSecClassGenericPassword ((__bridge id) kSecClassGenericPassword)
#define b_kSecMatchLimit           ((__bridge id) kSecMatchLimit)
#define b_kSecMatchLimitOne        ((__bridge id) kSecMatchLimitOne)
#define b_kSecReturnAttributes     ((__bridge id) kSecReturnAttributes)
#define b_kSecReturnData           ((__bridge id) kSecReturnData)
#define b_kSecValueData            ((__bridge id) kSecValueData)

#define b_CFDictionaryRef          __bridge CFDictionaryRef
#define b_id                       __bridge id
#define b_NSData                   __bridge NSData
#define b_NSDictionary             __bridge NSDictionary

@interface KeychainItemWrapper : NSObject

@property (strong, nonatomic) NSMutableDictionary *keychainItemData;
@property (strong, nonatomic) NSMutableDictionary *genericPasswordQuery;

- (id)initWithIdentifier: (NSString *)identifier accessGroup:(NSString *) accessGroup;

- (void)setObject:(id)inObject forKey:(id)key;
- (id)objectForKey:(id)key;

- (void)resetKeychainItem;
- (void)resetObjectForKey:(id)key;

@end
