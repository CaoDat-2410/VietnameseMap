import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

typedef AvatarFile = (String, Uint8List, String);

Future<AvatarFile?> pickAvatarFile() async {
  final completer = Completer<AvatarFile?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/webp';
  input.click();
  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is! List<int>) {
        completer.complete(null);
        return;
      }
      completer.complete((
        file.name,
        Uint8List.fromList(result),
        file.type.isNotEmpty ? file.type : 'image/jpeg',
      ));
    });
    reader.onError.listen((_) => completer.complete(null));
    reader.readAsArrayBuffer(file);
  });
  return completer.future;
}
