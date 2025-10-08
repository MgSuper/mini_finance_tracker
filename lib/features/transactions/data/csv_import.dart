import 'package:csv/csv.dart';

class ParsedCsv {
  ParsedCsv(this.headers, this.rows);
  final List<String> headers;
  final List<List<String>> rows;
}

ParsedCsv parseCsv(String raw) {
  final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
      .convert(raw)
      .map((r) => r.map((c) => c?.toString() ?? '').toList().cast<String>())
      .toList();

  if (rows.isEmpty) return ParsedCsv(const [], const []);
  final headers = rows.first.map((h) => h.trim()).toList();
  final data = rows.skip(1).toList();
  return ParsedCsv(headers, data);
}
