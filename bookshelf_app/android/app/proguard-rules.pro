# google_mlkit_text_recognition's initialize() references the options class for
# every script it supports, but we only depend on the Latin model. R8 treats the
# absent ones as fatal missing references unless told they're expected.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit resolves the recognizer and its bundled model reflectively, so R8 can't
# see those members used and strips them. The classes themselves survive, which
# is why there's no crash — processImage() simply never returns and the import
# spins at "0 of N" forever. Debug is unminified, so this cannot reproduce there.
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
