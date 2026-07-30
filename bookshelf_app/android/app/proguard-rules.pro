# google_mlkit_text_recognition's initialize() references the options class for
# every script it supports, but we only depend on the Latin model. R8 treats the
# absent ones as fatal missing references unless told they're expected.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
