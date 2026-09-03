// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

typedef ImagePickedCallback = void Function(String base64DataUrl, String fileName);

class ImagePickerPlatform {
  static Future<void> pickImage(ImagePickedCallback onPicked) async {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/png,image/jpeg,image/webp,image/jpg';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((event) {
          final result = reader.result as String?;
          if (result != null) {
            onPicked(result, file.name);
          }
        });
      }
    });
  }
}
