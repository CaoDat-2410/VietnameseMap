import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> savePdfFromUrl(
  String url, {
  required String suggestedFileName,
}) async {
  final response = await Dio().get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );
  final bytes = response.data;
  if (bytes == null || bytes.isEmpty) return false;

  final tempDir = await getTemporaryDirectory();
  final tempFile = File(
    '${tempDir.path}${Platform.pathSeparator}$suggestedFileName',
  );
  await tempFile.writeAsBytes(bytes, flush: true);
  final savedPath = await FlutterFileDialog.saveFile(
    params: SaveFileDialogParams(
      sourceFilePath: tempFile.path,
      fileName: suggestedFileName,
      mimeTypesFilter: const ['application/pdf'],
    ),
  );
  return savedPath != null;
}
