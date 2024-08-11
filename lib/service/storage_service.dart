import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService {
  StorageService() {}

  Future<String?> uploadUserPfp({
    required File file,
    required String uid,
  }) async {
    Reference fileRef = FirebaseStorage.instance
        .ref('users/pfps')
        .child('$uid${p.extension(file.path)}');
    UploadTask task = fileRef.putFile(file);

    return task.then((p) {
      if (p.state == TaskState.success) {
        return fileRef.getDownloadURL();
      }
    });
  }

  Future<String?> uploadImageToChat(
      {required File file, required String chatID}) async {
    Reference fileRef = FirebaseStorage.instance
        .ref('chats/$chatID')
        .child('${DateTime.now().toIso8601String()}${p.extension(file.path)}');

    UploadTask task = fileRef.putFile(file);

    return task.then((p) {
      if (p.state == TaskState.success) {
        return fileRef.getDownloadURL();
      } else {
        return null;
      }
    });
  }

  Future<void> deleteFileFromStorage({required String url}) async {
    try {
      final reference = FirebaseStorage.instance.refFromURL(url);
      await reference.delete();
    } catch (e) {
      throw Exception('Error deleting file from storage');
    }
  }
}
