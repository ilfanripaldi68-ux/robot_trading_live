// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class Candle {
  final DateTime time;
  final double open, high, low, close;
  Candle(this.time, this.open, this.high, this.low, this.close);
}

class ApiService {
  static const String _apiKey = "011b86a016224bd4a0a100d565d4ea3f";
  static const String _baseUrl = "https://api.twelvedata.com";

  static Future<List<Candle>> fetchCandles(String symbol, String interval) async {
    final url = Uri.parse("$_baseUrl/time_series?symbol=$symbol&interval=$interval&apikey=$_apiKey&outputsize=50");
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List values = data['values'];
      return values.map((v) {
        return Candle(
          DateTime.parse(v['datetime']),
          double.parse(v['open']),
          double.parse(v['high']),
          double.parse(v['low']),
          double.parse(v['close']),
        );
      }).toList().reversed.toList();
    } else {
      throw Exception("Failed to load data: ${res.body}");
    }
  }
}
