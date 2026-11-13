#import "MLKitUserDefaultsFix.h"

#import <objc/runtime.h>

// The app carries two GULUserDefaults classes: GoogleUtilities 8 (SPM, linked into Runner, used by
// ML Kit and Firebase) and GoogleUtilities 7 (CocoaPods, in GoogleUtilities.framework). 8 dropped
// -synchronize, which ML Kit still calls the first time a recognizer is created after install, so
// every first OCR crashed (#133, #120). NSClassFromString returns the framework's copy, so the class
// is declared here instead: the linker binds it to the copy inside Runner, the one ML Kit uses.
// A no-op is correct: GoogleUtilities 8 writes through to NSUserDefaults, which persists itself.
@interface GULUserDefaults : NSObject
@end

static void NoOpSynchronize(id self, SEL _cmd) {}

void RestoreUserDefaultsSynchronizeForMLKit(void) {
  class_addMethod([GULUserDefaults class], @selector(synchronize), (IMP)NoOpSynchronize, "v@:");
}
