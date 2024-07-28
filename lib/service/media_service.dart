import 'dart:io';

import 'package:image_picker/image_picker.dart';

class MediaService {
  final ImagePicker picker = ImagePicker();

  MediaService() {}

  Future<File?> getImageFromGallery() async {
    final XFile? _file = await picker.pickImage(source: ImageSource.gallery);

    if (_file != null) {
      return File(_file.path);
    }
    return null;
  }
}
