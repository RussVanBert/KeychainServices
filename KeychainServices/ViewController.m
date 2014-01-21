#import "ViewController.h"

@implementation ViewController

@synthesize name, password, keychain;

- (void)viewDidLoad {
  name.delegate = self;
  password.delegate = self;
  
  keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"YourAppKeychainId" accessGroup:nil];
  [self textFields];
}

- (void)textFields {
  NSString *nameFromKeychain = [keychain objectForKey:b_kSecAttrAccount];
  NSString *passwordFromKeychain = [keychain objectForKey:b_kSecValueData];
  
  NSLog(@"\nName: %@\nPassword: %@", nameFromKeychain, passwordFromKeychain);
  name.text = nameFromKeychain;
  password.text = passwordFromKeychain;
}

- (IBAction)addToKeychain:(id)sender
{
  [keychain setObject:name.text forKey:b_kSecAttrAccount];
  [keychain setObject:password.text forKey:b_kSecValueData];
}

- (IBAction)retreiveKeyFromKeychain:(id)sender
{
  [self textFields];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

- (IBAction)backgroundTapped:(id)sender
{
  [self.view endEditing:YES];
}

@end
