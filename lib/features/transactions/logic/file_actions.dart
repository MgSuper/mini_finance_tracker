import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvFileActions {
  static String buildTemplateName() {
    final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'mini_finance_template_$ts.csv';
  }

  /// ✅ Save to device / Downloads (Web: triggers download)
  static Future<void> saveToDevice({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await FileSaver.instance.saveFile(
      name: fileName.replaceAll('.csv', ''),
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  /// ✅ Share via system share sheet (Android/iOS)
  /// (Web will fallback to download/save usually)
  static Future<void> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$fileName');
    await f.writeAsBytes(bytes, flush: true);

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(f.path, mimeType: 'text/csv', name: fileName)],
      subject: 'Mini Finance CSV template',
      text: 'Use this CSV template to import transactions.',
    );
  }
}
