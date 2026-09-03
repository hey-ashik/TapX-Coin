typedef ImagePickedCallback = void Function(String base64DataUrl, String fileName);

class ImagePickerPlatform {
  static Future<void> pickImage(ImagePickedCallback onPicked) async {
    // Mobile stub
  }
}
