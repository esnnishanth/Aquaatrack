import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  ApiService({required this.baseUrl});

  Future<List<dynamic>> fuzzySearch(String term, List<dynamic> items) async {
    final url = Uri.parse('$baseUrl/api/algorithms/fuzzy');
    final resp = await http.post(url, body: jsonEncode({'term': term, 'items': items}), headers: {'Content-Type': 'application/json'});
    if (resp.statusCode == 200) return jsonDecode(resp.body) as List<dynamic>;
    throw Exception('API error ${resp.statusCode}');
  }

  // other adapters (forecast, anomaly) can be added similarly
}
