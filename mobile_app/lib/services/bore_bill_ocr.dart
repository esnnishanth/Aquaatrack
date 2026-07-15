import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class BoreBillOcr {
  BoreBillOcr({http.Client? client, String? backendBaseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = backendBaseUrl ?? const String.fromEnvironment(
          'BACKEND_BASE_URL',
          defaultValue: 'https://aquatrack-orpin.vercel.app',
        );

  final http.Client _client;
  final String _baseUrl;

  Future<BoreScanResult?> extract(XFile image) async {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mediaType = image.mimeType ?? 'image/jpeg';

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/ocr-bore-bill'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image_base64': base64Image,
            'media_type': mediaType,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      final errJson = _tryDecodeMap(response.body);
      throw Exception(
        'Server error (${response.statusCode}): ${errJson['error'] ?? errJson['detail'] ?? response.body}',
      );
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    return _parseAndValidate(json);
  }



  BoreScanResult _parseAndValidate(Map<String, dynamic> json) {
    final unclear = <String>[
      ...((json['unclear_fields'] as List?)?.cast<String>() ?? const []),
    ];

    double parseNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
    }

    final feetRaw = (json['feet_entries'] as List?) ?? const [];
    final feetEntries = <ScannedFeetEntry>[];
    double feetTotalCalc = 0;
    for (var i = 0; i < feetRaw.length; i++) {
      final row = feetRaw[i] as Map<String, dynamic>;
      final length = parseNum(row['length']);
      final rate = parseNum(row['rate']);
      final printedAmount = parseNum(row['amount']);
      final calcAmount = length * rate;
      feetTotalCalc += calcAmount;
      if (printedAmount > 0 && (printedAmount - calcAmount).abs() > 1) {
        unclear.add('Feet entry #${i + 1} (length or rate)');
      }
      if (length > 0) {
        feetEntries.add(ScannedFeetEntry(length: length, pricePerFeet: rate));
      }
    }
    final feetTotalPrinted = parseNum(json['feet_total_amount']);
    if (feetTotalPrinted > 0 &&
        (feetTotalPrinted - feetTotalCalc).abs() > 1) {
      unclear.add('Bore Feet Entries total');
    }

    final pipeRaw = (json['pipe_entries'] as List?) ?? const [];
    final pipeEntries = <ScannedPipeEntry>[];
    double pipeTotalCalc = 0;
    for (var i = 0; i < pipeRaw.length; i++) {
      final row = pipeRaw[i] as Map<String, dynamic>;
      final size = parseNum(row['size']);
      final length = parseNum(row['length']);
      final price = parseNum(row['price']);
      final printedAmount = parseNum(row['amount']);
      final calcAmount = length * price;
      pipeTotalCalc += calcAmount;
      if (printedAmount > 0 && (printedAmount - calcAmount).abs() > 1) {
        unclear.add('PVC entry #${i + 1} (length or price)');
      }
      if (length > 0) {
        pipeEntries.add(ScannedPipeEntry(
          size: size,
          length: length,
          pricePerPipeFoot: price,
        ));
      }
    }
    final pipeTotalPrinted = parseNum(json['pipe_total_amount']);
    if (pipeTotalPrinted > 0 &&
        (pipeTotalPrinted - pipeTotalCalc).abs() > 1) {
      unclear.add('PVC Pipe Entries total');
    }

    final steel = json['steel'] as Map<String, dynamic>?;
    final steelApplicable = steel?['applicable'] == true;
    final steelFeet = steelApplicable ? parseNum(steel!['feet']) : 0.0;
    final steelPrice = steelApplicable ? parseNum(steel!['price_per_feet']) : 0.0;
    final steelWelding =
        steelApplicable ? parseNum(steel!['welding_charge']) : 0.0;
    final steelPrinted = steelApplicable ? parseNum(steel!['amount']) : 0.0;
    final steelCalc = steelFeet * steelPrice + steelWelding;
    if (steelApplicable && steelPrinted > 0 &&
        (steelPrinted - steelCalc).abs() > 1) {
      unclear.add('Steel Entry amount');
    }

    final totalPrinted = parseNum(json['total_bill']);
    final totalCalc = feetTotalCalc + pipeTotalCalc + steelCalc;
    if (totalPrinted > 0 && (totalPrinted - totalCalc).abs() > 1) {
      unclear.add('Total Bill');
    }
    final totalBill = totalPrinted > 0 ? totalPrinted : totalCalc;

    DateTime? date;
    final dateStr = json['date'] as String?;
    if (dateStr != null) {
      date = DateTime.tryParse(dateStr);
    }

    final confidence = unclear.isEmpty
        ? 'high'
        : (unclear.length <= 2 ? 'medium' : 'low');

    return BoreScanResult(
      boreNumber: json['bore_number'] as String?,
      date: date,
      agentName: json['agent_name'] as String?,
      feetEntries: feetEntries,
      pipesUsed: pipeEntries,
      steelFeet: steelFeet,
      steelPricePerFeet: steelPrice,
      steelWeldingCharge: steelWelding,
      totalBill: totalBill,
      initialPayment: parseNum(json['initial_payment']),
      confidence: confidence,
      unclearFields: unclear,
    );
  }

  Map<String, dynamic> _tryDecodeMap(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> dispose() async {
    _client.close();
  }
}
