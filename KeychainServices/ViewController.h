#import "KeychainItemWrapper.h"
#import <UIKit/UIKit.h>
#import <Security/Security.h>

@interface ViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) KeychainItemWrapper *keychain;

- (IBAction)addToKeychain:(id)sender;
- (IBAction)retreiveKeyFromKeychain:(id)sender;

- (IBAction)backgroundTapped:(id)sender;

@end
