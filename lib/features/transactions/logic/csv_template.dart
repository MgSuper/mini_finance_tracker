import 'dart:convert';
import 'dart:typed_data';

const kMiniFinanceCsvTemplate = '''
date,amount,debit,credit,currency,merchant,description,category
2025-12-14,-9,,,USD,Starbucks,Coffee Cappuccino,Food & Drink
2025-12-14,-15,,,USD,Grab,To Hoi An,Transport
2025-12-14,200,,,USD,Salary,Debt repayment,Income
''';

Uint8List csvTemplateBytes() =>
    Uint8List.fromList(utf8.encode(kMiniFinanceCsvTemplate));
