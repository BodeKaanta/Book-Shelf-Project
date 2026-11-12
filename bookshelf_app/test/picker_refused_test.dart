import 'package:bookshelf_app/models/pending_book.dart';
import 'package:bookshelf_app/providers/import_provider.dart';
import 'package:bookshelf_app/screens/capture_screen.dart';
import 'package:bookshelf_app/screens/import_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

// #138: refusing the camera permission left Capture stuck on "Recognizing…".
// image_picker reports a refusal by throwing, exactly as this fake does, so
// these reproduce the tap that found the bug.
class _RefusingPicker extends ImagePickerPlatform {
  final String code;

  _RefusingPicker(this.code);

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => throw PlatformException(code: code);

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async => throw PlatformException(code: code);
}

// Starts with one book left in review from an earlier import.
class _WithPendingReview extends ImportNotifier {
  _WithPendingReview(super.ref) {
    state = const ImportState(
      queue: [PendingBook(imagePath: 'x.jpg', candidates: [], confidence: 0.5)],
    );
  }
}

void main() {
  Future<void> show(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [importProvider.overrideWith(_WithPendingReview.new)],
        child: MaterialApp(home: screen),
      ),
    );
  }

  Future<void> tapAndLetTheRefusalArrive(
    WidgetTester tester,
    String label,
  ) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // snackbar slides in
  }

  testWidgets(
    'Capture goes back to its start screen when the camera is refused',
    (tester) async {
      ImagePickerPlatform.instance = _RefusingPicker('camera_access_denied');
      await show(tester, const CaptureScreen());

      await tapAndLetTheRefusalArrive(tester, 'Take Photo');

      expect(find.text('Recognizing…'), findsNothing);
      expect(find.text('Take Photo'), findsOneWidget); // can be tapped again
      // iOS never asks twice, so the way back has to be named.
      expect(find.textContaining('allow it in Settings'), findsOneWidget);
    },
  );

  testWidgets('Import goes back to its start screen when photos are refused', (
    tester,
  ) async {
    ImagePickerPlatform.instance = _RefusingPicker('photo_access_denied');
    await show(tester, const ImportScreen());

    await tapAndLetTheRefusalArrive(tester, 'Choose Photos');

    expect(find.text('Loading your photos…'), findsNothing);
    expect(find.text('Choose Photos'), findsOneWidget);
    expect(find.textContaining('allow it in Settings'), findsOneWidget);
  });

  testWidgets('a refused pick keeps the books still waiting for review', (
    tester,
  ) async {
    ImagePickerPlatform.instance = _RefusingPicker('photo_access_denied');
    await show(tester, const ImportScreen());
    expect(find.text('1 book needs review'), findsOneWidget);

    await tapAndLetTheRefusalArrive(tester, 'Choose Photos');

    expect(find.text('1 book needs review'), findsOneWidget);
  });

  testWidgets('any other picker failure also clears the loader', (
    tester,
  ) async {
    ImagePickerPlatform.instance = _RefusingPicker('no_available_camera');
    await show(tester, const CaptureScreen());

    await tapAndLetTheRefusalArrive(tester, 'Take Photo');

    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text("Couldn't open the camera."), findsOneWidget);
  });
}
