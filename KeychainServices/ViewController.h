#import <UIKit/UIKit.h>
#import <Security/Security.h>

@interface ViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *password;

- (IBAction)addToKeychain:(id)sender;
- (IBAction)retreiveKeyFromKeychain:(id)sender;

- (IBAction)backgroundTapped:(id)sender;

@end
