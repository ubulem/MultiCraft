#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MultiCraft-Swift.h>
#import "VersionManager.h"
#import <Bugsnag/Bugsnag.h>
#include "ioswrap.h"

void ioswrap_log(const char *message)
{
#if !NDEBUG
	NSLog(@"%s", message);
#endif
}

void init_IOS_Settings()
{
	[Bugsnag startBugsnagWithApiKey:CrashliticsApiKey];
}

void ioswrap_paths(int type, char *dest, size_t destlen)
{
	NSArray *paths;

	if (type == PATH_DOCUMENTS)
		paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	else if (type == PATH_LIBRARY_SUPPORT || type == PATH_LIBRARY_CACHE)
		paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	else
		return;

	NSString *path = paths.firstObject;
	const char *path_c = path.UTF8String;

	if (type == PATH_DOCUMENTS)
		snprintf(dest, destlen, "%s", path_c);
	else if (type == PATH_LIBRARY_SUPPORT)
		snprintf(dest, destlen, "%s/Application Support", path_c);
	else // type == PATH_LIBRARY_CACHE
		snprintf(dest, destlen, "%s/Caches", path_c);
}


static void recursive_delete(NSString *path)
{
	NSFileManager *fm = [NSFileManager defaultManager];
	for (NSString *file in [fm contentsOfDirectoryAtPath:path error:nil])
		[fm removeItemAtPath:[path stringByAppendingPathComponent:file] error:nil];
}


void ioswrap_assets()
{
	MainWindow *window = [[MainWindow alloc] init];
	[window run];

	ProgressViewController *progressVC = [[ProgressViewController alloc] initWithNibName:@"ProgressViewController" bundle:nil];
	[progressVC presentIn:window.rootViewController];

	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, YES);

	ZipManager *manager = [[ZipManager alloc] init];
	[manager runProcess:^(NSInteger progress) {
		[progressVC updateProgress:progress];
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, YES);
	}];

	[progressVC dismissView];
	window.backgroundColor = [UIColor blackColor];
}

void ioswrap_asset_refresh(void)
{
	char buf[256];
	ioswrap_paths(PATH_LIBRARY_SUPPORT, buf, sizeof(buf));
	NSString *destpath = [NSString stringWithUTF8String:buf];

	// set asset version to 1, will be extracted next time
	[VersionManager writeVersionWithPath:destpath ver:1];
}

void ioswrap_size(unsigned int *dest)
{
	CGSize bounds = [[UIScreen mainScreen] bounds].size;
	CGFloat scale = [[UIScreen mainScreen] scale];
	dest[0] = (unsigned int) (bounds.width * scale);
	dest[1] = (unsigned int) (bounds.height * scale);
	dest[2] = (unsigned int) scale;
}

/********/

static int dialog_state;
static char dialog_text[512];

#define DIALOG_MULTILINE  1
#define DIALOG_SINGLELINE 2
#define DIALOG_PASSWORD   3

void ioswrap_show_dialog(void *uiviewcontroller, const char *accept, const char *hint, const char *current, int type)
{
	UIViewController *viewc = (__bridge UIViewController *) uiviewcontroller;

	if (type == DIALOG_MULTILINE) {
		MessageViewController *vc = [[MessageViewController alloc] initWithNibName:@"MessageViewController" bundle:nil];
		vc.message = [NSString stringWithUTF8String:current];
		[vc setDidSendMessage:^(NSString *message) {
			dialog_state = 0;
			strncpy(dialog_text, message.UTF8String, sizeof(dialog_text));
		}];
		[vc presentIn:viewc];

		dialog_state = -1;
		dialog_text[0] = 0;
	} else {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Text Input", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];

		[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
			textField.text = [NSString stringWithUTF8String:current];
			if (type == DIALOG_PASSWORD)
				textField.secureTextEntry = YES;
		}];

		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			dialog_state = 0;
			strncpy(dialog_text, alert.textFields[0].text.UTF8String, sizeof(dialog_text));
		}]];

		dialog_state = -1;
		dialog_text[0] = 0;
		[viewc presentViewController:alert animated:YES completion:nil];
	}
}

int ioswrap_get_dialog(const char **text)
{
	int ret = dialog_state;
	if (text) {
		*text = dialog_text;
		dialog_state = -1; // reset
	}

	return ret;
}
