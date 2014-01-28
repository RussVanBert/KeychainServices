#import "Keychain.h"
#import "ViewController.h"

@implementation ViewController

@synthesize name, password;

- (void)viewDidLoad {
  name.delegate = self;
  password.delegate = self;
  
  [self textFields];
}

- (void)textFields {
  NSString *nameFromKeychain = [[Keychain sharedKeychain] objectForKey:b_kSecAttrAccount];
  NSString *passwordFromKeychain = [[Keychain sharedKeychain] objectForKey:b_kSecValueData];
  
  NSLog(@"\nName: %@\nPassword: %@", nameFromKeychain, passwordFromKeychain);
  name.text = nameFromKeychain;
  password.text = passwordFromKeychain;
}

- (IBAction)addToKeychain:(id)sender
{
  [[Keychain sharedKeychain] setObject:name.text forKey:b_kSecAttrAccount];
  [[Keychain sharedKeychain] setObject:password.text forKey:b_kSecValueData];
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
